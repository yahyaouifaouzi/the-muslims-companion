import 'package:flutter/material.dart';

import '../../content/models/content_category.dart';
import 'icon_mapper.dart';

/// Card for one category. Rendered dynamically from JSON data; tapping navigates.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    this.entryCount,
    required this.onTap,
  });

  final ContentCategory category;

  /// Optional count of entries in this category, shown as a supporting line.
  final int? entryCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Row(
            children: [
              Icon(
                categoryIcon(category.iconKey),
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (category.subtitle.isNotEmpty)
                      Text(
                        category.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                textDirection: TextDirection.rtl,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
