import 'package:flutter/material.dart';

/// Material 3 theme for رفيق المسلم.
///
/// Palette: deep Islamic green, off-white surfaces, restrained beige/gold
/// accents. Used consistently across all screens; tweak values here only.
class AppTheme {
  AppTheme._();

  /// Deep Islamic green — primary brand color.
  static const Color greenPrimary = Color(0xFF2E6B34);

  /// Darker green for surface containers / dark accents.
  static const Color greenDark = Color(0xFF1E4A24);

  /// Warm beige/gold accent, used sparingly (dividers, highlights).
  static const Color beigeAccent = Color(0xFFCBB98A);

  /// Warm off-white background (slightly softer than pure white).
  static const Color offWhite = Color(0xFFFBF9F4);

  static ThemeData light() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: greenPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: greenPrimary,
          surface: offWhite,
          secondary: beigeAccent,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: offWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: greenPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x22800000), width: 1),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
