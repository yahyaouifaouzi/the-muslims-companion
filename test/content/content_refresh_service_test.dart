import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/content/refresh/content_cache.dart';
import 'package:the_muslims_companion/content/refresh/content_refresh_service.dart';
import 'package:the_muslims_companion/content/refresh/remote_content_client.dart';

/// A small, fully valid snapshot keyed by bare file name.
Map<String, Object?> _validSnapshot({int contentVersion = 2}) => {
  'manifest.json': {
    'schemaVersion': 1,
    'contentVersion': contentVersion,
    'updatedAt': '2026-10-14',
    'files': ['categories.json', 'duas.json'],
  },
  'categories.json': {
    'schemaVersion': 1,
    'categories': [
      {
        'id': 'duas-quran',
        'title': 'أدعية قرآنية',
        'iconKey': 'quran',
        'contentFile': 'duas.json',
        'sortOrder': 1,
        'enabled': true,
      },
    ],
  },
  'duas.json': {
    'schemaVersion': 1,
    'entries': [
      {
        'id': 'dua-1',
        'categoryId': 'duas-quran',
        'title': 'دعاء',
        'text': 'ربنا آتنا في الدنيا حسنة',
        'sortOrder': 1,
        'verified': true,
        'placeholder': false,
      },
    ],
  },
};

MockClient _httpServing(Map<String, Object?> snapshot) {
  return MockClient((request) async {
    final name = request.url.pathSegments.last;
    final file = snapshot[name];
    if (file == null) {
      return http.Response('not found', 404);
    }
    return http.Response.bytes(
      utf8.encode(jsonEncode(file)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ContentCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('refresh_test');
    cache = ContentCache(directory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  ContentRefreshService serviceWith(MockClient httpMock) =>
      ContentRefreshService(
        client: RemoteContentClient(
          baseUrl: 'https://content.example.com/v1',
          httpClient: httpMock,
          timeout: const Duration(milliseconds: 200),
        ),
        cache: cache,
      );

  test('successful update activates snapshot and persists metadata', () async {
    final service = serviceWith(
      _httpServing(_validSnapshot(contentVersion: 3)),
    );
    final outcome = await service.refresh();

    expect(outcome.status, RefreshStatus.updated);
    expect(await cache.getActiveContentVersion(), 3);
    expect(await cache.getLastRefresh(), isNotNull);
    final snapshot = await cache.readSnapshot();
    expect(snapshot, isNotNull);
    expect(snapshot!['duas.json'], isNotNull);
  });

  test('unchanged version skips download and does not update cache', () async {
    // Activate version 3 first.
    await serviceWith(_httpServing(_validSnapshot(contentVersion: 3)))
        .refresh();
    final snapshotBefore = await cache.readSnapshot();

    // Remote still reports version 3.
    final outcome = await serviceWith(
      _httpServing(_validSnapshot(contentVersion: 3)),
    ).refresh();

    expect(outcome.status, RefreshStatus.unchanged);
    final snapshotAfter = await cache.readSnapshot();
    expect(
      jsonEncode(snapshotAfter),
      jsonEncode(snapshotBefore),
      reason: 'unchanged refresh must not rewrite the snapshot',
    );
  });

  test('older remote version is not applied', () async {
    await serviceWith(_httpServing(_validSnapshot(contentVersion: 5)))
        .refresh();
    final outcome = await serviceWith(
      _httpServing(_validSnapshot(contentVersion: 4)),
    ).refresh();
    expect(outcome.status, RefreshStatus.unchanged);
    expect(await cache.getActiveContentVersion(), 5);
  });

  test('invalid remote JSON fails without touching the cache', () async {
    // Activate a valid snapshot first.
    await serviceWith(_httpServing(_validSnapshot(contentVersion: 3)))
        .refresh();
    final before = await cache.readSnapshot();

    // Remote now serves garbage for a content file.
    final bad = _validSnapshot(contentVersion: 4);
    bad['duas.json'] = 'not-an-object';
    final outcome = await serviceWith(_httpServing(bad)).refresh();

    expect(outcome.status, RefreshStatus.failed);
    final after = await cache.readSnapshot();
    expect(jsonEncode(after), jsonEncode(before));
    expect(await cache.getActiveContentVersion(), 3);
  });

  test('duplicate entry IDs fail without touching the cache', () async {
    final bad = _validSnapshot(contentVersion: 4);
    (bad['duas.json']! as Map<Object?, Object?>)['entries'] = <Object?>[
      {
        'id': 'dua-1',
        'categoryId': 'duas-quran',
        'title': 'أ',
        'text': 'نص',
        'sortOrder': 1,
        'verified': true,
        'placeholder': false,
      },
      {
        'id': 'dua-1', // duplicate
        'categoryId': 'duas-quran',
        'title': 'ب',
        'text': 'نص',
        'sortOrder': 2,
        'verified': true,
        'placeholder': false,
      },
    ];
    final outcome = await serviceWith(_httpServing(bad)).refresh();
    expect(outcome.status, RefreshStatus.failed);
    expect(await cache.getActiveContentVersion(), isNull);
  });

  test('invalid category reference fails without touching the cache', () async {
    final bad = _validSnapshot(contentVersion: 4);
    (bad['duas.json']! as Map<Object?, Object?>)['entries'] = <Object?>[
      {
        'id': 'dua-1',
        'categoryId': 'ghost-cat',
        'title': 'أ',
        'text': 'نص',
        'sortOrder': 1,
        'verified': true,
        'placeholder': false,
      },
    ];
    final outcome = await serviceWith(_httpServing(bad)).refresh();
    expect(outcome.status, RefreshStatus.failed);
    expect(await cache.getActiveContentVersion(), isNull);
  });

  test('manifest with disallowed file name fails', () async {
    final bad = _validSnapshot(contentVersion: 4);
    (bad['manifest.json']! as Map<Object?, Object?>)['files'] = [
      'categories.json',
      'duas.json',
      '../../etc/passwd',
    ];
    final outcome = await serviceWith(_httpServing(bad)).refresh();
    expect(outcome.status, RefreshStatus.failed);
    expect(await cache.getActiveContentVersion(), isNull);
  });

  test('partial download (404 on one file) fails without cache', () async {
    final snapshot = _validSnapshot(contentVersion: 4);
    // Serve manifest + categories but 404 on duas.json.
    final mock = MockClient((request) async {
      final name = request.url.pathSegments.last;
      if (name == 'duas.json') return http.Response('missing', 404);
      final file = snapshot[name];
      if (file == null) return http.Response('nf', 404);
      return http.Response.bytes(
        utf8.encode(jsonEncode(file)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final outcome = await serviceWith(mock).refresh();
    expect(outcome.status, RefreshStatus.failed);
    expect(await cache.getActiveContentVersion(), isNull);
    expect(await cache.readSnapshot(), isNull);
  });

  test('timeout fails without cache', () async {
    final slow = MockClient(
      (request) => Future.delayed(
        const Duration(seconds: 5),
        () => http.Response('{}', 200),
      ),
    );
    final outcome = await serviceWith(slow).refresh();
    expect(outcome.status, RefreshStatus.failed);
    expect(await cache.getActiveContentVersion(), isNull);
  });

  test('unsupported schema version fails', () async {
    final bad = _validSnapshot(contentVersion: 4);
    (bad['manifest.json']! as Map<Object?, Object?>)['schemaVersion'] = 99;
    final outcome = await serviceWith(_httpServing(bad)).refresh();
    expect(outcome.status, RefreshStatus.failed);
  });

  test('manifest missing categories.json fails', () async {
    final bad = _validSnapshot(contentVersion: 4);
    (bad['manifest.json']! as Map<Object?, Object?>)['files'] = ['duas.json'];
    final outcome = await serviceWith(_httpServing(bad)).refresh();
    expect(outcome.status, RefreshStatus.failed);
  });

  test(
    'rollback: failed update after a valid cache leaves the old snapshot',
    () async {
      // 1. Activate version 3.
      await serviceWith(_httpServing(_validSnapshot(contentVersion: 3)))
          .refresh();
      final before = await cache.readSnapshot();
      expect(await cache.getActiveContentVersion(), 3);

      // 2. Attempt an update that fails during validation.
      final bad = _validSnapshot(contentVersion: 4);
      bad['duas.json'] = 'broken';
      final outcome = await serviceWith(_httpServing(bad)).refresh();
      expect(outcome.status, RefreshStatus.failed);

      // 3. Old snapshot is intact and still loadable.
      final after = await cache.readSnapshot();
      expect(jsonEncode(after), jsonEncode(before));
      expect(await cache.getActiveContentVersion(), 3);
    },
  );
}
