import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Shell for the three root screens (home, favorites, settings) driven by a
/// bottom NavigationBar; [IndexedStack] keeps state across tab switches.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), FavoritesScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onSelect: (newIndex) => setState(() => _index = newIndex),
      ),
    );
  }
}
