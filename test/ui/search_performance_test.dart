import 'package:flutter_test/flutter_test.dart';
import 'package:the_muslims_companion/content/models/content_entry.dart';
import 'package:the_muslims_companion/ui/screens/search_screen.dart';

List<ContentEntry> buildEntries(int count) {
  return List.generate(count, (i) {
    return ContentEntry(
      id: 'e$i',
      categoryId: 'cat',
      title: 'عنوان الدعاء رقم $i',
      text: i % 100 == 0
          ? 'سبحان الله وبحمده $i'
          : 'نص تجريبي طويل نسبياً للبحث المرئي عن الكلمات رقم $i',
      sortOrder: i,
      verified: true,
      placeholder: false,
      tags: ['tag${i % 10}', 'ذكر'],
    );
  });
}

void main() {
  test('search on 5000 entries completes within a generous budget', () {
    final entries = buildEntries(5000);

    final sw = Stopwatch()..start();
    final hits = searchEntries(entries, 'سبحان');
    sw.stop();

    expect(hits, hasLength(50)); // every 100th entry
    // Generous bound (CI machines vary): one keystroke must stay well under
    // a perceptible threshold even with slower devices.
    expect(
      sw.elapsedMilliseconds,
      lessThan(1000),
      reason: 'search over 5000 entries took ${sw.elapsedMilliseconds}ms',
    );
  });

  test('normalization and matching stay correct on a large set', () {
    final entries = buildEntries(5000);
    expect(searchEntries(entries, 'الصَّبْحِ').length, 0); // tashkeel query
    expect(searchEntries(entries, 'splendid').length, 0);
    expect(searchEntries(entries, '   ').length, 0);
    final alef = searchEntries(entries, 'الدعاء'); // bare alef
    expect(alef, isNotEmpty);
  });
}
