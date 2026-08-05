import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/services/global_purchase_listener.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/services/unfinished_purchase_source.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupMockSupabaseWithAuth(const {}, userId: 'test-user-id');
  });

  tearDown(tearDownMockSupabase);

  /// [PurchaseSurfaceRegistration]과 그 [GlobalPurchaseListener]를 함께
  /// 만든다. `source`는 스캔 결과를, `plugin`은 finalize/complete 호출을
  /// 관찰한다.
  ({GlobalPurchaseListener listener, _FakePlugin plugin}) build(
    _FakeUnfinishedSource source, {
    DateTime Function()? clock,
    Duration resumeSweepInterval = const Duration(minutes: 5),
  }) {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final plugin = _FakePlugin();
    final listener = GlobalPurchaseListener(
      container: container,
      purchaseServiceFactory: (c, onPurchaseUpdate) => PurchaseService(
        container: c,
        inAppPurchaseService: plugin,
        receiptVerificationService: _FakeVerification(),
        analyticsService: AnalyticsService(),
        duplicatePreventionService: DuplicatePreventionService.forContainer(
          c,
        ),
        onPurchaseUpdate: onPurchaseUpdate,
        unfinishedPurchaseSource: source,
        sweepOnStart: false,
        clock: clock ?? DateTime.now,
        resumeSweepInterval: resumeSweepInterval,
      ),
    );
    addTearDown(listener.dispose);
    return (listener: listener, plugin: plugin);
  }

  group('GlobalPurchaseListener surface detach', () {
    test(
        'detaching the last surface triggers a resume sweep instead of '
        'waiting for the next real app resume', () async {
      final source = _FakeUnfinishedSource(const UnfinishedPurchaseScan());
      final built = build(source);

      final registration = built.listener.attachSurface((_) {});
      expect(
        source.scans,
        0,
        reason: '스토어 화면이 떠 있는 동안은 재개 스윕이 생략된다(기존 동작)',
      );

      registration.detach();
      // fire-and-forget 스윕이 돌 시간을 준다.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        source.scans,
        greaterThan(0),
        reason:
            '스토어 화면을 벗어나는 순간이, 화면이 떠 있는 동안 놓쳤을 수 '
            '있는 리컨사일을 되찾을 첫 기회여야 한다 - 실제 앱 재개까지 '
            '기다리면, 그 사이 서버 장애가 있었을 경우 사용자가 화면을 '
            '벗어난 뒤에도 한참 지나야 재시도된다',
      );
    });

    test(
        'detaching an already-detached registration is a safe no-op (does '
        'not crash, does not sweep twice)', () async {
      final source = _FakeUnfinishedSource(const UnfinishedPurchaseScan());
      final built = build(source);

      final registration = built.listener.attachSurface((_) {});
      registration.detach();
      registration.detach(); // 두 번째 호출은 안전해야 한다(identity 체크)

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        source.scans,
        1,
        reason: '이미 해제된 등록을 다시 detach 해도 스윕이 중복으로 도는 '
            '일은 없어야 한다',
      );
    });
  });

  group('GlobalPurchaseListener queue eviction', () {
    test(
        'eviction while no surface is mounted triggers an immediate manual '
        'sweep', () async {
      final source = _FakeUnfinishedSource(const UnfinishedPurchaseScan());
      final built = build(source);
      addTearDown(() => ReceiptQueueService().onItemsEvicted = null);

      expect(ReceiptQueueService().onItemsEvicted, isNotNull);
      ReceiptQueueService().onItemsEvicted!();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        source.scans,
        greaterThan(0),
        reason: '화면이 없으면 잘린 항목의 스토어 리컨사일을 다음 콜드스타트/'
            '재개까지 미룰 이유가 없다',
      );
    });

    test(
        'eviction while a surface IS mounted does NOT sweep immediately - it '
        'waits for the screen to close', () async {
      final source = _FakeUnfinishedSource(const UnfinishedPurchaseScan());
      final built = build(source);
      addTearDown(() => ReceiptQueueService().onItemsEvicted = null);

      final registration = built.listener.attachSurface((_) {});

      ReceiptQueueService().onItemsEvicted!();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        source.scans,
        0,
        reason:
            '스토어 화면이 진행 중인 자체 복원 정리와 경합할 수 있으므로, '
            '화면이 떠 있는 동안은 eviction 이 스윕을 걸어서는 안 된다 - '
            '이게 기존 sweepOnResume() 의 hasSurface 가드와 같은 불변식이다',
      );

      registration.detach();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        source.scans,
        greaterThan(0),
        reason: '화면을 벗어나면 미뤄뒀던 리컨사일 기회가 detach 트리거로 '
            '살아나야 한다(위 detach 그룹과 동일한 경로)',
      );
    });

    test(
        'a pending eviction reconcile survives detach even when the resume '
        'throttle would otherwise block it', () async {
      final source = _FakeUnfinishedSource(const UnfinishedPurchaseScan());
      final now = DateTime.utc(2026, 8, 4, 12);
      final built = build(
        source,
        clock: () => now,
        resumeSweepInterval: const Duration(minutes: 5),
      );
      addTearDown(() => ReceiptQueueService().onItemsEvicted = null);

      // 1) 화면을 한 번 열었다 닫아 재개 스윕을 이미 소진시킨다(스로틀
      // 기준 시각을 지금으로 고정) - 같은 시각에 재개 트리거로는 다시
      // 스윕이 안 돈다.
      final firstRegistration = built.listener.attachSurface((_) {});
      firstRegistration.detach();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(source.scans, 1);

      // 2) 화면이 다시 열린 동안 eviction 이 일어난다(pending 으로 남는다).
      final secondRegistration = built.listener.attachSurface((_) {});
      ReceiptQueueService().onItemsEvicted!();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(source.scans, 1, reason: '화면이 떠 있는 동안은 여전히 미뤄야 한다');

      // 3) 같은 시각에(스로틀이 아직 안 풀렸다) 화면을 닫는다.
      secondRegistration.detach();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        source.scans,
        2,
        reason:
            '보류해 둔 eviction 리컨사일은 detach 시점에 실제로 시도돼야 '
            '한다 - 일반 재개 스윕(resume 트리거)은 5분 스로틀에 걸려 '
            '아무 일도 안 하지만, eviction 은 자체적으로 즉시 시도를 '
            '약속했으므로(manual 트리거로) 스로틀에 막혀 조용히 사라지면 '
            '안 된다',
      );
    });

    test(
        'an eviction that races a concurrent sweep stays pending and is '
        'picked up by the next sweepOnResume() call, not just the next '
        'detach', () async {
      final scanGate = Completer<UnfinishedPurchaseScan>();
      final source = _FakeUnfinishedSource.controlled(scanGate.future);
      final built = build(source);
      addTearDown(() => ReceiptQueueService().onItemsEvicted = null);

      // 1) purchaseService 를 직접 통해 스윕 하나를 점유시킨다 - sweepOnColdStart()
      // 를 쓰면 그 안의 pending-체크용 await 때문에 이 테스트가 만들려는 "이미
      // 스윕이 진행 중"인 상태를 동기적으로 보장할 수 없다(eviction 쪽이 먼저
      // _sweepInFlight 를 선점해버리는 경합이 생긴다).
      final occupying = built.listener.purchaseService.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(source.scans, 1, reason: '점유용 스윕이 스캔까지 도달했다');

      // 2) 화면 없이 eviction 이 일어난다 - 스윕이 이미 진행 중이라
      // manual 시도는 concurrent 로 막힌다.
      ReceiptQueueService().onItemsEvicted!();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        source.scans,
        1,
        reason: '점유용 스윕만 스토어를 조회했다 - concurrent 로 막힌 '
            'eviction 시도는 스캔까지 가지 않는다',
      );

      // 3) 점유하던 스윕을 완료시킨다.
      scanGate.complete(const UnfinishedPurchaseScan());
      await occupying;

      // 4) detach 는 전혀 없었다 - 다음으로 오는 기회는 sweepOnResume().
      await built.listener.sweepOnResume();

      expect(
        source.scans,
        2,
        reason:
            'concurrent 로 놓친 eviction 리컨사일은 다음 detach 뿐 아니라 '
            'sweepOnResume()/sweepOnColdStart() 중 먼저 오는 어느 쪽이든 '
            '이어받아야 한다 - detach 만 본다면 사용자가 스토어 화면을 '
            '아예 열지 않은 채로도 앱을 계속 쓰는 동안 이 eviction 은 '
            '영원히 재시도되지 않는다',
      );
    });
  });

  group('GlobalPurchaseListener dispose lifecycle', () {
    test('dispose clears its own onItemsEvicted callback from the '
        'ReceiptQueueService singleton', () async {
      final source = _FakeUnfinishedSource(const UnfinishedPurchaseScan());
      final built = build(source);

      expect(ReceiptQueueService().onItemsEvicted, isNotNull);

      built.listener.dispose();

      expect(
        ReceiptQueueService().onItemsEvicted,
        isNull,
        reason:
            'ReceiptQueueService 는 싱글턴이다 - dispose 된 리스너의 콜백이 '
            '그대로 남으면, 다음 eviction 이 이미 정리된 purchaseService 를 '
            '가리키는 죽은 콜백을 부른다',
      );
    });

    test(
        "dispose does NOT clear a newer listener's callback (only its own)",
        () async {
      final sourceA = _FakeUnfinishedSource(const UnfinishedPurchaseScan());
      final builtA = build(sourceA);

      final sourceB = _FakeUnfinishedSource(const UnfinishedPurchaseScan());
      final builtB = build(sourceB);
      // build() 의 listener 는 각각 addTearDown 으로 자동 dispose 되므로,
      // 순서를 명시적으로 재현하기 위해 A 를 먼저 수동으로 dispose 한다.

      final callbackAfterB = ReceiptQueueService().onItemsEvicted;
      expect(callbackAfterB, isNotNull);

      builtA.listener.dispose();

      expect(
        ReceiptQueueService().onItemsEvicted,
        same(callbackAfterB),
        reason:
            '더 이상 살아있지 않은 listener A 를 dispose 해도, 그 뒤에 새로 '
            '만들어진 listener B 가 등록한 콜백을 지워서는 안 된다 - 자기 '
            '것이 아니면 손대지 않는다',
      );

      builtB.listener.dispose();
    });
  });

  group('GlobalPurchaseListener sweep aborts if a new surface attaches '
      'mid-flight', () {
    test(
        'a detach-triggered sweep backs off before verifying/finishing '
        'anything if a new surface attaches while the store scan is still '
        'in flight', () async {
      final scanGate = Completer<UnfinishedPurchaseScan>();
      final source = _FakeUnfinishedSource.controlled(scanGate.future);
      final built = build(source);

      final firstRegistration = built.listener.attachSurface((_) {});
      firstRegistration.detach(); // sweepOnResume() 시작, scan() 은 아직 안 끝남

      // 아직 scan() 이 안 끝난 사이에 새 화면이 붙는다(빠른 route 전환).
      built.listener.attachSurface((_) {});

      // 이제 scan() 을 완료시킨다 - 미완료 구매 1건을 들고.
      scanGate.complete(
        UnfinishedPurchaseScan(purchases: [_unfinishedPurchase()]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        built.plugin.finalized,
        0,
        reason:
            'scan() 이 끝났을 때 이미 새 화면이 붙어 있었다 - 그 화면의 '
            '자체 복원 로직과 경합하지 않도록, 검증/완료 처리로 진행하지 '
            '말고 트랜잭션을 그대로 보존해야 한다',
      );
    });
  });
}

PurchaseDetails _unfinishedPurchase() {
  final details = PurchaseDetails(
    purchaseID: 'tx-race',
    productID: 'STAR100',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'app-receipt',
      source: 'test',
    ),
    transactionDate: '1785228000000',
    status: PurchaseStatus.purchased,
  );
  details.pendingCompletePurchase = true;
  return details;
}

class _FakeUnfinishedSource implements UnfinishedPurchaseSource {
  _FakeUnfinishedSource(UnfinishedPurchaseScan scan) : _scanFuture = null, _scan = scan;

  /// scan() 이 끝나는 시점을 테스트가 직접 통제할 수 있게 하는 생성자.
  _FakeUnfinishedSource.controlled(Future<UnfinishedPurchaseScan> scanFuture)
      : _scanFuture = scanFuture,
        _scan = null;

  final UnfinishedPurchaseScan? _scan;
  final Future<UnfinishedPurchaseScan>? _scanFuture;

  int scans = 0;

  @override
  String get label => 'fake';

  @override
  Future<UnfinishedPurchaseScan> scan() async {
    scans++;
    return _scanFuture ?? _scan!;
  }
}

class _FakePlugin extends Mock implements InAppPurchaseService {
  int completed = 0;
  int finalized = 0;

  @override
  void initialize(Function(List<PurchaseDetails>) onPurchaseUpdate) {}

  @override
  Future<void> clearPendingPurchasesOnStartup() async {}

  @override
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    completed++;
  }

  @override
  Future<void> finalizeSettledPurchase(PurchaseDetails purchaseDetails) async {
    finalized++;
  }
}

class _FakeVerification extends ReceiptVerificationService {
  @override
  Future<String> getEnvironment() async => 'sandbox';

  @override
  Future<PurchaseSettlementResultModel> verifyReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async =>
      PurchaseSettlementResultModel(
        contractVersion: 'wallet.v1',
        operationId: 'operation',
        replayed: true,
        baseStarAmount: BigInt.from(200),
        baseBonusAmount: BigInt.zero,
        promotion: null,
        wallet: WalletSummaryModel(
          contractVersion: 'wallet.v1',
          star: BigInt.from(1600),
          bonus: BigInt.from(81),
          cotton: BigInt.zero,
          cottonExpiringAmount: BigInt.zero,
          cottonNextExpiresAt: null,
          snapshotAt: DateTime.utc(2026, 7),
        ),
      );
}
