import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/app/counter_store.dart';
import 'package:the_muslims_companion/app/favorites_store.dart';
import 'package:the_muslims_companion/content/models/content_entry.dart';
import 'package:the_muslims_companion/ui/screens/reader_screen.dart';
import 'package:the_muslims_companion/ui/widgets/counter_section.dart';

ContentEntry _entry({int? repeatCount}) => ContentEntry(
  id: 'dhikr-1',
  categoryId: 'adhkar-morning',
  title: 'تسبيح',
  text: 'سبحان الله وبحمده',
  repeatCount: repeatCount,
  sortOrder: 0,
  verified: true,
  placeholder: false,
);

Widget _readerWidget(ContentEntry entry, CounterStore store) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FavoritesStore()),
    ChangeNotifierProvider.value(value: store),
  ],
  child: MaterialApp(home: ReaderScreen(entry: entry)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CounterStore', () {
    test('starts at zero and increments', () {
      final store = CounterStore();
      expect(store.countFor('a'), 0);
      store.increment('a');
      store.increment('a');
      expect(store.countFor('a'), 2);
    });

    test('increment is capped at the target', () {
      final store = CounterStore();
      store.increment('a', target: 2);
      store.increment('a', target: 2);
      store.increment('a', target: 2); // ignored
      expect(store.countFor('a'), 2);
    });

    test('reset returns count to zero', () {
      final store = CounterStore();
      store.increment('a');
      store.increment('a');
      store.reset('a');
      expect(store.countFor('a'), 0);
    });

    test('never produces negative counts', () {
      final store = CounterStore();
      store.reset('a'); // no-op on empty
      expect(store.countFor('a'), 0);
    });

    test(
      'user target overrides nothing until set; persists across loads',
      () async {
        SharedPreferences.setMockInitialValues({});
        final first = CounterStore();
        await first.load();
        first.setUserTarget('a', 5);
        first.increment('a', target: 5);
        first.increment('a', target: 5);

        final second = CounterStore();
        await second.load();
        expect(second.userTargetFor('a'), 5);
        expect(second.countFor('a'), 2);
      },
    );

    test('setUserTarget ignores non-positive values', () {
      final store = CounterStore();
      store.setUserTarget('a', 0);
      store.setUserTarget('a', -3);
      expect(store.hasUserTarget('a'), isFalse);
    });

    test('clearUserTarget removes the override', () {
      final store = CounterStore();
      store.setUserTarget('a', 4);
      store.clearUserTarget('a');
      expect(store.hasUserTarget('a'), isFalse);
    });

    test('corrupted persisted JSON degrades to empty state', () async {
      SharedPreferences.setMockInitialValues({
        'counter_counts': 'not-json',
        'counter_targets': 'also-not-json',
      });
      final store = CounterStore();
      await store.load();
      expect(store.countFor('a'), 0);
      expect(store.hasUserTarget('a'), isFalse);
    });
  });

  group('CounterSection widget', () {
    testWidgets('shows the set-target prompt when no repeatCount exists', (
      tester,
    ) async {
      await tester.pumpWidget(_readerWidget(_entry(), CounterStore()));
      expect(find.text('حدد عدد التكرار'), findsOneWidget);
      expect(find.text('التكرار'), findsNothing);
    });

    testWidgets('increments, shows progress, and resets', (tester) async {
      final store = CounterStore();
      await tester.pumpWidget(_readerWidget(_entry(repeatCount: 3), store));

      expect(find.text('التكرار'), findsOneWidget);
      expect(find.text('0 من 3'), findsOneWidget);
      expect(find.text('إعادة العد'), findsNothing); // hidden at zero

      // Tap the big circle.
      await tester.tap(find.byKey(const ValueKey('counter-tap-target')));
      await tester.pump();
      expect(find.text('1 من 3'), findsOneWidget);
      expect(find.text('إعادة العد'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('counter-tap-target')));
      await tester.pump();
      expect(find.text('2 من 3'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('counter-tap-target')));
      await tester.pump();
      expect(find.text('3 من 3'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget); // completed state

      // Further taps are ignored at target.
      await tester.tap(
        find.byKey(const ValueKey('counter-tap-target')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.text('3 من 3'), findsOneWidget);

      await tester.tap(find.text('إعادة العد'));
      await tester.pump();
      expect(find.text('0 من 3'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('user-defined target shows the counter for an entry without '
        'repeatCount', (tester) async {
      final store = CounterStore();
      await tester.pumpWidget(_readerWidget(_entry(), store));

      await tester.tap(find.text('حدد عدد التكرار'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2');
      await tester.tap(find.text('تحديد'));
      await tester.pumpAndSettle();

      expect(store.userTargetFor('dhikr-1'), 2);
      expect(find.text('0 من 2'), findsOneWidget);
    });

    testWidgets('user target takes precedence over entry.repeatCount', (
      tester,
    ) async {
      final store = CounterStore()..setUserTarget('dhikr-1', 5);
      await tester.pumpWidget(_readerWidget(_entry(repeatCount: 3), store));
      expect(find.text('0 من 5'), findsOneWidget);
    });

    testWidgets('tap target is large enough for one-handed use', (
      tester,
    ) async {
      await tester.pumpWidget(
        _readerWidget(_entry(repeatCount: 3), CounterStore()),
      );
      final size = tester.getSize(
        find.byKey(const ValueKey('counter-tap-target')),
      );
      expect(size.width, greaterThanOrEqualTo(CounterSection.tapTargetSize));
      expect(size.height, greaterThanOrEqualTo(CounterSection.tapTargetSize));
    });
  });
}
