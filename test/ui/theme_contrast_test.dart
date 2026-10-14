import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_muslims_companion/app/theme/app_theme.dart';

double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrastRatio(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('WCAG AA contrast for theme tokens', () {
    for (final Brightness brightness in <Brightness>[
      Brightness.light,
      Brightness.dark,
    ]) {
      test('text pairs pass AA in $brightness theme', () {
        final AppColors palette = AppTheme.colorsFor(brightness);
        final List<(Color, Color, String)> pairs = <(Color, Color, String)>[
          (palette.ink, palette.parchment, 'ink on parchment'),
          (palette.ink, palette.card, 'ink on card'),
          (palette.muted, palette.parchment, 'muted on parchment'),
          (palette.muted, palette.card, 'muted on card'),
          (palette.goldInk, palette.parchment, 'goldInk on parchment'),
          (palette.goldInk, palette.card, 'goldInk on card'),
          (Colors.white, palette.emerald, 'white on emerald'),
          (Colors.white, palette.emeraldDeep, 'white on emeraldDeep'),
          // Completion checkmark on the gold medallion (icon-level, ≥3).
          (palette.emeraldDeep, palette.gold, 'checkmark on gold'),
        ];
        for (final (Color fg, Color bg, String label) in pairs) {
          final double ratio = contrastRatio(fg, bg);
          final double required = label.startsWith('checkmark') ? 3 : 4.5;
          expect(
            ratio,
            greaterThanOrEqualTo(required),
            reason:
                '$label in $brightness theme is ${ratio.toStringAsFixed(2)}:1',
          );
        }
      });
    }
  });
}
