import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/favorites_store.dart';
import '../../app/last_read_store.dart';
import '../../app/theme/app_theme.dart';
import '../../content/models/content_entry.dart';
import '../widgets/counter_section.dart';
import '../widgets/favorite_button.dart';
import '../widgets/ornaments.dart';
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

/// Single-entry reader: mushaf-style framed text, adjustable font size and a
/// floating action pill with copy/share/favorite.
///
/// The source line renders only when a verified reference exists (the model
/// guarantees `source` is absent otherwise), so an unverified attribution can
/// never appear as fact.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.entry});

  final ContentEntry entry;

  static const double minFontSize = 16;
  static const double maxFontSize = 30;
  static const double defaultFontSize = 20;
  static const double fontSizeStep = 2;

  /// Upper bound for the reading column so long Arabic lines stay readable.
  static const double maxLineWidth = 600;

  /// Where the chosen font size is persisted.
  static const String fontSizePrefsKey = 'reader_font_size';

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

  @override
  void initState() {
    super.initState();
    _restoreFontSize();
    // Remember for the home "continue" card. Deferred a frame so the
    // store's notifyListeners never fires during the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LastReadStore>().record(_entry.id);
    });
  }

  /// Restores the last chosen size; a missing or unreadable value keeps the
  /// default instead of breaking the reader.
  Future<void> _restoreFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble(ReaderScreen.fontSizePrefsKey);
      if (stored != null && mounted) {
        setState(() => _fontSize = ReaderScreen.clampFontSize(stored));
      }
    } catch (_) {
      // Best-effort restore only.
    }
  }

  void _adjustFontSize(double delta) {
    setState(() {
      _fontSize = ReaderScreen.clampFontSize(_fontSize + delta);
    });
    _persistFontSize();
  }

  Future<void> _persistFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(ReaderScreen.fontSizePrefsKey, _fontSize);
    } catch (_) {
      // Keep the in-session size even if persistence is unavailable.
    }
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
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    final source = _entry.source;
    final favorites = context.watch<FavoritesStore>();
    final isFavorite = favorites.contains(_entry.id);

    return Scaffold(
      appBar: OrnamentedAppBar(title: Text(_entry.title)),
      body: Stack(
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ReaderScreen.maxLineWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppTheme.space4,
                  AppTheme.space3,
                  AppTheme.space4,
                  112,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppCard(
                      ornate: true,
                      arch: true,
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppTheme.space5,
                        68,
                        AppTheme.space4,
                        AppTheme.space4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (_entry.placeholder) ...<Widget>[
                            const Center(child: PlaceholderBadge()),
                            const SizedBox(height: AppTheme.space4),
                          ],
                          Text(
                            _entry.text,
                            textAlign: TextAlign.center,
                            style: AppTheme.religious(
                              fontSize: _fontSize,
                              color: palette.ink,
                            ),
                          ),
                          if (source != null) ...<Widget>[
                            const OrnamentDivider(),
                            Text(
                              source.reference,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: palette.goldInk,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space3),
                    CounterSection(entry: _entry),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: AppTheme.space4,
            start: 0,
            end: 0,
            child: Center(
              child: _ReaderActions(
                canDecrease: _fontSize > ReaderScreen.minFontSize,
                canIncrease: _fontSize < ReaderScreen.maxFontSize,
                onDecrease: () => _adjustFontSize(-ReaderScreen.fontSizeStep),
                onIncrease: () => _adjustFontSize(ReaderScreen.fontSizeStep),
                onCopy: _copy,
                onShare: _share,
                isFavorite: isFavorite,
                onFavoriteToggle: () => favorites.toggle(_entry.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating pill holding the reader actions with 48dp targets.
class _ReaderActions extends StatelessWidget {
  const _ReaderActions({
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
    required this.onCopy,
    required this.onShare,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final AppColors palette = Theme.of(context).palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: palette.gold.withValues(alpha: 0.55)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.canvas,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space2,
            vertical: AppTheme.space1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'مشاركة',
                onPressed: onShare,
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'نسخ',
                onPressed: onCopy,
              ),
              const _PillDivider(),
              IconButton(
                icon: const Icon(Icons.text_decrease),
                tooltip: 'تصغير الخط',
                onPressed: canDecrease ? onDecrease : null,
              ),
              IconButton(
                icon: const Icon(Icons.text_increase),
                tooltip: 'تكبير الخط',
                onPressed: canIncrease ? onIncrease : null,
              ),
              const _PillDivider(),
              FavoriteButton(
                isFavorite: isFavorite,
                onToggle: onFavoriteToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: VerticalDivider(
        width: AppTheme.space3,
        color: Theme.of(context).palette.outline,
      ),
    );
  }
}
