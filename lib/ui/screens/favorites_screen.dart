import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../app/favorites_store.dart';
import '../../app/theme/app_theme.dart';
import '../../content/models/content_entry.dart';
import '../widgets/entry_card.dart';
import '../widgets/favorite_button.dart';
import '../widgets/ornaments.dart';
import '../widgets/state_views.dart';
import 'reader_screen.dart';

/// Persistent favorites: resolves stored IDs against the current content
/// snapshot. Stale IDs (entries removed by a content update) are skipped, so
/// the screen never crashes on outdated references.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesStore>();
    final catalog = context.watch<ContentProvider>().catalog;
    final entryById = {
      for (final entry in catalog?.allEntries ?? const <ContentEntry>[])
        entry.id: entry,
    };
    final entries = [for (final id in favorites.ids) ?entryById[id]];

    return Scaffold(
      appBar: const OrnamentedAppBar(title: Text('المفضلة')),
      body: entries.isEmpty
          ? const EmptyView(
              message: 'لا توجد مفضلات بعد',
              hint: 'أضف ما يعجبك من المحتوى لإيجاده هنا لاحقاً',
              icon: Icons.favorite_border,
            )
          : ListView.builder(
              padding: const EdgeInsetsDirectional.all(AppTheme.space4),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return EntryCard(
                  entry: entry,
                  onTap: () =>
                      Navigator.of(context)
                          .push(ReaderScreen.route(entry: entry)),
                  trailing: FavoriteButton(
                    isFavorite: true,
                    onToggle: () => favorites.toggle(entry.id),
                  ),
                );
              },
            ),
    );
  }
}
