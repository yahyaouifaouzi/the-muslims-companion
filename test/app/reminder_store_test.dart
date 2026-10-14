import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/app/reminder_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('nextDailyOccurrence', () {
    test('returns today\'s time when it is still ahead', () {
      final now = DateTime(2026, 10, 13, 6, 0);
      final next = nextDailyOccurrence(now, 7, 30);
      expect(next, DateTime(2026, 10, 13, 7, 30));
    });

    test('rolls to tomorrow when today\'s time has passed', () {
      final now = DateTime(2026, 10, 13, 8, 0);
      final next = nextDailyOccurrence(now, 7, 0);
      expect(next, DateTime(2026, 10, 14, 7, 0));
    });

    test('rolls to tomorrow when now equals the scheduled time', () {
      final now = DateTime(2026, 10, 13, 7, 0);
      final next = nextDailyOccurrence(now, 7, 0);
      expect(next, DateTime(2026, 10, 14, 7, 0));
    });

    test('handles midnight boundary', () {
      final now = DateTime(2026, 10, 13, 23, 59);
      final next = nextDailyOccurrence(now, 0, 5);
      expect(next, DateTime(2026, 10, 14, 0, 5));
    });
  });

  group('ReminderStore', () {
    test('defaults to disabled at 07:00 morning and 18:00 evening', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReminderStore();
      await store.loaded;
      expect(store.enabledFor(ReminderSlot.morning), isFalse);
      expect(store.timeLabel(ReminderSlot.morning), '07:00');
      expect(store.enabledFor(ReminderSlot.evening), isFalse);
      expect(store.timeLabel(ReminderSlot.evening), '18:00');
    });

    test('setEnabled and setTime persist across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final first = ReminderStore();
      await first.loaded;
      await first.setEnabled(ReminderSlot.evening, true);
      await first.setTime(ReminderSlot.evening, 21, 45);

      final second = ReminderStore();
      await second.loaded;
      expect(second.enabledFor(ReminderSlot.evening), isTrue);
      expect(second.timeLabel(ReminderSlot.evening), '21:45');
      // Morning slot untouched.
      expect(second.enabledFor(ReminderSlot.morning), isFalse);
      expect(second.timeLabel(ReminderSlot.morning), '07:00');
    });

    test('legacy single-reminder keys migrate to the morning slot', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_enabled': true,
        'reminder_hour': 6,
        'reminder_minute': 30,
      });
      final store = ReminderStore();
      await store.loaded;
      expect(store.enabledFor(ReminderSlot.morning), isTrue);
      expect(store.timeLabel(ReminderSlot.morning), '06:30');
      expect(store.enabledFor(ReminderSlot.evening), isFalse);
    });

    test('timeLabel zero-pads single digits', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReminderStore();
      await store.loaded;
      await store.setTime(ReminderSlot.morning, 7, 5);
      expect(store.timeLabel(ReminderSlot.morning), '07:05');
    });

    test('clamps out-of-range time values', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReminderStore();
      await store.loaded;
      await store.setTime(ReminderSlot.morning, 25, -10);
      expect(store.hourFor(ReminderSlot.morning), 23);
      expect(store.minuteFor(ReminderSlot.morning), 0);
    });

    test('load resets invalid persisted values to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_morning_enabled': true,
        'reminder_morning_hour': 99,
        'reminder_morning_minute': 99,
      });
      final store = ReminderStore();
      await store.loaded;
      expect(store.enabledFor(ReminderSlot.morning), isTrue);
      expect(store.hourFor(ReminderSlot.morning), 7);
      expect(store.minuteFor(ReminderSlot.morning), 0);
    });

    test('notifies listeners on change', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReminderStore();
      await store.loaded;
      var notified = false;
      store.addListener(() => notified = true);
      await store.setEnabled(ReminderSlot.morning, true);
      expect(notified, isTrue);
    });
  });
}
