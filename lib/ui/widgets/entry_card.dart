import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;

import '../../app/theme/app_theme.dart';
import '../../content/models/content_entry.dart';
import 'ornaments.dart';
import 'state_views.dart' show PlaceholderBadge;

/// Shared entry card used by category, search, and favorites lists. The
/// trailing slot lets the caller add actions (e.g. remove-from-favorites)
/// without forking the layout.
class EntryCard extends StatefulWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.trailing,
    this.maxTextLines,
    this.titleHighlight,
    this.textHighlight,
  });

  final ContentEntry entry;
  final VoidCallback onTap;
  final Widget? trailing;
  final int? maxTextLines;

  /// Character ranges of the original title/text to paint as search
  /// matches. Indices refer to the unmodified strings — display never
  /// changes, only the paint.
  final List<(int, int)>? titleHighlight;
  final List<(int, int)>? textHighlight;

  @override
  State<EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<EntryCard> {
  /// Dense source/fadl citations start collapsed to two lines with a
  /// "المزيد" toggle so list cards stay scannable.
  final GlobalKey _sourceKey = GlobalKey();
  bool _sourceExpanded = false;
  bool _sourceClipped = false;

  @override
  void initState() {
    super.initState();
    _checkSourceOverflow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkSourceOverflow();
  }

  /// Measures the collapsed citation after layout. Only meaningful while
  /// collapsed — an expanded paragraph never exceeds its maxLines.
  void _checkSourceOverflow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sourceExpanded) return;
      final RenderObject? render = _sourceKey.currentContext
          ?.findRenderObject();
      if (render is! RenderParagraph) return;
      if (render.didExceedMaxLines != _sourceClipped) {
        setState(() => _sourceClipped = render.didExceedMaxLines);
      }
    });
  }

  void _toggleSource() {
    setState(() => _sourceExpanded = !_sourceExpanded);
    _checkSourceOverflow();
  }

  Widget _text(
    String value,
    List<(int, int)>? highlight,
    TextStyle? style, {
    int? maxLines,
    TextOverflow? overflow,
  }) {
    if (highlight == null || highlight.isEmpty) {
      return Text(value, style: style, maxLines: maxLines, overflow: overflow);
    }
    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;
    for (final (int start, int end) in highlight) {
      if (start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, start)));
      }
      spans.add(
        TextSpan(
          text: value.substring(start, end),
          style: style?.copyWith(
            backgroundColor: const Color(0x59C9A45E), // gold @ 35%
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      cursor = end;
    }
    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor)));
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Some Quranic entries use the ayah reference itself as their title, which
  /// would print the same line twice on the card.
  bool _referenceIsTitle() {
    final String reference = widget.entry.source?.reference.trim() ?? '';
    return reference.isNotEmpty && reference == widget.entry.title.trim();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    final ContentEntry entry = widget.entry;
    final bool showSource = entry.source != null && !_referenceIsTitle();
    return AppCard(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _text(
                  entry.title,
                  widget.titleHighlight,
                  theme.textTheme.titleMedium,
                ),
              ),
              if (entry.placeholder) const PlaceholderBadge(),
              if (widget.trailing != null) ...<Widget>[
                const SizedBox(width: AppTheme.space1),
                widget.trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          _text(
            entry.text,
            widget.textHighlight,
            theme.textTheme.bodyLarge,
            maxLines: widget.maxTextLines,
            overflow: widget.maxTextLines != null
                ? TextOverflow.ellipsis
                : null,
          ),
          if (showSource) ...<Widget>[
            const SizedBox(height: AppTheme.space3),
            Text(
              entry.source!.reference,
              key: _sourceKey,
              maxLines: _sourceExpanded ? null : 2,
              overflow: _sourceExpanded ? null : TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.goldInk,
              ),
            ),
            if (_sourceExpanded || _sourceClipped)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _toggleSource,
                  style: TextButton.styleFrom(
                    foregroundColor: palette.goldInk,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppTheme.space2,
                    ),
                  ),
                  child: Text(_sourceExpanded ? 'أقل' : 'المزيد'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
