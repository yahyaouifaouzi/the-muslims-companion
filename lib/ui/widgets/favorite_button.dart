import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'ornaments.dart';

/// Heart toggle with a short scale/fill switch animation. Used by the reader
/// action pill and the favorites list, so both behave identically.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.tooltip,
  });

  static const IconData activeIcon = Icons.favorite;
  static const IconData inactiveIcon = Icons.favorite_border;

  final bool isFavorite;
  final VoidCallback onToggle;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final AppColors palette = Theme.of(context).palette;
    return IconButton(
      onPressed: onToggle,
      tooltip:
          tooltip ?? (isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة'),
      color: isFavorite ? palette.goldInk : palette.ink,
      icon: AnimatedSwitcher(
        duration: appMotion(context, 240),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          isFavorite ? activeIcon : inactiveIcon,
          key: ValueKey<bool>(isFavorite),
        ),
      ),
    );
  }
}
