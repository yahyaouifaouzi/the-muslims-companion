import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'content_exception.dart';
import 'models/content_category.dart';
import 'models/content_entry.dart';
import 'models/content_manifest.dart';

/// The exact bundled content files this app can ever load. Category
/// `contentFile` values from (possibly untrusted) JSON are validated against
/// this list — they are never used as arbitrary file paths.
const Set<String> kAllowedContentFiles = {
  'manifest.json',
  'categories.json',
  'duas.json',
  'hadiths.json',
  'adhkar.json',
};

/// Loads and decodes the JSON document stored at [assetPath].
typedef JsonDocumentLoader = Future<Object?> Function(String assetPath);

Future<Object?> _defaultLoader(String assetPath) async {
  try {
    return jsonDecode(await rootBundle.loadString(assetPath));
  } on ContentException {
    rethrow;
  } catch (error) {
    throw ContentException('Failed to read "$assetPath": $error');
  }
}

/// Everything loaded from the bundled snapshot.
class ContentCatalog {
  const ContentCatalog({
    required this.manifest,
    required this.categories,
    required this.allEntries,
    required this.entriesByCategory,
  });

  final ContentManifest manifest;
  final List<ContentCategory> categories;
  final List<ContentEntry> allEntries;
  final Map<String, List<ContentEntry>> entriesByCategory;
}

/// Read-only repository over the bundled JSON snapshot.
///
/// All failures surface as typed [ContentException]s; malformed data is never
/// silently reported as an empty list, and unknown category ids throw instead
/// of returning empty results. Country of truth stays the models: widgets
/// never see raw JSON maps.
class LocalContentRepository {
  LocalContentRepository({JsonDocumentLoader? loader})
    : _loadJson = loader ?? _defaultLoader;

  static const String _base = 'assets/data';

  final JsonDocumentLoader _loadJson;

  /// Loads and cross-validates the whole bundled snapshot.
  Future<ContentCatalog> loadCatalog() async {
    final manifest = ContentManifest.fromJson(
      await _loadJson('$_base/manifest.json'),
    );
    _checkSupportedSchema('manifest.json', manifest.schemaVersion);
    _validateManifestFiles(manifest);

    final categoryList = await _loadCategoriesFile(manifest);
    final categories = categoryList.file.categories
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final categoryById = {
      for (final category in categories) category.id: category,
    };

    final entriesByCategory = {
      for (final category in categories) category.id: <ContentEntry>[],
    };
    final allEntries = <ContentEntry>[];
    final seenEntryIds = <String>{};

    for (final fileName in categoryList.contentFileNames) {
      final fileEntries = await _loadEntriesFile('$_base/$fileName');
      for (final entry in fileEntries) {
        if (!seenEntryIds.add(entry.id)) {
          throw ContentException(
            '$fileName: entry id "${entry.id}" duplicates an id used in '
            'another content file.',
          );
        }
        final category = categoryById[entry.categoryId];
        if (category == null || category.contentFile != fileName) {
          throw ContentException(
            '$fileName: entry "${entry.id}" references category id '
            '"${entry.categoryId}" that does not belong to this file.',
          );
        }
        allEntries.add(entry);
        entriesByCategory[entry.categoryId]!.add(entry);
      }
    }

    allEntries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final entries in entriesByCategory.values) {
      entries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return ContentCatalog(
      manifest: manifest,
      categories: categories,
      allEntries: allEntries,
      entriesByCategory: entriesByCategory,
    );
  }

  /// All enabled ordering of categories, sorted by `sortOrder`.
  Future<List<ContentCategory>> loadCategories() =>
      loadCatalog().then((catalog) => catalog.categories);

  /// Entries of a single category, sorted by `sortOrder`.
  ///
  /// Throws [ContentException] for an unknown [categoryId]. A known category
  /// with no entries legitimately returns an empty list.
  Future<List<ContentEntry>> loadEntriesByCategory(String categoryId) async {
    final catalog = await loadCatalog();
    final entries = catalog.entriesByCategory[categoryId];
    if (entries == null) {
      throw ContentException('Unknown category id "$categoryId".');
    }
    return entries;
  }

  /// Every entry across all content files, sorted by `sortOrder`.
  Future<List<ContentEntry>> loadAllEntries() =>
      loadCatalog().then((catalog) => catalog.allEntries);

  Future<FileCategories> _loadCategoriesFile(ContentManifest manifest) async {
    final CategoriesFile categoriesFile;
    try {
      categoriesFile = CategoriesFile.fromJson(
        await _loadJson('$_base/categories.json'),
      );
    } on ContentException catch (error) {
      throw ContentException('categories.json: ${error.message}');
    }
    _checkSupportedSchema('categories.json', categoriesFile.schemaVersion);

    final contentFileNames = <String>[];
    for (final category in categoriesFile.categories) {
      final file = category.contentFile;
      if (!kAllowedContentFiles.contains(file)) {
        throw ContentException(
          'categories.json: category "${category.id}" references content file '
          '"$file" which is not in the allowed file list.',
        );
      }
      if (!manifest.files.contains(file)) {
        throw ContentException(
          'categories.json: category "${category.id}" references content file '
          '"$file" that is missing from manifest.json.',
        );
      }
      if (!contentFileNames.contains(file)) {
        contentFileNames.add(file);
      }
    }
    return FileCategories(categoriesFile, contentFileNames);
  }

  Future<List<ContentEntry>> _loadEntriesFile(String assetPath) async {
    final fileContext = assetPath.split('/').last;
    final EntriesFile entriesFile;
    try {
      entriesFile = EntriesFile.fromJson(
        await _loadJson(assetPath),
        fileContext: fileContext,
      );
    } on ContentException catch (error) {
      throw ContentException('$fileContext: ${error.message}');
    }
    _checkSupportedSchema(fileContext, entriesFile.schemaVersion);
    return entriesFile.entries;
  }

  void _checkSupportedSchema(String file, int schemaVersion) {
    if (schemaVersion != 1) {
      throw ContentException(
        '$file: unsupported schemaVersion $schemaVersion (expected 1).',
      );
    }
  }

  void _validateManifestFiles(ContentManifest manifest) {
    for (final file in manifest.files) {
      if (!kAllowedContentFiles.contains(file)) {
        throw ContentException(
          'manifest.json: file "$file" is not in the allowed file list.',
        );
      }
    }
    if (!manifest.files.contains('categories.json')) {
      throw const ContentException(
        'manifest.json: files must include categories.json.',
      );
    }
  }
}

class FileCategories {
  const FileCategories(this.file, this.contentFileNames);

  final CategoriesFile file;
  final List<String> contentFileNames;
}
