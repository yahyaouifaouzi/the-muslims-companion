import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode chosen in Settings; defaults to following the system setting.
class AppearanceStore extends ChangeNotifier {
  static const String prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Restores the persisted choice. Failures keep the system default.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = _fromName(prefs.getString(prefsKey));
    } catch (_) {
      // Best-effort restore only.
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, nameOf(mode));
    } catch (_) {
      // Keep the in-memory choice even if persistence is unavailable.
    }
  }

  static ThemeMode _fromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String nameOf(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
