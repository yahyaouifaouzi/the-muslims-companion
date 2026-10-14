/// Tabular (Kuwaiti) Hijri date — the same arithmetic approximation used by
/// Windows and most Islamic date APIs, shown in the home header.
///
/// It tracks the tabular calendar, so it can differ from moon-sighting
/// announcements by a day; it is a display aid, not a ruling.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  /// Arabic month names, in order.
  static const List<String> monthNames = <String>[
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  /// Converts a Gregorian date to its Hijri equivalent.
  factory HijriDate.fromDateTime(DateTime date) {
    const double iyear = 10631 / 30;
    const int epoch = 1948084;
    const double shift1 = 8.01 / 60;
    double z = (_julianDay(date) - epoch).toDouble();
    final int cycle = (z / 10631).floor();
    z -= 10631 * cycle;
    final int yearStep = ((z - shift1) / iyear).floor();
    final int hijriYear = 30 * cycle + yearStep;
    z -= (yearStep * iyear + shift1).floorToDouble();
    int hijriMonth = ((z + 28.5001) / 29.5).floor();
    if (hijriMonth > 12) hijriMonth = 12;
    final int hijriDay = (z - (29.5001 * hijriMonth - 29).floor()).round();
    return HijriDate(hijriYear, hijriMonth, hijriDay);
  }

  /// Julian day number for a Gregorian date (proleptic after 1583).
  static int _julianDay(DateTime date) {
    final int century = date.year ~/ 100;
    final int correction = 2 - century + century ~/ 4;
    return (365.25 * (date.year + 4716)).floor() +
        (30.6001 * (date.month + 1)).floor() +
        date.day +
        correction -
        1524;
  }

  /// "٣ ربيع الأول ١٤٤٨ هـ" with Latin digits, matching the rest of the UI.
  String get label => '$day ${monthNames[month - 1]} $year هـ';
}
