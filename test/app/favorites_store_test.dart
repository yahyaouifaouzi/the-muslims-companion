import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/app/favorites_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesStore', () {
    test('toggle adds then removes an id', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FavoritesStore();
      await store.load();

      await store.toggle('a');
      expect(store.contains('a'), isTrue);
      expect(store.ids, {'a'});

      await store.toggle('a');
      expect(store.contains('a'), isFalse);
      expect(store.ids, isEmpty);
    });

    test('persists toggles across store instances', () async {
      SharedPreferences.setMockInitialValues({});
      final first = FavoritesStore();
      await first.load();
      await first.toggle('x');
      await first.toggle('y');

      final second = FavoritesStore();
      await second.load();
      expect(second.ids, {'x', 'y'});
    });

    test('load restores previously persisted ids', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_entry_ids': ['keep-me', 'gone'],
      });
      final store = FavoritesStore();
      await store.load();
      expect(store.ids, {'keep-me', 'gone'});
    });

    test('load tolerates missing persistence (empty start)', () async {
      SharedPreferences.setMockInitialValues({});
      final store = FavoritesStore();
      await store.load();
      expect(store.ids, isEmpty);
    });
  });
}
