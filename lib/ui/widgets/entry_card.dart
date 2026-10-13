import 'package:flutter/material.dart';

import '../../content/models/content_entry.dart';
import 'state_views.dart' show PlaceholderBadge;

/// Shared entry card used by category, search, and favorites lists. The
/// trailing slot lets the caller add actions (e.g. remove-from-favorites)
/// without forking the layout.
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.trailing,
    this.maxTextLines,
  });

  final ContentEntry entry;
  final VoidCallback onTap;
  final Widget? trailing;
  final int? maxTextLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (entry.placeholder) const PlaceholderBadge(),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.text,
                maxLines: maxTextLines,
                overflow: maxTextLines != null ? TextOverflow.ellipsis : null,
                style: theme.textTheme.bodyLarge,
              ),
              if (entry.source != null) ...[
                const SizedBox(height: 10),
                Text(
                  entry.source!.reference,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
