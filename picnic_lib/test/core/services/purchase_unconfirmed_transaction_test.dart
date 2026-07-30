import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_processor.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_supabase.dart';

/// 미확정(unconfirmed) 구매의 트랜잭션 생명주기.
///
/// completePurchase/finalizeSettledPurchase는 영수증의 마지막 재시도 경로를
/// 끊는 행위다. 검증이 일시 실패한 구매에 호출되면 과금된 영수증이
/// 소멸하고(과금-미적립), 영구 거부된 구매에 호출되지 않으면 결코 성공할
/// 수 없는 영수증이 재전달 루프를 영원히 돈다. 분류기 숫자만이 아니라
/// 실제 finally 게이팅이 그 정책대로 움직이는지를 고정한다.
void main() {
  const productId = 'STAR100';
  const userId = 'user-1';

  late _CountingPlugin plugin;
  late ReceiptVerificationService verification;
  late PurchaseService service;
  late ProviderContainer container;
  late DuplicatePreventionService duplicates;
  late List<String> errors;
  late int alreadySettledReports;

  PurchaseDetails transaction() {
    final details = PurchaseDetails(
      purchaseID: 'tx-1',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server-receipt',
        source: 'test',
      ),
      transactionDate: '1785228000000',
      status: PurchaseStatus.purchased,
    );
    details.pendingCompletePurchase = true;
    return details;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupMockSupabaseWithAuth(const {}, userId: userId);
    errors = [];
    alreadySettledReports = 0;
  });

  tearDown(tearDownMockSupabase);

  /// Wires a real [PurchaseService] the way `PurchaseStarCandyState` does, with
  /// only the two collaborators that leave the device replaced.
  Future<void> build(
    WidgetTester tester,
    ReceiptVerificationService stub,
  ) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Named for analytics after the receipt verifies. Overridden so the
          // catalogue lookup cannot reach the store plugin from a test host.
          storeProductsProvider.overrideWithBuild(
            (ref, notifier) => <ProductDetails>[],
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            container = ProviderScope.containerOf(context, listen: false);
            return const SizedBox();
          },
        ),
      ),
    );

    verification = stub;
    plugin = _CountingPlugin();
    duplicates = DuplicatePreventionService(capturedRef);
    service = PurchaseService(
      container: container,
      inAppPurchaseService: plugin,
      receiptVerificationService: verification,
      analyticsService: AnalyticsService(),
      duplicatePreventionService: duplicates,
      onPurchaseUpdate: (_) {},
    );
  }

  Future<void> run(WidgetTester tester, Object failure) async {
    await build(tester, _ThrowingVerification(failure));
    await service.handleOptimizedPurchase(
      transaction(),
      (_) async {},
      errors.add,
      isActualPurchase: true,
      onAlreadySettled: () async => alreadySettledReports++,
    );
  }

  testWidgets('retryable failure keeps the transaction for redelivery',
      (tester) async {
    await run(
      tester,
      FunctionException(status: 503, details: null, reasonPhrase: 'test'),
    );
    expect(plugin.finalized, 0,
        reason: '일시 실패에 정리하면 과금된 영수증이 소멸한다');
    expect(plugin.completed, 0,
        reason: 'finish/consume 없이 남겨야 재전달/큐가 재시도할 수 있다');
  });

  testWidgets(
      'even a permanent rejection (422) never destroys the store transaction',
      (tester) async {
    await run(
      tester,
      FunctionException(status: 422, details: null, reasonPhrase: 'test'),
    );
    expect(plugin.finalized, 0,
        reason: '오판 시 과금 영수증이 소멸하고, Android는 미승인 구매의 '
            '3일 자동 환불 구제책까지 차단된다 - 422는 클라이언트 큐 '
            '재전송 중단에만 쓰인다');
    expect(plugin.completed, 0);
  });

  testWidgets('a duplicate whose grant is confirmed finalizes the transaction',
      (tester) async {
    await run(
      tester,
      ReusedPurchaseException(message: 'duplicate', grantConfirmed: true),
    );
    expect(plugin.finalized, 1,
        reason: '지급 확정 중복(멱등 캐시 히트 포함)은 finalize해야 정산 '
            '성공 후 finish만 실패한 트랜잭션이 림보에 갇히지 않는다');
  });

  testWidgets('a duplicate whose grant is confirmed is reported as a '
      'settlement, not an error', (tester) async {
    // 1.3.0 internal beta, iOS: a product whose first settlement failed
    // server-side and was settled afterwards kept its buy button spinning.
    // Every re-delivery of the preserved transaction hit the persisted iOS JWS
    // idempotency cache, which throws grantConfirmed: true - and that was
    // reported through onError, so the store's error branch left the attempt
    // registered (the tile stays `isLoading`), showed "이전 거래 처리 중" for
    // candy the user already owned, and armed a 60s duplicate cooldown.
    await run(
      tester,
      ReusedPurchaseException(message: 'duplicate', grantConfirmed: true),
    );

    expect(alreadySettledReports, 1,
        reason: '서버가 지급까지 확인한 중복은 성공 경로로 보고되어야 한다 '
            '- 스피너 해제·지갑 재조회가 여기 달려 있다');
    expect(errors, isEmpty,
        reason: '이미 정산된 구매를 오류로 보고하면 사용자는 받은 캔디에 대해 '
            '실패 안내를 받고, 어템프트가 살아남아 버튼이 로딩에 잠긴다');
  });

  testWidgets('a settled duplicate clears the persisted in-progress markers',
      (tester) async {
    await build(
      tester,
      _ThrowingVerification(
        ReusedPurchaseException(message: 'duplicate', grantConfirmed: true),
      ),
    );

    duplicates.registerPurchaseAttempt(productId, userId);
    duplicates.registerAuthenticationStart(productId, userId);
    await tester.pump();

    const key = '${productId}_$userId';
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt('${PurchaseConstants.lastPurchaseAttemptKey}$key'),
      isNotNull,
      reason: '전제: 구매 시작이 진행 마커를 남긴다',
    );

    await service.handleOptimizedPurchase(
      transaction(),
      (_) async {},
      errors.add,
      isActualPurchase: true,
      onAlreadySettled: () async => alreadySettledReports++,
    );
    await tester.pump();

    expect(
      prefs.getInt('${PurchaseConstants.lastPurchaseAttemptKey}$key'),
      isNull,
      reason: '정산이 확인된 구매의 진행 마커를 남기면 다음 실행까지 살아남는다',
    );
    expect(
      prefs.getInt('${PurchaseConstants.authenticationStartKey}$key'),
      isNull,
    );
    expect(
      prefs.getInt('${PurchaseConstants.backgroundPurchaseKey}$key'),
      isNull,
    );
  });

  testWidgets('a settled purchase is finished even when presenting it throws',
      (tester) async {
    // The other half of the same limbo: if anything downstream of verification
    // throws (wallet write, receipt dialog, spinner teardown), the settlement
    // used to unwind through _handleActualPurchase's catch, which preserves the
    // store transaction. The idempotency cache has already recorded the
    // receipt by then, so every later re-delivery answers as a duplicate and
    // the transaction can never be finished.
    await build(tester, _SettledVerification());
    await service.handleOptimizedPurchase(
      transaction(),
      (_) async => throw StateError('presentation blew up'),
      errors.add,
      isActualPurchase: true,
      onAlreadySettled: () async => alreadySettledReports++,
    );

    expect(plugin.finalized, 1,
        reason: '영수증이 검증된 순간 지급은 서버에서 끝났다 - 표시 실패가 '
            '트랜잭션 보존(=재전달 루프)을 유발해서는 안 된다');
    expect(errors, isEmpty,
        reason: '정산은 성공했다 - 표시 실패는 정산 실패가 아니다');
  });

  testWidgets('a settlement failure surfaces exactly one error to the UI',
      (tester) async {
    // _handleActualPurchase는 rethrow 전에 onError로 실패를 보고한다.
    // handleOptimizedPurchase의 catch가 같은 실패를 GENERIC으로 또 보고하면
    // 하나의 정산 실패에 에러 다이얼로그가 두 번 뜨고, 타임아웃류 실패에서는
    // 그중 하나가 "구매 처리 지연" 팝업으로 보인다 (1.3.0 베타).
    await run(
      tester,
      FunctionException(status: 503, details: null, reasonPhrase: 'test'),
    );
    expect(errors, hasLength(1),
        reason: '하나의 정산 실패는 UI에 정확히 한 번만 보고되어야 한다');
    expect(plugin.finalized, 0,
        reason: '보고 중복 제거는 UI 계층의 일이다 - 트랜잭션 보존은 그대로');
    expect(plugin.completed, 0);
  });

  // =========================================================================
  // C-1: 정산 실패가 UI 에 어떤 코드로 보고되는지.
  //
  // 트랜잭션 보존 정책(위 그룹)과 별개로, **사용자에게 무엇이라고 알리는지**가
  // 이중 과금을 만든다. 서버 워커의 리스는 60초이고 정산은 cron 재시도까지
  // 수 분이 걸릴 수 있는데 클라이언트 예산은 30초 + 2·4초다. 그래서 여기서
  // 종결 실패로 보고하면 **적립 직전의 결제**가 실패로 안내되고, 사용자는
  // 그 안내를 따라 같은 소비형 상품을 한 번 더 결제한다.
  // =========================================================================
  testWidgets('a timeout is reported as settlement-pending, not a failure',
      (tester) async {
    // 회귀 재현: errorString.contains('timeout') 은 TimeoutException 을
    // 잡지 못한다 ("TimeoutException after 0:00:30.000000: Future not
    // completed" — 소문자 timeout 이 없다). 그래서 GENERIC → purchaseFailed
    // (종결)로 떨어졌다.
    await run(tester, TimeoutException('verify', const Duration(seconds: 30)));

    expect(errors, [PurchaseConstants.errProcessing],
        reason: 'GENERIC 으로 떨어지면 "나중에 다시 시도해주세요" 가 뜨고 '
            '사용자는 정산 중인 소비형 상품을 다시 결제한다');
    expect(plugin.finalized, 0, reason: '미확정이므로 트랜잭션은 그대로 보존');
  });

  testWidgets('a 503 is reported as settlement-pending', (tester) async {
    await run(
      tester,
      FunctionException(status: 503, details: null, reasonPhrase: 'test'),
    );

    expect(errors, [PurchaseConstants.errProcessing],
        reason: 'FunctionException 에는 매칭할 단어가 없어 503 과 422 가 하나의 '
            '다이얼로그로 붕괴했다');
  });

  testWidgets('a 422 is reported as a permanent verification failure',
      (tester) async {
    await run(
      tester,
      FunctionException(status: 422, details: null, reasonPhrase: 'test'),
    );

    expect(errors, ['RECEIPT_VERIFICATION_FAILED'],
        reason: '서버가 의도적으로 구분한 비재시도 판정은 접수 안내가 아니라 '
            '종결 실패로 안내되어야 한다');
  });

  testWidgets('503 and 422 do not collapse into the same report',
      (tester) async {
    await run(
      tester,
      FunctionException(status: 503, details: null, reasonPhrase: 'test'),
    );
    final retryable = List<String>.from(errors);

    errors.clear();
    await run(
      tester,
      FunctionException(status: 422, details: null, reasonPhrase: 'test'),
    );

    expect(retryable, isNot(errors),
        reason: '서버의 503 vs 422 구분이 클라이언트에서 살아 있어야 한다');
  });

  testWidgets('a settlement-pending failure still reports exactly once',
      (tester) async {
    // 분류가 바뀌어도 "하나의 실패 = 하나의 보고" 는 유지된다.
    await run(tester, const SocketException('connection reset'));

    expect(errors, hasLength(1));
    expect(errors.single, PurchaseConstants.errProcessing);
  });

  testWidgets('a duplicate whose grant is unconfirmed keeps the transaction',
      (tester) async {
    await run(
      tester,
      ReusedPurchaseException(message: 'duplicate', grantConfirmed: false),
    );
    expect(plugin.finalized, 0);
    expect(plugin.completed, 0,
        reason: '지급 미확정 중복은 남겨야 큐/reconcile이 재시도한다');
    expect(alreadySettledReports, 0,
        reason: '지급이 확인되지 않은 중복은 성공이 아니다 - 스피너를 풀거나 '
            '성공 안내를 띄우면 미적립을 적립으로 오인시킨다');
    expect(errors, [PurchaseConstants.errProcessing],
        reason: '서버에 다시 물어도 정산을 확인해 주지 못한 중복이다. 결제는 '
            '접수됐으므로 실패가 아니라 미확정이다 - 예전의 ERR_PREV_TX 는 '
            '"잠시 후 다시 시도해 주세요" 로 표시되어 소비형 상품의 이중 '
            '과금을 유도했다');
  });

  testWidgets('the unconfirmed duplicate report is non-blocking and never '
      'tells the user to pay again', (tester) async {
    await run(
      tester,
      ReusedPurchaseException(message: 'duplicate', grantConfirmed: false),
    );

    final type = PurchaseProcessor.mapErrorToType(errors.single);
    expect(PurchaseProcessor.isSettlementPending(type), isTrue,
        reason: '"접수됐고 처리되면 자동 적립된다" 안내 경로여야 한다 - 빨간 '
            '오류 다이얼로그로 띄우면 사용자는 결제가 무효가 됐다고 읽는다');
    expect(PurchaseProcessor.isTerminalMappedError(type), isFalse,
        reason: '정산이 아직 도착할 수 있으므로 종결 실패로 다루면 안 된다');
    expect(
      PurchaseProcessor.classifyError(errors.single),
      PurchaseErrorAction.showMappedError,
      reason: 'ERR_PREV_TX 의 showPendingMessage 분기(= "이전 결제가 스토어에서 '
          '처리 중입니다. 잠시 후 다시 시도해 주세요.")를 더 이상 타지 않는다',
    );
  });

  testWidgets('the launch debounce blocks only the same product', (
    tester,
  ) async {
    // 구매 전 가드는 "같은 상품의 진행 중인 시도" 만 막을 수 있다. 연타 방지
    // 창(300ms)이 상품 단위가 아니면, 연속 구매의 다음 상품이 첫 상품 때문에
    // 막힌다.
    await build(tester, _SettledVerification());

    duplicates.registerPurchaseAttempt(productId, userId);

    final same = await duplicates.validatePurchaseAttempt(productId, userId);
    final other = await duplicates.validatePurchaseAttempt('STAR500', userId);

    expect(same.allowed, isFalse,
        reason: '같은 상품의 연타는 계속 막아야 한다');
    expect(same.reason, PurchaseConstants.errInProgress);
    expect(other.allowed, isTrue,
        reason: '다른 상품은 첫 상품의 진행 여부와 무관하게 열려 있어야 한다');
  });

  // =========================================================================
  // 재전달된(이미 정산된) 트랜잭션은 정산 성공으로 끝난다.
  //
  // iOS 는 정산이 확인되지 않은 트랜잭션을 절대 finish 하지 않으므로, 아직
  // finish 되지 않은 과거 결제는 StoreKit 이 새 구매와 나란히 다시 전달한다.
  // 그 재전달이 로컬 멱등 캐시에 걸려 "이전 결제가 스토어에서 처리 중입니다"
  // 로 보고되던 것이 patch 8 의 연속 구매 오차단이다.
  // =========================================================================
  testWidgets('an already-settled JWS redelivery settles from the server and '
      'finishes the transaction', (tester) async {
    // 멱등 캐시 히트가 이제 서버 재확인으로 이어지고, 서버는 이미 아는
    // 트랜잭션에 REPLAY(정본 정산)로 답한다 — 그 계약은
    // receipt_verification_service_test.dart 의 'already-settled redelivery is
    // resolved by the server' 그룹이 실제 서비스로 고정한다. 여기서는 그
    // 정산이 상위 구매 경로에서 무엇이 되는지를 고정한다: 오류가 아니라 금액
    // 있는 정산이고, 트랜잭션은 finish 된다.
    await build(tester, _SettledVerification());

    PurchaseSettlementResultModel? settled;
    await service.handleOptimizedPurchase(
      transaction(),
      (result) async => settled = result,
      errors.add,
      isActualPurchase: true,
      onAlreadySettled: () async => alreadySettledReports++,
    );

    expect(errors, isEmpty,
        reason: '이미 적립까지 끝난 구매에 오류 다이얼로그가 뜨면 사용자는 '
            '방금 성공한 결제가 실패했다고 읽는다 (patch 8 의 "이전 결제가 '
            '스토어에서 처리 중입니다" 오차단)');
    expect(settled, isNotNull,
        reason: '금액 있는 정산 경로로 들어가야 한다 - 지갑을 재조회 추측이 '
            '아니라 응답으로 맞춘다');
    expect(settled!.replayed, isTrue);
    expect(isSettlementRedelivery(settled!), isTrue,
        reason: '우리 재시도가 만든 replay 가 아니므로 공용 다이얼로그가 '
            '"재전달 안내" 로 라우팅된다 - 받은 적 없는 캔디를 받았다고 두 번 '
            '말하지 않는다');
    expect(plugin.finalized, 1,
        reason: '정산이 확인된 트랜잭션은 finish 해야 재전달 루프가 끊긴다 - '
            '이 트랜잭션이 다음 스토어 진입에서 자동 정리되는 근거');
  });
}

/// 검증이 지정된 실패를 던지거나 (ReusedPurchaseException은 실제 서비스와
/// 같은 경로로) 전달하는 스텁.
class _ThrowingVerification extends ReceiptVerificationService {
  _ThrowingVerification(this.failure);

  final Object failure;

  @override
  Future<String> getEnvironment() async => 'sandbox';

  @override
  Future<PurchaseSettlementResultModel> verifyReceipt(
    String receipt,
    String productId,
    String userId,
    String environment,
  ) async {
    throw failure;
  }
}

/// 검증이 정상 정산으로 끝나는 스텁.
class _SettledVerification extends ReceiptVerificationService {
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

class _CountingPlugin extends Mock implements InAppPurchaseService {
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
