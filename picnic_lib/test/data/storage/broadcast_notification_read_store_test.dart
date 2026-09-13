import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/storage/broadcast_notification_read_store.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

class _MemoryStorage implements LocalStorage {
  final Map<String, String> values = {};
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? firstSaveGate;
  final Completer<void> firstSaveStarted = Completer<void>();
  int saves = 0;

  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    if (failLoad) throw StateError('load failed');
    return values[key] ?? defaultValue;
  }

  @override
  Future<void> saveData(String key, String value) async {
    saves++;
    if (!firstSaveStarted.isCompleted) firstSaveStarted.complete();
    if (saves == 1 && firstSaveGate != null) await firstSaveGate!.future;
    if (failSave) throw StateError('save failed');
    values[key] = value;
  }

  @override
  Future<void> removeData(String key) async => values.remove(key);

  @override
  Future<void> clearStorage() async => values.clear();
}

void main() {
  test('read state survives store recreation for the same account', () async {
    final storage = _MemoryStorage();
    await BroadcastNotificationReadStore(
      storage: storage,
    ).markRead('user-a', 7);

    final restored = await BroadcastNotificationReadStore(
      storage: storage,
    ).readIds('user-a');

    expect(restored, {7});
  });

  test('accounts and guest have independent read sets', () async {
    final storage = _MemoryStorage();
    final store = BroadcastNotificationReadStore(storage: storage);
    await store.markRead('user-a', 1);
    await store.markRead('user-b', 2);
    await store.markRead(null, 3);

    expect(await store.readIds('user-a'), {1});
    expect(await store.readIds('user-b'), {2});
    expect(await store.readIds(null), {3});
  });

  test('failed persistence does not appear in a later read', () async {
    final storage = _MemoryStorage()..failSave = true;
    final store = BroadcastNotificationReadStore(storage: storage);

    await expectLater(store.markRead('user-a', 9), throwsStateError);
    storage.failSave = false;

    expect(await store.readIds('user-a'), isEmpty);
  });

  test('rapid writes from different store instances are serialized', () async {
    final storage = _MemoryStorage()..firstSaveGate = Completer<void>();
    final first = BroadcastNotificationReadStore(storage: storage);
    final second = BroadcastNotificationReadStore(storage: storage);

    final writeOne = first.markRead('user-a', 1);
    await storage.firstSaveStarted.future;
    final writeTwo = second.markRead('user-a', 2);
    storage.firstSaveGate!.complete();
    await Future.wait([writeOne, writeTwo]);

    expect(await first.readIds('user-a'), {1, 2});
  });

  test('mark all stores the complete union in one write', () async {
    final storage = _MemoryStorage();
    final store = BroadcastNotificationReadStore(storage: storage);
    await store.markRead('user-a', 1);
    final before = storage.saves;

    await store.markAllRead('user-a', {2, 3, 4});

    expect(storage.saves, before + 1);
    expect(await store.readIds('user-a'), {1, 2, 3, 4});
  });
}
