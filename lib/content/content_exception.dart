/// Thrown when bundled or remote content violates the content schema
/// (missing required field, wrong type, duplicate ID, invalid repeat count).
class ContentException implements Exception {
  const ContentException(this.message);

  /// Human-readable description of what failed and where.
  final String message;

  @override
  String toString() => 'ContentException: $message';
}
