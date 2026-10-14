import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palette carried by the theme, so widgets never hard-code a color.
///
/// Read it with `Theme.of(context).palette` (see [AppThemeX]). Light and dark
/// each ship their own instance; both are defined next to the ThemeData.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.parchment,
    required this.card,
    required this.ink,
    required this.muted,
    required this.gold,
    required this.goldInk,
    required this.emerald,
    required this.emeraldDeep,
    required this.track,
    required this.outline,
  });

  /// Parchment/cream app background (deep green-black in dark mode).
  final Color parchment;

  /// Raised card surface.
  final Color card;

  /// Primary text: soft dark green, never pure black (light in dark mode).
  final Color ink;

  /// Secondary/caption text.
  final Color muted;

  /// Warm gold for borders, ornaments and active accents (stroke-level use).
  final Color gold;

  /// Gold dark enough to read as text on a light card (bright in dark mode).
  final Color goldInk;

  /// Brand emerald — app bars, filled buttons.
  final Color emerald;

  /// Deeper emerald for gradients and dark app bars.
  final Color emeraldDeep;

  /// Track behind the tasbih progress ring.
  final Color track;

  /// Hairline border / divider color.
  final Color outline;

  @override
  AppColors copyWith({
    Color? parchment,
    Color? card,
    Color? ink,
    Color? muted,
    Color? gold,
    Color? goldInk,
    Color? emerald,
    Color? emeraldDeep,
    Color? track,
    Color? outline,
  }) {
    return AppColors(
      parchment: parchment ?? this.parchment,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      gold: gold ?? this.gold,
      goldInk: goldInk ?? this.goldInk,
      emerald: emerald ?? this.emerald,
      emeraldDeep: emeraldDeep ?? this.emeraldDeep,
      track: track ?? this.track,
      outline: outline ?? this.outline,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      parchment: Color.lerp(parchment, other.parchment, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldInk: Color.lerp(goldInk, other.goldInk, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      emeraldDeep: Color.lerp(emeraldDeep, other.emeraldDeep, t)!,
      track: Color.lerp(track, other.track, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }
}

/// Material 3 theme for رفيق Müslüman — deep emerald, warm gold, parchment.
///
/// Every color, typeface, spacing and radius used by the UI is declared here;
/// widgets read them through [AppThemeX] instead of hard-coding values.
class AppTheme {
  AppTheme._();

  // ── Typefaces (bundled, no network fetch) ───────────────────────────
  /// UI text: titles, labels, buttons.
  static const String fontUi = 'Tajawal';

  /// Calligraphic Naskh for Qur'an verses and duas.
  static const String fontQuran = 'Amiri';

  /// Naskh for hadith and other religious prose.
  static const String fontHadith = 'NotoNaskhArabic';

  // ── Spacing (8pt grid) ──────────────────────────────────────────────
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;

  // ── Radii ───────────────────────────────────────────────────────────
  static const double radiusCard = 16;
  static const double radiusMushaf = 20;
  static const double radiusPill = 28;
  static const double radiusField = 14;

  /// Warm off-white background, kept for callers that predate the palette.
  static const Color offWhite = Color(0xFFF6F1E6);

  static const AppColors _light = AppColors(
    parchment: Color(0xFFF6F1E6),
    card: Color(0xFFFFFDF7),
    ink: Color(0xFF1E3128),
    muted: Color(0xFF56675C),
    gold: Color(0xFFC9A45E),
    goldInk: Color(0xFF7C5E1C),
    emerald: Color(0xFF155E38),
    emeraldDeep: Color(0xFF0E4127),
    track: Color(0xFFE6DECB),
    outline: Color(0xFFE4DAC4),
  );

  static const AppColors _dark = AppColors(
    parchment: Color(0xFF0C1A13),
    card: Color(0xFF14261C),
    ink: Color(0xFFE9F0E9),
    muted: Color(0xFFA2B3A7),
    gold: Color(0xFFD9B869),
    goldInk: Color(0xFFE2C481),
    emerald: Color(0xFF2E7D51),
    emeraldDeep: Color(0xFF0F2419),
    track: Color(0xFF1F3A2C),
    outline: Color(0xFF26402F),
  );

  static AppColors colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool dark = brightness == Brightness.dark;
    final AppColors palette = colorsFor(brightness);
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: _light.emerald,
          brightness: brightness,
        ).copyWith(
          primary: palette.emerald,
          onPrimary: dark ? const Color(0xFFEAF6EE) : Colors.white,
          primaryContainer: dark
              ? palette.emeraldDeep
              : const Color(0xFFDCEBDF),
          onPrimaryContainer: dark
              ? const Color(0xFFDCEBDF)
              : const Color(0xFF0E3B23),
          secondary: palette.gold,
          onSecondary: dark ? const Color(0xFF231A05) : const Color(0xFF3A2E0C),
          secondaryContainer: dark
              ? const Color(0xFF3B3320)
              : const Color(0xFFF3E7C8),
          onSecondaryContainer: dark
              ? const Color(0xFFEADFBF)
              : const Color(0xFF4A3A10),
          onSurface: palette.ink,
          onSurfaceVariant: palette.muted,
          surface: palette.parchment,
          surfaceContainer: palette.card,
          surfaceContainerLow: palette.card,
          surfaceContainerHigh: dark ? const Color(0xFF1A2F23) : palette.card,
          surfaceContainerHighest: dark
              ? const Color(0xFF1F382A)
              : const Color(0xFFF1EADA),
          outline: palette.outline,
          outlineVariant: palette.outline,
          error: dark ? const Color(0xFFF2B8B5) : const Color(0xFFB3261E),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // UI typeface; religious styles override it with Amiri/NotoNaskh.
      fontFamily: fontUi,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.parchment,
      extensions: <ThemeExtension<dynamic>>[palette],
      textTheme: _textTheme(palette),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? palette.emeraldDeep : palette.emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontUi,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: palette.outline),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.outline,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.emerald,
        selectionColor: palette.gold.withValues(alpha: 0.35),
        selectionHandleColor: palette.emerald,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        hintStyle: TextStyle(color: palette.muted, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space4,
          vertical: space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: palette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: palette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: palette.gold, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.emerald,
          foregroundColor: dark ? const Color(0xFFEAF6EE) : Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: space5,
            vertical: space3,
          ),
          textStyle: const TextStyle(
            fontFamily: fontUi,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusField),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.emerald,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: fontUi,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: palette.ink,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.card,
        height: 68,
        indicatorColor: palette.gold.withValues(alpha: dark ? 0.22 : 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontUi,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? palette.emerald
                : palette.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? palette.emerald
                : palette.muted,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMushaf),
          side: BorderSide(color: palette.outline),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontUi,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontUi,
          fontSize: 16,
          color: palette.ink,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (dark ? const Color(0xFFEAF6EE) : Colors.white)
              : palette.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.emerald
              : palette.track,
        ),
      ),
      // Calmer than the default zoom push; settles quickly under tests.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Type scale: display, title, body, caption — UI body never below 16sp.
  static TextTheme _textTheme(AppColors palette) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontUi,
        fontSize: 44,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      displayMedium: TextStyle(
        fontFamily: fontUi,
        fontSize: 36,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      displaySmall: TextStyle(
        fontFamily: fontUi,
        fontSize: 30,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontUi,
        fontSize: 28,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontUi,
        fontSize: 24,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontUi,
        fontSize: 21,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      titleLarge: TextStyle(
        fontFamily: fontUi,
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      titleMedium: TextStyle(
        fontFamily: fontUi,
        fontSize: 18,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: palette.ink,
      ),
      titleSmall: TextStyle(
        fontFamily: fontUi,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: palette.ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontUi,
        fontSize: 17,
        height: 1.65,
        color: palette.ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontUi,
        fontSize: 16,
        height: 1.65,
        color: palette.ink,
      ),
      bodySmall: TextStyle(
        fontFamily: fontUi,
        fontSize: 14,
        height: 1.55,
        color: palette.muted,
      ),
      labelLarge: TextStyle(
        fontFamily: fontUi,
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      labelMedium: TextStyle(
        fontFamily: fontUi,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: palette.muted,
      ),
      labelSmall: TextStyle(
        fontFamily: fontUi,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: palette.muted,
      ),
    );
  }

  // ── Religious text styles (calligraphic, generous leading) ──────────

  /// Qur'an verses and duas: Amiri, tall line height for full tashkeel.
  static TextStyle religious({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    TextAlign? textAlign,
  }) {
    return TextStyle(
      fontFamily: fontQuran,
      fontSize: fontSize,
      height: 2.0,
      fontWeight: fontWeight,
      color: color,
      debugLabel: 'religious',
    );
  }

  /// Hadith: Noto Naskh, slightly smaller than the dua scale.
  static TextStyle hadith({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontHadith,
      fontSize: fontSize,
      height: 1.9,
      fontWeight: fontWeight,
      color: color,
      debugLabel: 'hadith',
    );
  }
}

/// Convenience access to the palette and the religious text styles.
extension AppThemeX on ThemeData {
  AppColors get palette =>
      extension<AppColors>() ??
      const AppColors(
        parchment: AppTheme.offWhite,
        card: Colors.white,
        ink: Colors.black,
        muted: Colors.black45,
        gold: Color(0xFFC9A45E),
        goldInk: Color(0xFF7C5E1C),
        emerald: Color(0xFF155E38),
        emeraldDeep: Color(0xFF0E4127),
        track: Color(0xFFE6DECB),
        outline: Color(0xFFE4DAC4),
      );
}
