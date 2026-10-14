import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last entry the user opened so the home screen can offer a
/// "continue where you left off" card. One id only; the card can be
/// dismissed, and stale ids (entry removed by a content update) are simply
/// not shown.
class LastReadStore extends ChangeNotifier {
  static const String _prefsKey = 'last_read_entry_id';

  String? entryId;

  /// Restores the persisted id. Failures leave it null in-memory.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      entryId = prefs.getString(_prefsKey);
    } catch (_) {
      // Best-effort restore only.
    }
    notifyListeners();
  }

  /// Records [id] as the most recently opened entry.
  Future<void> record(String id) async {
    if (entryId == id) return;
    entryId = id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, id);
    } catch (_) {
      // Keep the in-memory value even if persistence is unavailable.
    }
  }

  /// Dismisses the continue card.
  Future<void> clear() async {
    if (entryId == null) return;
    entryId = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {
      // Best-effort clear only.
    }
  }
}
