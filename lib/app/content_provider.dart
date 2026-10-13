// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../content/content_exception.dart';
import '../content/local_content_repository.dart';
import '../content/refresh/content_cache.dart';
import '../content/refresh/content_refresh_service.dart';

/// Holds the loaded content snapshot for the UI, with explicit
/// loading/error/success states. Widgets observe this via `provider`.
///
/// Load priority: validated local cache → bundled assets. A corrupt cache is
/// cleared and falls back to the bundle silently.
class ContentProvider extends ChangeNotifier {
  ContentProvider({
    LocalContentRepository? repository,
    ContentCache? cache,
    ContentRefreshService? refreshService,
  }) : _repository = repository ?? LocalContentRepository(),
       _cache = cache,
       _refreshService = refreshService;

  final LocalContentRepository _repository;
  final ContentCache? _cache;
  final ContentRefreshService? _refreshService;

  ContentCatalog? catalog;

  /// Arabic UI message for the failure state; null while fine.
  String? errorMessage;

  /// Current remote-refresh status; null when no refresh has been attempted.
  RefreshStatus? refreshStatus;

  /// Arabic message describing the last refresh failure; null when fine.
  String? refreshError;

  /// True while a refresh is in progress.
  bool refreshing = false;

  bool _loading = false;
  bool get loading => _loading;

  /// True when a cached snapshot is active (content came from cache, not
  /// the bundled assets).
  bool usingCache = false;

  /// Last successful remote-refresh time, or null when never refreshed.
  DateTime? lastRefresh;

  /// (Re)loads the content: cache first, then bundled assets. Concurrent
  /// calls collapse into one.
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      catalog = await _loadCatalog();
      final cache = _cache;
      if (cache != null) {
        final activeVersion = await cache.getActiveContentVersion();
        usingCache = catalog != null && activeVersion != null;
        lastRefresh = await cache.getLastRefresh();
      }
    } on ContentException catch (error) {
      errorMessage = 'تعذّر تحميل المحتوى: ${error.message}';
    } catch (error) {
      errorMessage = 'تعذّر تحميل المحتوى';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Triggers a remote content refresh. On success the catalog is reloaded
  /// from the new cache. On failure the current snapshot is retained.
  Future<RefreshOutcome?> refresh() async {
    final service = _refreshService;
    if (service == null || refreshing) return null;
    refreshing = true;
    refreshStatus = null;
    refreshError = null;
    notifyListeners();
    try {
      final outcome = await service.refresh();
      refreshStatus = outcome.status;
      refreshError = outcome.errorMessage;
      if (outcome.status == RefreshStatus.updated) {
        await load();
      }
      return outcome;
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  Future<ContentCatalog> _loadCatalog() async {
    final cache = _cache;
    if (cache != null) {
      final snapshot = await cache.readSnapshot();
      if (snapshot != null) {
        try {
          return await LocalContentRepository(loader: loaderForFiles(snapshot))
              .loadCatalog();
        } on ContentException {
          // Corrupt cache — clear and fall through to bundle.
          await cache.clear();
        }
      }
    }
    return _repository.loadCatalog();
  }
}
