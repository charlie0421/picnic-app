import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/data/storage/pending_ad_reward_store.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';

class _MemoryStorage implements LocalStorage {
  final values = <String, String>{};
  @override
  Future<String?> loadData(String key, String? fallback) async =>
      values[key] ?? fallback;
  @override
  Future<void> saveData(String key, String value) async => values[key] = value;
  @override
  Future<void> removeData(String key) async => values.remove(key);
  @override
  Future<void> clearStorage() async => values.clear();
}

class _FakeRepository implements AdRewardApi {
  final server = <AdRewardStatusModel>[];
  final statuses = <AdRewardReference, List<AdRewardStatusModel>>{};
  final acknowledged = <AdRewardReference>[];
  final reads = <AdRewardReference>[];
  final ackGates = <AdRewardReference, Completer<void>>{};
  final statusGates = <AdRewardReference, Completer<void>>{};
  final listGates = <Completer<void>>[];
  bool failAck = false;

  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async {
    reads.add(reference);
    final gate = statusGates[reference];
    if (gate != null) await gate.future;
    final values = statuses[reference]!;
    return values.length == 1 ? values.single : values.removeAt(0);
  }

  @override
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  }) async {
    if (listGates.isNotEmpty) await listGates.removeAt(0).future;
    return AdRewardPageModel(
      items: server,
      totalCount: BigInt.from(server.length),
      nextCursor: null,
      snapshotAt: DateTime.utc(2026),
    );
  }

  @override
  Future<void> acknowledge(AdRewardReference reference) async {
    acknowledged.add(reference);
    final gate = ackGates[reference];
    if (gate != null) await gate.future;
    if (failAck) throw StateError('ack failed');
  }

  @override
  Future<PangleClaimModel> createPangleClaim({
    required String platform,
    required String placementId,
    required String clientRequestId,
  }) => throw UnimplementedError();

  @override
  InternalShortformViewResponse parseInternalViewResponse(
    Map<String, dynamic> json,
  ) => InternalShortformViewResponse.fromJson(json);
}

class _GatedStore extends PendingAdRewardStore {
  _GatedStore(super.storage);
  final readGates = <String, Completer<void>>{};

  @override
  Future<List<StoredAdRewardReference>> readAll(String userId) async {
    final gate = readGates[userId];
    if (gate != null) await gate.future;
    return super.readAll(userId);
  }
}

class _RemoveGatedStore extends PendingAdRewardStore {
  _RemoveGatedStore(super.storage, this.removeGate);

  final Completer<void> removeGate;

  @override
  Future<void> remove(String userId, AdRewardReference reference) async {
    await removeGate.future;
    await super.remove(userId, reference);
  }
}

AdRewardReference _reference(int id) => AdRewardReference(
  type: AdRewardReferenceType.internalImpression,
  id: '00000000-0000-4000-8000-${id.toString().padLeft(12, '0')}',
);

WalletSummaryModel _wallet() => WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.zero,
  bonus: BigInt.zero,
  cotton: BigInt.zero,
  cottonExpiringAmount: BigInt.zero,
  cottonNextExpiresAt: null,
  snapshotAt: DateTime.utc(2026),
);

AdRewardStatusModel _status(AdRewardReference reference, AdRewardState state) =>
    AdRewardStatusModel(
      reference: reference,
      state: state,
      grant: null,
      wallet: _wallet(),
      snapshotAt: DateTime.utc(2026),
    );

void main() {
  late String? owner;
  late _FakeRepository repository;
  late PendingAdRewardStore store;
  late ProviderContainer container;
  late List<Duration> delays;
  late AdRewardDelay delay;

  setUp(() {
    owner = 'user-a';
    repository = _FakeRepository();
    store = PendingAdRewardStore(_MemoryStorage());
    delays = [];
    delay = (duration) async {
      delays.add(duration);
    };
    container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => owner),
        adRewardDelayProvider.overrideWithValue((duration) => delay(duration)),
      ],
    );
    addTearDown(container.dispose);
  });

  test('unions local and server references and sweeps each once', () async {
    final local = _reference(1);
    final server = _reference(2);
    await store.add('user-a', local);
    repository.server.add(_status(server, AdRewardState.granted));
    repository.statuses[local] = [_status(local, AdRewardState.pending)];
    repository.statuses[server] = [_status(server, AdRewardState.granted)];

    await container.read(adRewardRecoveryProvider.notifier).recover('user-a');

    expect(container.read(adRewardRecoveryProvider).references.toSet(), {
      local,
      server,
    });
    // 시작/복귀 스윕은 광고 직후 폴링 사다리를 재생하지 않는다. 사다리를
    // 재생하면 서버가 끝내 해소하지 않는 레퍼런스 하나가 실행/포그라운드마다
    // 30초를 다시 태운다.
    expect(delays, isEmpty);
    expect(repository.reads, unorderedEquals(<AdRewardReference>[local, server]));
    expect(repository.acknowledged, isEmpty);
    expect(
      container
          .read(adRewardRecoveryProvider)
          .dialogQueue
          .single
          .status
          .reference,
      server,
    );
  });

  test('startup sweep never raises the checking banner', () async {
    final pending = _reference(1);
    final gate = Completer<void>();
    await store.add('user-a', pending);
    repository.statuses[pending] = [_status(pending, AdRewardState.pending)];
    repository.statusGates[pending] = gate;

    final recovery = container
        .read(adRewardRecoveryProvider.notifier)
        .recover('user-a');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(adRewardRecoveryProvider).checkingReferences, isEmpty);
    gate.complete();
    await recovery;
    expect(container.read(adRewardRecoveryProvider).checkingReferences, isEmpty);
  });

  test('a stuck reference costs one read per launch, not a ladder', () async {
    final stuck = _reference(1);
    await store.add('user-a', stuck);
    repository.statuses[stuck] = [_status(stuck, AdRewardState.pending)];
    final notifier = container.read(adRewardRecoveryProvider.notifier);

    await notifier.recover('user-a');
    await notifier.recover('user-a');

    // 로컬 레코드는 그대로 남아 다음 실행에서도 다시 조회된다(보상 유실 없음).
    expect((await store.readAll('user-a')).single.reference, stuck);
    expect(repository.reads, [stuck, stuck]);
    expect(delays, isEmpty);
    expect(container.read(adRewardRecoveryProvider).checkingReferences, isEmpty);
    expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
  });

  test('post-ad poll shows the banner and replays the backoff ladder', () async {
    final watched = _reference(1);
    repository.statuses[watched] = List.generate(
      6,
      (_) => _status(watched, AdRewardState.pending),
    );
    final gate = Completer<void>();
    delay = (duration) {
      delays.add(duration);
      return delays.length == 1 ? gate.future : Future<void>.value();
    };

    final polling = container
        .read(adRewardRecoveryProvider.notifier)
        .poll(ownerUserId: 'user-a', reference: watched);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(adRewardRecoveryProvider).checkingReferences,
      contains(watched),
    );
    gate.complete();
    await polling;
    expect(delays, adRewardPollDelays);
    expect(container.read(adRewardRecoveryProvider).checkingReferences, isEmpty);
  });

  test('a background sweep cannot swallow the post-ad poll', () async {
    final watched = _reference(1);
    final gate = Completer<void>();
    await store.add('user-a', watched);
    repository.statuses[watched] = [_status(watched, AdRewardState.pending)];
    repository.statusGates[watched] = gate;
    final notifier = container.read(adRewardRecoveryProvider.notifier);

    final sweep = notifier.recover('user-a');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final polling = notifier.poll(ownerUserId: 'user-a', reference: watched);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(adRewardRecoveryProvider).checkingReferences,
      contains(watched),
    );
    gate.complete();
    await sweep;
    await polling;
    expect(delays, adRewardPollDelays);
    expect(container.read(adRewardRecoveryProvider).checkingReferences, isEmpty);
  });

  test('checking banner clears when the session read blips mid-poll', () async {
    final watched = _reference(1);
    repository.statuses[watched] = [_status(watched, AdRewardState.pending)];
    delay = (duration) async {
      delays.add(duration);
      // 토큰 갱신이 폴링 중간에 착지하면서 currentUser 가 잠깐 비는 상황.
      owner = null;
    };

    await container
        .read(adRewardRecoveryProvider.notifier)
        .poll(ownerUserId: 'user-a', reference: watched);

    expect(delays, [adRewardPollDelays.first]);
    expect(container.read(adRewardRecoveryProvider).activeUserId, 'user-a');
    expect(container.read(adRewardRecoveryProvider).checkingReferences, isEmpty);
  });

  test(
    'first render persists tombstone and failed ack never redisplays',
    () async {
      final reference = _reference(1);
      repository.server.add(_status(reference, AdRewardState.granted));
      repository.statuses[reference] = [
        _status(reference, AdRewardState.granted),
      ];
      final notifier = container.read(adRewardRecoveryProvider.notifier);
      await notifier.recover('user-a');
      final queued = container
          .read(adRewardRecoveryProvider)
          .dialogQueue
          .single;
      repository.failAck = true;

      await notifier.acknowledgeAfterRender(queued);
      expect(
        (await store.readAll('user-a')).single.state,
        PendingAdRewardLocalState.ackPending,
      );
      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);

      repository.failAck = false;
      await notifier.recover('user-a');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
      expect(await store.readAll('user-a'), isEmpty);
    },
  );

  test('ack retry cannot block listing or another terminal dialog', () async {
    final tombstone = _reference(1);
    final terminal = _reference(2);
    final gate = Completer<void>();
    await store.markAckPending('user-a', tombstone);
    repository.ackGates[tombstone] = gate;
    repository.server.add(_status(terminal, AdRewardState.denied));
    repository.statuses[terminal] = [_status(terminal, AdRewardState.denied)];

    final recovery = container
        .read(adRewardRecoveryProvider.notifier)
        .recover('user-a');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final state = container.read(adRewardRecoveryProvider);
    expect(state.references, [terminal]);
    expect(state.dialogQueue.map((value) => value.status.reference), [
      terminal,
    ]);
    expect(state.references, isNot(contains(tombstone)));
    gate.complete();
    await recovery;
  });

  test(
    'account switch invalidates stale owner completion and logout resets',
    () async {
      final a = _reference(1);
      final b = _reference(2);
      repository.statuses[a] = [_status(a, AdRewardState.granted)];
      repository.statuses[b] = [_status(b, AdRewardState.granted)];
      await store.add('user-a', a);
      final stale = container
          .read(adRewardRecoveryProvider.notifier)
          .recover('user-a');
      owner = 'user-b';
      await store.add('user-b', b);
      await container.read(adRewardRecoveryProvider.notifier).recover('user-b');
      await stale;
      final state = container.read(adRewardRecoveryProvider);
      expect(state.activeUserId, 'user-b');
      expect(state.references, [b]);
      container.read(adRewardRecoveryProvider.notifier).resetForLogout();
      expect(container.read(adRewardRecoveryProvider).activeUserId, isNull);
      expect(container.read(adRewardRecoveryProvider).references, isEmpty);
      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
    },
  );

  test(
    'gated A read completion cannot overwrite completed B recovery',
    () async {
      var currentOwner = 'user-a';
      final gatedStore = _GatedStore(_MemoryStorage());
      final gatedRepository = _FakeRepository();
      final readGate = Completer<void>();
      final a = _reference(11);
      final b = _reference(12);
      gatedRepository.statuses[b] = [_status(b, AdRewardState.denied)];
      await gatedStore.add('user-a', a);
      await gatedStore.add('user-b', b);
      gatedStore.readGates['user-a'] = readGate;
      final scoped = ProviderContainer(
        overrides: [
          adRewardRepositoryProvider.overrideWithValue(gatedRepository),
          pendingAdRewardStoreProvider.overrideWithValue(gatedStore),
          adRewardOwnerReaderProvider.overrideWithValue(() => currentOwner),
          adRewardDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(scoped.dispose);
      final stale = scoped
          .read(adRewardRecoveryProvider.notifier)
          .recover('user-a');
      await Future<void>.delayed(Duration.zero);
      currentOwner = 'user-b';
      await scoped.read(adRewardRecoveryProvider.notifier).recover('user-b');
      readGate.complete();
      await stale;
      final state = scoped.read(adRewardRecoveryProvider);
      expect(state.activeUserId, 'user-b');
      expect(state.references, [b]);
      expect(state.dialogQueue.single.status.reference, b);
    },
  );

  test('gated A list and status completions cannot mutate B state', () async {
    for (final gateAt in ['list', 'status']) {
      var currentOwner = 'user-a';
      final scopedStore = PendingAdRewardStore(_MemoryStorage());
      final scopedRepository = _FakeRepository();
      final a = _reference(gateAt == 'list' ? 21 : 22);
      final b = _reference(gateAt == 'list' ? 23 : 24);
      await scopedStore.add('user-a', a);
      await scopedStore.add('user-b', b);
      scopedRepository.statuses[a] = [_status(a, AdRewardState.denied)];
      scopedRepository.statuses[b] = [_status(b, AdRewardState.denied)];
      final gate = Completer<void>();
      if (gateAt == 'list') scopedRepository.listGates.add(gate);
      if (gateAt == 'status') scopedRepository.statusGates[a] = gate;
      final scoped = ProviderContainer(
        overrides: [
          adRewardRepositoryProvider.overrideWithValue(scopedRepository),
          pendingAdRewardStoreProvider.overrideWithValue(scopedStore),
          adRewardOwnerReaderProvider.overrideWithValue(() => currentOwner),
          adRewardDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      final stale = scoped
          .read(adRewardRecoveryProvider.notifier)
          .recover('user-a');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      currentOwner = 'user-b';
      await scoped.read(adRewardRecoveryProvider.notifier).recover('user-b');
      gate.complete();
      await stale;
      final state = scoped.read(adRewardRecoveryProvider);
      expect(state.activeUserId, 'user-b', reason: gateAt);
      expect(state.references, [b], reason: gateAt);
      expect(state.dialogQueue.single.status.reference, b, reason: gateAt);
      scoped.dispose();
    }
  });

  test(
    'local and server-only first-frame tombstones survive restart without redisplay',
    () async {
      for (final source in ['local', 'server']) {
        final storage = _MemoryStorage();
        final scopedStore = PendingAdRewardStore(storage);
        final firstRepository = _FakeRepository();
        final value = _reference(source == 'local' ? 31 : 32);
        if (source == 'local') await scopedStore.add('user-a', value);
        if (source == 'server') {
          firstRepository.server.add(_status(value, AdRewardState.denied));
        }
        firstRepository.statuses[value] = [
          _status(value, AdRewardState.denied),
        ];
        final ackNeverCompletes = Completer<void>();
        firstRepository.ackGates[value] = ackNeverCompletes;
        final first = ProviderContainer(
          overrides: [
            adRewardRepositoryProvider.overrideWithValue(firstRepository),
            pendingAdRewardStoreProvider.overrideWithValue(scopedStore),
            adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
            adRewardDelayProvider.overrideWithValue((_) async {}),
          ],
        );
        await first.read(adRewardRecoveryProvider.notifier).recover('user-a');
        final queued = first.read(adRewardRecoveryProvider).dialogQueue.single;
        unawaited(
          first
              .read(adRewardRecoveryProvider.notifier)
              .acknowledgeAfterRender(queued),
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(
          (await scopedStore.readAll('user-a')).single.state,
          PendingAdRewardLocalState.ackPending,
          reason: source,
        );
        expect(first.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
        first.dispose();

        final resumedRepository = _FakeRepository();
        if (source == 'server') {
          resumedRepository.server.add(_status(value, AdRewardState.denied));
        }
        final resumed = ProviderContainer(
          overrides: [
            adRewardRepositoryProvider.overrideWithValue(resumedRepository),
            pendingAdRewardStoreProvider.overrideWithValue(scopedStore),
            adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
            adRewardDelayProvider.overrideWithValue((_) async {}),
          ],
        );
        await resumed.read(adRewardRecoveryProvider.notifier).recover('user-a');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(resumed.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
        expect(resumedRepository.acknowledged, [value]);
        expect(await scopedStore.readAll('user-a'), isEmpty);
        resumed.dispose();
      }
    },
  );

  test(
    'captured callback cannot ACK after reset and same-owner relogin',
    () async {
      final old = _reference(41);
      final current = _reference(42);
      repository.server.add(_status(old, AdRewardState.denied));
      repository.statuses[old] = [_status(old, AdRewardState.denied)];
      final notifier = container.read(adRewardRecoveryProvider.notifier);
      await notifier.recover('user-a');
      final staleCallbackItem = container
          .read(adRewardRecoveryProvider)
          .dialogQueue
          .single;
      notifier.resetForLogout();
      repository.server.clear();
      repository.statuses[current] = [_status(current, AdRewardState.denied)];
      await store.add('user-a', current);
      await notifier.recover('user-a');

      await expectLater(
        notifier.acknowledgeAfterRender(staleCallbackItem),
        throwsStateError,
      );
      expect(repository.acknowledged, isEmpty);
      expect(
        container
            .read(adRewardRecoveryProvider)
            .dialogQueue
            .single
            .status
            .reference,
        current,
      );
      expect(
        (await store.readAll('user-a')).single.state,
        PendingAdRewardLocalState.pendingDisplay,
      );
    },
  );

  test('same-owner same-reference ABA rejects stale queued generation', () async {
    final value = _reference(51);
    repository.server.add(_status(value, AdRewardState.denied));
    repository.statuses[value] = [_status(value, AdRewardState.denied)];
    final notifier = container.read(adRewardRecoveryProvider.notifier);
    await notifier.recover('user-a');
    final stale = container.read(adRewardRecoveryProvider).dialogQueue.single;

    notifier.resetForLogout();
    await notifier.recover('user-a');
    final current = container.read(adRewardRecoveryProvider).dialogQueue.single;
    expect(current.generation, isNot(stale.generation));
    expect(current.status.reference, stale.status.reference);

    await expectLater(notifier.acknowledgeAfterRender(stale), throwsStateError);
    expect(repository.acknowledged, isEmpty);
    expect(container.read(adRewardRecoveryProvider).dialogQueue.single, current);
  });

  test(
    'restart after server ACK before local remove retries then cleans tombstone',
    () async {
      final storage = _MemoryStorage();
      final removeGate = Completer<void>();
      final firstStore = _RemoveGatedStore(storage, removeGate);
      final value = _reference(52);
      final firstRepository = _FakeRepository()
        ..server.add(_status(value, AdRewardState.denied))
        ..statuses[value] = [_status(value, AdRewardState.denied)];
      final first = ProviderContainer(
        overrides: [
          adRewardRepositoryProvider.overrideWithValue(firstRepository),
          pendingAdRewardStoreProvider.overrideWithValue(firstStore),
          adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
          adRewardDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      await first.read(adRewardRecoveryProvider.notifier).recover('user-a');
      final queued = first.read(adRewardRecoveryProvider).dialogQueue.single;
      unawaited(
        first
            .read(adRewardRecoveryProvider.notifier)
            .acknowledgeAfterRender(queued),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(firstRepository.acknowledged, [value]);
      expect(
        (await firstStore.readAll('user-a')).single.state,
        PendingAdRewardLocalState.ackPending,
      );
      first.dispose();

      final resumedRepository = _FakeRepository()
        ..server.add(_status(value, AdRewardState.denied));
      final resumedStore = PendingAdRewardStore(storage);
      final resumed = ProviderContainer(
        overrides: [
          adRewardRepositoryProvider.overrideWithValue(resumedRepository),
          pendingAdRewardStoreProvider.overrideWithValue(resumedStore),
          adRewardOwnerReaderProvider.overrideWithValue(() => 'user-a'),
          adRewardDelayProvider.overrideWithValue((_) async {}),
        ],
      );
      await resumed.read(adRewardRecoveryProvider.notifier).recover('user-a');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(resumed.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
      expect(resumedRepository.acknowledged, [value]);
      expect(await resumedStore.readAll('user-a'), isEmpty);
      resumed.dispose();
    },
  );
}
