import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../content/local_content_repository.dart' show ContentCatalog;
import '../widgets/category_card.dart';
import '../widgets/featured_section.dart';
import '../widgets/state_views.dart';
import 'categories_screen.dart';
import 'category_detail_screen.dart';
import 'reader_screen.dart';
import 'search_screen.dart';

/// Home: app title, greeting, search entry point, featured content (only if
/// valid content exists), and category cards rendered from the loaded catalog.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final catalog = provider.catalog;

    final Widget body;
    if (provider.loading) {
      body = const LoadingView();
    } else if (provider.errorMessage != null) {
      body = ErrorView(
        message: 'تعذّر تحميل المحتوى',
        onRetry: () => provider.load(),
      );
    } else if (catalog == null) {
      body = const EmptyView(message: 'لا يوجد محتوى');
    } else {
      body = _HomeBody(catalog: catalog);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('رفيق المسلم')),
      body: body,
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.catalog});

  final ContentCatalog catalog;

  static String _greeting() {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'صباح الخير' : 'مساء الخير';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledCategories = catalog.categories
        .where((category) => category.enabled)
        .toList();

    return ListView(
      padding: const EdgeInsetsDirectional.all(16),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(_greeting(), style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 16),
        const _SearchEntryPoint(),
        const SizedBox(height: 24),
        FeaturedSection(
          entries: catalog.allEntries,
          maxItems: 8,
          onEntryTap: (entry) =>
              Navigator.of(context).push(ReaderScreen.route(entry: entry)),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text('التصنيفات', style: theme.textTheme.titleLarge),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).push(CategoriesScreen.route()),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        if (enabledCategories.isEmpty)
          const EmptyView(
            message: 'لا توجد تصنيفات متاحة',
            hint: 'سيظهر المحتوى هنا عند توفره',
          )
        else
          for (final category in enabledCategories)
            CategoryCard(
              category: category,
              onTap: () =>
                  Navigator.of(context)
                      .push(CategoryDetailScreen.route(category: category)),
            ),
      ],
    );
  }
}

/// Search entry point: opens the full in-memory search screen.
class _SearchEntryPoint extends StatelessWidget {
  const _SearchEntryPoint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(SearchScreen.route()),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(14),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(
                'ابحث في المحتوى',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
