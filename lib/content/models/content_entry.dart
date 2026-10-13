import 'content_source.dart';
import '../content_exception.dart';

/// Container for a parsed entries file (duas.json, hadiths.json, adhkar.json).
class EntriesFile {
  const EntriesFile({required this.schemaVersion, required this.entries});

  final int schemaVersion;
  final List<ContentEntry> entries;

  factory EntriesFile.fromJson(Object? raw, {required String fileContext}) {
    if (raw is! Map<Object?, Object?>) {
      throw ContentException('$fileContext: root must be an object.');
    }
    final schemaVersion = raw['schemaVersion'];
    if (schemaVersion is! int) {
      throw ContentException('$fileContext: schemaVersion must be an integer.');
    }
    return EntriesFile(
      schemaVersion: schemaVersion,
      entries: ContentEntryList.listFromJson(
        raw['entries'],
        fileContext: fileContext,
      ),
    );
  }
}

/// Collection parser for entry lists with duplicate-ID detection.
class ContentEntryList {
  static List<ContentEntry> listFromJson(
    Object? raw, {
    required String fileContext,
  }) {
    if (raw is! List<Object?>) {
      throw ContentException('$fileContext: entries must be an array.');
    }
    final parsed = <ContentEntry>[];
    final seenIds = <String>{};
    for (var i = 0; i < raw.length; i++) {
      final entry = ContentEntry.fromJson(
        raw[i],
        fileContext: '$fileContext[${i + 1}]',
      );
      if (!seenIds.add(entry.id)) {
        throw ContentException(
          '$fileContext: duplicate entry id "${entry.id}".',
        );
      }
      parsed.add(entry);
    }
    return parsed;
  }
}

/// A single displayable content item (dua, hadith, or dhikr).
///
/// Favorite state is intentionally NOT part of this model: it lives only in
/// local user settings, never in remote or bundled content.
class ContentEntry {
  const ContentEntry({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.text,
    required this.sortOrder,
    required this.verified,
    required this.placeholder,
    this.source,
    this.repeatCount,
    this.tags = const [],
  });

  final String id;
  final String categoryId;
  final String title;
  final String text;

  /// Null when no verified attribution exists; empty source fields must be
  /// hidden by the UI, never shown as facts.
  final ContentSource? source;

  /// Positive repetition count supplied and validated upstream. Never present
  /// in bundled data unless the prescribed count is verified; null means the
  /// UI must not invent one (a user-defined target may exist separately).
  final int? repeatCount;

  final List<String> tags;
  final int sortOrder;

  /// True only when wording and attribution were reviewed; false placeholders
  /// must be clearly marked in the UI.
  final bool verified;

  /// Marks schema/demo placeholder rows that can never be mistaken for real
  /// religious content.
  final bool placeholder;

  factory ContentEntry.fromJson(Object? raw, {required String fileContext}) {
    if (raw is! Map<Object?, Object?>) {
      throw ContentException('$fileContext: entry must be an object.');
    }

    String requiredString(String key) {
      final value = raw[key];
      if (value is! String || value.trim().isEmpty) {
        throw ContentException(
          '$fileContext: "$key" is required and must be a non-empty string.',
        );
      }
      return value;
    }

    final id = requiredString('id');
    final categoryId = requiredString('categoryId');
    final title = requiredString('title');
    final text = requiredString('text');

    final source = raw['source'] == null
        ? null
        : ContentSource.fromJson(raw['source'], fileContext: fileContext);

    final repeatCount = raw['repeatCount'];
    if (repeatCount != null && repeatCount is! int) {
      throw ContentException(
        '$fileContext: repeatCount must be a positive integer or omitted.',
      );
    }
    if (repeatCount is int && repeatCount <= 0) {
      throw ContentException(
        '$fileContext: repeatCount must be positive (got $repeatCount).',
      );
    }

    final tagsRaw = raw['tags'];
    final tagList = <String>[];
    if (tagsRaw != null) {
      if (tagsRaw is! List<Object?>) {
        throw ContentException(
          '$fileContext: tags must be an array of strings.',
        );
      }
      for (final tag in tagsRaw) {
        if (tag is! String || tag.trim().isEmpty) {
          throw ContentException(
            '$fileContext: tags must be non-empty strings.',
          );
        }
        tagList.add(tag);
      }
    }

    final sortOrder = raw['sortOrder'];
    if (sortOrder is! int || sortOrder < 0) {
      throw ContentException(
        '$fileContext: sortOrder must be a non-negative integer.',
      );
    }

    final verified = raw['verified'];
    if (verified is! bool) {
      throw ContentException('$fileContext: verified must be a boolean.');
    }
    final placeholder = raw['placeholder'];
    if (placeholder is! bool) {
      throw ContentException('$fileContext: placeholder must be a boolean.');
    }
    if (placeholder && verified) {
      throw ContentException(
        '$fileContext: placeholder entries must also have verified=true.',
      );
    }

    return ContentEntry(
      id: id,
      categoryId: categoryId,
      title: title,
      text: text,
      source: source,
      repeatCount: repeatCount as int?,
      tags: tagList,
      sortOrder: sortOrder,
      verified: verified,
      placeholder: placeholder,
    );
  }
}
