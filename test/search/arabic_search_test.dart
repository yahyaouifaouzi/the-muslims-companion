import 'package:flutter_test/flutter_test.dart';
import 'package:the_muslims_companion/content/models/content_entry.dart';
import 'package:the_muslims_companion/content/models/content_source.dart';
import 'package:the_muslims_companion/content/search_index.dart';

ContentEntry _entry({
  required String id,
  required String title,
  required String text,
  String source = '',
  String categoryId = 'c',
  int sortOrder = 0,
  List<String> tags = const [],
}) => ContentEntry(
  id: id,
  categoryId: categoryId,
  title: title,
  text: text,
  source: source.isEmpty
      ? null
      : ContentSource(reference: source, kind: null, authenticity: null),
  tags: tags,
  sortOrder: sortOrder,
  verified: true,
  placeholder: false,
);

void main() {
  final entries = <ContentEntry>[
    _entry(
      id: 'morning',
      title: 'أذكار الصباح',
      text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      categoryId: 'adhkar-morning',
      sortOrder: 1,
    ),
    _entry(
      id: 'tahlil',
      title: 'التوحيد',
      text: 'لا إله إلا الله',
      source: 'رواه مسلم ٢٦',
      categoryId: 'general',
      sortOrder: 2,
    ),
    _entry(
      id: 'ayah',
      title: 'دعاء قرآني',
      text: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
      categoryId: 'quran',
      sortOrder: 3,
    ),
  ];
  final index = SearchIndex(
    entries,
    categoryNames: const {
      'adhkar-morning': 'أذكار الصباح',
      'general': 'أدعية عامة',
      'quran': 'أدعية قرآنية',
    },
  );

  group('normalization', () {
    test('Arabic-Indic and Persian digits unify to ASCII', () {
      expect(normalizeArabic('١٢٣٤٥'), '12345');
      expect(normalizeArabic('۰۹'), '09');
      // Mixed-width source numerals match an ASCII query.
      expect(searchEntries(entries, 'مسلم 26'), hasLength(1));
    });

    test('ta-marbuta matches heh', () {
      expect(searchEntries(entries, 'الرحمن'), isEmpty); // not present
      expect(normalizeArabic('رحمة'), 'رحمه');
      expect(searchEntries(entries, 'رحمه'), isEmpty); // body has رَحْمَة
      expect(searchEntries(entries, 'حسنه'), hasLength(1));
    });

    test('alef maqsura matches ya', () {
      expect(normalizeArabic('هدى'), 'هدي');
      expect(searchEntries(entries, 'لا الهي'), hasLength(0)); // sanity
      expect(searchEntries(entries, 'عليا'), isEmpty); // not present
    });

    test('hamza carriers unify', () {
      expect(normalizeArabic('مؤمن'), 'مومن');
      expect(normalizeArabic('ئيد'), 'ييد');
    });

    test('Quranic annotation marks are stripped', () {
      // U+06D6 (ruqaa sign) and U+06E5 (small waw) are tanzil annotation
      // marks; digits still unify and ta-marbuta still maps to heh.
      expect(normalizeArabic('سورة ۖ١ۥ'), 'سوره 1');
      expect(normalizeArabic('اللهُ').contains('الله'), isTrue);
    });

    test('displayed text is never rewritten', () {
      final hit = index.search('ربنا اتنا').first;
      expect(hit.entry.text, 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً');
    });
  });

  group('multi-word AND in any order', () {
    test('words may span different fields and any order', () {
      expect(index.search('الصباح سُبْحَانَ'), hasLength(1));
      expect(index.search('سبحان الصباح').first.entry.id, 'morning');
      expect(index.search('الله مسلم'), hasLength(1)); // text + source
      expect(index.search('الصباح مسلم'), isEmpty);
    });
  });

  group('fields', () {
    test('matches source and category name', () {
      expect(index.search('رواه مسلم').first.entry.id, 'tahlil');
      expect(index.search('قرآنية').first.entry.id, 'ayah'); // category
    });
  });

  group('ranking', () {
    final ranked = <ContentEntry>[
      _entry(id: 'a', title: 'الاستيقاظ', text: 'من دعاء النبي', sortOrder: 1),
      _entry(id: 'b', title: 'دعاء جامع', text: 'نص', sortOrder: 2),
      _entry(id: 'c', title: 'ذكر آخر', text: 'دعاء الكرب', sortOrder: 3),
      _entry(id: 'd', title: 'باب آخر', text: 'نص', sortOrder: 4),
    ];

    test('title prefix beats title contains beats text', () {
      final ids = SearchIndex(ranked)
          .search('دعاء')
          .map((hit) => hit.entry.id)
          .toList();
      expect(ids, <String>['b', 'a', 'c']); // d does not match
    });

    test('exact title ranks first', () {
      final ids = SearchIndex(<ContentEntry>[
        _entry(id: 'x', title: 'دعاء الكرب', text: 't', sortOrder: 1),
        _entry(
          id: 'y',
          title: 'أدعية',
          text: 'دعاء الكرب مرة أخرى',
          sortOrder: 2,
        ),
      ]).search('دعاء الكرب').map((hit) => hit.entry.id).toList();
      expect(ids, <String>['x', 'y']);
    });
  });

  group('highlight ranges', () {
    test('ranges index the original voweled text without altering it', () {
      final hit = index.search('سُبْحَانَ').first;
      expect(hit.entry.text, 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ');
      expect(hit.textRanges, isNotEmpty);
      final (int start, int end) = hit.textRanges.first;
      expect(hit.entry.text.substring(start, end), 'سُبْحَانَ');
    });

    test('query without tashkeel highlights the voweled original', () {
      final hit = index.search('سبحان').first;
      final (int start, int end) = hit.textRanges.first;
      expect(hit.entry.text.substring(start, end), 'سُبْحَانَ');
    });

    test('title match produces title ranges', () {
      final hit = index.search('الصباح').first;
      final (int start, int end) = hit.titleRanges.first;
      expect(hit.entry.title.substring(start, end), 'الصباح');
    });
  });

  group('empty and no-result states', () {
    test('blank query returns nothing', () {
      expect(index.search(''), isEmpty);
      expect(index.search('   '), isEmpty);
    });

    test('unknown word returns nothing', () {
      expect(index.search('كذب'), isEmpty);
    });
  });
}
