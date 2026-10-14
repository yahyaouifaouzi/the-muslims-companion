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
  bool systemNotificationsDisabled = false;
  bool schedulingSupported = true;
  int? lastHour;
  int? lastMinute;
  ReminderSlot? lastSlot;
  bool cancelled = false;

  @override
  void Function(ReminderSlot slot)? onOpenAdhkar;

  @override
  bool get supportsScheduling => schedulingSupported;

  @override
  Future<bool> init() async => true;

  @override
  Future<bool> requestPermission() async => allowPermission;

  @override
  Future<bool> areNotificationsEnabled() async => !systemNotificationsDisabled;

  @override
  Future<bool> scheduleDaily({
    required ReminderSlot slot,
    required int hour,
    required int minute,
  }) async {
    lastSlot = slot;
    lastHour = hour;
    lastMinute = minute;
    cancelled = false;
    return true;
  }

  @override
  Future<void> cancelSlot(ReminderSlot slot) async {
    if (lastSlot == slot) {
      cancelled = true;
      lastHour = null;
      lastMinute = null;
      lastSlot = null;
    }
  }

  @override
  Future<void> rescheduleEnabled(ReminderStore store) async {}
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
    await tester.ensureVisible(find.byType(Switch).first);
    await tester.pumpAndSettle();
  }

  testWidgets('both reminder toggles are off by default', (tester) async {
    await openSettings(tester, FakeNotificationService());
    expect(find.text('تذكير أذكار الصباح'), findsOneWidget);
    expect(find.text('تذكير أذكار المساء'), findsOneWidget);
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(2));
    expect(switches.every((s) => !s.value), isTrue);
    expect(find.textContaining('وقت تذكير'), findsNothing);
  });

  testWidgets('unsupported platform hides the reminder card', (tester) async {
    final fake = FakeNotificationService()..schedulingSupported = false;
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
        notificationService: fake,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    expect(
      find.text('التذكير اليومي غير مدعوم على هذا النظام.'),
      findsOneWidget,
    );
  });

  testWidgets('denied permission keeps the reminder off with a message', (
    tester,
  ) async {
    final fake = FakeNotificationService()..allowPermission = false;
    await openSettings(tester, fake);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.every((s) => !s.value), isTrue);
    expect(find.textContaining('تم رفض إذن الإشعارات'), findsOneWidget);
    expect(fake.lastHour, isNull); // never scheduled
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_morning_enabled'), isNot(true));
  });

  testWidgets('notifications disabled at OS level shows guidance', (
    tester,
  ) async {
    final fake = FakeNotificationService()
      ..allowPermission = false
      ..systemNotificationsDisabled = true;
    await openSettings(tester, fake);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('الإشعارات معطلة'), findsOneWidget);
    expect(fake.lastHour, isNull);
  });

  testWidgets('granting permission schedules the morning 07:00 reminder', (
    tester,
  ) async {
    final fake = FakeNotificationService();
    await openSettings(tester, fake);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(fake.lastSlot, ReminderSlot.morning);
    expect(fake.lastHour, ReminderStore.defaultTimes[ReminderSlot.morning]?.$1);
    expect(
      fake.lastMinute,
      ReminderStore.defaultTimes[ReminderSlot.morning]?.$2,
    );
    expect(find.text('وقت تذكير أذكار الصباح'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_morning_enabled'), isTrue);
  });

  testWidgets('evening toggle is independent of the morning one', (
    tester,
  ) async {
    final fake = FakeNotificationService();
    await openSettings(tester, fake);

    await tester.tap(find.byType(Switch).last); // evening
    await tester.pumpAndSettle();

    expect(fake.lastSlot, ReminderSlot.evening);
    expect(fake.lastHour, 18);
    expect(find.text('07:00'), findsNothing); // morning still off
    expect(find.text('18:00'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_morning_enabled'), isNot(true));
    expect(prefs.getBool('reminder_evening_enabled'), isTrue);
  });

  testWidgets('turning the reminder off cancels the schedule', (tester) async {
    final fake = FakeNotificationService();
    await openSettings(tester, fake);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(fake.cancelled, isFalse);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(fake.cancelled, isTrue);
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.every((s) => !s.value), isTrue);
    expect(find.textContaining('وقت تذكير'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reminder_morning_enabled'), isFalse);
  });
}
