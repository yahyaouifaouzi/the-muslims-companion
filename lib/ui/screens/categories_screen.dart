import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../app/theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/ornaments.dart';
import '../widgets/state_views.dart';
import 'category_detail_screen.dart';

/// All enabled categories, in the same card style as the home list.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const CategoriesScreen());

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final catalog = provider.catalog;
    final categories = catalog?.categories
        .where((category) => category.enabled)
        .toList();

    final Widget body;
    if (categories == null) {
      body = const LoadingView();
    } else if (categories.isEmpty) {
      body = const EmptyView(
        message: 'لا توجد تصنيفات متاحة',
        hint: 'سيظهر المحتوى هنا عند توفره',
      );
    } else {
      body = ListView(
        padding: const EdgeInsetsDirectional.all(AppTheme.space4),
        children: <Widget>[
          const SectionHeader(
            title: 'كل التصنيفات',
            icon: Icons.grid_view_outlined,
          ),
          for (final category in categories)
            CategoryCard(
              category: category,
              onTap: () =>
                  Navigator.of(context)
                      .push(CategoryDetailScreen.route(category: category)),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: const OrnamentedAppBar(title: Text('التصنيفات')),
      body: body,
    );
  }
}
