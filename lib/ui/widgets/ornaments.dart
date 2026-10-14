import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Shared vector ornaments (girih, mihrab, medallions) plus the card and
/// header components that carry them. Everything is drawn with CustomPaint —
/// no images — and every color comes from the theme palette.

/// Motion duration for the animations this app adds; zero when the platform
/// asks for reduced motion.
Duration appMotion(BuildContext context, [int milliseconds = 220]) {
  if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
  return Duration(milliseconds: milliseconds);
}

/// Eight-pointed star built from two overlapping squares (girih khatem).
Path octagramPath(Offset center, double radius) {
  final Path path = Path();
  for (final double base in const <double>[0, math.pi / 4]) {
    for (int i = 0; i < 4; i++) {
      final double angle = base + i * math.pi / 2;
      final Offset point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
  }
  return path;
}

/// Repeating girih lattice of small eight-pointed stars, at very low opacity.
/// Used behind app bars and headers; never over body text.
class GirihPatternPainter extends CustomPainter {
  GirihPatternPainter({
    required this.color,
    this.opacity = 0.16,
    this.spacing = 46,
    this.strokeWidth = 1,
  });

  final Color color;
  final double opacity;
  final double spacing;
  final double strokeWidth;

  late final Path _tile = octagramPath(Offset.zero, spacing * 0.34);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final double radius = spacing * 0.34;
    for (double y = radius; y <= size.height + radius; y += spacing) {
      for (double x = radius; x <= size.width + radius; x += spacing) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPath(_tile, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(GirihPatternPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity ||
      oldDelegate.spacing != spacing ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Filled eight-pointed star used as a divider/section ornament.
class StarOrnamentPainter extends CustomPainter {
  StarOrnamentPainter({required this.color, this.strokeWidth = 1.2});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width, size.height) / 2 - strokeWidth;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(octagramPath(center, radius), line);
    canvas.drawPath(octagramPath(center, radius * 0.52), line);
    canvas.drawCircle(center, radius * 0.16, Paint()..color = color);
  }

  @override
  bool shouldRepaint(StarOrnamentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Thin gold frame, four corner flourishes and an optional mihrab arch for
/// mushaf-style cards.
class MushafOrnamentPainter extends CustomPainter {
  MushafOrnamentPainter({
    required this.color,
    this.arch = false,
    this.inset = 7,
    this.strokeWidth = 1,
  });

  final Color color;
  final bool arch;
  final double inset;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final Rect rect = Rect.fromLTWH(
      inset,
      inset,
      math.max(0, size.width - inset * 2),
      math.max(0, size.height - inset * 2),
    );
    final double radius = math.max(2, AppTheme.radiusMushaf - inset);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      line,
    );

    // Corner flourishes: a concentric arc with a dot at its midpoint.
    final Paint dot = Paint()..color = color.withValues(alpha: 0.9);
    final double arcRadius = radius + 7;
    final List<(Offset, double)> corners = <(Offset, double)>[
      (Offset(rect.left + radius, rect.top + radius), math.pi),
      (Offset(rect.right - radius, rect.top + radius), -math.pi / 2),
      (Offset(rect.right - radius, rect.bottom - radius), 0),
      (Offset(rect.left + radius, rect.bottom - radius), math.pi / 2),
    ];
    for (final (Offset center, double start) in corners) {
      final Rect arc = Rect.fromCircle(center: center, radius: arcRadius);
      canvas.drawArc(arc, start, math.pi / 2, false, line);
      final double mid = start + math.pi / 4;
      canvas.drawCircle(
        center + Offset(math.cos(mid), math.sin(mid)) * arcRadius,
        2,
        dot,
      );
    }

    if (arch) _drawArch(canvas, size, line, dot);
  }

  void _drawArch(Canvas canvas, Size size, Paint line, Paint dot) {
    final double cx = size.width / 2;
    final double half = size.width * 0.2;
    final double base = inset + 52;
    final double apex = inset + 8;
    final Path arch = Path()
      ..moveTo(cx - half, base)
      ..cubicTo(
        cx - half,
        base - half * 0.85,
        cx - half * 0.4,
        apex + 10,
        cx,
        apex,
      )
      ..cubicTo(
        cx + half * 0.4,
        apex + 10,
        cx + half,
        base - half * 0.85,
        cx + half,
        base,
      );
    canvas.drawPath(arch, line);
    canvas.drawPath(octagramPath(Offset(cx, (apex + base) / 2 + 4), 7), dot);
  }

  @override
  bool shouldRepaint(MushafOrnamentPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.arch != arch ||
      oldDelegate.inset != inset ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Regular octagon outline used behind category icons.
class OctagonPainter extends CustomPainter {
  OctagonPainter({
    required this.color,
    required this.fill,
    this.strokeWidth = 1.4,
  });

  final Color color;
  final Color fill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width, size.height) / 2 - strokeWidth;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Path path = Path();
    for (int i = 0; i < 8; i++) {
      final double angle = math.pi / 8 + i * math.pi / 4;
      final Offset point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(OctagonPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.fill != fill ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// App bar with an emerald gradient and a faint girih lattice.
class OrnamentedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OrnamentedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final Widget title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final AppColors palette = Theme.of(context).palette;
    return AppBar(
      title: title,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: <Color>[palette.emerald, palette.emeraldDeep],
          ),
        ),
        child: CustomPaint(
          painter: GirihPatternPainter(color: palette.gold, opacity: 0.16),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Section title with an optional icon, trailing action and a short gold rule.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppTheme.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: palette.goldInk),
                const SizedBox(width: AppTheme.space2),
              ],
              Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              ?trailing,
            ],
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: AppTheme.space1),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: AppTheme.space2),
          Container(
            height: 2,
            width: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: <Color>[
                  palette.gold,
                  palette.gold.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hairline–star–hairline separator used between sections of religious text.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({super.key, this.starSize = 16, this.vertical = 12});

  final double starSize;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    final AppColors palette = Theme.of(context).palette;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: vertical),
      child: Row(
        children: <Widget>[
          _line(context, palette, atStart: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
            child: CustomPaint(
              size: Size.square(starSize),
              painter: StarOrnamentPainter(color: palette.gold),
            ),
          ),
          _line(context, palette, atStart: false),
        ],
      ),
    );
  }

  /// Fades toward the star, mirroring correctly in RTL.
  static Widget _line(
    BuildContext context,
    AppColors palette, {
    required bool atStart,
  }) {
    final bool startIsLeft = Directionality.of(context) != TextDirection.rtl;
    final Alignment outer = atStart
        ? (startIsLeft ? const Alignment(-1, 0) : const Alignment(1, 0))
        : (startIsLeft ? const Alignment(1, 0) : const Alignment(-1, 0));
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: outer,
            end: Alignment.center,
            colors: <Color>[
              palette.gold.withValues(alpha: 0.05),
              palette.gold.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: const SizedBox(height: 1),
      ),
    );
  }
}

/// Rounded card with a hairline border, soft shadow and press ripple.
///
/// [accent] swaps the border for gold (featured/warm cards); [ornate] adds the
/// mushaf frame and [arch] the mihrab crown used on the reader.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.accent = false,
    this.ornate = false,
    this.arch = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool accent;
  final bool ornate;
  final bool arch;

  @override
  Widget build(BuildContext context) {
    final AppColors palette = Theme.of(context).palette;
    final BorderRadius radius = BorderRadius.circular(
      ornate ? AppTheme.radiusMushaf : AppTheme.radiusCard,
    );
    final Widget content = Padding(
      padding: padding ?? const EdgeInsetsDirectional.all(AppTheme.space4),
      child: child,
    );
    final Widget painted = ornate
        ? CustomPaint(
            painter: MushafOrnamentPainter(color: palette.gold, arch: arch),
            child: content,
          )
        : content;
    return Padding(
      padding:
          margin ?? const EdgeInsetsDirectional.only(bottom: AppTheme.space3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.ink.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.canvas,
          color: palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: accent ? palette.gold : palette.outline,
              width: accent ? 1.2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? painted
              : InkWell(onTap: onTap, borderRadius: radius, child: painted),
        ),
      ),
    );
  }
}

/// Icon inside an octagonal medallion — used for category entries.
class MedallionIcon extends StatelessWidget {
  const MedallionIcon({super.key, required this.icon, this.size = 52});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppColors palette = Theme.of(context).palette;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size.square(size),
            painter: OctagonPainter(
              color: palette.gold,
              fill: palette.emerald.withValues(alpha: 0.08),
            ),
          ),
          Icon(icon, size: size * 0.46, color: palette.emerald),
        ],
      ),
    );
  }
}
