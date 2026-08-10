import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/analytics/analytics.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/services/unfinished_purchase_source.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_analytics_dedup.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/mock_supabase.dart';

/// GA4 `purchase` 가 **매출 지표**라는 점에서 나오는 규칙들을 고정한다.
///
/// 세 가지가 서로 다른 사실이고, 셋을 섞으면 각각 다른 방식으로 돈이 틀린다:
///   1. 서버가 이 영수증을 이미 정산했는가 (`replayed`)
///   2. 이 클라이언트가 이미 GA4 로 보냈는가 (`PurchaseAnalyticsDedup`)
///   3. 이 스토어 이벤트가 새 과금인가 (`PurchaseDetails.status`)
/// (1)을 (2)의 증거로 쓰면 매출이 영구 누락되고, (3)을 무시하면 복원이
/// 매출로 잡힌다.
const _productId = 'STAR100';
const _userId = 'user-1';

class _MockInAppPurchaseService extends Mock implements InAppPurchaseService {
  int settledFinalizations = 0;

  @override
  Future<void> clearPendingPurchasesOnStartup() async {}

  @override
  Future<bool> finalizeSettledPurchase(PurchaseDetails purchaseDetails) async {
    settledFinalizations++;
    return true;
  }
}

class _SettlingVerification extends ReceiptVerificationService {
  _SettlingVerification(this.result);

  final PurchaseSettlementResultModel result;
  int verifications = 0;

  @override
  Future<String> getEnvironment() async => 'sandbox';

  @override
  Future<PurchaseSettlementResultModel> verifyReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async {
    verifications++;
    return result;
  }
}

/// 프로세스 재시작을 흉내 내려면 저장소는 남기고 인스턴스만 갈 수 있어야 한다.
class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage({Map<String, String>? seed})
    : _data = <String, String>{...?seed};

  final Map<String, String> _data;

  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      _data[key] ?? defaultValue;

  @override
  Future<void> saveData(String key, String value) async => _data[key] = value;

  @override
  Future<void> removeData(String key) async => _data.remove(key);

  @override
  Future<void> clearStorage() async => _data.clear();
}

/// 스캔 결과를 그대로 돌려주는 스윕 소스.
class _StubUnfinishedSource implements UnfinishedPurchaseSource {
  _StubUnfinishedSource(this.purchases);

  final List<PurchaseDetails> purchases;

  @override
  String get label => 'test/stub';

  @override
  Future<UnfinishedPurchaseScan> scan() async =>
      UnfinishedPurchaseScan(purchases: purchases);
}

/// 카탈로그 조회가 끝나지 않는 상황. 애널리틱스가 결제 UX 를 잡아먹지 않는지
/// 확인하는 데 쓴다.
class _NeverResolvingCatalogue {
  final Completer<List<ProductDetails>> completer =
      Completer<List<ProductDetails>>();
}

PurchaseDetails _transaction({
  required PurchaseStatus status,
  String? purchaseId = 'txn-$_productId',
}) => PurchaseDetails(
  productID: _productId,
  purchaseID: purchaseId,
  transactionDate: DateTime.utc(2027).millisecondsSinceEpoch.toString(),
  status: status,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'server',
    source: 'test',
  ),
);

void main() {
  late ProviderContainer container;
  late RecordingGa4Sink sink;
  late _MockInAppPurchaseService plugin;
  late _SettlingVerification verification;
  late PurchaseService service;
  late List<String> errors;
  late List<PurchaseSettlementResultModel> settlements;

  final wallet = WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.from(100),
    bonus: BigInt.zero,
    cotton: BigInt.zero,
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026, 2),
  );

  PurchaseSettlementResultModel settlement({
    bool replayed = false,
    bool replayCausedByRetry = false,
    String operationId = 'operation-1',
  }) => PurchaseSettlementResultModel(
    contractVersion: 'wallet.v1',
    operationId: operationId,
    replayed: replayed,
    replayCausedByRetry: replayCausedByRetry,
    baseStarAmount: BigInt.from(100),
    baseBonusAmount: BigInt.from(10),
    promotion: null,
    wallet: wallet,
  );

  final soldProduct = ProductDetails(
    id: _productId,
    title: 'Star Candy 100',
    description: '100 star candies',
    price: '1.99',
    rawPrice: 1.99,
    currencyCode: 'USD',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupMockSupabaseWithAuth({}, userId: _userId);
    PurchaseAnalyticsDedup.resetProcessCache();
    sink = RecordingGa4Sink();
    PicnicAnalytics.overrideInstance(PicnicAnalytics(sink: sink));
    errors = [];
    settlements = [];
  });

  tearDown(() {
    PurchaseAnalyticsDedup.resetProcessCache();
    PicnicAnalytics.resetInstance();
    tearDownMockSupabase();
  });

  /// 스토어 화면이 없는 상태로 결제 경로만 세운다. 이 테스트들이 보는 것은
  /// 전부 `PurchaseService` 안에서 결정된다.
  PurchaseService buildService({
    required PurchaseSettlementResultModel result,
    LocalStorage? analyticsStorage,
    FutureOr<List<ProductDetails>> Function()? catalogue,
    UnfinishedPurchaseSource? sweepSource,
  }) {
    container = ProviderContainer(
      overrides: [
        storeProductsProvider.overrideWithBuild(
          (ref, notifier) => (catalogue ?? () => [soldProduct])(),
        ),
      ],
    );
    addTearDown(container.dispose);

    plugin = _MockInAppPurchaseService();
    verification = _SettlingVerification(result);

    return PurchaseService(
      container: container,
      inAppPurchaseService: plugin,
      receiptVerificationService: verification,
      analyticsService: AnalyticsService(
        dedup: PurchaseAnalyticsDedup(
          storage: analyticsStorage ?? _FakeLocalStorage(),
        ),
      ),
      duplicatePreventionService: DuplicatePreventionService.forContainer(
        container,
      ),
      onPurchaseUpdate: (_) {},
      unfinishedPurchaseSource: sweepSource,
      sweepOnStart: false,
    );
  }

  Future<void> deliver(PurchaseDetails transaction) =>
      service.handleOptimizedPurchase(
        transaction,
        (result) async => settlements.add(result),
        errors.add,
        isActualPurchase: true,
      );

  group('정산 재전달과 발송 이력은 서로 다른 사실이다', () {
    test('최초 실행이 발송 전에 죽었다면, 재전달된 정산도 매출로 보낸다', () async {
      // 재현: 서버는 정산했는데 응답이 유실됐거나 프로세스가 죽어서 최초
      // 실행이 GA4 발송 전에 끝난다. 다음 실행이 같은 구매를 재전달받으면
      // replayed=true / replayCausedByRetry=false 다. 예전에는 그 조합만으로
      // 발송을 건너뛰었고, 조건이 영구적이므로 그 결제는 GA4 에서 통째로
      // 사라졌다.
      service = buildService(
        result: settlement(replayed: true, replayCausedByRetry: false),
      );

      await deliver(_transaction(status: PurchaseStatus.purchased));

      expect(
        sink.purchases.map((p) => p.transactionId),
        ['txn-$_productId'],
        reason:
            '이 클라이언트는 이 결제를 한 번도 보낸 적이 없다 - 서버가 정산을 '
            '되돌려줬다는 사실은 우리가 보냈다는 증거가 아니다',
      );
      expect(sink.purchases.single.value, 1.99);
      expect(settlements, hasLength(1));
      expect(errors, isEmpty);
      expect(plugin.settledFinalizations, 1);
    });

    test('이전 실행이 이미 보낸 재전달은 다시 보내지 않는다', () async {
      // 재전달 게이트를 걷어내도 중복이 새지 않는다는 반대쪽 고정. 판정
      // 근거는 발송 이력(영속 dedup 기록)이지 replayed 플래그가 아니다.
      service = buildService(
        result: settlement(replayed: true),
        analyticsStorage: _FakeLocalStorage(
          seed: {PurchaseAnalyticsDedup.storageKey: 'txn-$_productId'},
        ),
      );

      await deliver(_transaction(status: PurchaseStatus.purchased));

      expect(sink.purchases, isEmpty);
      expect(
        settlements,
        hasLength(1),
        reason: '애널리틱스를 건너뛴 것이지 정산을 건너뛴 것이 아니다',
      );
    });

    test('같은 결제가 이번 실행에서 두 번 흘러도 한 번만 보낸다', () async {
      service = buildService(result: settlement());

      await deliver(_transaction(status: PurchaseStatus.purchased));
      await deliver(_transaction(status: PurchaseStatus.purchased));

      expect(sink.purchases, hasLength(1));
    });
  });

  group('restored 는 매출이 아니다', () {
    test('스토어 콜백으로 온 restored 는 purchase 를 보내지 않는다', () async {
      // 오늘의 두 전달 경로는 restored 를 여기까지 보내지 않는다:
      //   - 스토어 화면: PurchaseCampaignAttemptRegistry.bind 가 restored 를
      //     무조건 null 로 돌려주므로(purchase_campaign_attempt.dart:86)
      //     _processActivePurchase 에 닿지 못한다. 그 아래
      //     PurchaseHelper.shouldProcessActivePurchaseIOS 는 1·3단계에서
      //     restored 를 통과시키지만, 거기까지 오지 못한다.
      //   - 무화면 경로: GlobalPurchaseListener 가 restored 를 별도 분기로
      //     걸러낸다(global_purchase_listener.dart:437).
      // 그래서 이 게이트는 방어선이다. 두 층 위의 두 조건에 의존해서 지켜지는
      // 불변식이라 어느 한쪽이 바뀌면 조용히 깨지고, 깨진 결과는 매출 과대
      // 계상이다. PurchaseService.handlePurchase 는 지금도 restored 를 성공
      // 처리로 라우팅한다(purchase_service.dart:252) - 아래 테스트가 그쪽을
      // 직접 고정한다.
      service = buildService(result: settlement());

      await deliver(_transaction(status: PurchaseStatus.restored));

      expect(sink.purchases, isEmpty);
      expect(
        settlements,
        hasLength(1),
        reason:
            '결제 로직은 그대로다 - 게이트는 애널리틱스 발송에만 걸린다. '
            '복원건이라도 서버가 정산했으면 적립과 완료 처리는 계속 한다',
      );
      expect(plugin.settledFinalizations, 1);
      expect(errors, isEmpty);
    });

    test('스토어 콜백으로 온 purchased 는 보낸다', () async {
      service = buildService(result: settlement());

      await deliver(_transaction(status: PurchaseStatus.purchased));

      expect(sink.purchases, hasLength(1));
    });

    test('handlePurchase 가 restored 를 성공 처리로 보내도 매출로는 안 잡힌다', () async {
      // handlePurchase 의 switch 는 purchased 와 restored 를 같은 분기에 묶어
      // _handleSuccessfulPurchase 로 보낸다. 즉 restored 를 "성공한 구매"로
      // 다루겠다고 코드가 직접 말하는 유일한 자리다. 적립은 그대로 두되
      // 매출 이벤트만 막는다.
      service = buildService(result: settlement());
      var successes = 0;

      await service.handlePurchase(
        _transaction(status: PurchaseStatus.restored),
        () => successes++,
        errors.add,
      );

      expect(sink.purchases, isEmpty);
      expect(successes, 1, reason: '구매 처리 자체는 건드리지 않는다');
      expect(errors, isEmpty);
    });

    test('handlePurchase 가 purchased 를 처리하면 매출로 잡힌다', () async {
      service = buildService(result: settlement());

      await service.handlePurchase(
        _transaction(status: PurchaseStatus.purchased),
        () {},
        errors.add,
      );

      expect(sink.purchases, hasLength(1));
    });

    test('복구 스윕은 상태 라벨과 무관하게 보낸다', () async {
      // 스윕이 다루는 것은 스토어가 아직 미완료로 들고 있는 **과금된**
      // 트랜잭션이고, 그것이 매출이라는 증거는 상태 라벨이 아니라 서버
      // 정산이다. 여기에 purchased 게이트를 걸면 스윕이 복구하려던 매출이
      // 그대로 사라진다 (Android 의 queryPastPurchases 는 "과거 구매" 조회의
      // 결과를 돌려주므로 라벨을 권위로 삼을 수 없다).
      final swept = _transaction(status: PurchaseStatus.restored);
      service = buildService(
        result: settlement(),
        sweepSource: _StubUnfinishedSource([swept]),
      );

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );

      expect(report.outcome, PurchaseSweepOutcome.completed);
      expect(report.settled, 1);
      expect(sink.purchases.map((p) => p.transactionId), ['txn-$_productId']);
    });

    test('스윕과 스토어 콜백이 같은 결제를 처리해도 한 번만 보낸다', () async {
      final swept = _transaction(status: PurchaseStatus.purchased);
      service = buildService(
        result: settlement(),
        sweepSource: _StubUnfinishedSource([swept]),
      );

      await Future.wait([
        deliver(_transaction(status: PurchaseStatus.purchased)),
        service.sweepUnfinishedPurchases(trigger: PurchaseSweepTrigger.manual),
      ]);

      expect(
        sink.purchases,
        hasLength(1),
        reason:
            '발송 지점이 둘이라 동시 진입이 가능하다 - dedup 예약이 첫 await '
            '앞에 있어야 둘 중 하나만 통과한다',
      );
    });
  });

  group('애널리틱스는 결제 UX 를 잡아먹지 않는다', () {
    test('카탈로그 조회가 멈춰 있어도 정산 결과는 먼저 전달된다', () async {
      // 예전에는 검증 직후·정산 표시 전에 애널리틱스를 timeout 없이 await
      // 했다. 카탈로그 provider 나 네이티브 Firebase 채널이 정체되면 그만큼
      // 지갑 반영·영수증·스피너 해제가 통째로 밀린다.
      final stuck = _NeverResolvingCatalogue();
      addTearDown(() {
        if (!stuck.completer.isCompleted) {
          stuck.completer.complete(<ProductDetails>[]);
        }
      });
      service = buildService(
        result: settlement(),
        catalogue: () => stuck.completer.future,
      );

      final running = deliver(_transaction(status: PurchaseStatus.purchased));

      // 정산 콜백은 애널리틱스를 기다리지 않는다.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(
        settlements,
        hasLength(1),
        reason: '지갑 반영·영수증은 애널리틱스보다 앞에서 끝나야 한다',
      );

      stuck.completer.complete(<ProductDetails>[soldProduct]);
      await running;
      expect(errors, isEmpty);
    });

    test('카탈로그가 비어도 정산 purchase payload를 남긴다', () async {
      // 카탈로그 실패는 currency/value를 못 줄 뿐, 이미 확정된 거래와
      // 적립 수량을 없애는 근거가 아니다.
      service = buildService(
        result: settlement(),
        catalogue: () => <ProductDetails>[],
      );

      await deliver(_transaction(status: PurchaseStatus.purchased));

      expect(sink.purchases, hasLength(1));
      expect(sink.purchases.single.currency, isNull);
      expect(sink.purchases.single.value, isNull);
      expect(settlements, hasLength(1));
      expect(errors, isEmpty);
      expect(plugin.settledFinalizations, 1);
    });
  });
}
