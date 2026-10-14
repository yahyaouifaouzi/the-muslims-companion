import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../app/hijri_date.dart';
import '../../app/theme/app_theme.dart';
import '../../content/local_content_repository.dart' show ContentCatalog;
import '../widgets/category_card.dart';
import '../widgets/featured_section.dart';
import '../widgets/ornaments.dart';
import '../widgets/state_views.dart';
import 'categories_screen.dart';
import 'category_detail_screen.dart';
import 'reader_screen.dart';
import 'search_screen.dart';

/// Home: greeting header with the Hijri date, search entry point, featured
/// content (only if valid content exists), and category cards rendered from
/// the loaded catalog.
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
      appBar: const OrnamentedAppBar(title: Text('رفيق المسلم')),
      body: body,
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.catalog});

  final ContentCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final enabledCategories = catalog.categories
        .where((category) => category.enabled)
        .toList();

    return ListView(
      padding: const EdgeInsetsDirectional.all(AppTheme.space3),
      children: <Widget>[
        const _GreetingHeader(),
        const SizedBox(height: AppTheme.space3),
        const _SearchEntryPoint(),
        const SizedBox(height: AppTheme.space3),
        FeaturedSection(
          entries: catalog.allEntries,
          onEntryTap: (entry) =>
              Navigator.of(context).push(ReaderScreen.route(entry: entry)),
        ),
        const SizedBox(height: AppTheme.space3),
        SectionHeader(
          title: 'التصنيفات',
          icon: Icons.grid_view_outlined,
          trailing: TextButton(
            onPressed: () =>
                Navigator.of(context).push(CategoriesScreen.route()),
            child: const Text('عرض الكل'),
          ),
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
        const SizedBox(height: AppTheme.space4),
      ],
    );
  }
}

/// Emerald greeting panel with the Hijri date and a faint girih lattice.
class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  static String _greeting() {
    final hour = DateTime.now().hour;
    return hour < 12 ? 'صباح الخير' : 'مساء الخير';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    final String hijri = HijriDate.fromDateTime(DateTime.now()).label;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[palette.emerald, palette.emeraldDeep],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMushaf),
        border: Border.all(color: palette.gold.withValues(alpha: 0.55)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.emerald.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMushaf - 1),
        child: CustomPaint(
          painter: GirihPatternPainter(color: palette.gold, opacity: 0.14),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppTheme.space4,
              AppTheme.space3,
              AppTheme.space4,
              AppTheme.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _greeting(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Text(
                      hijri,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Search entry point: opens the full in-memory search screen.
class _SearchEntryPoint extends StatelessWidget {
  const _SearchEntryPoint();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      onTap: () => Navigator.of(context).push(SearchScreen.route()),
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.search, color: theme.palette.goldInk),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              'ابحث في المحتوى',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.palette.muted,
              ),
            ),
          ),
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right,
            color: theme.palette.muted,
          ),
        ],
      ),
    );
  }
}
