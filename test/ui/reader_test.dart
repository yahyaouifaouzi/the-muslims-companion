import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:the_muslims_companion/app/counter_store.dart';
import 'package:the_muslims_companion/app/favorites_store.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';
import 'package:the_muslims_companion/content/models/content_entry.dart';
import 'package:the_muslims_companion/content/models/content_source.dart';
import 'package:the_muslims_companion/main.dart';
import 'package:the_muslims_companion/ui/screens/reader_screen.dart';

import 'shell_test.dart' show fixtureLoader;

const _arabicBody =
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ';

ContentEntry _entry({bool withSource = false, bool placeholder = false}) =>
    ContentEntry(
      id: 'entry-1',
      categoryId: 'adhkar-morning',
      title: 'تسبيح',
      text: _arabicBody,
      sortOrder: 0,
      verified: !placeholder,
      placeholder: placeholder,
      source: withSource
          ? const ContentSource(
              reference: 'صحيح البخاري 1',
              authenticity: 'صحيح',
            )
          : null,
    );

Widget _readerWidget(ContentEntry entry) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FavoritesStore()),
    ChangeNotifierProvider(create: (_) => CounterStore()),
  ],
  child: MaterialApp(home: ReaderScreen(entry: entry)),
);

double _currentFontSize(WidgetTester tester) =>
    tester.widget<Text>(find.text(_arabicBody)).style!.fontSize!;

IconButton _button(WidgetTester tester, IconData icon) =>
    tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon));

Future<void> _tapUntilDisabled(WidgetTester tester, IconData icon) async {
  while (_button(tester, icon).onPressed != null) {
    await tester.tap(find.widgetWithIcon(IconButton, icon));
    await tester.pump();
  }
}

void main() {
  group('font size bounds', () {
    test('the default size is within bounds', () {
      expect(
        ReaderScreen.defaultFontSize,
        inInclusiveRange(ReaderScreen.minFontSize, ReaderScreen.maxFontSize),
      );
    });

    test('clampFontSize keeps values inside the bounds', () {
      expect(
        ReaderScreen.clampFontSize(ReaderScreen.minFontSize - 10),
        ReaderScreen.minFontSize,
      );
      expect(
        ReaderScreen.clampFontSize(ReaderScreen.maxFontSize + 10),
        ReaderScreen.maxFontSize,
      );
      expect(
        ReaderScreen.clampFontSize(ReaderScreen.defaultFontSize),
        ReaderScreen.defaultFontSize,
      );
    });
  });

  group('buildShareText', () {
    test('contains title, verbatim body, and attribution', () {
      expect(buildShareText(_entry()), 'تسبيح\n$_arabicBody\n— رفيق المسلم');
    });

    test('includes the source reference only when present', () {
      expect(
        buildShareText(_entry(withSource: true)),
        contains('صحيح البخاري 1'),
      );
      expect(buildShareText(_entry()), isNot(contains('صحيح البخاري 1')));
    });
  });

  testWidgets('renders the body, copy/share actions, and hides no source', (
    tester,
  ) async {
    await tester.pumpWidget(_readerWidget(_entry(withSource: true)));

    expect(find.text(_arabicBody), findsOneWidget);
    expect(find.text('صحيح البخاري 1'), findsOneWidget);
    expect(find.byIcon(Icons.text_decrease), findsOneWidget);
    expect(find.byIcon(Icons.text_increase), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
  });

  testWidgets('omits the source line when no verified reference exists', (
    tester,
  ) async {
    await tester.pumpWidget(_readerWidget(_entry()));

    expect(find.text(_arabicBody), findsOneWidget);
    expect(find.text('صحيح البخاري 1'), findsNothing);
  });

  testWidgets('font size adjusts and stops at both bounds', (tester) async {
    await tester.pumpWidget(_readerWidget(_entry()));
    expect(_currentFontSize(tester), ReaderScreen.defaultFontSize);

    await tester.tap(find.byIcon(Icons.text_increase));
    await tester.pump();
    expect(
      _currentFontSize(tester),
      ReaderScreen.defaultFontSize + ReaderScreen.fontSizeStep,
    );

    await _tapUntilDisabled(tester, Icons.text_increase);
    expect(_currentFontSize(tester), ReaderScreen.maxFontSize);

    await _tapUntilDisabled(tester, Icons.text_decrease);
    expect(_currentFontSize(tester), ReaderScreen.minFontSize);
  });

  testWidgets('tapping an entry in a category opens the reader', (
    tester,
  ) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سبحان الله وبحمده'));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('تسبيح'), findsOneWidget); // reader AppBar title
    expect(find.text('سبحان الله وبحمده'), findsOneWidget);
  });
}
