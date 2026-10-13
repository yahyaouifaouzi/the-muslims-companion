import 'package:flutter/material.dart';

import '../widgets/state_views.dart';

/// Favorites placeholder. Persistent favorites arrive in a later milestone;
/// the screen already shows the same empty-state pattern that will be used.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: ListView(
        children: const [
          SizedBox(height: 48),
          EmptyView(
            message: 'لا توجد مفضلات بعد',
            hint: 'أضف ما يعجبك من المحتوى لإيجاده هنا لاحقاً',
          ),
        ],
      ),
    );
  }
}
