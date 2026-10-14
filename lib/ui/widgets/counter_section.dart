import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/counter_store.dart';
import '../../app/theme/app_theme.dart';
import '../../content/models/content_entry.dart';
import 'ornaments.dart';

/// Tasbih-style repetition counter for one entry.
///
/// Visible when the content supplies a validated `repeatCount` **or** the
/// user has set their own target. No count is ever invented: when neither
/// exists, the widget offers an explicit "set target" action instead.
///
/// Semantics:
/// - Tap anywhere on the dial to increment (capped at the target); a light
///   haptic on each tap, a stronger one at the target.
/// - Progress is drawn as a gold arc over a muted track; at the target the
///   dial shows a check badge until it is reset.
/// - Reset returns the count to 0 (only shown once counting has started).
/// - A user-defined target overrides `entry.repeatCount` for that entry.
class CounterSection extends StatelessWidget {
  const CounterSection({super.key, required this.entry});

  final ContentEntry entry;

  /// Diameter of the tasbih dial — well above the 48dp accessibility floor.
  static const double tapTargetSize = 200;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    final CounterStore store = context.watch<CounterStore>();
    final int? target = store.userTargetFor(entry.id) ?? entry.repeatCount;

    if (target == null) {
      return Center(
        child: TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('حدد عدد التكرار'),
          onPressed: () => _promptTarget(context, store),
        ),
      );
    }

    final int count = store.countFor(entry.id);
    final bool complete = count >= target;
    final double progress = target > 0 ? (count / target).clamp(0.0, 1.0) : 0.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'التكرار',
            style: theme.textTheme.labelLarge?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppTheme.space2),
          SizedBox(
            width: tapTargetSize,
            height: tapTargetSize,
            child: Material(
              type: MaterialType.circle,
              color: Colors.transparent,
              child: Semantics(
                button: true,
                enabled: !complete,
                label: complete ? 'اكتمل العد' : 'اضغط للعد',
                child: InkWell(
                  key: const ValueKey('counter-tap-target'),
                  customBorder: const CircleBorder(),
                  onTap: complete
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          store.increment(entry.id, target: target);
                          if (count + 1 >= target) {
                            HapticFeedback.mediumImpact();
                          }
                        },
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned.fill(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: appMotion(context, 260),
                          curve: Curves.easeOutCubic,
                          builder:
                              (
                                BuildContext context,
                                double value,
                                Widget? child,
                              ) {
                                return CustomPaint(
                                  painter: _DialPainter(
                                    progress: value,
                                    palette: palette,
                                  ),
                                );
                              },
                        ),
                      ),
                      Text(
                        '$count',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 64,
                          height: 1,
                          color: complete ? palette.emerald : palette.ink,
                        ),
                      ),
                      if (complete)
                        Positioned(
                          bottom: 22,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: appMotion(context, 320),
                            curve: Curves.easeOutBack,
                            builder:
                                (
                                  BuildContext context,
                                  double value,
                                  Widget? child,
                                ) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: child,
                                    ),
                                  );
                                },
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.space1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: palette.gold,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text('$count من $target', style: theme.textTheme.titleMedium),
          if (count > 0 || complete) ...<Widget>[
            const SizedBox(height: AppTheme.space1),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة العد'),
              onPressed: () => store.reset(entry.id),
            ),
          ] else if (store.hasUserTarget(entry.id)) ...<Widget>[
            const SizedBox(height: AppTheme.space2),
            TextButton(
              onPressed: () => store.clearUserTarget(entry.id),
              child: const Text('إزالة الهدف المحدد'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _promptTarget(BuildContext context, CounterStore store) async {
    final int? result = await showDialog<int>(
      context: context,
      builder: (_) => _TargetDialog(entryId: entry.id, store: store),
    );
    if (result != null && result > 0) {
      store.setUserTarget(entry.id, result);
    }
  }
}

/// Gold progress arc over a muted track, with a faint inner ring.
class _DialPainter extends CustomPainter {
  const _DialPainter({required this.progress, required this.palette});

  final double progress;
  final AppColors palette;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    const double stroke = 12;
    final double radius = (math.min(size.width, size.height) - stroke) / 2 - 2;
    final Rect arc = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius - stroke / 2 - 5,
      Paint()..color = palette.card,
    );
    canvas.drawCircle(
      center,
      radius - stroke / 2 - 5,
      Paint()
        ..color = palette.gold.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = palette.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = palette.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Start-of-round mark at twelve o'clock, inside the ring.
    canvas.drawPath(
      octagramPath(Offset(center.dx, center.dy - radius + stroke + 12), 5),
      Paint()..color = palette.emerald.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.palette != palette;
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({required this.entryId, required this.store});

  final String entryId;
  final CounterStore store;

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final TextEditingController _controller = TextEditingController(text: '3');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('حدد عدد التكرار'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: 'مثال: 3'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final int? value = int.tryParse(_controller.text.trim());
            if (value != null && value > 0) {
              Navigator.of(context).pop(value);
            }
          },
          child: const Text('تحديد'),
        ),
      ],
    );
  }
}
