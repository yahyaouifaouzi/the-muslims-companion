import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted daily-reminder settings: enabled flag and chosen local time.
///
/// The reminder is opt-in and purely a user convenience — it is never
/// presented as a religious obligation.
class ReminderStore extends ChangeNotifier {
  static const String _enabledKey = 'reminder_enabled';
  static const String _hourKey = 'reminder_hour';
  static const String _minuteKey = 'reminder_minute';

  /// Default reminder time: 07:00 local.
  static const int defaultHour = 7;
  static const int defaultMinute = 0;

  bool enabled = false;
  int hour = defaultHour;
  int minute = defaultMinute;

  /// Formatted 24-hour time string, e.g. `'07:30'`.
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Restores persisted settings. Failures leave defaults in-memory.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_enabledKey) ?? false;
      hour = prefs.getInt(_hourKey) ?? defaultHour;
      minute = prefs.getInt(_minuteKey) ?? defaultMinute;
      if (hour < 0 || hour > 23) hour = defaultHour;
      if (minute < 0 || minute > 59) minute = defaultMinute;
    } catch (_) {
      // Best-effort restore only.
    }
    notifyListeners();
  }

  /// Persists the enabled flag.
  Future<void> setEnabled(bool value) async {
    enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (_) {
      // Keep the in-memory state even if persistence is unavailable.
    }
  }

  /// Persists the chosen local time. Invalid values are clamped.
  Future<void> setTime(int newHour, int newMinute) async {
    hour = newHour.clamp(0, 23);
    minute = newMinute.clamp(0, 59);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hourKey, hour);
      await prefs.setInt(_minuteKey, minute);
    } catch (_) {
      // Keep the in-memory state even if persistence is unavailable.
    }
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
