import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/app/content_provider.dart';
import 'package:the_muslims_companion/app/counter_store.dart';
import 'package:the_muslims_companion/app/favorites_store.dart';
import 'package:the_muslims_companion/app/last_read_store.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';
import 'package:the_muslims_companion/content/models/content_entry.dart';
import 'package:the_muslims_companion/main.dart';
import 'package:the_muslims_companion/ui/screens/reader_screen.dart';

Future<ContentEntry> _firstEntry({
  required String categoryId,
  bool longest = false,
}) async {
  final repository = LocalContentRepository();
  final entries = await repository.loadEntriesByCategory(categoryId);
  if (longest) {
    return entries.reduce((a, b) => a.text.length >= b.text.length ? a : b);
  }
  return entries.first;
}

void main() {
  testWidgets('home renders at 1.5x and 2x font scale without overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    for (final scale in <double>[1.5, 2.0]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: const MuslimCompanionApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'home at ${scale}x');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('reader with the longest bundled entry renders at 1.5x and 2x', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final entry = await _firstEntry(categoryId: 'duas-quran', longest: true);
    for (final scale in <double>[1.5, 2.0]) {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  ContentProvider(repository: LocalContentRepository())..load(),
            ),
            ChangeNotifierProvider(create: (_) => FavoritesStore()..load()),
            ChangeNotifierProvider(create: (_) => CounterStore()..load()),
            ChangeNotifierProvider(create: (_) => LastReadStore()..load()),
          ],
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: MaterialApp(home: ReaderScreen(entry: entry)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'reader at ${scale}x');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
