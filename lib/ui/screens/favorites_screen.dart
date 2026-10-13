import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../app/favorites_store.dart';
import '../../content/models/content_entry.dart';
import '../widgets/entry_card.dart';
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
      appBar: AppBar(title: const Text('المفضلة')),
      body: entries.isEmpty
          ? const EmptyView(
              message: 'لا توجد مفضلات بعد',
              hint: 'أضف ما يعجبك من المحتوى لإيجاده هنا لاحقاً',
            )
          : ListView.builder(
              padding: const EdgeInsetsDirectional.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return EntryCard(
                  entry: entry,
                  onTap: () =>
                      Navigator.of(context)
                          .push(ReaderScreen.route(entry: entry)),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite),
                    tooltip: 'إزالة من المفضلة',
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () => favorites.toggle(entry.id),
                  ),
                );
              },
            ),
    );
  }
}
