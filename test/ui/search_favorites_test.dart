import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/app/favorites_store.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';
import 'package:the_muslims_companion/main.dart';
import 'package:the_muslims_companion/ui/screens/reader_screen.dart';

import 'shell_test.dart' show fixtureLoader;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpApp(WidgetTester tester, {FavoritesStore? store}) async {
    await tester.pumpWidget(
      MuslimCompanionApp(
        contentRepository: LocalContentRepository(loader: fixtureLoader),
        favoritesStore: store,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openFavoritesTab(WidgetTester tester) async {
    // Tap the nav label (the icon alone is ambiguous with reader hearts).
    await tester.tap(find.text('المفضلة'));
    await tester.pumpAndSettle();
  }

  testWidgets('search finds entries by body text and opens the reader', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('ابحث في المحتوى'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'سبحان');
    await tester.pump(const Duration(milliseconds: 300)); // search debounce
    await tester.pumpAndSettle();

    expect(find.text('لا توجد نتائج'), findsNothing);
    expect(find.text('تسبيح'), findsOneWidget);

    await tester.tap(find.text('تسبيح'));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('سبحان الله وبحمده'), findsWidgets);
  });

  testWidgets('search shows a no-results state for unknown words', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('ابحث في المحتوى'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'كلمة غير موجودة');
    await tester.pump(const Duration(milliseconds: 300)); // search debounce
    await tester.pumpAndSettle();

    expect(find.text('لا توجد نتائج'), findsOneWidget);
  });

  testWidgets('favoriting from the reader lists the entry in the favorites '
      'tab', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سبحان الله وبحمده'));
    await tester.pumpAndSettle();

    // Reader heart (bottom nav still shows favorite_border on the home tab).
    await tester.tap(find.widgetWithIcon(IconButton, Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.widgetWithIcon(IconButton, Icons.favorite), findsOneWidget);

    // Material back buttons (pageBack only knows the Cupertino variant).
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await openFavoritesTab(tester);

    expect(find.text('تسبيح'), findsOneWidget);
    expect(find.text('لا توجد مفضلات بعد'), findsNothing);
  });

  testWidgets('stale favorite IDs are skipped, not crashed on', (tester) async {
    SharedPreferences.setMockInitialValues({
      'favorite_entry_ids': ['ghost-id', 'dhikr-1'],
    });
    final store = FavoritesStore();
    await store.load();

    await pumpApp(tester, store: store);
    await openFavoritesTab(tester);

    expect(find.text('تسبيح'), findsOneWidget); // resolved entry
    expect(find.text('لا توجد مفضلات بعد'), findsNothing);
  });

  testWidgets('removing from the favorites list updates immediately', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'favorite_entry_ids': ['dhikr-1'],
    });
    final store = FavoritesStore();
    await store.load();

    await pumpApp(tester, store: store);
    await openFavoritesTab(tester);
    expect(find.text('تسبيح'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.favorite));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مفضلات بعد'), findsOneWidget);
  });
}
