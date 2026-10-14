import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';
import 'package:the_muslims_companion/main.dart';

import 'shell_test.dart' show fixtureLoader;

/// Fixture-backed app: `rootBundle` only answers the first widget test in a
/// file, so the real asset loader would leave the second test loading forever.
Widget _app() => MuslimCompanionApp(
  contentRepository: LocalContentRepository(loader: fixtureLoader),
);

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(NavigationBar))).brightness;

Color _background(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(NavigationBar)))
        .scaffoldBackgroundColor;

void main() {
  testWidgets('follows the system (light) theme by default', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(_brightness(tester), Brightness.light);
    expect(_background(tester), app.theme!.scaffoldBackgroundColor);
    expect(find.text('رفيق المسلم'), findsOneWidget);
  });

  testWidgets('a saved dark preference paints the dark palette', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_mode': 'dark',
    });
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.themeMode, ThemeMode.dark);
    expect(_brightness(tester), Brightness.dark);
    expect(_background(tester), app.darkTheme!.scaffoldBackgroundColor);
    expect(find.text('رفيق المسلم'), findsOneWidget);
  });
}
