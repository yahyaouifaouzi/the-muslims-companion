import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted repetition-counter state per entry ID.
///
/// - `counts` maps entry ID → current progress (always ≥ 0).
/// - `targets` maps entry ID → **user-defined** target only. A content
///   `repeatCount` is never copied here — the effective target is
///   `userTarget ?? entry.repeatCount`, decided by the UI.
///
/// Reset removes the count (back to 0). Stale entry IDs left by content
/// updates are ignored by the UI and never crash.
class CounterStore extends ChangeNotifier {
  static const String _countsKey = 'counter_counts';
  static const String _targetsKey = 'counter_targets';

  Map<String, int> _counts = <String, int>{};
  Map<String, int> _targets = <String, int>{};

  /// Current progress for [entryId]; 0 when never counted.
  int countFor(String entryId) => _counts[entryId] ?? 0;

  /// User-defined target for [entryId], or null when none was set.
  int? userTargetFor(String entryId) => _targets[entryId];

  /// True when the user has explicitly set a target for [entryId].
  bool hasUserTarget(String entryId) => _targets.containsKey(entryId);

  /// Increments the count, capped at [target] when a positive target is
  /// given. Never produces a negative count.
  void increment(String entryId, {int? target}) {
    final current = countFor(entryId);
    if (target != null && target > 0 && current >= target) return;
    _counts[entryId] = current + 1;
    notifyListeners();
    unawaited(_persistCounts());
  }

  /// Resets the count for [entryId] back to 0 (removes the stored entry).
  void reset(String entryId) {
    if (!_counts.containsKey(entryId)) return;
    _counts.remove(entryId);
    notifyListeners();
    unawaited(_persistCounts());
  }

  /// Sets a user-defined target. [target] must be positive; invalid values
  /// are ignored.
  void setUserTarget(String entryId, int target) {
    if (target <= 0) return;
    _targets[entryId] = target;
    notifyListeners();
    unawaited(_persistTargets());
  }

  /// Removes a user-defined target (falls back to `entry.repeatCount`).
  void clearUserTarget(String entryId) {
    if (_targets.remove(entryId) == null) return;
    notifyListeners();
    unawaited(_persistTargets());
  }

  /// Restores persisted counts and user targets. Failures leave the store
  /// empty in-memory instead of breaking the app.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _counts = _decodeIntMap(prefs.getString(_countsKey));
      _targets = _decodeIntMap(prefs.getString(_targetsKey));
    } catch (_) {
      // Best-effort restore only.
    }
    notifyListeners();
  }

  static Map<String, int> _decodeIntMap(String? raw) {
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) return <String, int>{};
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          if (key is String && value is int && value >= 0) key: value,
      };
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _persistCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_countsKey, jsonEncode(_counts));
    } catch (_) {
      // Keep the in-memory state even if persistence is unavailable.
    }
  }

  Future<void> _persistTargets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_targetsKey, jsonEncode(_targets));
    } catch (_) {
      // Keep the in-memory state even if persistence is unavailable.
    }
  }
}
