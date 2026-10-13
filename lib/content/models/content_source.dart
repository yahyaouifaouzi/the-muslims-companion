import '../content_exception.dart';

/// Attribution metadata attached to a content entry.
///
/// Only bundled for entries whose wording and attribution were verified;
/// entries with `verified: false` must not carry a source so that no
/// unverified claim can be displayed as fact.
class ContentSource {
  const ContentSource({required this.reference, this.kind, this.authenticity});

  /// Where the text comes from, e.g. "سورة البقرة، آية 201" or
  /// "صحيح البخاري 1، صحيح مسلم 1907".
  final String reference;

  /// Coarse origin kind: "quran" or "hadith". Mapping to UI labels is the
  /// presentation layer's job; unknown kinds are kept verbatim.
  final String? kind;

  /// Authenticity grade (hadith only, e.g. "صحيح"). Must be null for Quran
  /// content. Never displayed unless the entry is verified.
  final String? authenticity;

  const ContentSource._(this.reference, this.kind, this.authenticity);

  /// Parses one source object. Throws [ContentException] on invalid input.
  factory ContentSource.fromJson(Object? raw, {required String fileContext}) {
    if (raw is! Map<Object?, Object?>) {
      throw ContentException('$fileContext: source must be an object.');
    }
    final reference = raw['reference'];
    if (reference is! String || reference.trim().isEmpty) {
      throw ContentException(
        '$fileContext: source.reference is required and must be a non-empty '
        'string.',
      );
    }
    final kind = raw['kind'];
    if (kind != null && kind is! String) {
      throw ContentException(
        '$fileContext: source.kind must be a string when present.',
      );
    }
    final authenticity = raw['authenticity'];
    if (authenticity != null && authenticity is! String) {
      throw ContentException(
        '$fileContext: source.authenticity must be a string when present.',
      );
    }
    return ContentSource._(reference, kind as String?, authenticity as String?);
  }

  Map<String, Object?> toJson() => {
    'reference': reference,
    if (kind != null) 'kind': kind,
    if (authenticity != null) 'authenticity': authenticity,
  };
}
