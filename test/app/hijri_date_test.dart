import 'package:flutter_test/flutter_test.dart';
import 'package:the_muslims_companion/app/hijri_date.dart';

void main() {
  test('anchors the tabular calendar to known Hijri new years', () {
    final List<(DateTime, List<int>)> anchors = <(DateTime, List<int>)>[
      (DateTime(2024, 7, 7), <int>[1446, 1, 1]),
      (DateTime(2025, 6, 26), <int>[1447, 1, 1]),
      (DateTime(2026, 6, 16), <int>[1448, 1, 1]),
    ];
    for (final (DateTime date, List<int> expected) in anchors) {
      final HijriDate hijri = HijriDate.fromDateTime(date);
      expect(
        <int>[hijri.year, hijri.month, hijri.day],
        expected,
        reason: 'conversion for $date',
      );
    }
  });

  test('label keeps the Arabic month name and the هـ suffix', () {
    expect(const HijriDate(1448, 3, 3).label, '3 ربيع الأول 1448 هـ');
    expect(HijriDate.monthNames.length, 12);
  });
}
