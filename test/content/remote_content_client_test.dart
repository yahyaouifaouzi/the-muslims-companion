import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_muslims_companion/content/content_exception.dart';
import 'package:the_muslims_companion/content/refresh/remote_content_client.dart';

void main() {
  group('RemoteContentClient construction', () {
    test('rejects non-HTTPS base URLs', () {
      expect(
        () => RemoteContentClient(baseUrl: 'http://example.com/v1'),
        throwsArgumentError,
      );
      expect(
        () => RemoteContentClient(baseUrl: 'ftp://example.com'),
        throwsArgumentError,
      );
    });

    test('accepts a valid HTTPS base URL', () {
      final client = RemoteContentClient(
        baseUrl: 'https://content.example.com/v1',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      expect(client, isNotNull);
    });
  });

  group('RemoteContentClient.fetchJson', () {
    RemoteContentClient clientWith(MockClient httpMock) => RemoteContentClient(
      baseUrl: 'https://content.example.com/v1',
      httpClient: httpMock,
      timeout: const Duration(milliseconds: 100),
      maxResponseBytes: 1024,
    );

    test('fetches and decodes JSON on 200', () async {
      final client = clientWith(
        MockClient((request) async {
          expect(
            request.url.toString(),
            'https://content.example.com/v1/manifest.json',
          );
          expect(request.url.scheme, 'https');
          return http.Response.bytes(
            utf8.encode(jsonEncode({'schemaVersion': 1})),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final result = await client.fetchJson('manifest.json');
      expect(result, {'schemaVersion': 1});
    });

    test('rejects path traversal and separators', () async {
      final client = clientWith(
        MockClient((_) async => http.Response('{}', 200)),
      );
      for (final bad in ['../secret', 'a/b', 'a\\b', '..']) {
        expect(
          () => client.fetchJson(bad),
          throwsA(isA<ContentException>()),
          reason: '"$bad" must be rejected',
        );
      }
    });

    test('non-200 status raises ContentException', () async {
      final client = clientWith(
        MockClient((_) async => http.Response('not found', 404)),
      );
      expect(
        client.fetchJson('manifest.json'),
        throwsA(isA<ContentException>()),
      );
    });

    test('oversized response raises ContentException', () async {
      final big = List.filled(2048, 0x20); // 2 KB > 1 KB limit
      final client = clientWith(
        MockClient((_) async => http.Response.bytes(big, 200)),
      );
      expect(
        client.fetchJson('manifest.json'),
        throwsA(isA<ContentException>()),
      );
    });

    test('invalid JSON raises ContentException', () async {
      final client = clientWith(
        MockClient((_) async => http.Response('not json', 200)),
      );
      expect(
        client.fetchJson('manifest.json'),
        throwsA(isA<ContentException>()),
      );
    });

    test('network timeout raises ContentException', () async {
      final client = clientWith(
        MockClient(
          (request) => Future.delayed(
            const Duration(seconds: 5),
            () => http.Response('{}', 200),
          ),
        ),
      );
      expect(
        client.fetchJson('manifest.json'),
        throwsA(isA<ContentException>()),
      );
    });
  });
}
