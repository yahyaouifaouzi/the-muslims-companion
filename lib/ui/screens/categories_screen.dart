import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/state_views.dart';
import 'category_detail_screen.dart';

/// All enabled categories, rendered from the loaded catalog.
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
      body = const EmptyView(message: 'لا توجد تصنيفات متاحة');
    } else {
      body = ListView.builder(
        padding: const EdgeInsetsDirectional.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) => CategoryCard(
          category: categories[index],
          onTap: () => Navigator.of(context)
              .push(CategoryDetailScreen.route(category: categories[index])),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      body: body,
    );
  }
}
