import '../content_exception.dart';

/// Top-level metadata for the bundled/remote content snapshot.
///
/// [schemaVersion] describes the JSON contract itself and changes only when
/// field structures change; [contentVersion] bumps whenever actual text
/// content is revised. The two are intentionally kept separate.
class ContentManifest {
  const ContentManifest({
    required this.schemaVersion,
    required this.contentVersion,
    required this.updatedAt,
    required this.files,
  });

  final int schemaVersion;
  final int contentVersion;

  /// ISO-8601 date when the snapshot was last reviewed/published.
  final String updatedAt;

  /// Exact asset file names composing the snapshot. File names must match a
  /// fixed allow-list before loading (validated by the repository).
  final List<String> files;

  factory ContentManifest.fromJson(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      throw const ContentException('manifest.json: root must be an object.');
    }
    final schemaVersion = raw['schemaVersion'];
    if (schemaVersion is! int) {
      throw const ContentException(
        'manifest.json: schemaVersion must be an integer.',
      );
    }
    final contentVersion = raw['contentVersion'];
    if (contentVersion is! int) {
      throw const ContentException(
        'manifest.json: contentVersion must be an integer.',
      );
    }
    final updatedAt = raw['updatedAt'];
    if (updatedAt is! String || updatedAt.isEmpty) {
      throw const ContentException(
        'manifest.json: updatedAt is required and must be a string.',
      );
    }
    final files = raw['files'];
    if (files is! List<Object?> || files.isEmpty) {
      throw const ContentException(
        'manifest.json: files must be a non-empty array of file names.',
      );
    }
    final fileNames = <String>[];
    for (final file in files) {
      if (file is! String || file.isEmpty) {
        throw const ContentException(
          'manifest.json: every file entry must be a non-empty string.',
        );
      }
      fileNames.add(file);
    }
    return ContentManifest(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      updatedAt: updatedAt,
      files: fileNames,
    );
  }
}
