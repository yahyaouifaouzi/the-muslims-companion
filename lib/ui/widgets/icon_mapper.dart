import 'package:flutter/material.dart';

/// Maps known, safe category `iconKey` values to icons. Unknown keys get a
/// neutral fallback; nothing here derives icons from untrusted data beyond
/// this closed set.
IconData categoryIcon(String iconKey) {
  switch (iconKey) {
    case 'sunrise':
      return Icons.wb_sunny_outlined;
    case 'moon':
      return Icons.nightlight_outlined;
    case 'quran':
      return Icons.menu_book_outlined;
    case 'hands':
      return Icons.volunteer_activism_outlined;
    case 'book':
      return Icons.book_outlined;
    default:
      return Icons.category_outlined;
  }
}
