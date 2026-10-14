import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../content/models/content_entry.dart';
import 'ornaments.dart';
import 'state_views.dart' show PlaceholderBadge;

/// Shared entry card used by category, search, and favorites lists. The
/// trailing slot lets the caller add actions (e.g. remove-from-favorites)
/// without forking the layout.
class EntryCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColors palette = theme.palette;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _text(
                  entry.title,
                  titleHighlight,
                  theme.textTheme.titleMedium,
                ),
              ),
              if (entry.placeholder) const PlaceholderBadge(),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppTheme.space1),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          _text(
            entry.text,
            textHighlight,
            theme.textTheme.bodyLarge,
            maxLines: maxTextLines,
            overflow: maxTextLines != null ? TextOverflow.ellipsis : null,
          ),
          if (entry.source != null) ...<Widget>[
            const SizedBox(height: AppTheme.space3),
            Text(
              entry.source!.reference,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.goldInk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
