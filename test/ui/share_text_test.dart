import 'package:flutter_test/flutter_test.dart';
import 'package:the_muslims_companion/content/models/content_entry.dart';
import 'package:the_muslims_companion/content/models/content_source.dart';
import 'package:the_muslims_companion/ui/screens/reader_screen.dart';

void main() {
  final entry = ContentEntry(
    id: 'e1',
    categoryId: 'c',
    title: 'دعاء',
    text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
    source: const ContentSource(reference: 'سورة البقرة، آية 201'),
    sortOrder: 0,
    verified: true,
    placeholder: false,
  );

  test('share text is title, verbatim body, source, attribution', () {
    expect(
      buildShareText(entry),
      'دعاء\n'
      'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً\n'
      'سورة البقرة، آية 201\n'
      '— رفيق المسلم',
    );
  });

  test('no source means no attribution line beyond the app name', () {
    final bare = ContentEntry(
      id: 'e2',
      categoryId: 'c',
      title: 'ذكر',
      text: 'لا إله إلا الله',
      sortOrder: 0,
      verified: true,
      placeholder: false,
    );
    expect(buildShareText(bare), 'ذكر\nلا إله إلا الله\n— رفيق المسلم');
  });
}
