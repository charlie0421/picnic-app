import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/services/unfinished_purchase_source.dart';
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

  // =========================================================================
  // 미완료 트랜잭션 스윕 (iOS 를 Android 와 대칭으로).
  //
  // iOS 에는 리컨사일이 아예 없었다: _reconcileAndroidPastPurchases 는 Android
  // 전용이고 restorePurchases() 는 복구용으로 호출되지 않았다. 그래서 정산이
  // 확인되지 않아 **의도적으로 보존된** iOS 트랜잭션은 다음 콜드 스타트에
  // StoreKit 이 재전달해 줄 때까지 갇혀 있었다 — 그리고 그 재전달을 받을
  // 리스너도 스토어 화면이 열릴 때까지 없었다.
  //
  // 스윕이 싼 이유는 서버가 만들어 줬다: 이미 정산된 트랜잭션 재전송은 200 +
  // 정본 wallet.v1 (engine PR #78), 영구 사망 intake 는 422 (PR #77). 그래서
  // 같은 큐를 반복해 훑어도 수렴한다.
  //
  // 여기서 고정하는 것은 스윕이 **기존 정산 경로의 규칙을 그대로** 따른다는
  // 점이다: 검증이 먼저, 완료(finish/consume)는 서버가 지급을 확인한 뒤에만.
  // =========================================================================
  group('unfinished transaction sweep', () {
    late _FakeUnfinishedSource source;
    late DateTime now;

    PurchaseDetails unfinished({String id = 'tx-sweep'}) {
      final details = PurchaseDetails(
        purchaseID: id,
        productID: productId,
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

    /// Wires a [PurchaseService] whose store enumeration is [scan] and whose
    /// clock the test drives, so rate limiting is asserted rather than waited
    /// out.
    Future<void> buildWithSource(
      WidgetTester tester,
      ReceiptVerificationService stub,
      UnfinishedPurchaseScan scan, {
      bool sweepOnStart = false,
      Duration resumeSweepInterval = const Duration(minutes: 5),
    }) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
      source = _FakeUnfinishedSource(scan);
      service = PurchaseService(
        container: container,
        inAppPurchaseService: plugin,
        receiptVerificationService: verification,
        analyticsService: AnalyticsService(),
        duplicatePreventionService: duplicates,
        onPurchaseUpdate: (_) {},
        unfinishedPurchaseSource: source,
        clock: () => now,
        resumeSweepInterval: resumeSweepInterval,
        sweepOnStart: sweepOnStart,
      );
    }

    setUp(() => now = DateTime.utc(2026, 7, 30, 12));

    testWidgets('settles a pre-existing unfinished transaction and finishes it',
        (tester) async {
      await buildWithSource(
        tester,
        _SettledVerification(),
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );

      expect(report.found, 1);
      expect(report.settled, 1);
      expect(report.preserved, 0);
      expect(plugin.finalized, 1,
          reason: '서버가 정산을 확인한 뒤에만 완료 처리한다 - 이게 재전달 '
              '루프를 끊는 유일한 지점이다');
    });

    testWidgets(
        'shouldAbort checked right after the scan skips verification '
        'entirely and preserves everything found', (tester) async {
      await buildWithSource(
        tester,
        _SettledVerification(),
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
        shouldAbort: () => true,
      );

      expect(
        report.outcome,
        PurchaseSweepOutcome.aborted,
        reason:
            '스토어 화면이 다시 붙는 등 이 스윕을 계속하면 안 되는 상황이 '
            '되면, 발견한 트랜잭션을 검증/완료 처리하지 않고 그대로 '
            '보존해야 한다 - 화면의 자체 복원 로직과 경합하면 안 된다',
      );
      expect(report.found, 1);
      expect(report.preserved, 1);
      expect(report.settled, 0);
      expect(plugin.finalized, 0);
      expect(plugin.completed, 0);
    });

    testWidgets(
        'shouldAbort becoming true mid-loop stops before the next item but '
        'does not undo work already done', (tester) async {
      await buildWithSource(
        tester,
        _SettledVerification(),
        UnfinishedPurchaseScan(
          purchases: [unfinished(id: 'tx-1'), unfinished(id: 'tx-2')],
        ),
      );

      var checks = 0;
      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
        shouldAbort: () {
          checks++;
          // 호출 순서: 1) 스캔 직후 점검, 2) 첫 항목 처리 전, 3) 두 번째
          // 항목 처리 전. 세 번째 호출부터 true - 첫 항목은 처리되고 두
          // 번째 항목 전에 멈춘다.
          return checks > 2;
        },
      );

      expect(report.outcome, PurchaseSweepOutcome.aborted);
      expect(
        report.found,
        1,
        reason: '중단 시점까지 실제로 훑은 항목 수 - 아직 손대지 않은 '
            '나머지는 found 가 아니라 preserved 로 잡힌다',
      );
      expect(
        report.settled,
        1,
        reason: '중단되기 전에 이미 처리한 첫 항목은 되돌리지 않는다',
      );
      expect(
        report.preserved,
        1,
        reason: '중단 이후의 항목은 손대지 않고 보존한다',
      );
      expect(plugin.finalized, 1);
    });

    testWidgets(
        'an aborted sweep does not consume the throttle - the next attempt '
        'can retry immediately', (tester) async {
      await buildWithSource(
        tester,
        _SettledVerification(),
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );

      await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.resume,
        shouldAbort: () => true,
      );

      final retry = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.resume,
      );

      expect(
        retry.outcome,
        isNot(PurchaseSweepOutcome.throttled),
        reason:
            '중단된 스윕은 실제로 서버 정산을 시도조차 못 했으므로, 이 '
            '실행이 재개 스로틀을 소진해서는 안 된다 - 그러면 진짜 기회를 '
            '5분 뒤로 미루게 된다',
      );
    });

    testWidgets(
        'shouldAbort turning true right after the loop finishes still '
        'skips the trailing queue flush', (tester) async {
      // 이 테스트가 (버그 상태에서) 실제로 flushPending() 을 트리거하면
      // 진짜 30초 프로덕션 타임아웃×재시도를 기다리게 된다 - 짧게 자른다.
      ReceiptQueueService().flushInvokeTimeout = const Duration(
        milliseconds: 100,
      );
      addTearDown(
        () => ReceiptQueueService().flushInvokeTimeout =
            PurchaseConstants.verificationTimeout,
      );

      await buildWithSource(
        tester,
        _SettledVerification(),
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );

      // flushPending() 이 만약 돈다면 건드릴 별개의 큐 항목을 미리 심는다.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'receipt_queue_v1',
        json.encode([
          {
            'client_trace_id': 'queued-item',
            'receipt': 'r',
            'productId': 'STAR100',
            'user_id': 'user-1',
            'platform': 'android',
            'environment': 'sandbox',
            'format': 'google_play',
            'attempt': 0,
            'createdAt': DateTime.now().toIso8601String(),
            'nextAt': 0,
          },
        ]),
      );

      var checks = 0;
      await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
        shouldAbort: () {
          checks++;
          // 1) 스캔 직후, 2) 유일한 항목 처리 전 - 둘 다 통과시켜 검증·완료
          // 처리까지 정상 진행하게 한다. 그 이후(트레일링 flushPending 직전)
          // 에만 true.
          return checks > 2;
        },
      );

      expect(
        capturedMockRequests
            .where((u) => u.path.contains('/functions/v1/verify-receipt-v2'))
            .length,
        0,
        reason:
            '루프의 마지막 항목까지 정상 처리했더라도, 그 검증/완료 처리를'
            ' 기다리는 동안 화면이 다시 붙었을 수 있다 - 트레일링 '
            'flushPending() 직전에 다시 shouldAbort 를 확인해야 한다',
      );
    });

    testWidgets('is a no-op when the store holds nothing unfinished',
        (tester) async {
      final stub = _SettledVerification();
      await buildWithSource(tester, stub, const UnfinishedPurchaseScan());

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );

      expect(source.scans, 1, reason: '스토어에는 물어봐야 한다');
      expect(report.found, 0);
      expect(report.settled, 0);
      expect(plugin.finalized, 0);
      expect(plugin.completed, 0,
          reason: '훑을 것이 없으면 아무 트랜잭션도 건드리지 않는다');
    });

    testWidgets('an unconfirmed outcome during a sweep preserves the '
        'transaction', (tester) async {
      await buildWithSource(
        tester,
        _ThrowingVerification(
          FunctionException(status: 503, details: null, reasonPhrase: 'test'),
        ),
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );

      expect(report.found, 1);
      expect(report.settled, 0);
      expect(report.preserved, 1);
      expect(plugin.finalized, 0,
          reason: '스윕이 미확정 트랜잭션을 소비하면 과금된 영수증이 소멸한다 '
              '- 스윕은 복구 수단이지 정리 수단이 아니다');
      expect(plugin.completed, 0);
    });

    testWidgets('even a permanent rejection (422) found by a sweep is not '
        'destroyed', (tester) async {
      await buildWithSource(
        tester,
        _ThrowingVerification(
          FunctionException(status: 422, details: null, reasonPhrase: 'test'),
        ),
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );

      expect(report.preserved, 1);
      expect(plugin.finalized, 0,
          reason: '422 는 클라이언트 큐 재전송 중단에만 쓰인다 - 스토어 '
              '트랜잭션 파괴 권한은 여기에도 없다');
    });

    testWidgets('a grant-confirmed duplicate found by a sweep is finished',
        (tester) async {
      await buildWithSource(
        tester,
        _ThrowingVerification(
          ReusedPurchaseException(message: 'duplicate', grantConfirmed: true),
        ),
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );

      expect(report.settled, 1);
      expect(plugin.finalized, 1,
          reason: '지급이 끝난 트랜잭션이 미완료로 남아 있으면 매 실행마다 '
              '재전달된다 - 스윕이 끊어 줘야 한다');
    });

    testWidgets('a duplicate whose grant is unconfirmed is preserved by a '
        'sweep', (tester) async {
      await buildWithSource(
        tester,
        _ThrowingVerification(
          ReusedPurchaseException(message: 'duplicate', grantConfirmed: false),
        ),
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );

      expect(report.preserved, 1);
      expect(plugin.finalized, 0);
    });

    testWidgets('nothing is verified while nobody is signed in', (tester) async {
      final stub = _SettledVerification();
      await buildWithSource(
        tester,
        stub,
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );
      // 세션 없는 클라이언트로 교체한다 (로그아웃 상태).
      setupMockSupabase(const {});

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.manual,
      );

      expect(report.outcome, PurchaseSweepOutcome.notSignedIn);
      expect(report.found, 1);
      expect(report.preserved, 1,
          reason: '검증할 계정이 없으면 트랜잭션은 그대로 두고 로그인 뒤에 '
              '다시 훑는다');
      expect(plugin.finalized, 0);
    });

    testWidgets('a sweep that found nobody signed in does not consume the '
        'cold-start run', (tester) async {
      // Supabase 는 runApp **이후** Phase 2 에서 초기화된다. 콜드 스타트 스윕이
      // 세션 복원을 앞지르는 것은 정상 시나리오이고, 그때 아무것도 물어보지
      // 못한 실행이 "한 번 돌았다"로 소진되면 과금된 트랜잭션이 다음 실행까지
      // 갇힌다.
      final stub = _SettledVerification();
      await buildWithSource(
        tester,
        stub,
        UnfinishedPurchaseScan(purchases: [unfinished()]),
      );
      setupMockSupabase(const {});

      final beforeLogin = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );
      expect(beforeLogin.outcome, PurchaseSweepOutcome.notSignedIn);

      await setupMockSupabaseWithAuth(const {}, userId: userId);
      final afterLogin = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );

      expect(afterLogin.outcome, PurchaseSweepOutcome.completed);
      expect(afterLogin.settled, 1);
      expect(plugin.finalized, 1);
    });

    testWidgets('a sweep whose store enumeration throws does not consume the '
        'cold-start run', (tester) async {
      // 부팅 직후에는 `supabase` 게터 자체가 StateError 를 던질 수 있다.
      await buildWithSource(
        tester,
        _SettledVerification(),
        const UnfinishedPurchaseScan(),
      );
      final throwing = _ThrowingUnfinishedSource();
      service = PurchaseService(
        container: container,
        inAppPurchaseService: plugin,
        receiptVerificationService: verification,
        analyticsService: AnalyticsService(),
        duplicatePreventionService: duplicates,
        onPurchaseUpdate: (_) {},
        unfinishedPurchaseSource: throwing,
        clock: () => now,
        sweepOnStart: false,
      );

      final failed = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );
      expect(failed.outcome, PurchaseSweepOutcome.failed);

      throwing.shouldThrow = false;
      final retried = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );
      expect(retried.outcome, PurchaseSweepOutcome.completed,
          reason: '실패한 스윕이 유일한 콜드 스타트 기회를 소진해서는 안 된다');
    });

    testWidgets(
        'a scan that reports an error (not an exception) is reported as '
        'failed, not completed, and does not consume the cold-start run',
        (tester) async {
      // iOS 가 앱 영수증을 못 읽는 경우 등: scan() 은 던지지 않고 빈
      // purchases + error 를 돌려준다. 이걸 "큐가 비었다"(completed)로
      // 뭉개면, 실제로는 확인하지 못했는데도 확인 끝난 것처럼 보고된다 -
      // 스토어 화면의 구매 게이트가 이 outcome 을 직접 읽게 되면서 실제
      // 결제 위험으로 이어진다(RestorePurchaseHandler).
      await buildWithSource(
        tester,
        _SettledVerification(),
        UnfinishedPurchaseScan(error: Exception('영수증을 읽을 수 없음')),
      );

      final failed = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );
      expect(failed.outcome, PurchaseSweepOutcome.failed);

      source.setScan(const UnfinishedPurchaseScan());
      final retried = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );
      expect(retried.outcome, PurchaseSweepOutcome.completed,
          reason: 'scan error 로 실패한 스윕이 유일한 콜드 스타트 기회를 소진해서는 안 된다');
    });

    test(
        'waitForInFlightSweep resolves immediately when nothing is running, '
        'and only after an in-flight sweep actually finishes', () async {
      final gate = Completer<UnfinishedPurchaseScan>();
      final plainContainer = ProviderContainer();
      addTearDown(plainContainer.dispose);

      // Nothing running yet.
      var idleResolved = false;
      final gated = _GatedUnfinishedSource(gate.future);
      final probe = PurchaseService(
        container: plainContainer,
        inAppPurchaseService: _CountingPlugin(),
        receiptVerificationService: _SettledVerification(),
        analyticsService: AnalyticsService(),
        duplicatePreventionService:
            DuplicatePreventionService.forContainer(plainContainer),
        onPurchaseUpdate: (_) {},
        unfinishedPurchaseSource: gated,
        sweepOnStart: false,
      );
      unawaited(probe.waitForInFlightSweep().then((_) {
        idleResolved = true;
      }));
      await Future<void>.delayed(Duration.zero);
      expect(idleResolved, isTrue);

      final occupying = probe.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(gated.scans, 1, reason: 'the occupying sweep reached the scan');

      var signalResolved = false;
      unawaited(probe.waitForInFlightSweep().then((_) {
        signalResolved = true;
      }));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        signalResolved,
        isFalse,
        reason: 'the occupying sweep has not finished yet',
      );

      gate.complete(const UnfinishedPurchaseScan());
      await occupying;
      await Future<void>.delayed(Duration.zero);
      expect(signalResolved, isTrue);
    });

    testWidgets('the cold-start sweep runs exactly once per process',
        (tester) async {
      await buildWithSource(
        tester,
        _SettledVerification(),
        const UnfinishedPurchaseScan(),
        sweepOnStart: true,
      );
      // 생성자의 unawaited 스윕이 완료될 시간을 준다.
      await tester.pump();
      expect(source.scans, 1);

      final again = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );

      expect(again.outcome, PurchaseSweepOutcome.throttled);
      expect(source.scans, 1);
    });

    testWidgets('resume sweeps are rate-limited to one per interval',
        (tester) async {
      await buildWithSource(
        tester,
        _SettledVerification(),
        const UnfinishedPurchaseScan(),
        resumeSweepInterval: const Duration(minutes: 5),
      );

      final first = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.resume,
      );
      expect(first.outcome, PurchaseSweepOutcome.completed);

      now = now.add(const Duration(minutes: 4, seconds: 59));
      final tooSoon = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.resume,
      );
      expect(tooSoon.outcome, PurchaseSweepOutcome.throttled,
          reason: '앱 전환을 반복하는 사용자가 같은 큐를 매번 재검증하게 '
              '만들면 안 된다');
      expect(source.scans, 1);

      now = now.add(const Duration(seconds: 2));
      final allowed = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.resume,
      );
      expect(allowed.outcome, PurchaseSweepOutcome.completed);
      expect(source.scans, 2);
    });

    testWidgets('a host with no store makes the sweep an inert no-op',
        (tester) async {
      // 기본 소스는 Platform 으로 정해지고, 테스트 호스트에는 스토어가 없다.
      // 이 경로가 예외를 던지면 앱 시작이 깨진다.
      await build(tester, _SettledVerification());

      final report = await service.sweepUnfinishedPurchases(
        trigger: PurchaseSweepTrigger.coldStart,
      );

      expect(report.outcome, PurchaseSweepOutcome.unsupported);
    });
  });

  // =========================================================================
  // iOS 큐에서 무엇을 "미완료 결제" 로 볼지.
  // =========================================================================
  group('IosPaymentQueueSource', () {
    SKPaymentTransactionWrapper txn(
      SKPaymentTransactionStateWrapper state, {
      String? id,
    }) =>
        SKPaymentTransactionWrapper(
          payment: SKPaymentWrapper(productIdentifier: productId),
          transactionState: state,
          transactionIdentifier: id,
          transactionTimeStamp: 1785228000,
        );

    test('only purchased transactions are swept', () async {
      final scanned = await IosPaymentQueueSource(
        readTransactions: () async => [
          txn(SKPaymentTransactionStateWrapper.purchasing),
          txn(SKPaymentTransactionStateWrapper.deferred),
          txn(SKPaymentTransactionStateWrapper.failed),
          txn(SKPaymentTransactionStateWrapper.restored, id: 'restored-1'),
          txn(SKPaymentTransactionStateWrapper.purchased, id: 'paid-1'),
        ],
        readReceipt: () async => 'base64-app-receipt',
      ).scan();

      expect(
        scanned.purchases.map((p) => p.purchaseID),
        ['paid-1'],
        reason: 'purchasing 은 아직 돈이 아니고 StoreKit 이 finish 를 금지한다; '
            'deferred(Ask to Buy 대기) 는 승인되면 purchased 로 다시 온다; '
            'failed 는 과금이 아니다; restored 는 기기 단위 앱 영수증으로 '
            '남의 결제를 지금 로그인한 계정에 정산시킬 수 있어 제외한다',
      );
      expect(
        scanned.purchases.single.verificationData.serverVerificationData,
        'base64-app-receipt',
        reason: '스윕된 트랜잭션은 실시간 구매와 **같은 모양**으로 서버에 '
            '도착해야 한다 - StoreKit 1 의 serverVerificationData 는 앱 '
            '영수증이다',
      );
      expect(scanned.error, isNull);
    });

    test('an unreadable app receipt is reported instead of sent', () async {
      final scanned = await IosPaymentQueueSource(
        readTransactions: () async => [
          txn(SKPaymentTransactionStateWrapper.purchased, id: 'paid-1'),
        ],
        readReceipt: () async => '',
      ).scan();

      expect(scanned.purchases, isEmpty);
      expect(scanned.error, isNotNull,
          reason: '빈 영수증을 검증에 보내면 서버가 영구 거부(422)로 답할 수 '
              '있고, 그 판정이 되돌릴 수 없다. 모른다고 남겨 다음 스윕이 '
              '다시 시도해야 한다');
    });

    test('an empty queue is an empty scan, not an error', () async {
      final scanned = await IosPaymentQueueSource(
        readTransactions: () async => [],
        readReceipt: () async => fail('영수증은 정산 대상이 있을 때만 읽는다'),
      ).scan();

      expect(scanned.isEmpty, isTrue);
      expect(scanned.error, isNull);
    });
  });
}

/// A stand-in store enumeration, so a sweep can be driven without StoreKit or
/// Play.
class _FakeUnfinishedSource implements UnfinishedPurchaseSource {
  _FakeUnfinishedSource(this._scan);

  UnfinishedPurchaseScan _scan;

  /// How many times the store was asked. The rate-limiting assertions are all
  /// about this number.
  int scans = 0;

  void setScan(UnfinishedPurchaseScan scan) => _scan = scan;

  @override
  String get label => 'fake';

  @override
  Future<UnfinishedPurchaseScan> scan() async {
    scans++;
    return _scan;
  }
}

/// A store enumeration whose [scan] doesn't resolve until the test completes
/// [scanGate], so a sweep can be held mid-flight on purpose.
class _GatedUnfinishedSource implements UnfinishedPurchaseSource {
  _GatedUnfinishedSource(this._scanGate);

  final Future<UnfinishedPurchaseScan> _scanGate;

  int scans = 0;

  @override
  String get label => 'gated';

  @override
  Future<UnfinishedPurchaseScan> scan() async {
    scans++;
    return _scanGate;
  }
}

/// Stands in for a store enumeration that cannot answer yet - which is what
/// `supabase` does before its Phase 2 initialisation finishes.
class _ThrowingUnfinishedSource implements UnfinishedPurchaseSource {
  bool shouldThrow = true;

  @override
  String get label => 'throwing';

  @override
  Future<UnfinishedPurchaseScan> scan() async {
    if (shouldThrow) throw StateError('store not ready');
    return const UnfinishedPurchaseScan();
  }
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
