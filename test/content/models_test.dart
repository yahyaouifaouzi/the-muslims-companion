import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:the_muslims_companion/content/content_exception.dart';
import 'package:the_muslims_companion/content/models/content_category.dart';
import 'package:the_muslims_companion/content/models/content_entry.dart';
import 'package:the_muslims_companion/content/models/content_manifest.dart';

Object? _json(String raw) => jsonDecode(raw);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContentEntry.fromJson', () {
    final validEntry = _json('''
      {
        "id": "e1",
        "categoryId": "cat1",
        "title": "عنوان",
        "text": "نص",
        "sortOrder": 2,
        "verified": true,
        "placeholder": false,
        "tags": ["أ", "ب"],
        "source": {"reference": "سورة البقرة، آية 201", "kind": "quran"},
        "repeatCount": 3
      }
    ''') as Map<Object?, Object?>;

    test('parses a fully populated entry', () {
      final entry = ContentEntry.fromJson(validEntry, fileContext: 'duas');
      expect(entry.id, 'e1');
      expect(entry.categoryId, 'cat1');
      expect(entry.repeatCount, 3);
      expect(entry.tags, ['أ', 'ب']);
      expect(entry.source?.reference, 'سورة البقرة، آية 201');
      expect(entry.source?.authenticity, isNull);
      expect(entry.verified, isTrue);
    });

    test('applies defaults for optional fields', () {
      final entry = ContentEntry.fromJson(
        _json('''
        {
          "id": "e2",
          "categoryId": "cat1",
          "title": "عنوان",
          "text": "نص",
          "sortOrder": 0,
          "verified": false,
          "placeholder": true
        }
      '''),
        fileContext: 'duas',
      );
      expect(entry.source, isNull);
      expect(entry.repeatCount, isNull);
      expect(entry.tags, isEmpty);
    });

    for (final key in ['id', 'categoryId', 'title', 'text']) {
      test('rejects missing "$key"', () {
        final broken = Map<Object?, Object?>.of(validEntry)..remove(key);
        expect(
          () => ContentEntry.fromJson(broken, fileContext: 'duas'),
          throwsA(isA<ContentException>()),
        );
      });
    }

    test('rejects invalid repeat counts (zero, negative, non-integer)', () {
      for (final bad in <Object?>['3', 0, -2, 1.5]) {
        final broken = Map<Object?, Object?>.of(validEntry)
          ..['repeatCount'] = bad;
        expect(
          () => ContentEntry.fromJson(broken, fileContext: 'duas'),
          throwsA(isA<ContentException>()),
        );
      }
    });

    test('rejects cross-field violations', () {
      final brokenSource = Map<Object?, Object?>.of(validEntry)
        ..remove('source');
      expect(
        () => ContentEntry.fromJson(
          brokenSource..['verified'] = true,
          fileContext: 'duas',
        ),
        returnsNormally, // verified without source is allowed (no claim made)
      );
      final placeholderButVerified = Map<Object?, Object?>.of(validEntry)
        ..['placeholder'] = true;
      expect(
        () =>
            ContentEntry.fromJson(placeholderButVerified, fileContext: 'duas'),
        throwsA(isA<ContentException>()),
      );
    });
  });
  group('ContentEntryList duplicate detection', () {
    test('rejects duplicate entry ids', () {
      final raw = _json('''
        {"schemaVersion": 1, "entries": [
          {"id": "x", "categoryId": "c", "title": "t", "text": "tx",
           "sortOrder": 0, "verified": true, "placeholder": false},
          {"id": "x", "categoryId": "c", "title": "t2", "text": "tx2",
           "sortOrder": 1, "verified": true, "placeholder": false}
        ]}
      ''');
      expect(
        () => EntriesFile.fromJson(raw, fileContext: 'duas'),
        throwsA(
          isA<ContentException>().having(
            (e) => e.message,
            'message',
            contains('duplicate entry id "x"'),
          ),
        ),
      );
    });

    test('rejects duplicate category ids', () {
      final raw = _json('''
        {"schemaVersion": 1, "categories": [
          {"id": "c1", "title": "فئة", "iconKey": "book",
           "contentFile": "duas.json", "sortOrder": 0, "enabled": true},
          {"id": "c1", "title": "فئة أخرى", "iconKey": "sunrise",
           "contentFile": "adhkar.json", "sortOrder": 1, "enabled": true}
        ]}
      ''');
      expect(
        () => CategoriesFile.fromJson(raw),
        throwsA(
          isA<ContentException>().having(
            (e) => e.message,
            'message',
            contains('duplicate category id'),
          ),
        ),
      );
    });
  });

  test('ContentManifest.fromJson parses and validates', () {
    final manifest = ContentManifest.fromJson(
      _json('''
      {"schemaVersion": 1, "contentVersion": 1,
       "updatedAt": "2026-10-13",
       "files": ["categories.json", "duas.json"]}
    '''),
    );
    expect(manifest.contentVersion, 1);
    expect(manifest.schemaVersion, 1);
    expect(manifest.files, ['categories.json', 'duas.json']);

    expect(
      () => ContentManifest.fromJson(
        _json(
          '{"schemaVersion": 1, "contentVersion": "x", '
          '"updatedAt": "2026-10-13", "files": ["duas.json"]}',
        ),
      ),
      throwsA(isA<ContentException>()),
    );
  });

  group('bundled assets', () {
    // Asset-readable because assets/data/ is registered in pubspec.yaml.
    const contentFiles = ['duas.json', 'hadiths.json', 'adhkar.json'];

    test('all bundled JSON files decode successfully', () async {
      final manifest = ContentManifest.fromJson(
        _json(await rootBundle.loadString('assets/data/manifest.json')),
      );
      expect(manifest.files.length, 4);
    });

    test(
      'categories.json parses with categories matching the manifest files',
      () async {
        final manifest = ContentManifest.fromJson(
          _json(await rootBundle.loadString('assets/data/manifest.json')),
        );
        final categoriesFile = CategoriesFile.fromJson(
          _json(await rootBundle.loadString('assets/data/categories.json')),
        );
        expect(categoriesFile.categories, isNotEmpty);

        final contentFileNames = categoriesFile.categories
            .map((c) => c.contentFile)
            .toSet();
        expect(contentFileNames, everyElement(isIn(manifest.files)));
      },
    );

    for (final file in contentFiles) {
      test(
        '$file parses and every categoryId references a real category',
        () async {
          final manifest = ContentManifest.fromJson(
            _json(await rootBundle.loadString('assets/data/manifest.json')),
          );
          expect(manifest.files, contains(file));
          final categoriesFile = CategoriesFile.fromJson(
            _json(await rootBundle.loadString('assets/data/categories.json')),
          );
          final categoryIds = categoriesFile.categories
              .map((c) => c.id)
              .toSet();

          final entriesFile = EntriesFile.fromJson(
            _json(await rootBundle.loadString('assets/data/$file')),
            fileContext: file,
          );
          expect(entriesFile.entries, isNotEmpty);
          for (final entry in entriesFile.entries) {
            expect(categoryIds, contains(entry.categoryId));
          }
          expect(
            entriesFile.entries.any((e) => e.placeholder && e.verified),
            isFalse,
          );
        },
      );
    }

    test('no bundled entry with a source is unverified', () async {
      for (final file in contentFiles) {
        final entriesFile = EntriesFile.fromJson(
          _json(await rootBundle.loadString('assets/data/$file')),
          fileContext: file,
        );
        for (final entry in entriesFile.entries) {
          if (entry.source != null) {
            expect(entry.verified, isTrue, reason: entry.id);
          }
        }
      }
    });

    test('no bundled entry invents a repeat count', () async {
      for (final file in contentFiles) {
        final entriesFile = EntriesFile.fromJson(
          _json(await rootBundle.loadString('assets/data/$file')),
          fileContext: file,
        );
        for (final entry in entriesFile.entries) {
          expect(entry.repeatCount, isNull, reason: entry.id);
        }
      }
    });
  });
}
