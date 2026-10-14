import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/main.dart';

/// Real-bundled-content smoke test: opens a morning dhikr and checks that
/// its counter renders with the repeatCount from the bundled JSON.
///
/// NOTE: only the first test in a file may use `rootBundle` — the test
/// binding serves assets to a single test per isolate.
void main() {
  testWidgets('bundled morning dhikr opens its counter', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final doc = jsonDecode(
      await rootBundle.loadString('assets/data/adhkar.json'),
    ) as Map<String, dynamic>;
    final entries = (doc['entries'] as List).cast<Map<String, dynamic>>();
    final entry = entries.firstWhere(
      (e) =>
          e['categoryId'] == 'adhkar-morning' &&
          (e['repeatCount'] as int? ?? 0) >= 3,
    );

    await tester.pumpWidget(const MuslimCompanionApp());
    await tester.pumpAndSettle();

    // The home screen has two scrollables (featured strip + page list).
    await tester.scrollUntilVisible(
      find.text('أذكار الصباح'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();

    final title = find.text(entry['title'] as String);
    await tester.scrollUntilVisible(title, 300);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();

    final progress = find.text('0 من ${entry['repeatCount']}');
    await tester.scrollUntilVisible(progress, 200);
    await tester.pumpAndSettle();
    expect(progress, findsOneWidget);
    expect(find.text('إعادة العد'), findsNothing); // hidden at zero
  });
}
