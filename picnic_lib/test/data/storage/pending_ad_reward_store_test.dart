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

  test(
    'wrong list entries and unknown local state are FormatException',
    () async {
      final storage = MemoryStorage();
      final store = PendingAdRewardStore(storage);
      storage.values['pending_ad_rewards_v1:a'] = '[1]';
      await expectLater(store.readAll('a'), throwsFormatException);
      storage.values['pending_ad_rewards_v1:a'] =
          '[{"reference":{"type":"INTERNAL_IMPRESSION","id":"id"},"state":"unknown"}]';
      await expectLater(store.readAll('a'), throwsFormatException);
      storage.values['pending_ad_rewards_v1:a'] = '{}';
      await expectLater(store.readAll('a'), throwsFormatException);
    },
  );
  group('로컬 기록 상한', () {
    // 시작·복귀 복구가 사라지면서 이 목록을 다시 읽어 비워 주는 경로도 함께
    // 사라졌다. ACK 이 끝내 실패한 건은 예전이면 다음 실행이 정리했지만 이제는
    // 남는다. 무한히 쌓이지 않도록 최신 것만 유지한다.
    test('keeps only the newest records once the cap is reached', () async {
      final store = PendingAdRewardStore(MemoryStorage(), maxRecords: 3);

      for (var i = 1; i <= 5; i++) {
        await store.add('a', ref(i));
      }

      expect((await store.readAll('a')).map((e) => e.reference), [
        ref(3),
        ref(4),
        ref(5),
      ]);
    });

    test('the record the current session just wrote always survives', () async {
      final store = PendingAdRewardStore(MemoryStorage(), maxRecords: 2);
      for (var i = 1; i <= 4; i++) {
        await store.add('a', ref(i));
      }

      await store.markAckPending('a', ref(9));

      final kept = await store.readAll('a');
      expect(kept.last.reference, ref(9));
      expect(kept.last.state, PendingAdRewardLocalState.ackPending);
      expect(kept, hasLength(2));
    });

    test('re-adding an existing reference does not grow the list', () async {
      final store = PendingAdRewardStore(MemoryStorage(), maxRecords: 3);
      await store.add('a', ref(1));

      for (var i = 0; i < 10; i++) {
        await store.add('a', ref(1));
      }

      expect(await store.readAll('a'), hasLength(1));
    });

    test('trimming one owner never touches another owner', () async {
      final store = PendingAdRewardStore(MemoryStorage(), maxRecords: 2);
      await store.add('b', ref(100));

      for (var i = 1; i <= 5; i++) {
        await store.add('a', ref(i));
      }

      expect((await store.readAll('a')), hasLength(2));
      expect((await store.readAll('b')).single.reference, ref(100));
    });

    test(
      'the default cap bounds an unbounded run of failed acknowledgements',
      () async {
        final store = PendingAdRewardStore(MemoryStorage());

        for (var i = 0; i < kPendingAdRewardMaxRecords + 25; i++) {
          await store.markAckPending('a', ref(i));
        }

        expect(await store.readAll('a'), hasLength(kPendingAdRewardMaxRecords));
      },
    );
    test(
      'acknowledging an old record refreshes its place in the list',
      () async {
        // 방금 확인한 건이 오래됐다는 이유로 잘려 나가면, ACK 이 진행 중인 동안
        // 톰스톤이 남지 않는다. 확인은 항상 "지금" 쓰는 기록이다.
        final store = PendingAdRewardStore(MemoryStorage(), maxRecords: 3);
        for (var i = 1; i <= 3; i++) {
          await store.add('a', ref(i));
        }

        await store.markAckPending('a', ref(1));
        await store.add('a', ref(4));

        final kept = await store.readAll('a');
        expect(kept.map((e) => e.reference), [ref(3), ref(1), ref(4)]);
        expect(
          kept.firstWhere((e) => e.reference == ref(1)).state,
          PendingAdRewardLocalState.ackPending,
        );
      },
    );
  });
}
