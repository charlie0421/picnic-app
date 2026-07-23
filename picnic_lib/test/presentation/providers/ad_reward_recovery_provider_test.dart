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
  final ackGates = <AdRewardReference, Completer<void>>{};
  bool failAck = false;

  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async {
    final values = statuses[reference]!;
    return values.length == 1 ? values.single : values.removeAt(0);
  }

  @override
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  }) async => AdRewardPageModel(
    items: server,
    totalCount: BigInt.from(server.length),
    nextCursor: null,
    snapshotAt: DateTime.utc(2026),
  );

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

  test('unions local and server references and uses fixed backoff', () async {
    final local = _reference(1);
    final server = _reference(2);
    await store.add('user-a', local);
    repository.server.add(_status(server, AdRewardState.granted));
    repository.statuses[local] = List.generate(
      6,
      (_) => _status(local, AdRewardState.pending),
    );
    repository.statuses[server] = [_status(server, AdRewardState.granted)];

    await container.read(adRewardRecoveryProvider.notifier).recover('user-a');

    expect(container.read(adRewardRecoveryProvider).references.toSet(), {
      local,
      server,
    });
    expect(delays, adRewardPollDelays);
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

  test('terminal poll is not blocked by another reference delay', () async {
    final pending = _reference(1);
    final terminal = _reference(2);
    final gate = Completer<void>();
    await store.add('user-a', pending);
    repository.server.add(_status(terminal, AdRewardState.granted));
    repository.statuses[pending] = List.generate(
      6,
      (_) => _status(pending, AdRewardState.pending),
    );
    repository.statuses[terminal] = [_status(terminal, AdRewardState.granted)];
    delay = (_) => gate.future;

    final recovery = container
        .read(adRewardRecoveryProvider.notifier)
        .recover('user-a');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final state = container.read(adRewardRecoveryProvider);
    expect(state.checkingReferences, contains(pending));
    expect(
      state.dialogQueue.map((value) => value.status.reference),
      contains(terminal),
    );
    gate.complete();
    await recovery;
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
}
