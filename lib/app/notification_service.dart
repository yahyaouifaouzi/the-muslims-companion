import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_store.dart';

/// Wraps flutter_local_notifications for a single daily reminder.
///
/// Design choices:
/// - **Inexact scheduling** (`AndroidScheduleMode.inexact`) — no exact-alarm
///   permission is requested; the reminder fires within a system-defined
///   window around the chosen time.
/// - **Single notification ID** — rescheduling replaces the previous
///   schedule; there are never duplicate reminders.
/// - **Daily repetition** via `DateTimeComponents.time` so the OS re-arms
///   the alarm each day.
/// - **Tap opens the app** via the default launcher activity (no deep link).
///
/// Cross-platform: Android and Windows support `zonedSchedule`. Linux does
/// not (the plugin only supports immediate `show`), so [supportsScheduling]
/// is false there and the reminder UI is hidden.
class NotificationService {
  static const int _reminderId = 0;
  static const String _aumid = 'com.ideas2d.themuslimscompanion';
  static const String _winGuid = '{8f3a5b1e-2c4d-4e6f-8a9b-0c1d2e3f4a5b}';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

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
      final ok = await _plugin.initialize(settings);
      _initialized = ok ?? false;
      return _initialized;
    } catch (_) {
      _initialized = false;
      return false;
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

  /// Schedules (or replaces) the daily reminder at the given local time.
  ///
  /// Uses inexact scheduling — no exact-alarm permission required. Must be
  /// called after [init] has succeeded. Returns false when the platform does
  /// not support scheduling (Linux).
  Future<bool> scheduleDaily({required int hour, required int minute}) async {
    if (!_initialized || !supportsScheduling) return false;
    try {
      // Cancel any previous schedule first — rescheduling replaces.
      await _plugin.cancel(_reminderId);

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
        _reminderId,
        'رفيق المسلم',
        'حان وقت أذكار الصباح',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancels the daily reminder if scheduled.
  Future<void> cancel() async {
    try {
      await _plugin.cancel(_reminderId);
    } catch (_) {
      // Best-effort cancel only.
    }
  }
}
