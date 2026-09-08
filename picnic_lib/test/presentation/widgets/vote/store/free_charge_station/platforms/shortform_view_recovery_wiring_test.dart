import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/data/storage/pending_ad_reward_store.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_flow.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_session.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform.dart';

/// 시청 콜백이 돌아왔을 때 **광고 화면은 이미 사라져 있을 수 있다.**
///
/// `AdPlatform.ref` 는 `WidgetRef` 다. 사용자가 영상이 끝나자마자 광고를 닫으면
/// 이 플랫폼을 만든 Consumer 가 dispose 되고, 그 뒤의 `ref.read` 는 던진다.
/// `InternalShortformViewRecoveryFlow` 는 통계 경로의 예외를 삼키도록 되어 있어
/// (보상 흐름을 막지 않기 위해), 그 예외는 **서버가 이미 확정한 GRANTED 가
/// 조용히 사라지는** 형태로만 드러난다.
///
/// 그래서 여기서는 flow 를 단위 테스트하지 않는다 — 실제
/// [ShortformInternalPlatform.buildViewRecoveryFlow] 로 배선을 만들고, 그
/// Consumer 를 진짜로 dispose 시킨 다음 지연된 시청 응답을 완료시킨다.
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

class _Repository implements AdRewardApi {
  final statuses = <AdRewardReference, AdRewardStatusModel>{};
  final acknowledged = <AdRewardReference>[];
  final reads = <AdRewardReference>[];

  @override
  Future<AdRewardStatusModel> getStatus(AdRewardReference reference) async {
    reads.add(reference);
    return statuses[reference]!;
  }

  @override
  Future<void> acknowledge(AdRewardReference reference) async =>
      acknowledged.add(reference);

  @override
  Future<AdRewardPageModel> listUnacknowledged({
    String? cursor,
    int limit = 20,
  }) async => throw StateError('목록 조회는 개편에서 제거됐다');

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

const _impressionId = '00000000-0000-4000-8000-000000000501';
const _reference = AdRewardReference(
  type: AdRewardReferenceType.internalImpression,
  id: _impressionId,
);

Map<String, dynamic> _wallet() => {
  'contract_version': 'wallet.v1',
  'star': '0',
  'bonus': '0',
  'cotton': '3',
  'cotton_expiring_amount': '3',
  'cotton_next_expires_at': null,
  'snapshot_at': '2026-09-08T00:00:00.000Z',
};

Map<String, dynamic> _viewResponse(String state, {bool withGrant = true}) => {
  'ok': true,
  'reward_added': 0,
  'impression_id': _impressionId,
  'new_bonus': null,
  'reward': {
    'reference': {'type': 'INTERNAL_IMPRESSION', 'id': _impressionId},
    'state': state,
    'grant': withGrant
        ? {
            'id': 'grant-1',
            'currency': 'COTTON_CANDY',
            'amount': '3',
            'granted_at': '2026-09-08T00:00:00.000Z',
            'expires_at': '2026-10-08T00:00:00.000Z',
          }
        : null,
    'wallet': _wallet(),
    'snapshot_at': '2026-09-08T00:00:00.000Z',
  },
};

AdRewardStatusModel _status(AdRewardState state) => AdRewardStatusModel(
  reference: _reference,
  state: state,
  grant: null,
  wallet: WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.zero,
    bonus: BigInt.zero,
    cotton: BigInt.zero,
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026),
  ),
  snapshotAt: DateTime.utc(2026),
);

void main() {
  late _Repository repository;
  late PendingAdRewardStore store;
  late List<AdRewardStatusModel> earnRecords;
  late String? owner;
  late ProviderContainer container;

  setUp(() {
    repository = _Repository();
    store = PendingAdRewardStore(_MemoryStorage());
    earnRecords = [];
    owner = 'user-a';
    container = ProviderContainer(
      overrides: [
        adRewardRepositoryProvider.overrideWithValue(repository),
        pendingAdRewardStoreProvider.overrideWithValue(store),
        adRewardOwnerReaderProvider.overrideWithValue(() => owner),
        adRewardDelayProvider.overrideWithValue((_) async {}),
        adRewardEarnRecorderProvider.overrideWithValue((status) async {
          earnRecords.add(status);
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  /// 실제 [ShortformInternalPlatform] 을 살아 있는 Consumer 의 `WidgetRef` 로
  /// 만든다. 광고 화면이 떠 있는 동안의 상태다.
  Future<(ShortformInternalPlatform, WidgetRef)> mountPlatform(
    WidgetTester tester,
  ) async {
    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return (
      ShortformInternalPlatform(
        capturedRef,
        capturedContext,
        'internal',
        AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 1),
        ),
      ),
      capturedRef,
    );
  }

  /// 광고 화면을 닫는다. 이 시점 이후로 `WidgetRef` 는 죽는다.
  Future<void> closeAd(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  InternalShortformViewFlow gatedView({
    required Completer<Map<String, dynamic>> gate,
    required String? Function() currentOwner,
    required InternalShortformRewardSession session,
  }) => InternalShortformViewFlow(
    session: session,
    currentOwner: currentOwner,
    invokeCallback: () => gate.future,
    parse: InternalShortformViewResponse.fromJson,
  );

  Future<InternalShortformRewardSession> boundSession() async {
    final session = InternalShortformRewardSession();
    await session.bindIssued(
      owner: 'user-a',
      issuedReference: _reference,
      persist: (_, _) async {},
    );
    return session;
  }

  testWidgets('a disposed Consumer really does kill its WidgetRef', (
    tester,
  ) async {
    // 이 테스트가 없으면 아래 회귀들이 "그냥 통과"하는 건지 실제 경계를 넘는
    // 건지 구분되지 않는다.
    final (_, ref) = await mountPlatform(tester);
    await closeAd(tester);

    expect(
      () => ref.read(adRewardRecoveryProvider.notifier),
      throwsA(anything),
      reason: 'dispose 된 Consumer 의 WidgetRef 는 read 에서 던진다',
    );
  });

  testWidgets(
    'a grant confirmed after the ad is closed still reaches the outbox',
    (tester) async {
      final (platform, _) = await mountPlatform(tester);
      final gate = Completer<Map<String, dynamic>>();
      final flow = platform.buildViewRecoveryFlow(
        gatedView(
          gate: gate,
          currentOwner: () => owner,
          session: await boundSession(),
        ),
      );

      // 영상이 끝나 시청 콜백이 나간 뒤, 응답을 기다리는 동안 사용자가 광고를
      // 닫는다. 서버는 그 뒤에 GRANTED 를 돌려준다.
      final reporting = flow.report();
      await closeAd(tester);
      gate.complete(_viewResponse('GRANTED'));
      final response = await reporting;

      expect(response.reward!.state, AdRewardState.granted);
      expect(
        earnRecords.map((value) => value.reference),
        [_reference],
        reason: '앱이 관측한 GRANTED 는 광고 화면 수명과 무관하게 기록돼야 한다',
      );
      expect(earnRecords.single.grant!.amount, BigInt.from(3));
    },
  );

  testWidgets('a pending reward still starts polling after the ad is closed', (
    tester,
  ) async {
    final (platform, _) = await mountPlatform(tester);
    repository.statuses[_reference] = _status(AdRewardState.denied);
    final gate = Completer<Map<String, dynamic>>();
    final flow = platform.buildViewRecoveryFlow(
      gatedView(
        gate: gate,
        currentOwner: () => owner,
        session: await boundSession(),
      ),
    );

    final reporting = flow.report();
    await closeAd(tester);
    gate.complete(_viewResponse('PENDING', withGrant: false));
    await reporting;
    // poll 은 unawaited 로 떠난다. 사다리가 한 바퀴 돌 틈을 준다.
    for (var i = 0; i < 6; i++) {
      await tester.pump(Duration.zero);
    }

    expect(repository.reads, [
      _reference,
    ], reason: 'poll 콜백도 같은 WidgetRef 문제를 갖고 있었다');
  });

  testWidgets(
    'a grant whose owner changed while the ad closed is not recorded',
    (tester) async {
      final (platform, _) = await mountPlatform(tester);
      final gate = Completer<Map<String, dynamic>>();
      final flow = platform.buildViewRecoveryFlow(
        gatedView(
          gate: gate,
          // 발급 소유자와 현재 소유자가 갈리면 시청 응답 자체가 거부된다.
          currentOwner: () => owner,
          session: await boundSession(),
        ),
      );

      final reporting = flow.report();
      await closeAd(tester);
      owner = 'user-b';
      gate.complete(_viewResponse('GRANTED'));

      await expectLater(reporting, throwsA(isA<StateError>()));
      expect(earnRecords, isEmpty, reason: '남의 계정 적립을 기록하지 않는다');
    },
  );

  testWidgets('a repeated confirmation after the ad closed records once', (
    tester,
  ) async {
    final (platform, _) = await mountPlatform(tester);
    final session = await boundSession();
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    final flows = [
      platform.buildViewRecoveryFlow(
        gatedView(gate: first, currentOwner: () => owner, session: session),
      ),
      platform.buildViewRecoveryFlow(
        gatedView(gate: second, currentOwner: () => owner, session: session),
      ),
    ];

    final reporting = flows.map((flow) => flow.report()).toList();
    await closeAd(tester);
    first.complete(_viewResponse('GRANTED'));
    second.complete(_viewResponse('GRANTED'));
    await Future.wait(reporting);

    expect(earnRecords, hasLength(1), reason: '중복 콜백은 한 번만 집계한다');
  });
}
