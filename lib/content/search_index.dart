import 'dart:math' as math;

import 'models/content_entry.dart';

/// Lower-effort match form of [input]: strips tashkeel (U+064B–U+065F,
/// U+0670) and tatweel, drops Quranic annotation marks (U+06D6–U+06DC,
/// U+06DF–U+06E8, U+06EA–U+06ED), unifies alef/hamza-carrier and
/// ta-marbuta/ya variants, maps Arabic-Indic and Persian digits to ASCII,
/// and collapses whitespace to single spaces. Used only for matching —
/// stored and displayed text is never rewritten.
String normalizeArabic(String input) => normalizeArabicIndexed(input).text;

/// [normalizeArabic] plus a per-character map back to the original string,
/// so match ranges can be highlighted without altering the text.
class NormalizedText {
  const NormalizedText(this.text, this.sourceIndices, this.original);

  /// The unmodified input; kept so highlight ranges can cover trailing
  /// combining marks of the last matched letter.
  final String original;

  /// Normalized form; `sourceIndices[i]` is the original index of
  /// `text[i]` (whitespace collapse maps a single space to the first
  /// whitespace char of the run).
  final String text;
  final List<int> sourceIndices;
}

/// Normalizes [input] for Arabic search while recording source indices.
NormalizedText normalizeArabicIndexed(String input) {
  final StringBuffer buffer = StringBuffer();
  final List<int> indices = <int>[];
  bool pendingSpace = false;
  bool started = false;
  for (int i = 0; i < input.length; i++) {
    final String ch = input[i];
    final int unit = ch.codeUnitAt(0);
    if (_isStripped(unit)) continue;
    if (ch.trim().isEmpty) {
      if (started) pendingSpace = true;
      continue;
    }
    if (pendingSpace) {
      buffer.write(' ');
      indices.add(i);
      pendingSpace = false;
    }
    final String mapped = _mapChar(ch);
    for (final String m in mapped.toLowerCase().split('')) {
      buffer.write(m);
      indices.add(i);
    }
    started = true;
  }
  return NormalizedText(buffer.toString(), indices, input);
}

bool _isStripped(int unit) =>
    (unit >= 0x064B && unit <= 0x065F) ||
    unit == 0x0670 || // dagger alef
    unit == 0x0640 || // tatweel
    (unit >= 0x06D6 && unit <= 0x06DC) ||
    (unit >= 0x06DF && unit <= 0x06E8) ||
    (unit >= 0x06EA && unit <= 0x06ED);

String _mapChar(String ch) {
  switch (ch) {
    case '\u0623': // أ
    case '\u0625': // إ
    case '\u0622': // آ
    case '\u0671': // ٱ
      return 'ا';
    case '\u0649': // ى
      return 'ي';
    case '\u0629': // ة
      return 'ه';
    case '\u0624': // ؤ
      return 'و';
    case '\u0626': // ئ
      return 'ي';
  }
  final int unit = ch.codeUnitAt(0);
  if (unit >= 0x0660 && unit <= 0x0669) {
    return String.fromCharCode(0x30 + (unit - 0x0660)); // ٠-٩
  }
  if (unit >= 0x06F0 && unit <= 0x06F9) {
    return String.fromCharCode(0x30 + (unit - 0x06F0)); // ۰-۹
  }
  return ch;
}

/// One search result: the entry plus character ranges (indices into the
/// original, unmodified title/text) to highlight.
class SearchHit {
  const SearchHit({
    required this.entry,
    required this.titleRanges,
    required this.textRanges,
  });

  final ContentEntry entry;
  final List<(int, int)> titleRanges;
  final List<(int, int)> textRanges;
}

class _Row {
  _Row(ContentEntry entry, String categoryName)
    : entry = entry,
      title = normalizeArabicIndexed(entry.title),
      text = normalizeArabicIndexed(entry.text),
      source = normalizeArabicIndexed(entry.source?.reference ?? ''),
      category = normalizeArabicIndexed(categoryName),
      tags = [for (final String tag in entry.tags) normalizeArabicIndexed(tag)];

  final ContentEntry entry;
  final NormalizedText title;
  final NormalizedText text;
  final NormalizedText source;
  final NormalizedText category;
  final List<NormalizedText> tags;

  bool _contains(String word) =>
      title.text.contains(word) ||
      text.text.contains(word) ||
      source.text.contains(word) ||
      category.text.contains(word) ||
      tags.any((NormalizedText tag) => tag.text.contains(word));

  /// Lower is better; null = no match. Ranking: exact title, title prefix,
  /// title contains, every word in the text, then source/category/tag.
  int? score(List<String> words, String fullQuery) {
    for (final String word in words) {
      if (!_contains(word)) return null;
    }
    if (title.text == fullQuery) return 0;
    if (title.text.startsWith(fullQuery)) return 1;
    if (title.text.contains(fullQuery)) return 2;
    if (words.every(text.text.contains)) return 3;
    return 4;
  }

  SearchHit hit(List<String> words) => SearchHit(
    entry: entry,
    titleRanges: _highlight(title, words),
    textRanges: _highlight(text, words),
  );
}

List<(int, int)> _highlight(NormalizedText haystack, List<String> words) {
  final List<(int, int)> raw = <(int, int)>[];
  for (final String word in words) {
    int from = 0;
    while (from <= haystack.text.length - word.length) {
      final int i = haystack.text.indexOf(word, from);
      if (i < 0) break;
      final int start = haystack.sourceIndices[i];
      int end = haystack.sourceIndices[i + word.length - 1] + 1;
      // Cover combining marks (tashkeel, annotations) that trail the last
      // matched letter so the painted range matches the visible word.
      while (end < haystack.original.length &&
          _isStripped(haystack.original.codeUnitAt(end))) {
        end++;
      }
      raw.add((start, end));
      from = i + word.length;
    }
  }
  if (raw.isEmpty) return const <(int, int)>[];
  raw.sort(((int, int) a, (int, int) b) => a.$1.compareTo(b.$1));
  final List<(int, int)> merged = <(int, int)>[raw.first];
  for (final (int, int) range in raw.skip(1)) {
    final (int, int) last = merged.last;
    if (range.$1 <= last.$2) {
      merged[merged.length - 1] = (last.$1, math.max(last.$2, range.$2));
    } else {
      merged.add(range);
    }
  }
  return merged;
}

/// Precomputed in-memory index over the loaded catalog. Normalization runs
/// once per entry at load; per-keystroke search only scans normalized
/// strings, so it stays cheap as long as the catalog stays human-scale.
class SearchIndex {
  SearchIndex(
    List<ContentEntry> entries, {
    Map<String, String> categoryNames = const <String, String>{},
  }) : _rows = [
         for (final ContentEntry entry in entries)
           _Row(entry, categoryNames[entry.categoryId] ?? ''),
       ];

  final List<_Row> _rows;

  /// Ranks [entries] matching [query]. Every query word must appear in at
  /// least one field (title, text, source, category name, or tags), in any
  /// order. An empty/blank query returns no results.
  List<SearchHit> search(String query) {
    final NormalizedText normalizedQuery = normalizeArabicIndexed(query);
    final List<String> words = normalizedQuery.text
        .split(' ')
        .where((String word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return const <SearchHit>[];
    final List<({_Row row, int score})> hits = <({_Row row, int score})>[];
    for (final _Row row in _rows) {
      final int? score = row.score(words, normalizedQuery.text);
      if (score != null) hits.add((row: row, score: score));
    }
    hits.sort((a, b) {
      final int byScore = a.score.compareTo(b.score);
      if (byScore != 0) return byScore;
      final int byOrder = a.row.entry.sortOrder.compareTo(
        b.row.entry.sortOrder,
      );
      return byOrder != 0
          ? byOrder
          : a.row.entry.title.compareTo(b.row.entry.title);
    });
    return <SearchHit>[for (final h in hits) h.row.hit(words)];
  }
}

/// Filters [entries] whose title, body, source, or tags contain [query]
/// after Arabic normalization. Kept as a thin wrapper over [SearchIndex]
/// for tests and one-off use; the UI uses a prebuilt index instead.
List<ContentEntry> searchEntries(List<ContentEntry> entries, String query) =>
    SearchIndex(entries)
        .search(query)
        .map((SearchHit hit) => hit.entry)
        .toList();
