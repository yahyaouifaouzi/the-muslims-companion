import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/favorites_store.dart';
import '../../content/models/content_entry.dart';
import '../widgets/counter_section.dart';
import '../widgets/state_views.dart' show PlaceholderBadge;

/// Text composed for copy/share: title, body, optional verified reference,
/// and a short app attribution. The Arabic content is included verbatim —
/// diacritics and punctuation are never normalized or rewritten.
String buildShareText(ContentEntry entry) {
  final source = entry.source;
  return [
    entry.title,
    entry.text,
    if (source != null) source.reference,
    '— رفيق المسلم',
  ].join('\n');
}

/// Single-entry reader: adjustable font size plus copy/share actions.
///
/// The source line renders only when a verified reference exists (the model
/// guarantees `source` is absent otherwise), so an unverified attribution can
/// never appear as fact.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.entry});

  final ContentEntry entry;

  static const double minFontSize = 14;
  static const double maxFontSize = 28;
  static const double defaultFontSize = 18;
  static const double fontSizeStep = 2;

  /// Upper bound for the reading column so long Arabic lines stay readable.
  static const double maxLineWidth = 600;

  /// Clamps [size] into the reader's font-size bounds.
  static double clampFontSize(double size) {
    if (size < minFontSize) return minFontSize;
    if (size > maxFontSize) return maxFontSize;
    return size;
  }

  static Route<void> route({required ContentEntry entry}) =>
      MaterialPageRoute<void>(builder: (_) => ReaderScreen(entry: entry));

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  double _fontSize = ReaderScreen.defaultFontSize;

  ContentEntry get _entry => widget.entry;

  void _adjustFontSize(double delta) {
    setState(() {
      _fontSize = ReaderScreen.clampFontSize(_fontSize + delta);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: buildShareText(_entry)));
      if (mounted) _showMessage('تم نسخ المحتوى');
    } catch (_) {
      if (mounted) _showMessage('تعذّر النسخ');
    }
  }

  Future<void> _share() async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: buildShareText(_entry), title: _entry.title),
      );
      if (!mounted) return;
      if (result.status == ShareResultStatus.success) {
        _showMessage('تمت المشاركة');
      } else {
        await _copyForShareFallback();
      }
    } catch (_) {
      if (!mounted) return;
      await _copyForShareFallback();
    }
  }

  /// Desktop/headless fallback: when the share sheet is unavailable, copy the
  /// text instead so the user still gets the content.
  Future<void> _copyForShareFallback() async {
    try {
      await Clipboard.setData(ClipboardData(text: buildShareText(_entry)));
      if (mounted) _showMessage('تعذّرت المشاركة — تم نسخ المحتوى');
    } catch (_) {
      if (mounted) _showMessage('تعذّرت المشاركة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = _entry.source;
    final favorites = context.watch<FavoritesStore>();
    final isFavorite = favorites.contains(_entry.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_entry.title),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
            onPressed: () => favorites.toggle(_entry.id),
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'تصغير الخط',
            onPressed: _fontSize > ReaderScreen.minFontSize
                ? () => _adjustFontSize(-ReaderScreen.fontSizeStep)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'تكبير الخط',
            onPressed: _fontSize < ReaderScreen.maxFontSize
                ? () => _adjustFontSize(ReaderScreen.fontSizeStep)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'نسخ',
            onPressed: _copy,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة',
            onPressed: _share,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ReaderScreen.maxLineWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_entry.placeholder) ...[
                  const PlaceholderBadge(),
                  const SizedBox(height: 16),
                ],
                Text(
                  _entry.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: _fontSize,
                    height: 1.9,
                  ),
                ),
                if (source != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    source.reference,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                CounterSection(entry: _entry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
