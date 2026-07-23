import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/data/storage/pending_ad_reward_store.dart';

class MemoryStorage implements LocalStorage {
  final values = <String, String>{};
  bool cleared = false;
  @override
  Future<String?> loadData(String key, String? fallback) async =>
      values[key] ?? fallback;
  @override
  Future<void> saveData(String key, String value) async {
    await Future<void>.delayed(Duration.zero);
    values[key] = value;
  }

  @override
  Future<void> removeData(String key) async => values.remove(key);
  @override
  Future<void> clearStorage() async {
    cleared = true;
    values.clear();
  }
}

AdRewardReference ref(int id) => AdRewardReference(
  type: AdRewardReferenceType.internalImpression,
  id: '00000000-0000-4000-8000-${id.toString().padLeft(12, '0')}',
);

void main() {
  test('deduplicates references and isolates owners', () async {
    final storage = MemoryStorage();
    final store = PendingAdRewardStore(storage);
    await store.add('user-a', ref(1));
    await store.add('user-a', ref(1));
    expect((await store.readAll('user-a')).map((e) => e.reference), [ref(1)]);
    expect(await store.readAll('user-b'), isEmpty);
    expect(storage.cleared, isFalse);
  });

  test('serializes 100 concurrent adds across owners without loss', () async {
    final storage = MemoryStorage();
    final store = PendingAdRewardStore(storage);
    await Future.wait(
      List.generate(100, (i) => store.add(i.isEven ? 'a' : 'b', ref(i))),
    );
    expect(await store.readAll('a'), hasLength(50));
    expect(await store.readAll('b'), hasLength(50));
    expect(storage.cleared, isFalse);
  });

  test(
    'ack is monotonic, upserts server-only rows, and remove is scoped',
    () async {
      final store = PendingAdRewardStore(MemoryStorage());
      await store.markAckPending('a', ref(1));
      await store.add('a', ref(1));
      await store.add('b', ref(1));
      expect(
        (await store.readAll('a')).single.state,
        PendingAdRewardLocalState.ackPending,
      );
      await store.remove('a', ref(1));
      expect(await store.readAll('a'), isEmpty);
      expect(await store.readAll('b'), hasLength(1));
    },
  );
}
