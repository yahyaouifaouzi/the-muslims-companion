import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'ornaments.dart';

/// Shared non-content states so every screen renders failures and empties
/// the same calm way.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppTheme.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MedallionIcon(icon: Icons.error_outline, size: 72),
            const SizedBox(height: AppTheme.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: AppTheme.space4),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.hint,
    this.icon = Icons.inbox_outlined,
  });

  final String message;

  /// Optional Arabic supporting line shown under the message.
  final String? hint;

  /// Medallion illustration; callers pass an icon that fits their context.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppTheme.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MedallionIcon(icon: icon, size: 88),
            const SizedBox(height: AppTheme.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (hint != null) ...<Widget>[
              const SizedBox(height: AppTheme.space1),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppTheme.space3),
            SizedBox(
              width: 140,
              child: OrnamentDivider(starSize: 12, vertical: 0),
            ),
          ],
        ),
      ),
    );
  }
}

/// "غير موثّق" chip marking placeholder/unverified content, so every screen
/// labels it the same way.
class PlaceholderBadge extends StatelessWidget {
  const PlaceholderBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTheme.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: palette.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.gold.withValues(alpha: 0.55)),
      ),
      child: Text(
        'غير موثّق',
        style: theme.textTheme.labelSmall?.copyWith(color: palette.goldInk),
      ),
    );
  }
}
