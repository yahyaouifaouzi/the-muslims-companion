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
    test('defaults to disabled at 07:00', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReminderStore();
      await store.load();
      expect(store.enabled, isFalse);
      expect(store.hour, ReminderStore.defaultHour);
      expect(store.minute, ReminderStore.defaultMinute);
      expect(store.timeLabel, '07:00');
    });

    test('setEnabled and setTime persist across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final first = ReminderStore();
      await first.load();
      await first.setEnabled(true);
      await first.setTime(21, 45);

      final second = ReminderStore();
      await second.load();
      expect(second.enabled, isTrue);
      expect(second.hour, 21);
      expect(second.minute, 45);
      expect(second.timeLabel, '21:45');
    });

    test('timeLabel zero-pads single digits', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReminderStore();
      await store.load();
      await store.setTime(7, 5);
      expect(store.timeLabel, '07:05');
    });

    test('clamps out-of-range time values', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReminderStore();
      await store.load();
      await store.setTime(25, -10);
      expect(store.hour, 23);
      expect(store.minute, 0);
    });

    test('load resets invalid persisted values to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_enabled': true,
        'reminder_hour': 99,
        'reminder_minute': 99,
      });
      final store = ReminderStore();
      await store.load();
      expect(store.enabled, isTrue);
      expect(store.hour, ReminderStore.defaultHour);
      expect(store.minute, ReminderStore.defaultMinute);
    });

    test('notifies listeners on change', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ReminderStore();
      await store.load();
      var notified = false;
      store.addListener(() => notified = true);
      await store.setEnabled(true);
      expect(notified, isTrue);
    });
  });
}
