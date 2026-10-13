import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/counter_store.dart';
import '../../content/models/content_entry.dart';

/// Repetition counter for one entry.
///
/// Visible when the content supplies a validated `repeatCount` **or** the
/// user has set their own target. No count is ever invented: when neither
/// exists, the widget offers an explicit "set target" action instead.
///
/// Semantics:
/// - Tap the big circle to increment (capped at the target).
/// - At the target the circle turns solid green with a checkmark; further
///   taps are ignored until reset.
/// - Reset returns the count to 0 (only shown once counting has started).
/// - A user-defined target overrides `entry.repeatCount` for that entry.
class CounterSection extends StatelessWidget {
  const CounterSection({super.key, required this.entry});

  final ContentEntry entry;

  /// Minimum side of the increment button — well above the 48dp accessibility
  /// floor so it is comfortable for one-handed thumb use.
  static const double tapTargetSize = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<CounterStore>();
    final target = store.userTargetFor(entry.id) ?? entry.repeatCount;

    if (target == null) {
      return Center(
        child: TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('حدد عدد التكرار'),
          onPressed: () => _promptTarget(context, store),
        ),
      );
    }

    final count = store.countFor(entry.id);
    final complete = count >= target;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('التكرار', style: theme.textTheme.labelLarge),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            enabled: !complete,
            label: complete ? 'اكتمل العد' : 'اضغط للعد',
            child: InkWell(
              key: const ValueKey('counter-tap-target'),
              customBorder: const CircleBorder(),
              onTap: complete
                  ? null
                  : () => store.increment(entry.id, target: target),
              child: Container(
                width: tapTargetSize,
                height: tapTargetSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: complete
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer,
                ),
                child: Center(
                  child: complete
                      ? Icon(
                          Icons.check,
                          size: 48,
                          color: theme.colorScheme.onPrimary,
                        )
                      : Text(
                          '$count',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('$count من $target', style: theme.textTheme.titleMedium),
          if (count > 0 || complete) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة العد'),
              onPressed: () => store.reset(entry.id),
            ),
          ] else if (store.hasUserTarget(entry.id)) ...[
            const SizedBox(height: 8),
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
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _TargetDialog(entryId: entry.id, store: store),
    );
    if (result != null && result > 0) {
      store.setUserTarget(entry.id, result);
    }
  }
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({required this.entryId, required this.store});

  final String entryId;
  final CounterStore store;

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final _controller = TextEditingController(text: '3');

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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text.trim());
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
