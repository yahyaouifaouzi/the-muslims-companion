import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../app/theme/app_theme.dart';
import '../../content/models/content_entry.dart';
import '../widgets/entry_card.dart';
import '../widgets/ornaments.dart';
import '../widgets/state_views.dart';
import 'reader_screen.dart';

/// Lower-effort match form: strips tashkeel (U+064B–U+065F, U+0670) and
/// tatweel, unifies common alef variants to bare alef. Does not mutate the
/// input; stored and displayed text is never rewritten.
String normalizeArabic(String input) {
  return input
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll(RegExp(r'[\u0623\u0625\u0622\u0671]'), 'ا');
}

/// Filters [entries] whose title, body, or tags contain [query] after Arabic
/// normalization. An empty/blank query returns an empty list (the UI shows
/// its prompt state instead).
List<ContentEntry> searchEntries(List<ContentEntry> entries, String query) {
  final normalizedQuery = normalizeArabic(query).trim().toLowerCase();
  if (normalizedQuery.isEmpty) return const <ContentEntry>[];
  return entries.where((entry) {
    bool matches(String value) =>
        normalizeArabic(value).toLowerCase().contains(normalizedQuery);
    return matches(entry.title) ||
        matches(entry.text) ||
        entry.tags.any(matches);
  }).toList();
}

/// Full-content in-memory search over the current snapshot. No network, no
/// per-keystroke requests.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const SearchScreen());

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<ContentProvider>().catalog;
    // ponytail: recompute-per-keystroke over allEntries (~25ms @5k entries);
    // memoize normalized haystacks when content grows past ~20k or search lags.
    final entries = searchEntries(catalog?.allEntries ?? const [], _query);
    final Color barForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;

    final Widget body;
    if (catalog == null) {
      body = const EmptyView(message: 'المحتوى غير جاهز للبحث');
    } else if (_query.trim().isEmpty) {
      body = const EmptyView(
        message: 'ابحث في كل المحتوى',
        hint: 'اكتب كلمة من العنوان أو النص أو الوسوم',
        icon: Icons.search,
      );
    } else if (entries.isEmpty) {
      body = const EmptyView(
        message: 'لا توجد نتائج',
        hint: 'جرّب كلمات أخرى أو تحقق من الإملاء',
        icon: Icons.search_off,
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsetsDirectional.all(AppTheme.space4),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return EntryCard(
            entry: entry,
            onTap: () =>
                Navigator.of(context).push(ReaderScreen.route(entry: entry)),
          );
        },
      );
    }

    return Scaffold(
      appBar: OrnamentedAppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: barForeground, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'ابحث في المحتوى',
            hintStyle: TextStyle(
              color: barForeground.withValues(alpha: 0.7),
              fontSize: 18,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: <Widget>[
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'مسح البحث',
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: body,
    );
  }
}
