// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../content_exception.dart';
import '../local_content_repository.dart' show JsonDocumentLoader;

/// Creates a [JsonDocumentLoader] backed by an in-memory map of file name →
/// decoded JSON object. Used for both cache loading and refresh validation.
JsonDocumentLoader loaderForFiles(Map<String, Object?> files) {
  return (String assetPath) async {
    final name = assetPath.split('/').last;
    final file = files[name];
    if (file == null) {
      throw ContentException('Content file "$name" is missing.');
    }
    return file;
  };
}

/// On-disk cache for a validated content snapshot.
///
/// Stores all content files as a single JSON object in one file so activation
/// is atomic (write to temp, rename). Metadata (active version, last refresh
/// time) lives in shared_preferences. A missing or unreadable snapshot file
/// simply reads as "no cache" — the app falls back to bundled assets.
class ContentCache {
  ContentCache({required Directory directory, SharedPreferences? prefs})
    : _dir = directory,
      _prefs = prefs;

  static const String _snapshotFileName = 'snapshot.json';
  static const String _versionKey = 'active_content_version';
  static const String _lastRefreshKey = 'last_refresh_at';

  final Directory _dir;
  SharedPreferences? _prefs;

  File get _snapshotFile => File('${_dir.path}/$_snapshotFileName');

  /// Active content version, or null when no snapshot has been activated.
  Future<int?> getActiveContentVersion() async =>
      (await _ensurePrefs()).getInt(_versionKey);

  /// Last successful refresh time, or null when never refreshed.
  Future<DateTime?> getLastRefresh() async {
    final raw = (await _ensurePrefs()).getString(_lastRefreshKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<SharedPreferences> _ensurePrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Reads the cached snapshot as a file-name → JSON-object map, or null when
  /// no snapshot exists or it is unreadable/corrupt.
  Future<Map<String, Object?>?> readSnapshot() async {
    final file = _snapshotFile;
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<Object?, Object?>) return null;
      return decoded.cast<String, Object?>();
    } catch (_) {
      return null;
    }
  }

  /// Atomically activates a complete snapshot: writes to a temp file, then
  /// renames over the old one. If any step fails, the previous snapshot (if
  /// any) remains intact.
  Future<void> writeSnapshot(Map<String, Object?> files) async {
    if (!await _dir.exists()) {
      await _dir.create(recursive: true);
    }
    final tmp = File('${_dir.path}/$_snapshotFileName.tmp');
    await tmp.writeAsString(jsonEncode(files), flush: true);
    await tmp.rename(_snapshotFile.path);
  }

  /// Persists refresh metadata after a successful activation.
  Future<void> writeRefreshMetadata({required int contentVersion}) async {
    final prefs = await _ensurePrefs();
    await prefs.setInt(_versionKey, contentVersion);
    await prefs.setString(_lastRefreshKey, DateTime.now().toIso8601String());
  }

  /// Removes the snapshot and metadata. Used when a corrupt cache is detected.
  Future<void> clear() async {
    final file = _snapshotFile;
    if (await file.exists()) {
      await file.delete();
    }
    final prefs = await _ensurePrefs();
    await prefs.remove(_versionKey);
    await prefs.remove(_lastRefreshKey);
  }
}
