import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../content/models/content_entry.dart';
import 'ornaments.dart';
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
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(entry.title, style: theme.textTheme.titleMedium),
              ),
              if (entry.placeholder) const PlaceholderBadge(),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppTheme.space1),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            entry.text,
            maxLines: maxTextLines,
            overflow: maxTextLines != null ? TextOverflow.ellipsis : null,
            style: theme.textTheme.bodyLarge,
          ),
          if (entry.source != null) ...<Widget>[
            const SizedBox(height: AppTheme.space3),
            Text(
              entry.source!.reference,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.goldInk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
