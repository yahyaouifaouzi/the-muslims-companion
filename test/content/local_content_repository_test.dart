import 'package:flutter_test/flutter_test.dart';

import 'package:the_muslims_companion/content/content_exception.dart';
import 'package:the_muslims_companion/content/local_content_repository.dart';

/// Fixture builder: a small, fully valid content snapshot.
Map<String, Object?> _validFixture() => {
  'assets/data/manifest.json': {
    'schemaVersion': 1,
    'contentVersion': 1,
    'updatedAt': '2026-10-13',
    'files': ['categories.json', 'duas.json', 'adhkar.json'],
  },
  'assets/data/categories.json': {
    'schemaVersion': 1,
    'categories': [
      {
        'id': 'duas-quran',
        'title': 'أدعية قرآنية',
        'iconKey': 'quran',
        'contentFile': 'duas.json',
        'sortOrder': 3,
        'enabled': true,
      },
      {
        'id': 'adhkar-morning',
        'title': 'أذكار الصباح',
        'iconKey': 'sunrise',
        'contentFile': 'adhkar.json',
        'sortOrder': 1,
        'enabled': true,
      },
      {
        'id': 'empty-cat',
        'title': 'فئة بلا محتوى',
        'iconKey': 'book',
        'contentFile': 'adhkar.json',
        'sortOrder': 2,
        'enabled': true,
      },
    ],
  },
  'assets/data/duas.json': {
    'schemaVersion': 1,
    'entries': [
      {
        'id': 'dua-b',
        'categoryId': 'duas-quran',
        'title': 'ب',
        'text': 'نص ب',
        'sortOrder': 5,
        'verified': true,
        'placeholder': false,
        'source': {'reference': 'سورة البقرة، آية 201', 'kind': 'quran'},
      },
      {
        'id': 'dua-a',
        'categoryId': 'duas-quran',
        'title': 'أ',
        'text': 'نص أ',
        'sortOrder': 1,
        'verified': true,
        'placeholder': false,
        'source': {'reference': 'سورة إبراهيم، آية 40', 'kind': 'quran'},
      },
    ],
  },
  'assets/data/adhkar.json': {
    'schemaVersion': 1,
    'entries': [
      {
        'id': 'dhikr-demo',
        'categoryId': 'adhkar-morning',
        'title': 'محتوى تجريبي (غير موثّق)',
        'text': '[محتوى تجريبي]',
        'sortOrder': 2,
        'verified': false,
        'placeholder': true,
      },
      {
        'id': 'dhikr-a',
        'categoryId': 'adhkar-morning',
        'title': 'تسبيح',
        'text': 'سبحان الله وبحمده',
        'sortOrder': 1,
        'verified': true,
        'placeholder': false,
      },
    ],
  },
};

/// In-memory loader standing in for the asset bundle.
Future<Object?> Function(String) loaderFor(Map<String, Object?> files) {
  return (String path) async {
    final file = files[path];
    if (file == null) {
      throw ContentException('Failed to read "$path": not found.');
    }
    return file;
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('successful loading (fixture)', () {
    test(
      'loadCatalog returns sorted categories and cross-referenced entries',
      () async {
        final repository = LocalContentRepository(
          loader: loaderFor(_validFixture()),
        );

        final catalog = await repository.loadCatalog();

        expect(catalog.categories.map((c) => c.id).toList(), [
          'adhkar-morning',
          'empty-cat',
          'duas-quran',
        ]);
        // Stable sort by sortOrder: ties keep file load order.
        expect(catalog.allEntries.map((e) => e.id).toList(), [
          'dua-a',
          'dhikr-a',
          'dhikr-demo',
          'dua-b',
        ]);
        expect(catalog.entriesByCategory['adhkar-morning']!.map((e) => e.id), [
          'dhikr-a',
          'dhikr-demo',
        ]);
      },
    );

    test('loadEntriesByCategory returns sorted entries', () async {
      final repository = LocalContentRepository(
        loader: loaderFor(_validFixture()),
      );

      final entries = await repository.loadEntriesByCategory('duas-quran');
      expect(entries.map((e) => e.id).toList(), ['dua-a', 'dua-b']);
    });

    test('a known category with zero entries returns an empty list', () async {
      final repository = LocalContentRepository(
        loader: loaderFor(_validFixture()),
      );

      expect(await repository.loadEntriesByCategory('empty-cat'), isEmpty);
    });

    test('allEntries and per-category views stay independent', () async {
      final repository = LocalContentRepository(
        loader: loaderFor(_validFixture()),
      );

      final all = await repository.loadAllEntries();
      expect(all.length, 4);
      expect(all.where((e) => e.placeholder).length, 1);
    });

    test(
      'excludeUnverified (release mode) drops placeholder/unverified entries '
      'but still validates every entry',
      () async {
        final repository = LocalContentRepository(
          loader: loaderFor(_validFixture()),
          excludeUnverified: true,
        );

        final catalog = await repository.loadCatalog();
        expect(catalog.allEntries.map((e) => e.id), [
          'dua-a',
          'dhikr-a',
          'dua-b',
        ]);
        expect(catalog.allEntries.any((e) => e.placeholder), isFalse);
        expect(catalog.allEntries.any((e) => !e.verified), isFalse);
        expect(catalog.entriesByCategory['adhkar-morning']!.map((e) => e.id), [
          'dhikr-a',
        ]);
      },
    );
  });

  group('error handling', () {
    test('unknown category throws instead of returning empty data', () async {
      final repository = LocalContentRepository(
        loader: loaderFor(_validFixture()),
      );

      await expectLater(
        repository.loadEntriesByCategory('does-not-exist'),
        throwsA(isA<ContentException>()),
      );
    });

    test('malformed JSON surfaces as ContentException', () {
      Future<Object?> decodeFail(String path) async =>
          throw ContentException('decode failed');
      final repository = LocalContentRepository(loader: decodeFail);

      expect(repository.loadCatalog(), throwsA(isA<ContentException>()));
    });

    test('wrong JSON shape (list root) is rejected, not swallowed', () {
      Future<Object?> listRoot(String path) async => <Object?>['unexpected'];
      final repository = LocalContentRepository(loader: listRoot);

      expect(repository.loadCatalog(), throwsA(isA<ContentException>()));
    });

    test('duplicate ids across files are rejected', () {
      final files = _validFixture();
      (files['assets/data/adhkar.json']!
          as Map<Object?, Object?>)['entries'] = <Object?>[
        {
          'id': 'dua-a', // same id used in duas.json
          'categoryId': 'adhkar-morning',
          'title': 'تكرار',
          'text': 'نص',
          'sortOrder': 1,
          'verified': true,
          'placeholder': false,
        },
      ];
      final repository = LocalContentRepository(loader: loaderFor(files));

      expect(
        repository.loadCatalog(),
        throwsA(
          isA<ContentException>().having(
            (e) => e.message,
            'message',
            contains('duplicates an id'),
          ),
        ),
      );
    });

    test('entry pointing at a foreign file-for-category is rejected', () {
      final files = _validFixture();
      (files['assets/data/duas.json']!
          as Map<Object?, Object?>)['entries'] = <Object?>[
        {
          'id': 'dua-misfiled',
          'categoryId': 'adhkar-morning', // category lives in adhkar.json
          'title': 'خطأ',
          'text': 'نص',
          'sortOrder': 1,
          'verified': true,
          'placeholder': false,
        },
      ];
      final repository = LocalContentRepository(loader: loaderFor(files));

      expect(
        repository.loadCatalog(),
        throwsA(
          isA<ContentException>().having(
            (e) => e.message,
            'message',
            contains('does not belong to this file'),
          ),
        ),
      );
    });

    test('entry referencing a nonexistent category is rejected', () {
      final files = _validFixture();
      (files['assets/data/duas.json']!
          as Map<Object?, Object?>)['entries'] = <Object?>[
        {
          'id': 'dua-orphan',
          'categoryId': 'ghost-cat',
          'title': 'يتم',
          'text': 'نص',
          'sortOrder': 1,
          'verified': true,
          'placeholder': false,
        },
      ];
      final repository = LocalContentRepository(loader: loaderFor(files));

      expect(repository.loadCatalog(), throwsA(isA<ContentException>()));
    });

    test('untrusted content file names are rejected', () {
      for (final bad in ['../manifest.json', 'duas.json.bak', 'duas.json/']) {
        final files = _validFixture();
        (files['assets/data/categories.json']!
            as Map<Object?, Object?>)['categories'] = <Object?>[
          {
            'id': 'duas-quran',
            'title': 'أدعية قرآنية',
            'iconKey': 'quran',
            'contentFile': bad,
            'sortOrder': 1,
            'enabled': true,
          },
        ];
        final repository = LocalContentRepository(loader: loaderFor(files));

        expect(
          repository.loadCatalog(),
          throwsA(isA<ContentException>()),
          reason: 'contentFile "$bad" must be rejected',
        );
      }
    });

    test('missing file in the fixture loader is not swallowed', () {
      final files = _validFixture()..remove('assets/data/duas.json');
      final repository = LocalContentRepository(loader: loaderFor(files));

      expect(repository.loadCatalog(), throwsA(isA<ContentException>()));
    });
  });

  group('bundled assets (real snapshot)', () {
    test('real bundle loads with all cross-references intact', () async {
      final repository = LocalContentRepository();
      final catalog = await repository.loadCatalog();

      expect(catalog.categories, isNotEmpty);
      expect(catalog.allEntries.length, 316);

      for (final category in catalog.categories) {
        expect(catalog.entriesByCategory, contains(category.id));
        for (final entry in catalog.entriesByCategory[category.id]!) {
          expect(entry.categoryId, category.id);
        }
      }
      // Sorted by sortOrder everywhere.
      expect(
        catalog.categories.map((c) => c.sortOrder),
        equals([...catalog.categories.map((c) => c.sortOrder)]..sort()),
      );
      // Placeholder data never lays claim to a source.
      for (final entry in catalog.allEntries) {
        if (entry.placeholder) expect(entry.source, isNull);
      }
    });

    test('real bundle loads entries for a known category', () async {
      final repository = LocalContentRepository();
      final morningEntries = await repository.loadEntriesByCategory(
        'adhkar-morning',
      );
      expect(
        morningEntries.map((e) => e.categoryId),
        everyElement('adhkar-morning'),
      );
    });
  });
}
