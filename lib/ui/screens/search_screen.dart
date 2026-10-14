import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/content_provider.dart';
import '../../app/theme/app_theme.dart';
import '../../content/search_index.dart';
import '../widgets/entry_card.dart';
import '../widgets/ornaments.dart';
import '../widgets/state_views.dart';
import 'reader_screen.dart';

export '../../content/search_index.dart'
    show SearchHit, SearchIndex, normalizeArabic, searchEntries;

/// Full-content in-memory search over the current snapshot. No network, no
/// per-keystroke requests; the index is precomputed at load and queries are
/// debounced.
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final catalog = provider.catalog;
    final List<SearchHit> hits = catalog == null || _query.trim().isEmpty
        ? const <SearchHit>[]
        : provider.searchIndex?.search(_query) ?? const <SearchHit>[];
    final Color barForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;

    final Widget body;
    if (catalog == null) {
      body = const EmptyView(message: 'المحتوى غير جاهز للبحث');
    } else if (_query.trim().isEmpty) {
      body = const EmptyView(
        message: 'ابحث في كل المحتوى',
        hint: 'اكتب كلمة من العنوان أو النص أو المصدر أو الوسوم',
        icon: Icons.search,
      );
    } else if (hits.isEmpty) {
      body = const EmptyView(
        message: 'لا توجد نتائج',
        hint: 'جرّب كلمات أخرى أو تحقق من الإملاء',
        icon: Icons.search_off,
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsetsDirectional.all(AppTheme.space4),
        itemCount: hits.length,
        itemBuilder: (context, index) {
          final SearchHit hit = hits[index];
          return EntryCard(
            entry: hit.entry,
            titleHighlight: hit.titleRanges,
            textHighlight: hit.textRanges,
            onTap: () =>
                Navigator.of(context)
                    .push(ReaderScreen.route(entry: hit.entry)),
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
          onChanged: _onChanged,
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
