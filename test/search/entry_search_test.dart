import 'package:flutter_test/flutter_test.dart';
import 'package:the_muslims_companion/content/models/content_entry.dart';
import 'package:the_muslims_companion/ui/screens/search_screen.dart';

ContentEntry _entry({
  required String id,
  required String title,
  required String text,
  List<String> tags = const [],
}) => ContentEntry(
  id: id,
  categoryId: 'c',
  title: title,
  text: text,
  tags: tags,
  sortOrder: 0,
  verified: true,
  placeholder: false,
);

void main() {
  group('normalizeArabic', () {
    test('strips tashkeel', () {
      expect(normalizeArabic('سُبْحَانَ اللَّهِ'), 'سبحان الله');
    });

    test('strips tatweel', () {
      expect(normalizeArabic('سبـــحان'), 'سبحان');
    });

    test('unifies common alef variants', () {
      expect(normalizeArabic('أإآٱ'), 'اااا');
    });

    test('leaves already-normalized text unchanged', () {
      expect(normalizeArabic('سبحان الله'), 'سبحان الله');
    });
  });

  group('searchEntries', () {
    final entries = [
      _entry(
        id: '1',
        title: 'أذكار الصباح',
        text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
        tags: ['صباح'],
      ),
      _entry(id: '2', title: 'دعاء قرآني', text: 'ربنا آتنا في الدنيا حسنة'),
    ];

    test('matches title, body, and tags', () {
      expect(searchEntries(entries, 'أذكار'), hasLength(1));
      expect(searchEntries(entries, 'الله'), hasLength(1));
      expect(searchEntries(entries, 'صباح'), hasLength(1)); // tag
      expect(searchEntries(entries, 'حسنة'), hasLength(1)); // body
    });

    test('matches despite tashkeel and alef variants', () {
      // Body has full tashkeel; plain query still matches.
      expect(searchEntries(entries, 'سبحان الله'), hasLength(1));
      // Body uses آ (alef-madda); plain-alef query still matches.
      expect(searchEntries(entries, 'ربنا اتنا'), hasLength(1));
    });

    test('empty or blank query returns no results', () {
      expect(searchEntries(entries, ''), isEmpty);
      expect(searchEntries(entries, '   '), isEmpty);
    });

    test('no match returns empty list', () {
      expect(searchEntries(entries, 'كذب'), isEmpty);
    });
  });
}
