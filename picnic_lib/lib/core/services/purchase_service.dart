import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/config_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/core/analytics/analytics_outbox.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/services/purchase_service_helper.dart';
import 'package:picnic_lib/core/services/unfinished_purchase_source.dart';
// 🔥 복잡한 가드 시스템 제거 - 단순 중복 방지만 사용
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';

typedef PurchaseSuccess =
    Future<void> Function(PurchaseSettlementResultModel result);

Future<void> deliverVerifiedPurchaseResult(
  PurchaseSettlementResultModel result,
  PurchaseSuccess onSuccess,
) => onSuccess(result);

/// Which path is asking for the GA4 `purchase` event.
///
/// The two differ in one thing only: whether `PurchaseDetails.status` is
/// evidence about the transaction.
enum PurchaseAnalyticsSource {
  /// A live `purchaseStream` callback.
  ///
  /// Here the status is authoritative and `restored` means the store replayed
  /// an entitlement the user already owns - not a new charge. Only
  /// [PurchaseStatus.purchased] may be counted as revenue.
  storeCallback,

  /// [PurchaseService.sweepUnfinishedPurchases]'s recovery loop.
  ///
  /// Here the status carries no such meaning and must not gate the event.
  /// `IosPaymentQueueSource` has *already* filtered the queue down to
  /// `SKPaymentTransactionStateWrapper.purchased` before it builds any
  /// `PurchaseDetails`, and Android's `queryPastPurchases` answers a
  /// "past purchases" query - a label about how the row was enumerated, not
  /// about whether money moved. What proves money moved on this path is the
  /// same thing that proves it on the other: the server settled the receipt
  /// and granted candy. Gating the sweep on a `purchased` status would delete
  /// exactly the revenue the sweep exists to recover.
  recoverySweep,
}

/// Why a recovery sweep was started.
enum PurchaseSweepTrigger {
  /// Once per process, from the constructor.
  coldStart,

  /// The app came back to the foreground.
  resume,

  /// Explicitly asked for (debug tooling, tests).
  manual,
}

/// Where an Android PENDING token was observed.
enum PendingIntakeSource { storeSurface, headless, sweep }

enum PurchaseSweepOutcome {
  /// The store was asked and every transaction it returned was driven through
  /// verification.
  completed,

  /// Rate limiting declined this run.
  throttled,

  /// Another sweep was already running.
  concurrent,

  /// There is no store on this host (unit tests, desktop).
  unsupported,

  /// Nobody was signed in, so there was no account to settle against.
  ///
  /// Distinct from [completed] because it does not consume the run: a cold-start
  /// sweep can easily beat session restore (Supabase is initialised *after*
  /// `runApp`), and a sweep that never asked the server must not be the reason a
  /// charged transaction waits for the next launch.
  notSignedIn,

  /// The enumeration or the reconcile threw. Also does not consume the run.
  failed,

  /// [PurchaseService.sweepUnfinishedPurchases]'s `shouldAbort` callback
  /// turned true mid-run - typically because a store screen attached while
  /// this sweep was in flight. Anything not yet verified/finished is
  /// preserved untouched, since the mounted screen's own restore logic may
  /// now be racing the same transactions. Does not consume the run: the
  /// caller genuinely never got a clean shot at the server.
  aborted,
}

/// What one sweep found and what it managed to do about it, so the log line is
/// a fact and not a guess.
class PurchaseSweepReport {
  const PurchaseSweepReport({
    required this.trigger,
    required this.outcome,
    this.source,
    this.found = 0,
    this.settled = 0,
    this.preserved = 0,
    this.scanError,
    this.liveInFlight = 0,
  });

  final PurchaseSweepTrigger trigger;
  final PurchaseSweepOutcome outcome;
  final String? source;

  /// Transactions the store still held open.
  final int found;

  /// Of those, the ones the server settled (or confirmed already settled) and
  /// which are therefore now finished/consumed.
  final int settled;

  /// Of those, the ones left untouched because the settlement was not
  /// confirmed. These stay recoverable by design.
  final int preserved;

  final Object? scanError;

  /// Transactions the store is holding with a **live payment** that is not
  /// settleable yet - iOS `purchasing`/`deferred`. See
  /// [UnfinishedPurchaseScan.liveInFlight].
  final int liveInFlight;

  bool get ran => outcome == PurchaseSweepOutcome.completed;

  /// 이 스윕이 **"큐를 확인했고 애초에 아무것도 없었다"** 를 증명하는가.
  ///
  /// [ran] 이나 `preserved == 0` 보다 엄격하다: `found > 0 && settled > 0 &&
  /// preserved == 0` 인 스윕도 outcome 은 completed 지만, 그건 "비어 있었다"가
  /// 아니라 "방금 실결제를 발견해 정산했다"이다. 두 사실을 뭉개면 실결제가
  /// 있었던 시도를 "아무 일도 없었다"로 정리해 버린다 (Sol 머지 게이트 리뷰,
  /// PR #137 - 90초 취소 억제 판정이 같은 이유로 리포트를 직접 본다).
  ///
  /// [liveInFlight] 도 0 이어야 한다. 정산 대상(purchased)이 없는 것과 큐가
  /// 비어 있는 것은 다르다 - 사용자가 결제 시트 안에 있거나(iOS purchasing)
  /// Ask to Buy 승인을 기다리는 동안(deferred) 정산할 것은 없지만 결제는
  /// 살아 있다. 이 둘을 뭉개면 "큐가 비었다"가 진행 중인 정상 결제를 지워도
  /// 된다는 증거로 오독된다 (Sol 교차 리뷰 MAJOR, 2026-08-07).
  bool get verifiedEmpty =>
      outcome == PurchaseSweepOutcome.completed &&
      scanError == null &&
      found == 0 &&
      preserved == 0 &&
      liveInFlight == 0;

  @override
  String toString() =>
      'PurchaseSweepReport(${trigger.name}, ${outcome.name}, '
      'source: $source, found: $found, settled: $settled, '
      'preserved: $preserved, liveInFlight: $liveInFlight, '
      'scanError: $scanError)';
}

class PurchaseService {
  PurchaseService({
    required this.container,
    required this.inAppPurchaseService,
    required this.receiptVerificationService,
    required this.analyticsService,
    required this.duplicatePreventionService,
    required void Function(List<PurchaseDetails>) onPurchaseUpdate,
    UnfinishedPurchaseSource? unfinishedPurchaseSource,
    DateTime Function() clock = DateTime.now,
    Duration resumeSweepInterval = const Duration(minutes: 5),
    Future<bool?> Function()? pendingIntakeEnabled,
    Duration pendingIntakeCacheDuration = const Duration(seconds: 30),
    Duration pendingIntakeLookupTimeout = const Duration(seconds: 2),
    bool sweepOnStart = true,
  }) : unfinishedPurchaseSource =
           unfinishedPurchaseSource ?? defaultUnfinishedPurchaseSource(),
       _clock = clock,
       _resumeSweepInterval = resumeSweepInterval,
       _pendingIntakeCacheDuration = pendingIntakeCacheDuration,
       _pendingIntakeLookupTimeout = pendingIntakeLookupTimeout {
    _pendingIntakeEnabledLoader =
        pendingIntakeEnabled ??
        () async {
          final raw = await container
              .read(configServiceProvider)
              .getConfig(pendingIntakeConfigKey);
          if (raw == null) return null;
          return raw.trim().toLowerCase() == 'true';
        };

    inAppPurchaseService.initialize(onPurchaseUpdate);
    inAppPurchaseService.clearPendingPurchasesOnStartup();

    // 🚨 타임아웃 콜백 설정
    inAppPurchaseService.onPurchaseTimeout = handlePurchaseTimeout;

    logger.i('✅ PurchaseService 초기화 완료 - 강화된 중복 방지 시스템 활성화');

    // 앱 시작 시 큐 플러시.
    //
    // 이제 이 생성자는 앱 첫 프레임에 돈다(예전에는 스토어 화면 진입). 그
    // 시점에는 Supabase 초기화(runApp 이후 Phase 2)가 아직 끝나지 않았을 수
    // 있고, 그러면 큐 전송이 던진다. 큐는 durable 하므로 다음 플러시가
    // 재시도하지만, 미처리 async 예외로 새는 것은 막는다.
    final receiptQueue = ReceiptQueueService();
    receiptQueue.canFlushPendingIntake = _pendingIntakeEnabled;
    unawaited(
      receiptQueue.flushPending().catchError((Object e) {
        logger.w('영수증 큐 플러시 실패(다음 기회에 재시도): $e');
      }),
    );

    // `ReceiptQueueService.onItemsEvicted` 는 여기서 연결하지 않는다.
    // eviction 이 스토어 화면이 떠 있는 동안 일어나면, 화면이 진행 중일
    // 수도 있는 자체 복원 정리와 리컨사일이 경합해서는 안 되는데, 이
    // 클래스는 스토어 화면이 떠 있는지(surface) 모른다. 그래서
    // `GlobalPurchaseListener` 가 그 콜백을 설정한다 - 화면이 없을 때만
    // 걸고, 화면이 진행 중이면 화면이 닫힐 때까지 미룬다.

    // 콜드 스타트 리컨사일: 스토어가 아직 미완료로 들고 있는 결제를 검증에
    // 태운다. Android 는 queryPastPurchases, iOS 는 SKPaymentQueue 로 같은
    // 루프를 돈다.
    //
    // 기본값은 켜져 있지만 `GlobalPurchaseListener` 는 끄고
    // [sweepUnfinishedPurchases] 를 SDK 초기화 뒤에 직접 부른다 - 세션 복원
    // 전에 훑으면 정산할 계정이 없다.
    if (sweepOnStart) {
      unawaited(
        sweepUnfinishedPurchases(trigger: PurchaseSweepTrigger.coldStart),
      );
    }
  }

  /// The Riverpod container, captured while the store was mounted.
  ///
  /// Not a [WidgetRef]: the reads below outlive the store. Receipt verification
  /// takes as long as the network takes, and the user is free to leave the
  /// store while it runs - `ConsumerState.ref` throws the moment `mounted` is
  /// false, so a read reached through the widget turns a purchase the server
  /// has already settled into an exception on the success path. The container
  /// belongs to the app-level `ProviderScope` and outlives the route, so the
  /// same read still lands. Same reason `WalletSummaryApplier` exists for the
  /// wallet write at the end of that path.
  final ProviderContainer container;
  final InAppPurchaseService inAppPurchaseService;
  final ReceiptVerificationService receiptVerificationService;
  final AnalyticsService analyticsService;
  final DuplicatePreventionService duplicatePreventionService;

  /// How the unfinished transactions of *this* build's store are enumerated.
  ///
  /// Null on a host with no store, which is what makes the sweep a no-op in
  /// unit tests instead of an exception.
  final UnfinishedPurchaseSource? unfinishedPurchaseSource;

  final DateTime Function() _clock;
  final Duration _resumeSweepInterval;
  static const String pendingIntakeConfigKey =
      'PURCHASE_PENDING_INTAKE_ANDROID';
  final Duration _pendingIntakeCacheDuration;
  final Duration _pendingIntakeLookupTimeout;
  late final Future<bool?> Function() _pendingIntakeEnabledLoader;
  bool? _cachedPendingIntakeEnabled;
  DateTime? _pendingIntakeCacheAt;

  bool _coldStartSweepDone = false;
  bool _sweepInFlight = false;
  DateTime? _lastSweepAt;

  /// Completes when the currently in-flight sweep's `finally` block runs.
  /// `null` when no sweep is running.
  ///
  /// A caller that gets [PurchaseSweepOutcome.concurrent] learned nothing
  /// about the queue - the sweep it collided with might itself abort (a
  /// store screen attaching mid-sweep) without ever finishing a real check.
  /// Blindly retrying on a fixed delay can outlast the other sweep and give
  /// up before either one actually looked at the queue. Waiting on this
  /// signal instead means the retry starts the instant the lock is free, and
  /// is themselves the one to perform the real check.
  Completer<void>? _sweepDoneSignal;

  /// Resolves once no sweep is in flight - immediately if none is running.
  Future<void> waitForInFlightSweep() =>
      _sweepDoneSignal?.future ?? Future<void>.value();

  /// When the last sweep actually ran. Exposed so the rate limiting can be
  /// asserted rather than assumed.
  @visibleForTesting
  DateTime? get lastSweepAt => _lastSweepAt;

  /// Helper for pure logic methods (testable without platform dependencies)
  final PurchaseServiceHelper helper = const PurchaseServiceHelper();

  // 🔥 단순화: 복잡한 가드 시스템 제거
  // 기본적인 제품별 구매 진행 상태만 추적 (백업용)
  final Set<String> _processingProducts = {};

  // 🧹 UI 리셋 콜백 (타임아웃 시 UI 상태 정리용)
  void Function()? onTimeoutUIReset;

  /// 구매 처리 메인 메서드
  Future<void> handlePurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      logger.i('=== Purchase Handling Started ===');
      logger.i(
        'Processing: ${purchaseDetails.productID} (${purchaseDetails.status})',
      );

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          logger.i('Purchase is pending...');
          break;
        case PurchaseStatus.error:
          await _handlePurchaseError(purchaseDetails, onError);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchaseDetails, onSuccess, onError);
          break;
        case PurchaseStatus.canceled:
          await _handlePurchaseCanceled(purchaseDetails, onError);
          break;
      }

      await _completePurchaseIfNeeded(purchaseDetails);
      logger.i('=== Purchase Handling Completed ===');
    } catch (e, s) {
      logger.e('Error handling purchase: $e', stackTrace: s);
      onError('GENERIC');
    }
  }

  /// 구매 처리 (단순화)
  ///
  /// 스토어 완료 처리(iOS finish / Android acknowledge·consume)는
  /// 영수증의 마지막 재시도 경로를 끊는 행위이므로 서버 정산이 확인된
  /// 경우에만 실행한다. 미확정 실패는 종류를 불문하고 트랜잭션을 남겨
  /// StoreKit 재전달(iOS)·큐/reconcile(Android)이 재시도하게 한다 —
  /// 예전에는 iOS를 무조건 finish해서, 일시적 네트워크 실패만으로도
  /// 과금된 영수증이 소멸(과금-미적립)할 수 있었다.
  ///
  /// [onAlreadySettled] is the success path for a purchase the server reports
  /// as *already* settled - a grant-confirmed duplicate. There is no settlement
  /// object to hand over (the response carries only the duplicate verdict), but
  /// the grant exists server-side, so this is a success and must be reported as
  /// one: the caller releases the product's spinner, re-reads the wallet and
  /// stops holding the purchase open. Reporting it through [onError] instead -
  /// what this did until 1.3.0 - left the store tile spinning until the 90s
  /// safety net fired, showed the user an error for candy they already own, and
  /// armed a duplicate cooldown that blocked the retry.
  Future<void> handleOptimizedPurchase(
    PurchaseDetails purchaseDetails,
    PurchaseSuccess onSuccess,
    Function(String) onError, {
    required bool isActualPurchase,
    Future<void> Function()? onAlreadySettled,
  }) async {
    var settlementConfirmed = false;
    Object? settlementFailure;
    try {
      if (isActualPurchase) {
        logger.i('=== 🚀 신규 구매 처리 ===');
        logger.i('Product: ${purchaseDetails.productID}');

        settlementConfirmed = await _handleActualPurchase(
          purchaseDetails,
          onSuccess,
          onError,
          onAlreadySettled: onAlreadySettled,
        );

        logger.i('=== ✅ 신규 구매 완료 ===');
      } else {
        logger.i('=== 🚫 복원 구매 무시 ===');
        logger.i('Product: ${purchaseDetails.productID}');

        // 🔥 복원 구매는 완전히 무시 - 콜백 실행 안함
        await _handleRestoredPurchase(purchaseDetails, onSuccess, onError);

        logger.i('=== ✅ 복원 구매 무시 완료 ===');
      }
    } catch (e, s) {
      logger.e('❌ 구매 처리 오류: $e', stackTrace: s);
      settlementFailure = e;

      // 🔥 오류 시 진행 상태 정리
      _processingProducts.remove(purchaseDetails.productID);

      // _handleActualPurchase는 rethrow 전에 이미 onError로 실패를 보고했다.
      // 여기서 또 부르면 하나의 정산 실패에 에러 다이얼로그가 두 번 뜨고
      // (타임아웃류 실패에서는 그중 하나가 "구매 처리 지연" 팝업이다 -
      // 1.3.0 베타), 타임아웃·네트워크에서 살려 두기로 한 어템프트까지
      // GENERIC(종결) 매핑이 제거해 버린다. 자체 보고가 없는 복원 경로의
      // 실패만 여기서 보고한다.
      if (!isActualPurchase) {
        onError('GENERIC');
      }
    } finally {
      if (settlementConfirmed) {
        // Android: consume(소비)까지, iOS: finish. 실패는 정산 결과를
        // 뒤집으면 안 되므로 로그만 남긴다(다음 reconcile이 재시도).
        final finalized = await inAppPurchaseService.finalizeSettledPurchase(
          purchaseDetails,
        );
        if (!finalized) {
          logger.w(
            '정산 확정 구매 완료 처리 실패(다음 reconcile 재시도): '
            '${purchaseDetails.productID}',
          );
        }
      } else {
        // 미확정 실패는 종류를 불문하고 스토어 트랜잭션을 파괴하지 않는다.
        // - 일시 실패(네트워크·5xx·타임아웃·인증): iOS는 StoreKit 재전달이,
        //   Android는 큐/reconcile이 재시도한다.
        // - 서버 영구 거부(422)조차 여기서 finish/consume하지 않는다:
        //   잘못 정리하면 과금된 영수증이 소멸하고(과금-미적립), Android는
        //   acknowledge/consume이 "미승인 구매 3일 자동 환불"이라는
        //   사용자의 마지막 구제책까지 차단한다. 잘못 보존한 비용은
        //   앱 시작마다의 재검증 노이즈뿐이며, 그 비대칭 때문에 보존이
        //   항상 이긴다. (영구 거부의 클라이언트 큐 재전송 중단은
        //   isPermanentSettlementRejection이 큐 계층에서 따로 처리한다.)
        logger.w(
          '⏸️ 서버 정산 미확인 - 구매 완료 처리 보류: '
          '${purchaseDetails.productID} (재전달/큐가 재시도, '
          '실패: $settlementFailure)',
        );
      }
    }
  }

  /// 구매 시작 (강화된 중복 방지) - 취소와 에러를 구분하여 반환
  ///
  /// **반환하는 결과 맵이 이 단계 실패의 유일한 보고 경로다.** 예전에는
  /// 같은 실패를 `onError(...)` 로도 보고했는데, 스토어 화면은 그 콜백에서
  /// `showErrorDialog` 를 띄우고 반환된 맵도 `PurchaseSafetyManager
  /// .handlePurchaseResult` 를 거쳐 다시 `showErrorDialog` 를 띄운다 —
  /// 하나의 실패에 다이얼로그가 두 장 겹쳐 뜬다. 결과 맵을 유일한 보고
  /// 경로로 남긴 이유는 그것이 취소 여부(`wasCancelled`)와 차단 유형
  /// (`denyType`)까지 함께 나르고, 상태 정리(어템프트 해제·쿨다운·스피너)가
  /// 이미 그 경로에 붙어 있기 때문이다.
  ///
  /// `errorMessage` 는 사용자 문장이 아니라 **에러 코드**다. arb 매핑은
  /// 호출자(UI)가 한다.
  ///
  /// 정산 단계(`handleOptimizedPurchase`)는 별개다 — 그쪽은 `onError` 가
  /// 유일한 보고 경로다.
  ///
  /// [onStoreLaunchStart] 는 스토어 결제 플로가 실제로 열리는 순간
  /// (`InAppPurchaseService.makePurchase` 안의 `buyConsumable` 직전)에
  /// 동기적으로 불린다. 이 메서드 진입부터 그 지점까지는 중복 방지 검증과
  /// 상품 조회라는 **비동기 사전 처리**가 있으므로, 호출자가 진입 시점에
  /// lifecycle 기준점을 잡으면 그 사전 처리 중의 백그라운드 왕복까지
  /// 결제 시트의 것으로 오인된다 (Sol 5차 재검증 MAJOR).
  Future<Map<String, dynamic>> initiatePurchase(
    String productId, {
    void Function()? onStoreLaunchStart,
  }) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'wasCancelled': false,
        'errorMessage': 'USER_NOT_AUTHENTICATED',
      };
    }

    try {
      // 🛡️ 1. 강화된 중복 방지 검증
      final validation = await duplicatePreventionService
          .validatePurchaseAttempt(productId, currentUser.id);

      if (!validation.allowed) {
        logger.w('🚫 구매 중복 방지 검증 실패: ${validation.reason}');
        return {
          'success': false,
          'wasCancelled': false,
          'errorMessage': validation.reason,
          'denyType': validation.type?.toString(),
        };
      }

      logger.i('💳 구매 프로세스 시작 - Touch ID/Face ID 인증이 요청될 수 있습니다');

      // 🛡️ 2. 구매 시도 등록 (중복 방지 서비스에)
      duplicatePreventionService.registerPurchaseAttempt(
        productId,
        currentUser.id,
      );

      // 3. 제품 정보 확인
      final storeProducts = await container.read(storeProductsProvider.future);
      final serverProduct = container
          .read(serverProductsProvider.notifier)
          .getProductDetailById(productId);

      if (serverProduct == null) {
        duplicatePreventionService.completePurchase(
          productId,
          currentUser.id,
          success: false,
        );
        throw Exception('서버에서 상품 정보를 찾을 수 없습니다');
      }

      // 4. 구매 진행 상태 등록 (백업용)
      _processingProducts.add(productId);
      logger.i('✅ 구매 시작: $productId');

      // 🛡️ 5. Touch ID/Face ID 인증 시작 등록
      duplicatePreventionService.registerAuthenticationStart(
        productId,
        currentUser.id,
      );

      // 6. 실제 구매 시작
      final productDetails = _findProductDetails(storeProducts, serverProduct);
      logger.i('🚀 StoreKit 구매 프로세스 시작 (Touch ID/Face ID 인증 포함)');

      final purchaseResult = await inAppPurchaseService.makePurchase(
        productDetails,
        applicationUserName: currentUser.id,
        onStoreLaunchStart: onStoreLaunchStart,
      );

      if (!purchaseResult) {
        // 🔍 구매 실패 시 취소인지 실제 에러인지 구분
        if (inAppPurchaseService.lastPurchaseWasCancelled) {
          logger.i('🚫 구매 취소: $productId');
          _processingProducts.remove(productId);
          duplicatePreventionService.completePurchase(
            productId,
            currentUser.id,
            success: false,
          );
          // 취소는 에러가 아니므로 onError 호출하지 않음
          return {'success': false, 'wasCancelled': true, 'errorMessage': null};
        } else {
          logger.w('❌ 구매 요청 시작 실패: $productId');
          _processingProducts.remove(productId);
          duplicatePreventionService.completePurchase(
            productId,
            currentUser.id,
            success: false,
          );
          return {
            'success': false,
            'wasCancelled': false,
            // 런치 자체가 실패했다 - 아직 과금이 없으므로 재시도 안내가 맞다.
            'errorMessage': 'GENERIC',
          };
        }
      } else {
        logger.i('✅ StoreKit 구매 프로세스 시작 성공');
      }

      return {'success': true, 'wasCancelled': false, 'errorMessage': null};
    } catch (e, s) {
      logger.e('Error during purchase initiation: $e', stackTrace: s);
      _processingProducts.remove(productId);
      duplicatePreventionService.completePurchase(
        productId,
        currentUser.id,
        success: false,
      );

      return {
        'success': false,
        'wasCancelled': false,
        'errorMessage': helper.getPurchaseInitiationErrorCode(e),
      };
    }
  }

  /// 구매 에러 처리 (개선)
  Future<void> _handlePurchaseError(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    final error = purchaseDetails.error;
    logger.e('❌ 구매 에러: ${error?.message}, code: ${error?.code}');

    // 🔥 에러 시에도 진행 상태에서 제거
    _processingProducts.remove(purchaseDetails.productID);

    final errorMessage = _getErrorMessage(error);
    onError(errorMessage);

    await analyticsService.logPurchaseErrorEvent(
      productId: purchaseDetails.productID,
      errorCode: error?.code ?? 'unknown',
      errorMessage: error?.message ?? 'No error message',
    );

    logger.i('✅ 구매 에러 처리 완료: ${purchaseDetails.productID}');
  }

  /// 구매 취소 처리 (개선)
  Future<void> _handlePurchaseCanceled(
    PurchaseDetails purchaseDetails,
    Function(String) onError,
  ) async {
    logger.i('🚫 구매 취소: ${purchaseDetails.productID}');

    // 🔥 진행 상태에서 제거 (중요!)
    _processingProducts.remove(purchaseDetails.productID);

    // 🔥 구매 취소 애널리틱스 로깅
    await analyticsService.logPurchaseCancelEvent(purchaseDetails.productID);

    logger.i('✅ 구매 취소 처리 완료: ${purchaseDetails.productID}');

    // 🔥 취소는 오류가 아니므로 onError 호출하지 않음
    // UI에서 별도의 취소 처리 로직이 있음 (_processErrorAndCancel)
  }

  /// 성공적인 구매 처리
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
    VoidCallback onSuccess,
    Function(String) onError,
  ) async {
    try {
      logger.i('Starting successful purchase handling...');

      _validateUserAuthentication();
      final environment = await receiptVerificationService.getEnvironment();

      final result = await _verifyReceipt(purchaseDetails, environment);

      // 성공 보고가 먼저다 - 애널리틱스는 결제 결과에 아무 영향이 없으므로
      // 사용자가 기다릴 이유가 없다.
      onSuccess();
      await _logPurchaseAnalytics(
        purchaseDetails,
        result,
        source: PurchaseAnalyticsSource.storeCallback,
      );
      logger.i('Purchase successfully completed: ${purchaseDetails.productID}');
    } on ReusedPurchaseException catch (e) {
      logger.w('🔄 JWT 재사용 감지 (handleSuccessfulPurchase) - ${e.message}');
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
          purchaseDetails.productID,
          currentUser.id,
          // 지급이 확정된 중복은 사용자 입장에서 성공이다 - 영구 저장된
          // 진행 마커까지 정리해야 다음 실행에 유령으로 남지 않는다.
          success: e.grantConfirmed,
        );
      }
      if (e.grantConfirmed) {
        // 서버가 지급까지 확인한 중복은 성공으로 보고한다. 오류로 보고하면
        // 이미 받은 캔디에 대해 실패 안내가 뜬다.
        onSuccess();
        return;
      }
      // 지급 미확정 중복은 실패가 아니라 미확정이다 -
      // [_handleActualPurchase] 의 같은 분기와 이유가 같다.
      onError(PurchaseConstants.errProcessing);
      rethrow;
    } catch (e, s) {
      logger.e('Error in handleSuccessfulPurchase: $e', stackTrace: s);
      onError(_getDetailedErrorMessage(e));
      rethrow;
    }
  }

  /// 실제 구매 처리 (단순화)
  ///
  /// 반환값은 "서버 정산 확정" 여부다: 검증 성공, 또는 지급 완료가 확인된
  /// 중복(409)일 때만 true. 그 외에는 구매를 완료(consume)하면 안 된다.
  Future<bool> _handleActualPurchase(
    PurchaseDetails purchaseDetails,
    PurchaseSuccess onSuccess,
    Function(String) onError, {
    Future<void> Function()? onAlreadySettled,
  }) async {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    logger.i('🎯 실제 구매 처리 시작 ($platform) - 영수증 검증');
    logger.i('  - Product ID: ${purchaseDetails.productID}');
    logger.i('  - Transaction ID: ${purchaseDetails.purchaseID}');
    logger.i('  - Status: ${purchaseDetails.status}');

    try {
      _validateUserAuthentication();

      final environment = await receiptVerificationService.getEnvironment();
      logger.i('🌍 Environment detected: $environment ($platform)');

      await _validateReceiptData(purchaseDetails);
      logger.i('✅ 영수증 데이터 검증 완료 ($platform)');

      // 🔥 영수증 검증 (서버 검증 단계만 - 타임아웃 있음)
      logger.i('🔍 서버 영수증 검증 시작 ($platform)');
      final result = await _verifyReceipt(purchaseDetails, environment);
      logger.i('✅ 서버 영수증 검증 완료 ($platform)');

      // 🔥 구매 완료 시 진행 상태 제거
      _processingProducts.remove(purchaseDetails.productID);

      // 🛡️ 중복 방지 서비스에 성공 알림
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
          purchaseDetails.productID,
          currentUser.id,
          success: true,
        );
      }

      await _presentSettlementGuarded(
        () => deliverVerifiedPurchaseResult(result, onSuccess),
        purchaseDetails,
      );

      // 정산 표시(지갑 반영·영수증·스피너 해제)가 끝난 뒤에 보낸다. 예전에는
      // 검증 직후에 있어서, 네이티브 Firebase 채널이나 상품 카탈로그 조회가
      // 정체되면 그만큼 적립 UX 가 통째로 밀렸다. 애널리틱스는 결제 결과에
      // 영향을 주지 않으므로 뒤로 미룰 수 있고, 미뤄도 유실되지 않는다 —
      // payload가 outbox에 먼저 남아 store 거래/다음 sweep과 무관하게 재시도된다.
      await _logPurchaseAnalytics(
        purchaseDetails,
        result,
        source: PurchaseAnalyticsSource.storeCallback,
      );

      logger.i('✅ 실제 구매 검증 완료 ($platform)');
      return true;
    } on ReusedPurchaseException catch (e) {
      logger.w('🔄 JWT 재사용 감지 ($platform) - StoreKit 캐시 문제: ${e.message}');
      _processingProducts.remove(purchaseDetails.productID);

      final currentUser = supabase.auth.currentUser;
      if (e.grantConfirmed) {
        // 서버가 "이 영수증은 지급까지 끝났다"고 확인한 중복이다. 사용자
        // 입장에서 이것은 성공이며, 실패로 보고하면 (1) 이미 받은 캔디에
        // 대해 오류 안내가 뜨고 (2) 상품 스피너가 90초 안전망까지 내려가지
        // 않고 (3) 중복 쿨다운이 재시도까지 막는다. 1.3.0 베타의 "실패한
        // 구매의 버튼이 영구 로딩" 리포트가 이 경로다 — iOS 멱등 캐시
        // (SharedPreferences)는 앱을 재시작해도 살아 있으므로 재전달마다
        // 같은 예외가 되풀이됐다.
        logger.w('♻️ 서버 지급 확정 중복 - 정산 성공으로 처리 ($platform)');
        if (currentUser != null) {
          // success: true는 진행 상태와 함께 영구 저장된 구매 진행 마커
          // (last_purchase_attempt_/authentication_start_/
          // background_purchase_)까지 정리한다.
          duplicatePreventionService.completePurchase(
            purchaseDetails.productID,
            currentUser.id,
            success: true,
          );
        }
        if (onAlreadySettled != null) {
          await _presentSettlementGuarded(onAlreadySettled, purchaseDetails);
        }
        // 지급이 확인된 중복만 스토어 트랜잭션을 완료(finish/consume)한다.
        return true;
      }

      // 🛡️ 중복 방지 서비스에 실패 알림
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
          purchaseDetails.productID,
          currentUser.id,
          success: false,
        );
      }

      // 여기까지 왔다는 것은 서버에 다시 물어봐도(ReceiptVerificationService
      // 의 재확인 경로) 정산을 확인해 주지 못했다는 뜻이다: 영수증은 서버가
      // 알고 있는데 지급은 확정되지 않았다. 결제는 접수된 상태이므로 이것은
      // **실패가 아니라 미확정**이다.
      //
      // 예전에는 `ERR_PREV_TX` 를 보고했고, 그 코드는 "이전 결제가 스토어에서
      // 처리 중입니다. 잠시 후 다시 시도해 주세요." 로 표시된다 — 소비형
      // 상품에서 재시도를 권하는 문장이라 되돌릴 수 없는 이중 과금을
      // 유도한다. PROCESSING 은 같은 사실을 "접수됐고 처리되면 자동
      // 적립된다"로 안내하고, 그 상품의 재구매만 정산 쿨다운으로 막는다.
      onError(PurchaseConstants.errProcessing);
      // 지급이 확인되지 않은 중복(영수증만 있고 지급 실패)은 트랜잭션을
      // 남겨 두어 재시도를 보존한다.
      return false;
    } catch (e, s) {
      logger.e('❌ 실제 구매 처리 중 오류 ($platform): $e', stackTrace: s);
      _processingProducts.remove(purchaseDetails.productID);

      // 🛡️ 중복 방지 서비스에 실패 알림
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        duplicatePreventionService.completePurchase(
          purchaseDetails.productID,
          currentUser.id,
          success: false,
        );
      }

      onError(_getDetailedErrorMessage(e));
      rethrow;
    }
  }

  /// 복원된 구매 처리 (무시)
  Future<void> _handleRestoredPurchase(
    PurchaseDetails purchaseDetails,
    PurchaseSuccess onSuccess,
    Function(String) onError,
  ) async {
    logger.i('🚫 복원된 구매 무시: ${purchaseDetails.productID}');

    // iOS: 조용히 finish만 해서 반복 재전달을 막는다.
    // Android: 복원(restored)으로 온 미소비 구매를 여기서 완료하면 검증 없이
    // 소비되어 복구가 불가능해진다. reconcile(과거 구매 재검증)이 검증 후
    // 소비하므로 여기서는 손대지 않는다.
    if (Platform.isIOS) {
      await _completePurchaseIfNeeded(purchaseDetails);
    }

    // 진행 상태에서 제거 (혹시 있다면)
    _processingProducts.remove(purchaseDetails.productID);

    logger.i('✅ 복원된 구매 무시 완료');
  }

  /// 사용자 인증 검증 (단순화 - 타임아웃 제거)
  void _validateUserAuthentication() {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('USER_NOT_AUTHENTICATED');
    }
    logger.i('✅ 사용자 인증 확인 완료: ${currentUser.id}');
  }

  /// 영수증 데이터 검증
  Future<void> _validateReceiptData(PurchaseDetails purchaseDetails) async {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    final receiptData = purchaseDetails.verificationData.serverVerificationData;

    logger.i('🔍 영수증 데이터 검증 시작 ($platform)');
    logger.i('  - Receipt length: ${receiptData.length} characters');
    logger.i(
      '  - Receipt preview: ${receiptData.length > 50 ? "${receiptData.substring(0, 50)}..." : receiptData}',
    );

    if (receiptData.isEmpty) {
      logger.e('❌ 영수증 데이터가 비어있음 ($platform)');
      throw Exception('영수증 데이터가 비어있습니다');
    }

    logger.i('✅ 영수증 데이터 검증 완료 ($platform) - 길이: ${receiptData.length}');
  }

  /// 영수증 검증 (단순화 - 서비스에 위임)
  Future<PurchaseSettlementResultModel> _verifyReceipt(
    PurchaseDetails purchaseDetails,
    String environment,
  ) async {
    final receiptData = purchaseDetails.verificationData.serverVerificationData;
    final currentUser = supabase.auth.currentUser!;

    logger.i('🔍 영수증 검증 시작 (서버 검증 단계)');
    logger.i('Environment: $environment');

    // 요청과 같은 자리에서 카탈로그 통화를 한 번 읽어 함께 보낸다. 별도 저장소나
    // 시각 매칭이 아니라 이 거래의 요청 본문에 실리는 필드 하나라, "어느 시도의
    // 값인지" 를 나중에 지목할 필요 자체가 없다. Google 은 provider 응답에
    // 통화 필드가 없어 서버가 이 값을 마지막 폴백으로 쓴다.
    final observedCurrency = _observedStoreCurrency(purchaseDetails.productID);

    // ReceiptVerificationService가 타임아웃 + 재시도 로직을 모두 처리
    final result = await receiptVerificationService.verifyReceipt(
      receiptData,
      purchaseDetails.productID,
      currentUser.id,
      environment,
      clientObservedCurrency: observedCurrency,
    );

    logger.i('✅ 영수증 검증 완료');
    return result;
  }

  /// 이미 메모리에 로드된 스토어 카탈로그에서 이 상품의 통화를 읽는다.
  ///
  /// 카탈로그 future 를 기다리지 않는다. 결제 경로에서 조회가 지연되면 그만큼
  /// 검증이 밀리고, 통화 하나 때문에 정산을 늦출 이유는 없다 — 없으면 없는
  /// 대로 보내고 서버가 자기 소스로 채운다.
  String? _observedStoreCurrency(String productId) =>
      _cachedProduct(productId)?.currencyCode;

  /// Durably records an Android PENDING token behind a fail-closed capability
  /// gate. This path never verifies through [ReceiptVerificationService] and
  /// never finalizes the store transaction.
  Future<void> recordPendingPurchase(
    PurchaseDetails purchase, {
    required PendingIntakeSource source,
  }) async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        purchase.status != PurchaseStatus.pending) {
      return;
    }
    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty) return;

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        logger.i(
          'Android pending 접수 보류(비로그인/${source.name}): '
          '${purchase.productID}',
        );
        return;
      }
      if (!await _pendingIntakeEnabled()) {
        logger.i(
          'Android pending 접수 비활성(게이트 OFF/fail-closed, '
          '${source.name}) - Play 큐에 보존: ${purchase.productID}',
        );
        return;
      }

      final environment = await receiptVerificationService.getEnvironment();
      final receiptQueue = ReceiptQueueService();
      await receiptQueue.enqueue(
        platform: ReceiptQueueService.platformAndroid,
        receipt: token,
        productId: purchase.productID,
        userId: currentUser.id,
        environment: environment,
        clientObservedCurrency: _observedStoreCurrency(purchase.productID),
        pendingIntake: true,
      );
      unawaited(
        receiptQueue.flushPending().catchError((Object e) {
          logger.w('Android pending 접수 전송 실패(큐 보존): $e');
        }),
      );
    } catch (e, s) {
      // Play owns the unacknowledged token, so an intake failure is preserved
      // for the next event/cold-start/resume sweep rather than surfaced as a
      // terminal purchase failure.
      logger.w(
        'Android pending 접수 보류(${source.name}) - 다음 스윕에서 재시도: $e',
        stackTrace: s,
      );
    }
  }

  Future<bool> _pendingIntakeEnabled() async {
    final cached = _cachedPendingIntakeEnabled;
    final cachedAt = _pendingIntakeCacheAt;
    final now = _clock();
    final cacheAge = cachedAt == null ? null : now.difference(cachedAt);
    if (cached != null &&
        cacheAge != null &&
        !cacheAge.isNegative &&
        cacheAge < _pendingIntakeCacheDuration) {
      return cached;
    }

    try {
      final loaded = await _pendingIntakeEnabledLoader().timeout(
        _pendingIntakeLookupTimeout,
      );
      if (loaded == null) return false;
      _cachedPendingIntakeEnabled = loaded;
      _pendingIntakeCacheAt = now;
      return loaded;
    } catch (e, s) {
      logger.w('Android pending 원격 게이트 조회 실패 - fail-closed: $e', stackTrace: s);
      return false;
    }
  }

  num? _observedStorePrice(String productId) =>
      _cachedProduct(productId)?.rawPrice;

  ProductDetails? _cachedProduct(String productId) {
    try {
      final cached = container.read(storeProductsProvider).value;
      if (cached == null) return null;
      for (final product in cached) {
        if (product.id == productId) return product;
      }
    } catch (e, s) {
      logger.w('카탈로그 상세 조회 실패 — 서버 소스에 맡긴다', error: e, stackTrace: s);
    }
    return null;
  }

  /// Runs the caller's settlement presentation and swallows whatever it throws.
  ///
  /// Everything downstream of a verified receipt is presentation: the wallet
  /// write, the receipt dialog, the spinner teardown. The grant already exists
  /// server-side, so a failure there says nothing about whether the purchase
  /// settled - but letting it escape makes `_handleActualPurchase` return
  /// through its catch, which reports `settlementConfirmed = false` and so
  /// *preserves* the store transaction. On iOS that transaction is re-delivered
  /// on every launch, and because the iOS idempotency cache has already
  /// recorded the receipt, every re-delivery comes back as a duplicate instead
  /// of a settlement - the permanent limbo behind the stuck buy button.
  ///
  /// Preserving a transaction is the right default for an *unconfirmed*
  /// settlement only. Once the server has confirmed the grant, finishing is
  /// what stops the loop, so a presentation failure must not veto it.
  Future<void> _presentSettlementGuarded(
    Future<void> Function() present,
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      await present();
    } catch (e, s) {
      logger.e(
        '정산 결과 표시 실패 - 서버 정산은 이미 확정: ${purchaseDetails.productID}',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// 구매 애널리틱스 로깅
  ///
  /// Runs between "the receipt verified" and "the caller is told the purchase
  /// succeeded", and therefore must not be able to fail the purchase. By the
  /// time it runs the candy is already granted server-side; letting it throw
  /// hands the settled purchase to the catch in [_handleActualPurchase], which
  /// records `completePurchase(success: false)` for a purchase that succeeded
  /// and calls `onError` instead of `onSuccess` - so the settlement, and with
  /// it the wallet write, never runs.
  ///
  /// [AnalyticsService] already swallows its own failures. What could throw is
  /// the *lookup* this needs to name the product: the provider read, and the
  /// `PRODUCT_NOT_FOUND` below when the store catalogue does not carry an id it
  /// just sold. Neither says anything about whether the user was charged.
  ///
  /// [result] is the settlement the server just confirmed, and it is what makes
  /// this call safe to make at all: GA4 `purchase` feeds revenue reporting, so
  /// it may only fire for a delivery that actually granted candy.
  ///
  /// **Whether this event has already been sent is decided by one thing: the
  /// dedup record keyed on the transaction.** It used to be decided by
  /// [isSettlementRedelivery] as well, and that was wrong in a way that loses
  /// money permanently. `replayed` answers "did the server settle this receipt
  /// before?", not "did this client already report it?". Those come apart the
  /// moment a first run settles server-side and then dies - response lost in
  /// transport, process killed - before analytics fires. Every later delivery
  /// of that transaction arrives `replayed: true` with `replayCausedByRetry:
  /// false` (the retry counter lives inside a single `verifyReceipt` call and
  /// resets with the process), so the gate would suppress the event forever and
  /// the charge would never appear in GA4 at all. `PurchaseAnalyticsDedup`
  /// answers the question that actually matters, and it answers it from a
  /// record of *sends*, which survives restarts. So the redelivery that
  /// `replayed` was there to catch is still caught - by the dedup key.
  ///
  /// [source] decides whether `PurchaseDetails.status` gets a vote; see
  /// [PurchaseAnalyticsSource]. On the live callback path a `restored`
  /// transaction is not a new charge and must never be counted, even though the
  /// rest of that path deliberately treats a bound `restored` event as a normal
  /// purchase (iOS delivers late successes that way).
  ///
  /// The `base_amount` / `bonus_amount` item parameters are read off the same
  /// settlement rather than recomputed from the catalogue, so what analytics
  /// reports is what the server actually credited - promotion bonus included,
  /// and only when the promotion was `GRANTED`.
  ///
  /// Bounded by [_analyticsBudget]. Nothing downstream of a settled purchase may
  /// wait on analytics. 카탈로그는 이미 로드된 provider state만 읽고, 없으면
  /// currency/value를 생략한다. Firebase native channel은 outbox background
  /// drain만 접근하므로 이 경로가 기다리는 것은 bounded local persistence뿐이다.
  ///
  /// **The timeout here bounds this path's UX, not the dedup reservation.**
  /// `Future.timeout` does not cancel what it gave up on, so a timeout fired
  /// out here would leave the send still running and its reservation held by
  /// nobody - and under the old marker-before-send order it left a *persisted*
  /// "already sent" marker for an event that never went out, losing that
  /// purchase from GA4 permanently. The same budget is therefore handed to
  /// `logPurchaseEvent` as [AnalyticsService.defaultSendTimeout]'s override, so
  /// the reservation is always settled - committed on a confirmed send,
  /// released otherwise - by the code that took it out.
  Future<void> _logPurchaseAnalytics(
    PurchaseDetails purchaseDetails,
    PurchaseSettlementResultModel result, {
    required PurchaseAnalyticsSource source,
  }) async {
    try {
      if (source == PurchaseAnalyticsSource.storeCallback &&
          purchaseDetails.status != PurchaseStatus.purchased) {
        logger.w(
          '애널리틱스 로깅 생략 - 실결제 상태가 아님(${purchaseDetails.status}): '
          '${purchaseDetails.productID}',
        );
        return;
      }

      await _sendPurchaseAnalytics(
        purchaseDetails,
        result,
      ).timeout(_analyticsBudget);
    } catch (e, s) {
      logger.e('애널리틱스 로깅 실패 - 구매 결과에는 영향 없음: $e', stackTrace: s);
    }
  }

  /// How long the purchase path is willing to wait for analytics before it
  /// gives up and moves on. The event is worth having; it is not worth holding
  /// a settled purchase's UX behind.
  static const Duration _analyticsBudget = Duration(seconds: 5);

  Future<void> _sendPurchaseAnalytics(
    PurchaseDetails purchaseDetails,
    PurchaseSettlementResultModel result,
  ) async {
    // 정산이 확정된 뒤 카탈로그 future를 기다리면, 조회 실패/무한 지연이
    // outbox 저장보다 먼저 발생해 store finish 후 매출 payload가 사라진다.
    // 이미 메모리에 로드된 상세가 있으면 currency/value를 보강하고, 없으면
    // 숫자를 지어내지 않은 채 거래/적립 사실부터 durable하게 남긴다.
    ProductDetails? productDetails;
    final cachedProducts = container.read(storeProductsProvider).value;
    if (cachedProducts != null) {
      for (final product in cachedProducts) {
        if (product.id == purchaseDetails.productID) {
          productDetails = product;
          break;
        }
      }
    }
    if (productDetails == null) {
      logger.w(
        'purchase analytics 카탈로그 상세 없음 — 서버가 통화를 주지 않았다면 '
        'outbox 에 보류로 남는다: ${purchaseDetails.productID}',
      );
    }

    final promotion = result.promotion;
    final promoBonus = promotion?.state == PurchasePromotionState.granted
        ? promotion!.promoBonusAmount
        : BigInt.zero;

    logger.i('애널리틱스 로깅...');
    final stored = await analyticsService.logPurchasePayload(
      storeProductId: purchaseDetails.productID,
      // 서버가 확정한 통화·금액이 있으면 그것이 정본이다. 카탈로그 값은 서버가
      // 통화를 주지 못했을 때만 쓰이며, 그때도 통화와 금액을 쌍으로만 쓴다.
      serverCurrency: result.currency,
      serverValue: result.value,
      catalogCurrency: productDetails?.currencyCode,
      catalogValue: productDetails?.rawPrice,
      transactionId: purchaseDetails.purchaseID,
      idempotencyFallbackKey: result.operationId,
      baseAmount: result.baseStarAmount.toInt(),
      bonusAmount: (result.baseBonusAmount + promoBonus).toInt(),
      sendTimeout: _analyticsBudget,
    );
    logger.i('애널리틱스 로깅 완료: ${stored.name}');

    // 매출 이벤트가 durable 하게 남은 뒤에만 영수증 큐의 복구 재료를 버린다.
    // 저장에 실패했는데 큐까지 지우면 그 거래는 되살릴 방법이 없다.
    if (stored != PurchaseOutboxResult.failed) {
      await _releaseReceiptQueueEntry(result);
    }
  }

  /// 부팅 큐 복구가 받은 정산의 매출 이벤트를 durable 하게 넘겨받는다.
  ///
  /// 이 경로에는 스토어 카탈로그가 로드돼 있다는 보장이 없다. 그래서 큐가
  /// 요청 시점에 함께 저장해 둔 관측 통화가 서버 값 다음의 소스가 된다.
  ///
  /// `true` 를 돌려줄 때만 큐가 항목을 비운다. 저장 실패를 성공으로 답하면
  /// 그 거래의 매출을 되살릴 재료가 사라진다.
  Future<bool> adoptRecoveredSettlement(
    PurchaseSettlementResultModel settlement, {
    required String storeProductId,
    required String? clientObservedCurrency,
  }) async {
    final promotion = settlement.promotion;
    final promoBonus = promotion?.state == PurchasePromotionState.granted
        ? promotion!.promoBonusAmount
        : BigInt.zero;
    try {
      final stored = await analyticsService.logPurchasePayload(
        storeProductId: storeProductId,
        serverCurrency: settlement.currency,
        serverValue: settlement.value,
        catalogCurrency: _observedStoreCurrency(storeProductId),
        catalogValue: _observedStorePrice(storeProductId),
        clientObservedCurrency: clientObservedCurrency,
        idempotencyFallbackKey: settlement.operationId,
        baseAmount: settlement.baseStarAmount.toInt(),
        bonusAmount: (settlement.baseBonusAmount + promoBonus).toInt(),
        sendTimeout: _analyticsBudget,
      );
      return stored != PurchaseOutboxResult.failed;
    } catch (e, s) {
      logger.e('큐 복구 매출 이벤트 저장 실패', error: e, stackTrace: s);
      return false;
    }
  }

  /// 영수증 큐가 갖고 있던 이 정산의 복구 항목을 제거한다.
  ///
  /// 큐 항목은 "서버 정산 응답 확보"까지를 소유하고, analytics outbox 는 그
  /// 뒤부터 "통화 확보와 GA4 전송 성공"까지를 소유한다. 소유권이 넘어간
  /// 것을 확인하기 전에 큐를 비우면 그 사이의 실패가 곧 영구 유실이다.
  Future<void> _releaseReceiptQueueEntry(
    PurchaseSettlementResultModel result,
  ) async {
    final traceId = result.receiptQueueClientTraceId;
    if (traceId == null || traceId.isEmpty) return;
    try {
      await receiptVerificationService.releaseQueuedReceipt(traceId);
    } catch (e, s) {
      logger.e(
        '영수증 큐 항목 제거 실패 — 다음 부팅 flush 가 다시 정리한다: $traceId',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// 구매 완료 처리
  Future<void> _completePurchaseIfNeeded(
    PurchaseDetails purchaseDetails,
  ) async {
    if (purchaseDetails.pendingCompletePurchase) {
      logger.i('구매 완료 처리 중...');
      await inAppPurchaseService.completePurchase(purchaseDetails);
      logger.i('구매 완료 처리됨');
    }
  }

  /// 상품 세부 정보 찾기
  ProductDetails _findProductDetails(
    List<ProductDetails> storeProducts,
    Map<String, dynamic> serverProduct,
  ) {
    return helper.findProductDetails(
      storeProducts: storeProducts,
      serverProductId: serverProduct['id'] as String,
      isAndroid: isAndroid(),
      inappAppNamePrefix: Environment.inappAppNamePrefix,
      environment: Environment.currentEnvironment,
      // 단일 출처 — 카탈로그 조회·버튼 판정과 반드시 같은 값.
      paymentProductNamespace: Environment.storeQueryNamespace,
    );
  }

  /// 에러 메시지 생성
  String _getErrorMessage(IAPError? error) {
    return helper.getErrorMessage(error);
  }

  /// 상세 에러 메시지 생성
  String _getDetailedErrorMessage(dynamic error) {
    return helper.getDetailedErrorMessage(error);
  }

  /// 서비스 해제 시 모든 진행 상태 정리
  void dispose() {
    logger.i('🧹 PurchaseService 해제: ${_processingProducts.length}개 진행 상태 정리');
    _processingProducts.clear();

    final receiptQueue = ReceiptQueueService();
    if (receiptQueue.canFlushPendingIntake == _pendingIntakeEnabled) {
      receiptQueue.canFlushPendingIntake = null;
    }

    // 🛡️ 중복 방지 서비스 데이터 정리
    duplicatePreventionService.cleanupExpiredData();

    logger.i('✅ PurchaseService 해제 완료');
  }

  /// 현재 진행 중인 구매 수 (디버그용)
  int get activeProcessingCount => _processingProducts.length;

  /// 타임아웃 발생 시 구매 상태 정리 (InAppPurchaseService에서 호출)
  void handlePurchaseTimeout(String productId) {
    logger.w('⏰ 구매 타임아웃으로 인한 상태 정리: $productId');

    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      // 🛡️ 중복 방지 서비스에서 백그라운드 구매로 전환
      duplicatePreventionService.handlePurchaseTimeout(
        productId,
        currentUser.id,
      );
    }

    if (_processingProducts.contains(productId)) {
      _processingProducts.remove(productId);
      logger.i('✅ 타임아웃된 구매 상태 정리 완료: $productId');
    } else {
      logger.i('ℹ️ 타임아웃된 구매가 진행 상태에 없음: $productId');
    }

    // 🧹 UI 상태 리셋 (로딩 해제, 구매 상태 초기화)
    if (onTimeoutUIReset != null) {
      logger.i('🧹 타임아웃으로 인한 UI 상태 리셋 호출');
      onTimeoutUIReset!();
    } else {
      logger.w('⚠️ UI 리셋 콜백이 설정되지 않음 - UI가 로딩 상태로 남을 수 있음');
    }

    // 타임아웃 이후에도 큐 플러시 재시도
    unawaited(ReceiptQueueService().flushPending());
  }

  /// Drives every transaction the store still holds open through the existing
  /// verification/settlement path.
  ///
  /// This is the recovery half of the money path, and it is now symmetric
  /// across the two stores: Android enumerates through `queryPastPurchases`,
  /// iOS through `SKPaymentQueue` (see [UnfinishedPurchaseSource]). Both feed
  /// the same loop, and the loop's rule is unchanged from the Android-only
  /// version it grew out of: **verify first, finish only once the server has
  /// confirmed the grant.** Finishing first would destroy the receipt's last
  /// retry path if verification then failed.
  ///
  /// It is cheap and it terminates because the server made it so: re-sending an
  /// already-settled transaction answers 200 with the canonical `wallet.v1`
  /// settlement (engine PR #78) and a permanently dead intake answers 422
  /// (PR #77). So a sweep over the same queue converges - every transaction
  /// either gets settled and finished, or is answered as un-settleable and left
  /// alone for a human to look at.
  ///
  /// Rate limiting is the caller-visible contract: exactly once per cold start,
  /// and at most once per [_resumeSweepInterval] on resume. Without it, a user
  /// flicking between apps would re-verify the same queue on every foreground.
  /// [shouldAbort] is checked after the store scan returns, and again before
  /// each transaction the sweep is about to verify/finish - not just once at
  /// entry. A caller that knows about a mounted store surface (currently only
  /// `GlobalPurchaseListener`) uses it to back off mid-flight if a screen
  /// attaches while this sweep is already running: a check made only before
  /// the scan would miss a screen attaching during the (often slow) scan or
  /// between transactions.
  Future<PurchaseSweepReport> sweepUnfinishedPurchases({
    required PurchaseSweepTrigger trigger,
    bool Function()? shouldAbort,
  }) async {
    final source = unfinishedPurchaseSource;
    if (source == null) {
      return PurchaseSweepReport(
        trigger: trigger,
        outcome: PurchaseSweepOutcome.unsupported,
      );
    }

    if (_sweepInFlight) {
      logger.i('⏭️ 미완료 구매 스윕이 이미 진행 중 - ${trigger.name} 요청 무시');
      return PurchaseSweepReport(
        trigger: trigger,
        outcome: PurchaseSweepOutcome.concurrent,
        source: source.label,
      );
    }

    if (!_sweepAllowed(trigger)) {
      logger.i('⏭️ 미완료 구매 스윕 제한(${trigger.name}) - 마지막 실행: $_lastSweepAt');
      return PurchaseSweepReport(
        trigger: trigger,
        outcome: PurchaseSweepOutcome.throttled,
        source: source.label,
      );
    }

    _sweepInFlight = true;
    _sweepDoneSignal = Completer<void>();
    final previousColdStartDone = _coldStartSweepDone;
    final previousSweepAt = _lastSweepAt;
    if (trigger == PurchaseSweepTrigger.coldStart) {
      _coldStartSweepDone = true;
    }
    _lastSweepAt = _clock();

    try {
      final report = await _reconcileUnfinishedPurchases(
        source,
        trigger,
        shouldAbort,
      );
      if (report.outcome == PurchaseSweepOutcome.notSignedIn ||
          report.outcome == PurchaseSweepOutcome.aborted ||
          report.outcome == PurchaseSweepOutcome.failed) {
        // 이 실행은 소진하지 않는다 - 서버에 정산을 제대로 시도하지 못했으니
        // 다음 기회에 다시 훑어야 한다.
        _coldStartSweepDone = previousColdStartDone;
        _lastSweepAt = previousSweepAt;
      }
      logger.i('✅ 미완료 구매 스윕 완료: $report');
      return report;
    } catch (e, s) {
      // 부팅 직후에는 Supabase 초기화(runApp 이후 Phase 2)보다 먼저 도달할 수
      // 있고, 그때 `supabase` 게터는 StateError 를 던진다. 실패한 스윕이 이
      // 실행을 소진하면 과금된 트랜잭션이 다음 콜드 스타트까지 기다린다.
      _coldStartSweepDone = previousColdStartDone;
      _lastSweepAt = previousSweepAt;
      logger.e('미완료 구매 스윕 실패(${source.label}): $e', stackTrace: s);
      return PurchaseSweepReport(
        trigger: trigger,
        outcome: PurchaseSweepOutcome.failed,
        source: source.label,
        scanError: e,
      );
    } finally {
      _sweepInFlight = false;
      _sweepDoneSignal?.complete();
      _sweepDoneSignal = null;
    }
  }

  bool _sweepAllowed(PurchaseSweepTrigger trigger) {
    switch (trigger) {
      case PurchaseSweepTrigger.coldStart:
        return !_coldStartSweepDone;
      case PurchaseSweepTrigger.manual:
        return true;
      case PurchaseSweepTrigger.resume:
        final last = _lastSweepAt;
        if (last == null) return true;
        return _clock().difference(last) >= _resumeSweepInterval;
    }
  }

  Future<PurchaseSweepReport> _reconcileUnfinishedPurchases(
    UnfinishedPurchaseSource source,
    PurchaseSweepTrigger trigger,
    bool Function()? shouldAbort,
  ) async {
    logger.i('🔍 미완료 구매 조회 시작 (${source.label}, ${trigger.name})');
    final scan = await source.scan();
    if (scan.error != null) {
      // 빈 목록과 조회 실패는 다르다 - "확인해보니 없었다"가 아니라
      // "확인하지 못했다"이므로 completed 로 뭉개면 안 된다. 호출자(스토어
      // 화면의 구매 게이트 등)가 이 둘을 구분하지 못하면 실제로는 검증하지
      // 못한 채로 "정리 완료"로 보일 수 있다.
      logger.w('⚠️ 미완료 구매 조회 오류: ${scan.error}');
      return PurchaseSweepReport(
        trigger: trigger,
        outcome: PurchaseSweepOutcome.failed,
        source: source.label,
        scanError: scan.error,
        liveInFlight: scan.liveInFlight,
      );
    }
    if (scan.isEmpty && scan.pendingPurchases.isEmpty) {
      logger.i('ℹ️ 미완료 구매 없음 (${source.label}, 진행 중 ${scan.liveInFlight}건)');
      return PurchaseSweepReport(
        trigger: trigger,
        outcome: PurchaseSweepOutcome.completed,
        source: source.label,
        liveInFlight: scan.liveInFlight,
      );
    }

    // 스토어 조회(비동기, 종종 느림) 도중 조건이 바뀌었을 수 있으니 여기서
    // 한 번 더 확인한다 - 진입 시점 검사만으로는 스캔 도중 붙는 화면을
    // 놓친다.
    if (shouldAbort?.call() ?? false) {
      logger.i('⏭️ 미완료 구매 스윕 중단(조건 변경) - ${scan.purchases.length}건 보존');
      return PurchaseSweepReport(
        trigger: trigger,
        outcome: PurchaseSweepOutcome.aborted,
        source: source.label,
        found: scan.purchases.length,
        preserved: scan.purchases.length,
        scanError: scan.error,
        liveInFlight: scan.liveInFlight,
      );
    }

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      logger.w(
        'ℹ️ 로그인되지 않아 미완료 구매 재검증 생략 '
        '(정산 ${scan.purchases.length}건, pending '
        '${scan.pendingPurchases.length}건)',
      );
      return PurchaseSweepReport(
        trigger: trigger,
        outcome: PurchaseSweepOutcome.notSignedIn,
        source: source.label,
        found: scan.purchases.length,
        preserved: scan.purchases.length,
        scanError: scan.error,
        liveInFlight: scan.liveInFlight,
      );
    }

    for (final pending in scan.pendingPurchases) {
      if (shouldAbort?.call() ?? false) {
        logger.i('⏭️ Android pending intake 중 스윕 조건 변경 - Play 큐에 보존');
        return PurchaseSweepReport(
          trigger: trigger,
          outcome: PurchaseSweepOutcome.aborted,
          source: source.label,
          found: scan.purchases.length,
          preserved: scan.purchases.length,
          liveInFlight: scan.liveInFlight,
        );
      }
      await recordPendingPurchase(pending, source: PendingIntakeSource.sweep);
    }

    if (scan.purchases.isEmpty) {
      logger.i(
        'ℹ️ 정산 가능한 구매 없음 (${source.label}, Android pending '
        '${scan.pendingPurchases.length}건)',
      );
      return PurchaseSweepReport(
        trigger: trigger,
        outcome: PurchaseSweepOutcome.completed,
        source: source.label,
        liveInFlight: scan.liveInFlight,
      );
    }

    final environment = await receiptVerificationService.getEnvironment();

    var found = 0;
    var settled = 0;
    var preserved = 0;
    var aborted = false;

    for (var i = 0; i < scan.purchases.length; i++) {
      if (shouldAbort?.call() ?? false) {
        // 이미 처리한 항목은 되돌리지 않는다 - 남은 항목만 손대지 않고
        // 보존한다.
        aborted = true;
        preserved += scan.purchases.length - i;
        logger.i('⏭️ 미완료 구매 스윕 중단(조건 변경) - 남은 항목 보존');
        break;
      }
      final p = scan.purchases[i];
      final receipt = p.verificationData.serverVerificationData;
      if (receipt.isEmpty) continue;
      found++;

      // 서버는 트랜잭션(구매 토큰 / 트랜잭션 ID) 기준으로 멱등하므로 직접
      // 재검증한다. (verifyReceipt가 내부에서 큐 적재→성공 시 제거를
      // 수행하므로 실패해도 항목이 큐에 남아 이후 플러시가 재시도한다.)
      // 소비(consume)/finish는 적립이 확인된 뒤에만 한다 — 소비가 먼저면
      // 실패 시 복구 수단이 사라진다.
      try {
        final result = await receiptVerificationService.verifyReceipt(
          receipt,
          p.productID,
          currentUser.id,
          environment,
        );
        // 이 경로도 "검증 성공 = 적립 확정"이라 매출이다. 여기서 안 보내면
        // 결제 직후 앱이 죽거나 네트워크가 끊겨 스윕이 대신 정산한 구매가
        // GA4 에서 통째로 사라진다. 이전 세션이 이미 보낸 건이든 같은 결제를
        // 반복 스윕한 것이든, 걸러내는 것은 거래 ID 중복 방어 하나다 —
        // 정산의 재전달 플래그는 발송 증거가 아니다(_logPurchaseAnalytics 문서).
        await _logPurchaseAnalytics(
          p,
          result,
          source: PurchaseAnalyticsSource.recoverySweep,
        );
        if (await _tryFinalize(p)) {
          settled++;
          logger.i('♻️ 미완료 구매 정산+완료: ${p.productID} (${p.purchaseID})');
        } else {
          // 서버 정산은 끝났지만 스토어 완료 처리(consume/acknowledge)가
          // 실패했다 - Play 큐엔 여전히 미소비 트랜잭션이 남아 있으므로
          // settled로 세면 안 된다. preserved로 세야 구매 게이트
          // (preserved==0을 "검증 완료"로 신뢰한다)가 다음 구매를 실제로
          // 열어도 되는 상태로 오판하지 않는다.
          preserved++;
        }
      } on ReusedPurchaseException catch (e) {
        if (e.grantConfirmed) {
          // 이미 지급까지 끝난 구매 → 스토어 완료 처리만 하면 된다.
          if (await _tryFinalize(p)) {
            settled++;
            logger.i('♻️ 기지급 미완료 구매 완료 처리: ${p.productID}');
          } else {
            preserved++;
          }
        } else {
          preserved++;
          logger.w('미완료 구매 중복이나 지급 미확인 - 완료 처리 보류: ${p.productID}');
        }
      } catch (e) {
        preserved++;
        logger.w('미완료 구매 재검증 실패(트랜잭션·큐 유지): ${p.productID} ($e)');
      }
    }

    // 루프를 정상적으로 다 돌았어도, 마지막 항목의 검증/완료 처리를
    // 기다리는 동안 화면이 다시 붙었을 수 있다 - 루프 안 검사만으로는 이
    // 틈을 못 잡는다. 트레일링 플러시 직전에 한 번 더 확인한다.
    if (!aborted && (shouldAbort?.call() ?? false)) {
      aborted = true;
      logger.i('⏭️ 트레일링 큐 플러시 생략(조건 변경)');
    }
    // 중단됐으면 큐 플러시도 건너뛴다 - 화면이 다시 붙어 자체 정리를 하는
    // 중일 수 있는 상황에서 굳이 서버 왕복을 더 만들 이유가 없다.
    if (!aborted) {
      await ReceiptQueueService().flushPending();
    }

    return PurchaseSweepReport(
      trigger: trigger,
      outcome: aborted
          ? PurchaseSweepOutcome.aborted
          : PurchaseSweepOutcome.completed,
      source: source.label,
      found: found,
      settled: settled,
      preserved: preserved,
      scanError: scan.error,
      liveInFlight: scan.liveInFlight,
    );
  }

  /// 스토어 완료 처리(consume/acknowledge)를 시도하고 성공 여부를 반환한다.
  ///
  /// 실패해도 예외를 던지지 않는다 - 트랜잭션은 큐에 그대로 남아 다음
  /// 스윕이 재시도한다. 반환값은 호출자가 이 항목을 settled/preserved 중
  /// 어디로 셀지 정하는 데 쓰인다.
  Future<bool> _tryFinalize(PurchaseDetails purchase) async {
    try {
      final finalized = await inAppPurchaseService.finalizeSettledPurchase(
        purchase,
      );
      if (!finalized) {
        logger.w('미완료 구매 완료 처리 실패(다음 스윕에서 재시도): ${purchase.productID}');
      }
      return finalized;
    } catch (e) {
      logger.w('미완료 구매 완료 처리 실패(다음 스윕에서 재시도): $e');
      return false;
    }
  }

  /// 모든 진행 중인 구매 상태 강제 정리 (긴급 상황용)
  void clearAllProcessingStates() {
    logger.w('🚨 모든 구매 진행 상태 강제 정리: ${_processingProducts.length}개');
    _processingProducts.clear();
    logger.i('✅ 모든 구매 상태 정리 완료');
  }

  /// 특정 상품의 진행 상태 확인 (디버그용)
  bool isProductProcessing(String productId) {
    return _processingProducts.contains(productId);
  }

  // 🧪 ============ 디버그 기능들 ============

  /// 🧪 디버그 모드 활성화 (타임아웃 시간 3초로 단축)
  void enableDebugMode() {
    inAppPurchaseService.setDebugMode(true);
    logger.w('🧪 구매 디버그 모드 활성화 - 타임아웃 3초로 단축');
  }

  /// 🧪 디버그 모드 비활성화 (타임아웃 시간 30초로 복원)
  void disableDebugMode() {
    inAppPurchaseService.setDebugMode(false);
    logger.i('🧪 구매 디버그 모드 비활성화 - 타임아웃 30초로 복원');
  }

  /// 🧪 타임아웃 모드 설정 (더 세밀한 제어)
  void setTimeoutMode(String mode) {
    inAppPurchaseService.setTimeoutMode(mode);
    logger.w('🧪 타임아웃 모드 설정: $mode');
  }

  /// 🧪 구매 지연 시뮬레이션 활성화
  void enableSlowPurchase() {
    inAppPurchaseService.setSlowPurchaseSimulation(true);
    logger.w('🧪 구매 지연 시뮬레이션 활성화 - 5초 지연');
  }

  /// 🧪 구매 지연 시뮬레이션 비활성화
  void disableSlowPurchase() {
    inAppPurchaseService.setSlowPurchaseSimulation(false);
    logger.i('🧪 구매 지연 시뮬레이션 비활성화');
  }

  /// 🎯 강제 타임아웃 시뮬레이션 활성화 (실제 구매 요청 안함)
  void enableForceTimeout() {
    inAppPurchaseService.setForceTimeoutSimulation(true);
    logger.w('🎯 강제 타임아웃 시뮬레이션 활성화 - 실제 구매 요청 없이 무조건 타임아웃');
  }

  /// 🎯 강제 타임아웃 시뮬레이션 비활성화 (정상 구매 진행)
  void disableForceTimeout() {
    inAppPurchaseService.setForceTimeoutSimulation(false);
    logger.i('🎯 강제 타임아웃 시뮬레이션 비활성화 - 정상 구매 진행');
  }

  /// 🧪 수동 타임아웃 트리거 (테스트용)
  void triggerManualTimeout({String? productId}) {
    logger.w('🧪 수동 타임아웃 트리거 요청: ${productId ?? "현재 구매 중인 상품"}');
    inAppPurchaseService.triggerManualTimeout(productId: productId);
  }

  /// 🧪 현재 디버그 상태와 진행 중인 구매 상태 출력
  void printDebugStatus() {
    logger.i(
      '🧪 === 구매 디버그 상태 ===\n🧪 디버그 모드: ${inAppPurchaseService.debugMode ? "활성화" : "비활성화"}\n🧪 타임아웃 모드: ${inAppPurchaseService.debugTimeoutMode}\n🧪 구매 지연: ${inAppPurchaseService.simulateSlowPurchase ? "활성화" : "비활성화"}\n🎯 강제 타임아웃: ${inAppPurchaseService.forceTimeoutSimulation ? "활성화" : "비활성화"}\n🧪 진행 중인 구매: ${_processingProducts.length}개${_processingProducts.isNotEmpty ? '\n${_processingProducts.map((productId) => '🧪   → $productId').join('\n')}' : ''}\n🧪 ========================',
    );
  }
}
