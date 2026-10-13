import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted set of favorite entry IDs.
///
/// Only stable content IDs are stored — never favorite flags inside content
/// JSON. A stored ID whose entry is missing from a later content snapshot is
/// simply not resolved by the UI (stale IDs are skipped, never crash).
class FavoritesStore extends ChangeNotifier {
  static const String _prefsKey = 'favorite_entry_ids';

  final Set<String> _ids = <String>{};

  /// Unmodifiable view of the currently favorite entry IDs.
  Set<String> get ids => Set<String>.unmodifiable(_ids);

  bool contains(String entryId) => _ids.contains(entryId);

  /// Restores the persisted set. Persistence failures (missing plugin, bad
  /// storage) leave favorites empty in-memory instead of breaking the app.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ids
        ..clear()
        ..addAll(prefs.getStringList(_prefsKey) ?? const <String>[]);
    } catch (_) {
      // Best-effort restore only.
    }
    notifyListeners();
  }

  /// Adds the ID if absent, removes it if present. The UI updates immediately
  /// via [notifyListeners]; persistence is best-effort afterwards.
  Future<void> toggle(String entryId) async {
    if (!_ids.add(entryId)) {
      _ids.remove(entryId);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _ids.toList());
    } catch (_) {
      // Keep the in-memory toggle even if persistence is unavailable.
    }
  }
}
