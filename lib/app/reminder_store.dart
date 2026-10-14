import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two optional daily adhkar reminders. Each slot is independent: its
/// own toggle and local time. The reminder is opt-in and purely a user
/// convenience — it is never presented as a religious obligation.
enum ReminderSlot {
  morning('morning', 'أذكار الصباح', 'حان وقت أذكار الصباح', 'adhkar-morning'),
  evening('evening', 'أذكار المساء', 'حان وقت أذكار المساء', 'adhkar-evening');

  const ReminderSlot(this.id, this.label, this.body, this.categoryId);

  final String id;
  final String label;

  /// Notification body text.
  final String body;

  /// Content category opened when the notification is tapped.
  final String categoryId;
}

class ReminderStore extends ChangeNotifier {
  /// Default local times: morning 07:00, evening 18:00.
  static const Map<ReminderSlot, (int, int)> defaultTimes =
      <ReminderSlot, (int, int)>{
        ReminderSlot.morning: (7, 0),
        ReminderSlot.evening: (18, 0),
      };

  bool _morningEnabled = false;
  int _morningHour = 7;
  int _morningMinute = 0;
  bool _eveningEnabled = false;
  int _eveningHour = 18;
  int _eveningMinute = 0;

  /// Completes when the persisted settings have been restored.
  late final Future<void> loaded;

  ReminderStore() {
    loaded = load();
  }

  bool enabledFor(ReminderSlot slot) => switch (slot) {
    ReminderSlot.morning => _morningEnabled,
    ReminderSlot.evening => _eveningEnabled,
  };

  int hourFor(ReminderSlot slot) => switch (slot) {
    ReminderSlot.morning => _morningHour,
    ReminderSlot.evening => _eveningHour,
  };

  int minuteFor(ReminderSlot slot) => switch (slot) {
    ReminderSlot.morning => _morningMinute,
    ReminderSlot.evening => _eveningMinute,
  };

  /// Formatted 24-hour time string, e.g. `'07:30'`.
  String timeLabel(ReminderSlot slot) =>
      '${hourFor(slot).toString().padLeft(2, '0')}:'
      '${minuteFor(slot).toString().padLeft(2, '0')}';

  /// Restores persisted settings. Failures leave defaults in-memory.
  /// Legacy single-reminder keys (`reminder_*`) migrate into the morning
  /// slot so an existing opt-in is never silently dropped.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyEnabled = prefs.getBool('reminder_enabled');
      final morningEnabled = prefs.getBool(_enabledKey(ReminderSlot.morning));
      if (morningEnabled == null && legacyEnabled != null) {
        _morningEnabled = legacyEnabled;
        _morningHour = _clampHour(prefs.getInt('reminder_hour') ?? 7);
        _morningMinute = _clampMinute(prefs.getInt('reminder_minute') ?? 0);
      } else {
        _morningEnabled = morningEnabled ?? false;
        _morningHour = _loadHour(prefs, ReminderSlot.morning);
        _morningMinute = _loadMinute(prefs, ReminderSlot.morning);
      }
      _eveningEnabled =
          prefs.getBool(_enabledKey(ReminderSlot.evening)) ?? false;
      _eveningHour = _loadHour(prefs, ReminderSlot.evening);
      _eveningMinute = _loadMinute(prefs, ReminderSlot.evening);
    } catch (_) {
      // Best-effort restore only.
    }
    notifyListeners();
  }

  /// Persists the enabled flag for [slot].
  Future<void> setEnabled(ReminderSlot slot, bool value) async {
    switch (slot) {
      case ReminderSlot.morning:
        _morningEnabled = value;
      case ReminderSlot.evening:
        _eveningEnabled = value;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey(slot), value);
    } catch (_) {
      // Keep the in-memory state even if persistence is unavailable.
    }
  }

  /// Persists the chosen local time for [slot]. Invalid values are clamped.
  Future<void> setTime(ReminderSlot slot, int hour, int minute) async {
    final int clampedHour = _clampHour(hour);
    final int clampedMinute = _clampMinute(minute);
    switch (slot) {
      case ReminderSlot.morning:
        _morningHour = clampedHour;
        _morningMinute = clampedMinute;
      case ReminderSlot.evening:
        _eveningHour = clampedHour;
        _eveningMinute = clampedMinute;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hourKey(slot), clampedHour);
      await prefs.setInt(_minuteKey(slot), clampedMinute);
    } catch (_) {
      // Keep the in-memory state even if persistence is unavailable.
    }
  }

  static String _enabledKey(ReminderSlot slot) => 'reminder_${slot.id}_enabled';
  static String _hourKey(ReminderSlot slot) => 'reminder_${slot.id}_hour';
  static String _minuteKey(ReminderSlot slot) => 'reminder_${slot.id}_minute';

  static int _clampHour(int value) => value.clamp(0, 23);
  static int _clampMinute(int value) => value.clamp(0, 59);

  int _loadHour(SharedPreferences prefs, ReminderSlot slot) {
    final int? stored = prefs.getInt(_hourKey(slot));
    final int fallback = defaultTimes[slot]?.$1 ?? 7;
    return stored == null || stored < 0 || stored > 23 ? fallback : stored;
  }

  int _loadMinute(SharedPreferences prefs, ReminderSlot slot) {
    final int? stored = prefs.getInt(_minuteKey(slot));
    final int fallback = defaultTimes[slot]?.$2 ?? 0;
    return stored == null || stored < 0 || stored > 59 ? fallback : stored;
  }
}

/// Computes the next occurrence of a daily [hour]:[minute] after [now].
///
/// Pure function (no timezone dependency) so it is trivially unit-testable.
/// If today's occurrence has already passed, returns tomorrow's.
DateTime nextDailyOccurrence(DateTime now, int hour, int minute) {
  var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
  if (!scheduled.isAfter(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}
