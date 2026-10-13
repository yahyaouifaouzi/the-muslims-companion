import '../content_exception.dart';

/// Container for a parsed categories.json file.
class CategoriesFile {
  const CategoriesFile({required this.schemaVersion, required this.categories});

  final int schemaVersion;
  final List<ContentCategory> categories;

  factory CategoriesFile.fromJson(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      throw const ContentException('categories.json: root must be an object.');
    }
    final schemaVersion = raw['schemaVersion'];
    if (schemaVersion is! int) {
      throw const ContentException(
        'categories.json: schemaVersion must be an integer.',
      );
    }
    return CategoriesFile(
      schemaVersion: schemaVersion,
      categories: ContentCategoryList.listFromJson(raw['categories']),
    );
  }
}

/// Collection parser for category lists with duplicate-ID detection.
class ContentCategoryList {
  static List<ContentCategory> listFromJson(Object? raw) {
    if (raw is! List<Object?>) {
      throw const ContentException(
        'categories.json: categories must be an array.',
      );
    }
    final parsed = <ContentCategory>[];
    final seenIds = <String>{};
    for (var i = 0; i < raw.length; i++) {
      final category = ContentCategory.fromJson(
        raw[i],
        fileContext: 'categories.json[${i + 1}]',
      );
      if (!seenIds.add(category.id)) {
        throw ContentException(
          'categories.json: duplicate category id "${category.id}".',
        );
      }
      parsed.add(category);
    }
    return parsed;
  }
}

/// A browsable content category. Stable fields: use [id] for navigation and
/// persistence; [iconKey] is mapped to an icon in the UI layer with a safe
/// fallback for unknown keys.
class ContentCategory {
  const ContentCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconKey,
    required this.contentFile,
    required this.sortOrder,
    required this.enabled,
  });

  final String id;
  final String title;
  final String subtitle;
  final String iconKey;

  /// Bundled asset file that holds this category's entries. The repository
  /// validates this against a fixed allow-list; never trust arbitrary paths.
  final String contentFile;

  final int sortOrder;

  /// Disabled categories are hidden from the UI but kept in the file.
  final bool enabled;

  factory ContentCategory.fromJson(Object? raw, {required String fileContext}) {
    if (raw is! Map<Object?, Object?>) {
      throw ContentException('$fileContext: category must be an object.');
    }
    final id = _requiredString(raw, 'id', fileContext);
    final title = _requiredString(raw, 'title', fileContext);
    final subtitle = raw['subtitle'];
    if (subtitle != null && subtitle is! String) {
      throw ContentException('$fileContext: subtitle must be a string.');
    }
    final iconKey = _requiredString(raw, 'iconKey', fileContext);
    final contentFile = _requiredString(raw, 'contentFile', fileContext);
    final sortOrder = raw['sortOrder'];
    if (sortOrder is! int || sortOrder < 0) {
      throw ContentException(
        '$fileContext: sortOrder must be a non-negative integer.',
      );
    }
    final enabled = raw['enabled'];
    if (enabled is! bool) {
      throw ContentException('$fileContext: enabled must be a boolean.');
    }
    return ContentCategory(
      id: id,
      title: title,
      subtitle: subtitle as String? ?? '',
      iconKey: iconKey,
      contentFile: contentFile,
      sortOrder: sortOrder,
      enabled: enabled,
    );
  }

  static String _requiredString(
    Map<Object?, Object?> raw,
    String key,
    String fileContext,
  ) {
    final value = raw[key];
    if (value is! String || value.trim().isEmpty) {
      throw ContentException(
        '$fileContext: "$key" is required and must be a non-empty string.',
      );
    }
    return value;
  }
}
