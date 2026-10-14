import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../app/theme/app_theme.dart';
import '../../content/models/content_category.dart';
import '../widgets/entry_card.dart';
import '../widgets/ornaments.dart';
import '../widgets/state_views.dart';
import 'reader_screen.dart';

/// Entries of one category, loaded from the current content snapshot.
class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final ContentCategory category;

  static Route<void> route({required ContentCategory category}) =>
      MaterialPageRoute<void>(
        builder: (_) => CategoryDetailScreen(category: category),
      );

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ContentProvider>().catalog;
    final entries = catalog?.entriesByCategory[category.id] ?? const [];

    return Scaffold(
      appBar: OrnamentedAppBar(title: Text(category.title)),
      body: entries.isEmpty
          ? const EmptyView(
              message: 'لا يوجد محتوى في هذا القسم بعد',
              hint: 'سيظهر المحتوى هنا عند توفره',
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
                );
              },
            ),
    );
  }
}
