import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../app/notification_service.dart';
import '../../app/reminder_store.dart';
import '../../content/models/content_category.dart';
import '../widgets/app_bottom_nav.dart';
import 'category_detail_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Shell for the three root screens (home, favorites, settings) driven by a
/// bottom NavigationBar; [IndexedStack] keeps state across tab switches.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.notificationService});

  final NotificationService notificationService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    widget.notificationService.onOpenAdhkar = _onReminderTapped;
    // Cold start from a tapped notification: open the matching adhkar once
    // the catalog is ready.
    final pending = NotificationService.pendingSlot;
    if (pending != null) {
      NotificationService.pendingSlot = null;
      _openCategoryWhenReady(pending.categoryId);
    }
    // Re-arm enabled reminders so a timezone change (or a cleared plugin
    // schedule DB) never leaves a stored opt-in silently dead.
    widget.notificationService.rescheduleEnabled(context.read<ReminderStore>());
  }

  @override
  void dispose() {
    widget.notificationService.onOpenAdhkar = null;
    super.dispose();
  }

  void _onReminderTapped(ReminderSlot slot) =>
      _openCategoryWhenReady(slot.categoryId);

  void _openCategoryWhenReady(String categoryId) {
    final provider = context.read<ContentProvider>();
    if (provider.catalog != null) {
      _pushCategory(categoryId);
      return;
    }
    void retry() {
      if (!mounted) return;
      if (context.read<ContentProvider>().catalog == null) return;
      context.read<ContentProvider>().removeListener(retry);
      _pushCategory(categoryId);
    }

    provider.addListener(retry);
  }

  void _pushCategory(String categoryId) {
    final catalog = context.read<ContentProvider>().catalog;
    if (catalog == null || !mounted) return;
    ContentCategory? match;
    for (final category in catalog.categories) {
      if (category.id == categoryId && category.enabled) {
        match = category;
        break;
      }
    }
    final category = match;
    if (category == null) return;
    Navigator.of(context).push(CategoryDetailScreen.route(category: category));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          const FavoritesScreen(),
          SettingsScreen(notificationService: widget.notificationService),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onSelect: (newIndex) => setState(() => _index = newIndex),
      ),
    );
  }
}
