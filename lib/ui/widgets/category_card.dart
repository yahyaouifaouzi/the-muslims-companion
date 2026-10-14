import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../content/models/content_category.dart';
import 'icon_mapper.dart';
import 'ornaments.dart';

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
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.all(AppTheme.space3),
      child: Row(
        children: <Widget>[
          MedallionIcon(icon: categoryIcon(category.iconKey)),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  category.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (category.subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppTheme.space1),
                  Text(category.subtitle, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          Icon(
            // Forward chevron points the way reading progresses: left in
            // RTL, right in LTR. (Icon's textDirection does not mirror
            // the glyph, so the direction must pick the icon.)
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right,
            color: palette.muted,
          ),
        ],
      ),
    );
  }
}
