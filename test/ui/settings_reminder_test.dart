import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/app/notification_service.dart';
import 'package:the_muslims_companion/app/reminder_store.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';
import 'package:the_muslims_companion/main.dart';

import 'shell_test.dart' show fixtureLoader;

/// Controllable stand-in for the platform notification service.
class FakeNotificationService implements NotificationService {
  bool allowPermission = true;
  int? lastHour;
  int? lastMinute;
  bool cancelled = false;

  @override
  bool get initialized => true;

  @override
  Future<bool> init() async => true;

  @override
  Future<bool> requestPermission() async => allowPermission;

  @override
  Future<bool> areNotificationsEnabled() async => allowPermission;

  @override
  Future<bool> scheduleDaily({
    required int hour,
    required int minute,
    String title = 'رفيق المسلم',
    String body = 'حان وقت أذكار الصباح',
  }) async {
    lastHour = hour;
    lastMinute = minute;
    cancelled = false;
    return true;
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
    lastHour = null;
    lastMinute = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openSettings(
    WidgetTester tester,
    NotificationService fake,
  ) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
        notificationService: fake,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
  }

  testWidgets('reminder toggle is off by default', (tester) async {
    await openSettings(tester, FakeNotificationService());
    expect(find.text('تذكير يومي'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('وقت التذكير'), findsNothing);
  });

  testWidgets('denied permission keeps the reminder off with a message', (
    tester,
  ) async {
    final fake = FakeNotificationService()..allowPermission = false;
    await openSettings(tester, fake);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.textContaining('تم رفض إذن الإشعارات'), findsOneWidget);
    expect(fake.lastHour, isNull); // never scheduled
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_enabled'), isNot(true));
  });

  testWidgets('granting permission schedules the default 07:00 reminder', (
    tester,
  ) async {
    final fake = FakeNotificationService();
    await openSettings(tester, fake);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(fake.lastHour, ReminderStore.defaultHour);
    expect(fake.lastMinute, ReminderStore.defaultMinute);
    expect(find.text('وقت التذكير'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_enabled'), isTrue);
  });

  testWidgets('turning the reminder off cancels the schedule', (tester) async {
    final fake = FakeNotificationService();
    await openSettings(tester, fake);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(fake.cancelled, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(fake.cancelled, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('وقت التذكير'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_enabled'), isFalse);
  });
}
