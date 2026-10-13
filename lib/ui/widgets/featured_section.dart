import 'package:flutter/material.dart';

import '../../content/models/content_entry.dart';

/// "Featured" strip showing a few verified, non-placeholder entries.
/// Renders nothing when there is no such content. Navigation is delegated
/// to the parent via [onEntryTap] — the section stays screen-agnostic.
class FeaturedSection extends StatelessWidget {
  const FeaturedSection({
    super.key,
    required this.entries,
    required this.onEntryTap,
    this.maxItems = 2,
  });

  final List<ContentEntry> entries;
  final ValueChanged<ContentEntry> onEntryTap;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = entries.where(_isFeatureable).take(maxItems).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مختارات', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final entry in items)
          Card(
            margin: const EdgeInsetsDirectional.only(bottom: 12),
            child: InkWell(
              onTap: () => onEntryTap(entry),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static bool _isFeatureable(ContentEntry entry) =>
      entry.verified && entry.source != null && !entry.placeholder;
}
