import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/content/refresh/content_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ContentCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('content_cache_test');
    cache = ContentCache(directory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ContentCache', () {
    test('readSnapshot returns null when no snapshot exists', () async {
      expect(await cache.readSnapshot(), isNull);
    });

    test('writeSnapshot then readSnapshot round-trips', () async {
      final files = {
        'manifest.json': {'schemaVersion': 1},
        'categories.json': {'schemaVersion': 1, 'categories': <Object?>[]},
      };
      await cache.writeSnapshot(files);
      final read = await cache.readSnapshot();
      expect(read, isNotNull);
      expect(read!['manifest.json'], {'schemaVersion': 1});
      expect(read['categories.json'], {
        'schemaVersion': 1,
        'categories': <Object?>[],
      });
    });

    test('writeSnapshot overwrites atomically', () async {
      await cache.writeSnapshot({
        'manifest.json': {'v': 1},
      });
      await cache.writeSnapshot({
        'manifest.json': {'v': 2},
      });
      final read = await cache.readSnapshot();
      expect(read!['manifest.json'], {'v': 2});
    });

    test('corrupt snapshot file reads as null', () async {
      final file = File('${tempDir.path}/snapshot.json');
      await file.writeAsString('not-json{{{');
      expect(await cache.readSnapshot(), isNull);
    });

    test('clear removes snapshot and metadata', () async {
      await cache.writeSnapshot({
        'manifest.json': {'v': 1},
      });
      await cache.writeRefreshMetadata(contentVersion: 5);
      expect(await cache.getActiveContentVersion(), 5);
      expect(await cache.getLastRefresh(), isNotNull);

      await cache.clear();
      expect(await cache.readSnapshot(), isNull);
      expect(await cache.getActiveContentVersion(), isNull);
      expect(await cache.getLastRefresh(), isNull);
    });

    test('metadata persists across instances sharing prefs', () async {
      await cache.writeRefreshMetadata(contentVersion: 7);
      final second = ContentCache(directory: tempDir);
      expect(await second.getActiveContentVersion(), 7);
      expect(await second.getLastRefresh(), isNotNull);
    });
  });
}
