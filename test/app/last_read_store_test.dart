import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_muslims_companion/app/last_read_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts empty and records the last opened id', () async {
    final store = LastReadStore();
    await store.load();
    expect(store.entryId, isNull);
    await store.record('dhikr-1');
    expect(store.entryId, 'dhikr-1');
  });

  test('recorded id persists across instances', () async {
    final first = LastReadStore();
    await first.load();
    await first.record('dua-2');

    final second = LastReadStore();
    await second.load();
    expect(second.entryId, 'dua-2');
  });

  test('clear removes the persisted id', () async {
    final first = LastReadStore();
    await first.load();
    await first.record('dhikr-1');
    await first.clear();
    expect(first.entryId, isNull);

    final second = LastReadStore();
    await second.load();
    expect(second.entryId, isNull);
  });

  test('record skips the notify when the id is unchanged', () async {
    final store = LastReadStore();
    await store.load();
    await store.record('dhikr-1');
    var notified = false;
    store.addListener(() => notified = true);
    await store.record('dhikr-1');
    expect(notified, isFalse);
  });
}
