import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
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
  final statuses = <AdRewardReference, List<AdRewardStatusModel>>{};
  final acknowledged = <AdRewardReference>[];
  final reads = <AdRewardReference>[];
  final ackGates = <AdRewardReference, Completer<void>>{};
  final statusGates = <AdRewardReference, Completer<void>>{};
  final statusErrors = <AdRewardReference, Object>{};

  /// 앱이 목록 RPC 를 부르는지 세는 유일한 계측점.
  ///
  /// 개편의 핵심 계약은 "시작·복귀·같은 사용자 인증 이벤트에서
  /// `list_unacknowledged_ad_rewards` 0회"다. 이 카운터가 0 이 아니면 그
  /// 계약이 깨진 것이다.
  var listCallCount = 0;
  bool failAck = false;

  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async {
    reads.add(reference);
    final gate = statusGates[reference];
    if (gate != null) await gate.future;
    final error = statusErrors[reference];
    if (error != null) throw error;
    final values = statuses[reference]!;
    return values.length == 1 ? values.single : values.removeAt(0);
  }

  @override
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  }) async {
    listCallCount++;
    return AdRewardPageModel(
      items: const [],
      totalCount: BigInt.zero,
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

AdRewardStatusModel _grantedStatus(
  AdRewardReference reference, {
  int amount = 3,
}) => AdRewardStatusModel(
  reference: reference,
  state: AdRewardState.granted,
  grant: AdRewardGrantModel(
    id: 'grant-${reference.id}',
    currency: WalletCurrency.cottonCandy,
    amount: BigInt.from(amount),
    grantedAt: DateTime.utc(2026),
    expiresAt: DateTime.utc(2026, 2),
  ),
  wallet: _wallet(),
  snapshotAt: DateTime.utc(2026),
);

Future<void> _flushEventQueue() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late String? owner;
  late _FakeRepository repository;
  late PendingAdRewardStore store;
  late ProviderContainer container;
  late List<Duration> delays;
  late AdRewardDelay delay;
  late List<AdRewardStatusModel> earnRecords;
  late bool earnStored;

  setUp(() {
    owner = 'user-a';
    repository = _FakeRepository();
    store = PendingAdRewardStore(_MemoryStorage());
    delays = [];
    earnRecords = [];
    earnStored = true;
    delay = (duration) async {
      delays.add(duration);
    };
    container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => owner),
        adRewardDelayProvider.overrideWithValue((duration) => delay(duration)),
        adRewardEarnRecorderProvider.overrideWithValue((status) async {
          earnRecords.add(status);
          return earnStored;
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  group('확정된 적립의 analytics outbox 저장', () {
    test('a confirmed grant is recorded without any dialog host', () async {
      final watched = _reference(1);
      repository.statuses[watched] = [_grantedStatus(watched, amount: 5)];
      final notifier = container.read(adRewardRecoveryProvider.notifier);

      await notifier.poll(ownerUserId: 'user-a', reference: watched);

      // 팝업이 마운트되지 않았고 ACK 도 아직인데 통계는 이미 저장됐다.
      expect(earnRecords.single.reference, watched);
      expect(earnRecords.single.grant!.amount, BigInt.from(5));
      expect(
        container.read(adRewardRecoveryProvider).dialogQueue,
        hasLength(1),
      );
    });

    test('non-granted terminal states are never recorded as an earn', () async {
      for (final state in [
        AdRewardState.denied,
        AdRewardState.expired,
        AdRewardState.abandoned,
      ]) {
        final watched = _reference(state.index + 10);
        repository.statuses[watched] = [_status(watched, state)];
        await container
            .read(adRewardRecoveryProvider.notifier)
            .poll(ownerUserId: 'user-a', reference: watched);
      }

      expect(earnRecords, isEmpty);
    });

    test('duplicate callbacks for one ad record a single earn', () async {
      final watched = _reference(2);
      repository.statuses[watched] = [
        _grantedStatus(watched),
        _grantedStatus(watched),
      ];
      final notifier = container.read(adRewardRecoveryProvider.notifier);

      await notifier.poll(ownerUserId: 'user-a', reference: watched);
      await notifier.poll(ownerUserId: 'user-a', reference: watched);

      expect(earnRecords, hasLength(1));
      expect(
        container.read(adRewardRecoveryProvider).dialogQueue,
        hasLength(1),
      );
    });

    test('a reward presented by the ad route itself is recorded', () async {
      final presented = _reference(3);
      final notifier = container.read(adRewardRecoveryProvider.notifier);

      await notifier.acknowledgePresented(
        ownerUserId: 'user-a',
        status: _grantedStatus(presented, amount: 2),
      );

      // 내부 숏폼 전체화면 경로는 dialogQueue 를 거치지 않는다. 그래도 확정된
      // 적립이므로 통계에는 남아야 한다.
      expect(earnRecords.single.reference, presented);
      expect(repository.acknowledged, [presented]);
    });

    test('a failed outbox write is retried by a later confirmation', () async {
      final watched = _reference(4);
      repository.statuses[watched] = [
        _grantedStatus(watched),
        _grantedStatus(watched),
      ];
      earnStored = false;
      final notifier = container.read(adRewardRecoveryProvider.notifier);

      await notifier.poll(ownerUserId: 'user-a', reference: watched);
      earnStored = true;
      await notifier.poll(ownerUserId: 'user-a', reference: watched);

      expect(earnRecords, hasLength(2));
    });

    test('a grant confirmed after the owner changed is not recorded', () async {
      final watched = _reference(5);
      final gate = Completer<void>();
      repository.statuses[watched] = [_grantedStatus(watched)];
      repository.statusGates[watched] = gate;
      final notifier = container.read(adRewardRecoveryProvider.notifier);

      final polling = notifier.poll(ownerUserId: 'user-a', reference: watched);
      owner = 'user-b';
      gate.complete();
      await polling;

      expect(earnRecords, isEmpty);
      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
    });
  });

  group('목록 자동 복구 제거', () {
    test('watching one ad never lists unacknowledged rewards', () async {
      final watched = _reference(1);
      repository.statuses[watched] = [_grantedStatus(watched)];

      await container
          .read(adRewardRecoveryProvider.notifier)
          .poll(ownerUserId: 'user-a', reference: watched);

      expect(repository.listCallCount, 0);
    });

    test('only the ad that was just watched is read', () async {
      final watched = _reference(1);
      final leftoverFromLastSession = _reference(2);
      // 지난 세션이 남긴 로컬 레코드. 예전에는 시작·복귀마다 이 레퍼런스까지
      // 사다리를 다시 태웠다.
      await store.add('user-a', leftoverFromLastSession);
      await store.add('user-a', watched);
      repository.statuses[watched] = [_grantedStatus(watched)];

      await container
          .read(adRewardRecoveryProvider.notifier)
          .poll(ownerUserId: 'user-a', reference: watched);

      expect(repository.reads, [watched]);
      expect(repository.listCallCount, 0);
      expect(
        container.read(adRewardRecoveryProvider).references,
        [watched],
        reason: '과거 로컬 보상은 복구 대상이 아니다',
      );
    });

    test('a leftover ACK_PENDING tombstone is not replayed', () async {
      final tombstone = _reference(3);
      final watched = _reference(4);
      await store.markAckPending('user-a', tombstone);
      await store.add('user-a', watched);
      repository.statuses[watched] = [_grantedStatus(watched)];
      final notifier = container.read(adRewardRecoveryProvider.notifier);

      await notifier.poll(ownerUserId: 'user-a', reference: watched);
      await notifier.acknowledgeAfterRender(
        container.read(adRewardRecoveryProvider).dialogQueue.single,
      );
      await _flushEventQueue();

      expect(repository.reads, [watched]);
      expect(repository.acknowledged, [watched]);
      // 지난 세션이 남긴 톰스톤의 ACK 재시도는 더 이상 일어나지 않는다. 서버
      // 보상과 원장은 앱이 건드리지 않으므로 로컬 기록도 그대로 남는다.
      expect((await store.readAll('user-a')).single.reference, tombstone);
    });

    test('logout clears the ad state without touching the server', () async {
      final watched = _reference(5);
      repository.statuses[watched] = [_grantedStatus(watched)];
      final notifier = container.read(adRewardRecoveryProvider.notifier);
      await notifier.poll(ownerUserId: 'user-a', reference: watched);
      expect(
        container.read(adRewardRecoveryProvider).dialogQueue,
        hasLength(1),
      );

      notifier.resetForLogout();

      final state = container.read(adRewardRecoveryProvider);
      expect(state.activeUserId, isNull);
      expect(state.references, isEmpty);
      expect(state.dialogQueue, isEmpty);
      expect(repository.listCallCount, 0);
    });
  });

  group('현재 광고의 개별 확인', () {
    test(
      'post-ad poll shows the banner and replays the backoff ladder',
      () async {
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
        expect(
          container.read(adRewardRecoveryProvider).checkingReferences,
          isEmpty,
        );
      },
    );

    test('a pending ad flips to granted inside the same ladder', () async {
      final watched = _reference(1);
      repository.statuses[watched] = [
        _status(watched, AdRewardState.pending),
        _grantedStatus(watched, amount: 4),
      ];

      await container
          .read(adRewardRecoveryProvider.notifier)
          .poll(ownerUserId: 'user-a', reference: watched);

      expect(delays, [adRewardPollDelays.first]);
      final queued = container
          .read(adRewardRecoveryProvider)
          .dialogQueue
          .single;
      expect(queued.status.state, AdRewardState.granted);
      expect(queued.status.grant!.amount, BigInt.from(4));
    });

    test(
      'checking banner clears when the session read blips mid-poll',
      () async {
        final watched = _reference(1);
        repository.statuses[watched] = [
          _status(watched, AdRewardState.pending),
        ];
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
        expect(
          container.read(adRewardRecoveryProvider).checkingReferences,
          isEmpty,
        );
      },
    );

    test('a status answer for another reference is rejected', () async {
      final requested = _reference(142);
      final returned = _reference(143);
      await store.add('user-a', requested);
      repository.statuses[requested] = [
        _status(returned, AdRewardState.denied),
      ];

      await expectLater(
        container
            .read(adRewardRecoveryProvider.notifier)
            .poll(ownerUserId: 'user-a', reference: requested),
        throwsA(isA<FormatException>()),
      );

      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
      expect((await store.readAll('user-a')).single.reference, requested);
    });
  });

  group('표시와 ACK', () {
    test('first render persists the tombstone before acknowledging', () async {
      final watched = _reference(1);
      repository.statuses[watched] = [_grantedStatus(watched)];
      await store.add('user-a', watched);
      final notifier = container.read(adRewardRecoveryProvider.notifier);
      await notifier.poll(ownerUserId: 'user-a', reference: watched);
      final queued = container
          .read(adRewardRecoveryProvider)
          .dialogQueue
          .single;

      await notifier.acknowledgeAfterRender(queued);

      expect(repository.acknowledged, [watched]);
      expect(await store.readAll('user-a'), isEmpty);
      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
    });

    test('a failed ack keeps the tombstone and never redisplays', () async {
      final watched = _reference(1);
      repository.statuses[watched] = [
        _grantedStatus(watched),
        _grantedStatus(watched),
      ];
      await store.add('user-a', watched);
      final notifier = container.read(adRewardRecoveryProvider.notifier);
      await notifier.poll(ownerUserId: 'user-a', reference: watched);
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

      // 같은 광고가 다시 확인돼도 영수증이 두 번 뜨지 않는다.
      repository.failAck = false;
      await notifier.poll(ownerUserId: 'user-a', reference: watched);
      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
    });

    test(
      'a duplicate callback adds no second ladder and no second receipt',
      () async {
        // 같은 광고의 콜백이 두 번 도착하는 경우. 사다리가 하나로 줄면서 진행
        // 중인 확인에 겹쳐 든 콜백은 조회를 새로 만들지 않고, ACK 이 끝난 뒤 온
        // 콜백도 영수증·ACK·통계를 다시 만들지 않아야 한다.
        final watched = _reference(1);
        await store.add('user-a', watched);
        repository.statuses[watched] = [
          _status(watched, AdRewardState.pending),
          _grantedStatus(watched),
          _grantedStatus(watched),
        ];
        final parked = Completer<void>();
        delay = (duration) {
          delays.add(duration);
          return delays.length == 1 ? parked.future : Future<void>.value();
        };
        final notifier = container.read(adRewardRecoveryProvider.notifier);

        // 첫 콜백의 사다리가 PENDING 을 읽고 첫 칸에서 잠든다.
        final polling = notifier.poll(
          ownerUserId: 'user-a',
          reference: watched,
        );
        await _flushEventQueue();
        expect(repository.reads, [watched]);

        // 진행 중인 확인에 겹쳐 든 중복 콜백.
        await notifier.poll(ownerUserId: 'user-a', reference: watched);
        expect(repository.reads, [watched], reason: '중복 조회');

        parked.complete();
        await polling;
        final queued = container
            .read(adRewardRecoveryProvider)
            .dialogQueue
            .single;
        await notifier.acknowledgeAfterRender(queued);
        expect(repository.acknowledged, [watched]);

        // ACK 이 끝난 뒤 도착한 콜백.
        await notifier.poll(ownerUserId: 'user-a', reference: watched);

        expect(
          container.read(adRewardRecoveryProvider).dialogQueue,
          isEmpty,
          reason: '중복 다이얼로그',
        );
        expect(repository.acknowledged, [watched], reason: '중복 ACK');
        expect(earnRecords, hasLength(1), reason: '중복 통계');
        expect(await store.readAll('user-a'), isEmpty);
      },
    );

    test(
      'fullscreen first-frame acknowledgement clears its durable record',
      () async {
        final reference = _reference(30);
        await store.add('user-a', reference);

        await container
            .read(adRewardRecoveryProvider.notifier)
            .acknowledgePresented(
              ownerUserId: 'user-a',
              status: _status(reference, AdRewardState.granted),
            );

        expect(repository.acknowledged, [reference]);
        expect(await store.readAll('user-a'), isEmpty);
        expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
      },
    );

    test('a discarded dialog leaves the server reward untouched', () async {
      final watched = _reference(1);
      repository.statuses[watched] = [_grantedStatus(watched)];
      await store.add('user-a', watched);
      final notifier = container.read(adRewardRecoveryProvider.notifier);
      await notifier.poll(ownerUserId: 'user-a', reference: watched);
      final queued = container
          .read(adRewardRecoveryProvider)
          .dialogQueue
          .single;

      notifier.discardDialog(queued);

      expect(container.read(adRewardRecoveryProvider).dialogQueue, isEmpty);
      expect(repository.acknowledged, isEmpty);
      expect((await store.readAll('user-a')).single.reference, watched);
    });
  });

  group('계정 격리', () {
    test('an account switch discards the earlier owner state', () async {
      final a = _reference(1);
      final b = _reference(2);
      repository.statuses[a] = [_grantedStatus(a)];
      repository.statuses[b] = [_grantedStatus(b)];
      final notifier = container.read(adRewardRecoveryProvider.notifier);
      await notifier.poll(ownerUserId: 'user-a', reference: a);

      owner = 'user-b';
      await notifier.poll(ownerUserId: 'user-b', reference: b);

      final state = container.read(adRewardRecoveryProvider);
      expect(state.activeUserId, 'user-b');
      expect(state.references, [b]);
      expect(state.dialogQueue.single.status.reference, b);
    });

    test('a gated A status answer cannot mutate B state', () async {
      final a = _reference(11);
      final b = _reference(12);
      final gate = Completer<void>();
      repository.statuses[a] = [_grantedStatus(a)];
      repository.statuses[b] = [_grantedStatus(b)];
      repository.statusGates[a] = gate;
      final notifier = container.read(adRewardRecoveryProvider.notifier);

      final stale = notifier.poll(ownerUserId: 'user-a', reference: a);
      await Future<void>.delayed(Duration.zero);
      owner = 'user-b';
      await notifier.poll(ownerUserId: 'user-b', reference: b);
      gate.complete();
      await stale;

      final state = container.read(adRewardRecoveryProvider);
      expect(state.activeUserId, 'user-b');
      expect(state.references, [b]);
      expect(state.dialogQueue.single.status.reference, b);
      expect(earnRecords.map((value) => value.reference), [b]);
    });

    test('A to B to A keeps each owner queue separate', () async {
      final a = _reference(21);
      final b = _reference(22);
      final a2 = _reference(23);
      repository.statuses[a] = [_grantedStatus(a)];
      repository.statuses[b] = [_grantedStatus(b)];
      repository.statuses[a2] = [_grantedStatus(a2)];
      final notifier = container.read(adRewardRecoveryProvider.notifier);

      await notifier.poll(ownerUserId: 'user-a', reference: a);
      owner = 'user-b';
      await notifier.poll(ownerUserId: 'user-b', reference: b);
      owner = 'user-a';
      await notifier.poll(ownerUserId: 'user-a', reference: a2);

      final state = container.read(adRewardRecoveryProvider);
      expect(state.activeUserId, 'user-a');
      expect(state.references, [a2]);
      expect(state.dialogQueue.map((value) => value.status.reference), [a2]);
    });

    test('a poll for a user who is not signed in does nothing', () async {
      final watched = _reference(1);
      repository.statuses[watched] = [_grantedStatus(watched)];
      owner = null;

      await container
          .read(adRewardRecoveryProvider.notifier)
          .poll(ownerUserId: 'user-a', reference: watched);

      expect(repository.reads, isEmpty);
      expect(container.read(adRewardRecoveryProvider).activeUserId, isNull);
      expect(earnRecords, isEmpty);
    });

    test('presenting for a signed-out owner is refused', () async {
      owner = null;

      await expectLater(
        container
            .read(adRewardRecoveryProvider.notifier)
            .acknowledgePresented(
              ownerUserId: 'user-a',
              status: _grantedStatus(_reference(1)),
            ),
        throwsStateError,
      );

      expect(earnRecords, isEmpty);
      expect(repository.acknowledged, isEmpty);
    });
  });
}
