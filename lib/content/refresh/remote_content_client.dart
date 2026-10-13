import 'dart:convert';

import 'package:http/http.dart' as http;

import '../content_exception.dart';

/// HTTP client constrained to a fixed HTTPS base URL.
///
/// Security properties:
/// - HTTPS is enforced at construction and per-request.
/// - Only known file names are fetched (path separators and traversal
///   sequences are rejected).
/// - A configurable timeout and response-size limit bound every request.
/// - Non-200 status codes and non-JSON bodies raise [ContentException].
///
/// The base URL is a build-time configuration value — a downloaded manifest
/// can never redirect the app to a different host.
class RemoteContentClient {
  RemoteContentClient({
    required String baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 2 * 1024 * 1024, // 2 MB per file
  }) : _http = httpClient ?? http.Client() {
    final uri = Uri.parse(baseUrl);
    if (uri.scheme != 'https' || uri.host.isEmpty) {
      throw ArgumentError('baseUrl must be a valid HTTPS URL, got "$baseUrl"');
    }
    // Normalise: strip trailing slash so path joining is consistent.
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  late final String _baseUrl;
  final http.Client _http;
  final Duration timeout;
  final int maxResponseBytes;

  /// Fetches and decodes a single JSON file from the trusted base URL.
  Future<Object?> fetchJson(String fileName) async {
    _validateFileName(fileName);
    final uri = Uri.parse('$_baseUrl/$fileName');
    if (uri.scheme != 'https') {
      throw const ContentException('Non-HTTPS URL rejected.');
    }

    final http.Response response;
    try {
      response = await _http.get(uri).timeout(timeout);
    } on Exception catch (error) {
      throw ContentException('Network error fetching "$fileName": $error');
    }

    if (response.statusCode != 200) {
      throw ContentException(
        'Unexpected HTTP ${response.statusCode} fetching "$fileName".',
      );
    }
    if (response.bodyBytes.length > maxResponseBytes) {
      throw ContentException(
        'Response for "$fileName" exceeds $maxResponseBytes bytes.',
      );
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (error) {
      throw ContentException('Invalid JSON in "$fileName": $error');
    }
  }

  void _validateFileName(String fileName) {
    if (fileName.isEmpty ||
        fileName.contains('/') ||
        fileName.contains('\\') ||
        fileName.contains('..')) {
      throw ContentException('Invalid content file name "$fileName".');
    }
  }

  void dispose() => _http.close();
}
