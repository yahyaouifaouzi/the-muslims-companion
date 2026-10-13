import 'package:flutter/foundation.dart';

import '../content/content_exception.dart';
import '../content/local_content_repository.dart';

/// Holds the loaded content snapshot for the UI, with explicit
/// loading/error/success states. Widgets observe this via `provider`.
class ContentProvider extends ChangeNotifier {
  ContentProvider({LocalContentRepository? repository})
    : _repository = repository ?? LocalContentRepository();

  final LocalContentRepository _repository;

  ContentCatalog? catalog;

  /// Arabic UI message for the failure state; null while fine.
  String? errorMessage;

  bool _loading = false;
  bool get loading => _loading;

  /// (Re)loads the bundled snapshot. Concurrent calls collapse into one.
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      catalog = await _repository.loadCatalog();
    } on ContentException catch (error) {
      errorMessage = 'تعذّر تحميل المحتوى: ${error.message}';
    } catch (error) {
      errorMessage = 'تعذّر تحميل المحتوى';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
