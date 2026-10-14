import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';
import 'package:the_muslims_companion/main.dart';
import 'package:the_muslims_companion/ui/screens/reader_screen.dart';

import 'shell_test.dart' show fixtureLoader;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('continue card appears for the last opened entry and opens it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'last_read_entry_id': 'dhikr-1'});
    await pumpApp(tester);

    expect(find.text('تابع من حيث توقفت'), findsOneWidget);
    expect(find.text('تسبيح'), findsOneWidget);

    await tester.tap(find.text('تابع من حيث توقفت'));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('سبحان الله وبحمده'), findsOneWidget);
  });

  testWidgets('dismissing the continue card hides it and clears storage', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'last_read_entry_id': 'dhikr-1'});
    await pumpApp(tester);
    expect(find.text('تابع من حيث توقفت'), findsOneWidget);

    await tester.tap(find.byTooltip('إخفاء'));
    await tester.pumpAndSettle();

    expect(find.text('تابع من حيث توقفت'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('last_read_entry_id'), isNull);
  });

  testWidgets('stale last-read ids are simply not shown', (tester) async {
    SharedPreferences.setMockInitialValues({
      'last_read_entry_id': 'removed-by-update',
    });
    await pumpApp(tester);
    expect(find.text('تابع من حيث توقفت'), findsNothing);
  });

  testWidgets('opening the reader records it for the next home visit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);
    expect(find.text('تابع من حيث توقفت'), findsNothing);

    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسبيح'));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle(); // category
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle(); // home

    expect(find.text('تابع من حيث توقفت'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('last_read_entry_id'), 'dhikr-1');
  });
}
