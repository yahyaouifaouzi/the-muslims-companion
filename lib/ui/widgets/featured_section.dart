import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../content/models/content_entry.dart';
import 'ornaments.dart';

/// "Featured" strip: equal-width, horizontally swipeable cards with a gold
/// accent, showing a few verified, non-placeholder entries. Renders nothing
/// when there is no such content. Navigation is delegated to the parent via
/// [onEntryTap] — the section stays screen-agnostic.
class FeaturedSection extends StatelessWidget {
  const FeaturedSection({
    super.key,
    required this.entries,
    required this.onEntryTap,
    this.maxItems = 4,
  });

  final List<ContentEntry> entries;
  final ValueChanged<ContentEntry> onEntryTap;
  final int maxItems;

  static const double _cardWidth = 272;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    final Iterable<ContentEntry> featureable = entries.where(_isFeatureable);
    // Curated entries (tagged مختارة) win; without any (e.g. fixtures or a
    // fresh snapshot) fall back to the first featureable ones.
    final Iterable<ContentEntry> curated = featureable.where(
      (entry) => entry.tags.contains('مختارة'),
    );
    final List<ContentEntry> items =
        (curated.isNotEmpty ? curated : featureable).take(maxItems).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'مختارات', icon: Icons.auto_awesome),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.only(
              start: AppTheme.space1,
              end: AppTheme.space4,
            ),
            children: <Widget>[
              for (final ContentEntry entry in items)
                SizedBox(
                  width: _cardWidth,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppTheme.space3,
                    ),
                    child: AppCard(
                      accent: true,
                      onTap: () => onEntryTap(entry),
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsetsDirectional.all(AppTheme.space3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            entry.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space2),
                          Expanded(
                            child: Text(
                              entry.text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space2),
                          if (entry.source != null)
                            Text(
                              entry.source!.reference,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: palette.goldInk,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static bool _isFeatureable(ContentEntry entry) =>
      entry.verified && entry.source != null && !entry.placeholder;
}
