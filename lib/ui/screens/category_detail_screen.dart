import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../content/models/content_category.dart';
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
      appBar: AppBar(title: Text(category.title)),
      body: entries.isEmpty
          ? const EmptyView(
              message: 'لا يوجد محتوى في هذا القسم بعد',
              hint: 'سيظهر المحتوى هنا عند توفره',
            )
          : ListView.builder(
              padding: const EdgeInsetsDirectional.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final theme = Theme.of(context);
                return Card(
                  margin: const EdgeInsetsDirectional.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () =>
                        Navigator.of(context)
                            .push(ReaderScreen.route(entry: entry)),
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(entry.text, style: theme.textTheme.bodyLarge),
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
              },
            ),
    );
  }
}
