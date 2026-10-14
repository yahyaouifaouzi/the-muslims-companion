import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_store.dart';

/// Wraps flutter_local_notifications for the two optional adhkar reminders.
///
/// Design choices:
/// - **Inexact scheduling** (`AndroidScheduleMode.inexact`) — no exact-alarm
///   permission is requested; each reminder fires within a system-defined
///   window around the chosen time.
/// - **One notification id per [ReminderSlot]** — rescheduling replaces the
///   previous schedule for that slot; the two slots never collide.
/// - **Daily repetition** via `DateTimeComponents.time` so the OS re-arms
///   the alarm each day. The plugin's boot receiver re-registers schedules
///   after a reboot (Android), and [rescheduleEnabled] re-arms after a
///   timezone change on next launch.
/// - **Tap opens the matching adhkar** via [onOpenAdhkar] (or the pending
///   slot handed to the shell on a cold start).
///
/// Cross-platform: Android and Windows support `zonedSchedule`. Linux does
/// not (the plugin only supports immediate `show`), so [supportsScheduling]
/// is false there and the reminder UI is hidden.
class NotificationService {
  static const Map<ReminderSlot, int> _ids = <ReminderSlot, int>{
    ReminderSlot.morning: 0,
    ReminderSlot.evening: 1,
  };
  static const String _aumid = 'com.ideas2d.themuslimscompanion';
  static const String _winGuid = '{8f3a5b1e-2c4d-4e6f-8a9b-0c1d2e3f4a5b}';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Set by the shell; called when the user taps a reminder notification.
  void Function(ReminderSlot slot)? onOpenAdhkar;

  /// A notification tap that arrived before [onOpenAdhkar] was attached
  /// (cold start). Consumed once by the shell.
  static ReminderSlot? pendingSlot;

  /// True on platforms where the plugin supports scheduled (zoned) reminders.
  ///
  /// Android and Windows: yes. Linux: no (plugin lacks `zonedSchedule`).
  bool get supportsScheduling =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.windows;

  /// Initializes timezone handling and the notification plugin.
  ///
  /// Returns false when initialization fails (the app still works; the
  /// reminder simply cannot be scheduled).
  Future<bool> init() async {
    if (_initialized) return true;
    try {
      tz_data.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open',
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: 'Rafiq',
        appUserModelId: _aumid,
        guid: _winGuid,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      );
      final ok = await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      _initialized = ok ?? false;
      return _initialized;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final slot = ReminderSlot.values.cast<ReminderSlot?>().firstWhere(
      (ReminderSlot? slot) => slot?.categoryId == response.payload,
      orElse: () => null,
    );
    if (slot == null) return;
    final handler = onOpenAdhkar;
    if (handler != null) {
      handler(slot);
    } else {
      pendingSlot = slot;
    }
  }

  /// Requests the POST_NOTIFICATIONS runtime permission (Android 13+).
  ///
  /// Returns true when notifications are allowed (either already granted or
  /// newly granted). Returns false when the user denies or the platform
  /// reports notifications disabled. Non-Android platforms return true
  /// (no runtime permission model for local notifications).
  Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return true; // Non-Android: no runtime permission.
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// True when the OS currently allows notifications (Android only check;
  /// other platforms report true). Used to explain a denied state instead
  /// of silently failing to schedule.
  Future<bool> areNotificationsEnabled() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return true;
      return await android.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Schedules (or replaces) the daily reminder for [slot] at the given
  /// local time. Tapping the notification opens [ReminderSlot.categoryId].
  ///
  /// Uses inexact scheduling — no exact-alarm permission required. Must be
  /// called after [init] has succeeded. Returns false when the platform does
  /// not support scheduling (Linux).
  Future<bool> scheduleDaily({
    required ReminderSlot slot,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized || !supportsScheduling) return false;
    try {
      final id = _ids[slot]!;
      // Cancel any previous schedule first — rescheduling replaces.
      await _plugin.cancel(id);

      final now = DateTime.now();
      final next = nextDailyOccurrence(now, hour, minute);
      final scheduledDate = tz.TZDateTime.from(next, tz.local);

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'تذكير يومي',
          channelDescription: 'تذكير اختياري بأوقات الأذكار',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        windows: WindowsNotificationDetails(),
      );

      // ponytail: inexact window (system-defined, typically ≤15min skew);
      // switch to exactAllowWhileIdle only if users report mistimed reminders.
      await _plugin.zonedSchedule(
        id,
        'رفيق المسلم',
        slot.body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: slot.categoryId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancels the daily reminder for [slot] if scheduled.
  Future<void> cancelSlot(ReminderSlot slot) async {
    try {
      await _plugin.cancel(_ids[slot]!);
    } catch (_) {
      // Best-effort cancel only.
    }
  }

  /// Re-arms every enabled slot from [store]. Called on launch so a
  /// timezone change (or a plugin DB cleared by an update) never leaves a
  /// stored opt-in silently dead. No-op when scheduling is unsupported.
  Future<void> rescheduleEnabled(ReminderStore store) async {
    if (!_initialized || !supportsScheduling) return;
    for (final slot in ReminderSlot.values) {
      if (store.enabledFor(slot)) {
        await scheduleDaily(
          slot: slot,
          hour: store.hourFor(slot),
          minute: store.minuteFor(slot),
        );
      } else {
        await cancelSlot(slot);
      }
    }
  }
}
