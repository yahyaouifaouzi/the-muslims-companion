import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';
import 'package:the_muslims_companion/main.dart';
import 'package:the_muslims_companion/ui/widgets/counter_section.dart';

import 'shell_test.dart' show fixtureLoader;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMorningReader(WidgetTester tester) async {
    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسبيح'));
    await tester.pumpAndSettle();
  }

  testWidgets('every icon button on home, settings and reader has a tooltip', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final iconButton in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      expect(
        iconButton.tooltip,
        isNotNull,
        reason: 'home icon buttons must carry Arabic tooltips',
      );
    }

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    // The font-size card sits below the fold; the list builds lazily.
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.byType(IconButton), findsWidgets);
    for (final iconButton in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      expect(iconButton.tooltip, isNotNull);
    }

    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    await openMorningReader(tester);
    expect(find.byType(IconButton), findsWidgets);
    for (final iconButton in tester.widgetList<IconButton>(
      find.byType(IconButton),
    )) {
      expect(iconButton.tooltip, isNotNull);
    }
  });

  testWidgets('counter dial exposes an Arabic accessibility label', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(tester);
    await openMorningReader(tester);

    expect(find.byType(CounterSection), findsOneWidget);
    // The fixture entry ships no repeatCount: set a target first.
    await tester.tap(find.text('حدد عدد التكرار'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('تحديد'));
    await tester.pumpAndSettle();

    // The tap node merges the dial label with the progress text.
    expect(find.bySemanticsLabel(RegExp('اضغط للعد')), findsOneWidget);

    // Progress is announced through the same region after a tap.
    await tester.tap(find.byKey(const ValueKey('counter-tap-target')));
    await tester.pump();
    expect(find.text('1 من 3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('search clear action is labelled in Arabic', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('ابحث في المحتوى'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'سبحان');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byTooltip('مسح البحث'), findsOneWidget);
  });

  testWidgets('reader actions use the expected Arabic tooltips', (
    tester,
  ) async {
    await pumpApp(tester);
    await openMorningReader(tester);

    expect(find.byTooltip('مشاركة'), findsOneWidget);
    expect(find.byTooltip('نسخ'), findsOneWidget);
    expect(find.byTooltip('تصغير الخط'), findsOneWidget);
    expect(find.byTooltip('تكبير الخط'), findsOneWidget);
    expect(find.byTooltip('إضافة إلى المفضلة'), findsOneWidget);
  });
}
