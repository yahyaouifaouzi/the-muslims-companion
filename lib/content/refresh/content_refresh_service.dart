import '../content_exception.dart';
import '../local_content_repository.dart';
import '../models/content_manifest.dart';
import 'content_cache.dart';
import 'remote_content_client.dart';

/// Result of a content refresh attempt.
enum RefreshStatus { unchanged, updated, failed }

class RefreshOutcome {
  const RefreshOutcome(this.status, {this.errorMessage});

  const RefreshOutcome.unchanged() : this(RefreshStatus.unchanged);
  const RefreshOutcome.updated() : this(RefreshStatus.updated);
  const RefreshOutcome.failed([String? message])
    : this(RefreshStatus.failed, errorMessage: message);

  final RefreshStatus status;
  final String? errorMessage;
}

/// Orchestrates a remote content refresh with full validation before
/// activation.
///
/// Flow:
/// 1. Fetch the remote manifest and validate it (schema, file allow-list).
/// 2. Compare `contentVersion` with the active cached version — skip
///    downloads when unchanged or older.
/// 3. Download every content file listed in the manifest.
/// 4. Validate the complete snapshot by loading it through
///    [LocalContentRepository] (unique IDs, category cross-references,
///    field bounds — all existing rules).
/// 5. Atomically activate the snapshot in [ContentCache] and persist
///    metadata.
///
/// Any failure at any step leaves the previous snapshot (or bundled assets)
/// untouched. The cache is never partially written.
class ContentRefreshService {
  ContentRefreshService({required this.client, required this.cache});

  final RemoteContentClient client;
  final ContentCache cache;

  Future<RefreshOutcome> refresh() async {
    try {
      // 1. Fetch and validate the remote manifest.
      final manifestRaw = await client.fetchJson('manifest.json');
      final manifest = ContentManifest.fromJson(manifestRaw);
      if (manifest.schemaVersion != 1) {
        throw ContentException(
          'Unsupported schemaVersion ${manifest.schemaVersion}.',
        );
      }
      _validateManifestFiles(manifest);

      // 2. Skip when unchanged or older.
      final activeVersion = await cache.getActiveContentVersion();
      if (activeVersion != null && manifest.contentVersion <= activeVersion) {
        return const RefreshOutcome.unchanged();
      }

      // 3. Download every file.
      final files = <String, Object?>{'manifest.json': manifestRaw};
      for (final fileName in manifest.files) {
        files[fileName] = await client.fetchJson(fileName);
      }

      // 4. Validate the complete snapshot through the repository.
      await LocalContentRepository(loader: loaderForFiles(files)).loadCatalog();

      // 5. Activate atomically and persist metadata.
      await cache.writeSnapshot(files);
      await cache.writeRefreshMetadata(contentVersion: manifest.contentVersion);

      return const RefreshOutcome.updated();
    } on ContentException catch (error) {
      return RefreshOutcome.failed(error.message);
    } catch (_) {
      return const RefreshOutcome.failed();
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
