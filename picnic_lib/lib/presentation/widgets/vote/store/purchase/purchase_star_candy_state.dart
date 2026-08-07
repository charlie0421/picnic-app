import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/global_purchase_listener.dart';
// `InAppPurchaseService` 확장(cleanupPurchaseTimersOnSuccess)이 이 라이브러리의
// part 파일에 있어, 타입만 전달돼도 확장 사용에는 직접 import 가 필요하다.
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/global_purchase_provider.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/reward_breakdown.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'handlers/restore_purchase_handler.dart';
import 'handlers/purchase_safety_manager.dart';
import 'handlers/purchase_dialog_handler.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/config/payment_product_id_policy.dart';
import 'package:picnic_lib/core/services/purchase_service_helper.dart';

import 'purchase_helper.dart';
import 'purchase_processor.dart';
import 'purchase_timeout_notice.dart';
import 'purchase_campaign_attempt.dart';
import 'purchase_settlement_step.dart';
import 'wallet_summary_applier.dart';

class PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// The app-level purchase service. **Not constructed here.**
  ///
  /// Building one here is what made the store the only subscriber to
  /// `InAppPurchase.purchaseStream`, so every purchase event that arrived
  /// without a store on screen was dropped (broadcast stream, no listener).
  /// `GlobalPurchaseListener` owns the subscription for the process lifetime;
  /// this screen borrows the same service and registers itself as the
  /// presentation surface for as long as it is mounted.
  late final PurchaseService _purchaseService;

  /// This screen's claim on presentation, released in [dispose].
  PurchaseSurfaceRegistration? _surface;

  late final AnimationController _rotationController;
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
      GlobalKey<LoadingOverlayWithIconState>();

  late final RestorePurchaseHandler _restoreHandler;
  late final PurchaseSafetyManager _safetyManager;
  late final PurchaseDialogHandler _dialogHandler;

  /// Bound in [initState], while this state is guaranteed to be mounted.
  ///
  /// A settlement can land after the user has left the store - receipt
  /// verification outlives the route - and `ref` throws once `mounted` is
  /// false, so the wallet write must not go through it.
  ///
  /// The binding has to be eager. Writing this as a `late final` *initializer*
  /// compiles and keeps the suite green, but then the capture runs on first
  /// read - inside the settlement callback, where the context is already
  /// defunct - which is the bug this field exists to close.
  /// `purchase_after_leaving_store_test.dart` reads it for the first time from
  /// an unmounted store, which is the only place that distinction shows.
  late final WalletSummaryApplier _applyWalletSummary;

  /// The wallet re-read used by settlements that arrive without amounts (a
  /// grant-confirmed duplicate). Bound eagerly for the same reason as
  /// [_applyWalletSummary].
  late final WalletSummaryRefresher _refreshWalletSummary;

  /// The wallet write a settlement will use, exposed so a test can be the
  /// first thing to read it - after the store is gone.
  @visibleForTesting
  WalletSummaryApplier get walletSummaryApplier => _applyWalletSummary;

  bool _transactionsCleared = false;
  bool _isInitializing = true;

  /// 구매 런치 성공(스토어 결제 시트 표시) 이후 앱이 resumed 이벤트를
  /// 받았는지 - **상품별** 관찰.
  ///
  /// Android 는 Play 결제 시트가 열려 있는 동안 앱이 inactive/paused 로
  /// 내려가고 시트가 닫혀야 resumed 로 복귀하므로, 90초 안전망이 울릴 때까지
  /// 그 시도의 값이 false 면 사용자가 아직 시트 안에 있다(방치 포함)고 본다 —
  /// 문구 분기는 [resolvePurchaseTimeoutNotice] 참고. 키는 안전망 타이머와
  /// 같은 canonical 상품 키를 쓴다 (Android 는 타이머가 서버 ID 로 시작되고
  /// 이벤트는 소문자 SKU 로 도착하므로 통일 필수).
  final PurchaseLaunchLifecycleTracker _launchLifecycle =
      PurchaseLaunchLifecycleTracker(
        canonicalize: PurchaseCampaignAttemptRegistry.canonicalProductKey,
      );
  final Set<String> _currentlyProcessingIDs = {};
  final PurchaseCampaignAttemptRegistry _purchaseAttempts =
      PurchaseCampaignAttemptRegistry();
  final PurchaseSettlementStep _settlementStep = const PurchaseSettlementStep();

  void _removeAttempt(String productId, String attemptId) {
    _purchaseAttempts.removeIfMatches(productId, attemptId);
  }

  @override
  void initState() {
    super.initState();
    logger.d('[PurchaseStarCandyState] initState called');

    WidgetsBinding.instance.addObserver(this);

    _applyWalletSummary = ContainerWalletSummaryApplier.of(context);
    _refreshWalletSummary = ContainerWalletSummaryRefresher.of(context);

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 앱 수명 리스너에서 서비스를 빌려 오고, 화면이 살아 있는 동안만
    // "표시 서피스"로 등록한다. 여기서 PurchaseService 를 새로 만들면 구매
    // 스트림 구독이 화면 수명에 묶여, 화면이 없는 동안 도착한 결제 이벤트가
    // 아무에게도 전달되지 않는다 (broadcast 스트림이라 유실).
    final listener = ref.read(globalPurchaseListenerProvider);
    _purchaseService = listener.purchaseService;
    _surface = listener.attachSurface(_onPurchaseUpdate);

    _restoreHandler = RestorePurchaseHandler(
      purchaseService: _purchaseService,
      loadingKey: _loadingKey,
      context: context,
    );

    _safetyManager = PurchaseSafetyManager(
      loadingKey: _loadingKey,
      resetPurchaseState: _resetAllPurchaseState,
    );

    _dialogHandler = PurchaseDialogHandler(
      context: context,
      purchaseService: _purchaseService,
    );

    // 🎯 복원 핸들러와 안전망 매니저 연결 (연속 구매 보호)
    _restoreHandler.setSafetyManager(_safetyManager);

    // 🎯 심플 타임아웃 처리: 직접 콜백 설정
    _safetyManager.onTimeoutUIReset = (productId) async {
      if (mounted) {
        setState(() {});
        _loadingKey.currentState?.hide();
        final l10n = AppLocalizations.of(context);
        // 90초가 지났다는 것은 "실패했다"가 아니다. 서버 워커의 리스는
        // 60초이고 정산은 cron 재시도를 거쳐 수 분이 걸릴 수 있으므로,
        // 이 시점의 진실은 "접수됐고 아직 처리 중"이다. 예전 문구
        // (purchase_timeout_message: "나중에 다시 시도해주세요")는 소비형
        // 상품의 재결제를 권해 이중 과금을 유도했다.
        //
        // 단, Android 에서 **이 시도의** 런치 후 앱이 한 번도 resumed 되지
        // 않았다면 사용자가 아직 Play 결제 시트 안에 있을 수 있다 — 그 경우
        // "결제가 접수되었습니다" 는 아직 일어나지 않았을 결제를 단정하므로,
        // 접수를 전제하지 않는 문구로 안내한다 (재결제 금지 안내는 두 문구
        // 모두 유지한다). 그리고 식별자 없는 취소가 관측됐고 구매 증거가
        // 전혀 없는 시도(= 사실상 취소, 취소 이벤트가 ID 없이 와서 타이머를
        // 못 지운 경우)는 팝업 자체를 생략한다 — 방금 취소한 사용자에게
        // "접수됐다" 는 안내는 무의미하다 (iOS 실기기, 2026-08-06). 판정은
        // 타이머가 알려 준 productId 의 관찰값만 쓴다 - 다른 상품의 런치가
        // 이 시도의 이력을 덮으면 안 된다.
        final observation = _launchLifecycle.observationFor(productId);
        final notice = resolvePurchaseTimeoutNotice(
          isIOS: Platform.isIOS,
          resumedSincePurchaseLaunch: observation.resumedSinceLaunch,
          currentLifecycleState: WidgetsBinding.instance.lifecycleState,
          identitylessCancellationObserved:
              observation.identitylessCancellationObserved,
          purchaseEvidenceObserved: observation.purchaseEvidenceObserved,
        );
        _launchLifecycle.clear(productId);
        if (notice == PurchaseTimeoutNotice.suppressed) {
          // 관찰(신원 없는 취소)만으로는 인과를 증명할 수 없다 - 이전
          // 세대의 지연 취소가 새 시도에 잘못 기록됐을 가능성을 배제할 수
          // 없으므로, 생략 전에 스토어 큐를 실측으로 재확인한다. 판정은
          // boolean 요약이 아니라 리포트로 한다: 스윕이 발견 즉시 정산에
          // 성공하면(found>0, settled>0, preserved==0) 요약은 "비어
          // 있음"과 구분되지 않는데, 그 경우는 실결제가 있었던 것이므로
          // 무통보로 생략하면 안 된다 (Sol 머지 게이트 리뷰, PR #137).
          // **큐를 확인했고 애초에 아무것도 없었을 때만** 생략한다.
          final report = await _restoreHandler.resolveStoreQueueSweep();
          if (!mounted) return;
          if (report?.verifiedEmpty ?? false) {
            logger.i(
              '[PurchaseStarCandyState] Safety timeout for $productId '
              'suppressed - identity-less cancellation observed, no '
              'purchase evidence, store queue verified empty',
            );
            return;
          }
          // 스윕이 방금 실결제를 정산했다면 지갑에 반영부터 한다 - 안내
          // 없이 잔액만 바뀌어 있으면 더 혼란스럽다.
          if (report != null && report.settled > 0) {
            await _refreshWalletSummary.refresh();
            if (!mounted) return;
          }
          logger.w(
            '[PurchaseStarCandyState] Suppression aborted for $productId - '
            'store queue not verified empty '
            '(found=${report?.found}, settled=${report?.settled}, '
            'preserved=${report?.preserved}), keeping the warning',
          );
          showSimpleDialog(content: l10n.purchase_payment_accepted_message);
          return;
        }
        showSimpleDialog(
          content: notice == PurchaseTimeoutNotice.paymentUnconfirmed
              ? l10n.purchase_payment_unconfirmed_message
              : l10n.purchase_payment_accepted_message,
        );
      }
    };
    _safetyManager.onProductTimeout = (productId, attemptId) {
      if (attemptId != null) {
        _purchaseAttempts.removeIfMatches(productId, attemptId);
      }
      if (mounted) setState(() {});
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });
  }

  /// 페이지 초기화 (복원 구매 예방적 정리 포함)
  Future<void> _initializePage() async {
    final initStartTime = DateTime.now();
    final platform = Theme.of(context).platform;
    logger.i(
      '[PurchaseStarCandyState] Starting initialization with proactive restore cleanup (${platform.name})',
    );

    if (!mounted) return;

    try {
      _loadingKey.currentState?.show();

      await _restoreHandler.performProactiveCleanup();

      final initEndTime = DateTime.now();
      final initDuration = initEndTime.difference(initStartTime);
      logger.i(
        '[PurchaseStarCandyState] Initialization completed - Duration: ${initDuration.inMilliseconds}ms',
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _transactionsCleared = true;
        });
        _loadingKey.currentState?.hide();
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] Initialization failed: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _transactionsCleared = true;
        });
        _loadingKey.currentState?.hide();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _launchLifecycle.recordResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restoreHandler.dispose();
    _safetyManager.disposeSafetyTimer();
    _rotationController.dispose();
    // 구매 스트림 구독은 여기서 끊지 않는다 - 애초에 이 화면의 것이 아니다.
    // 표시 서피스만 반납하면, 이 뒤에 도착하는 결제 완료 이벤트는
    // GlobalPurchaseListener 의 무화면 정산이 받아 검증·적립·지갑 반영까지
    // 수행한다 (그리고 띄울 화면이 있으면 공용 영수증까지). 예전에는 구독을
    // 유지한 채 dispose 된 State 의 콜백이 계속 이벤트를 받았고, 그래서
    // "화면이 없는 동안"은 첫 스토어 진입 이후에만 커버됐다.
    _surface?.detach();
    _surface = null;
    // 타이머류만 정리한다.
    _purchaseService.inAppPurchaseService.cleanupPurchaseTimersOnSuccess();
    super.dispose();
  }

  /// 구매 취소 감지
  bool _isPurchaseCanceled(PurchaseDetails purchaseDetails) {
    return PurchaseHelper.isPurchaseCanceled(purchaseDetails);
  }

  /// 특정 시도에 안전하게 묶일 수 없는 이벤트인지.
  ///
  /// 거래ID(purchaseID)가 없으면 productID가 있어도 묶지 않는다 - productID는
  /// 거래 식별자가 아니고, 레지스트리는 상품당 컨텍스트를 하나만 들고 있어
  /// 이미 정리된 이전 시도의 지연 이벤트가 같은 상품의 새 시도를 잘못 지울
  /// 수 있다 (Codex Frontier 리뷰, PR #137).
  bool _isIdentityless(PurchaseDetails purchaseDetails) {
    return purchaseDetails.purchaseID == null ||
        purchaseDetails.purchaseID!.isEmpty;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    final statusCounts = _getStatusCounts(purchaseDetailsList);

    logger.d(
      '''[PurchaseStarCandyState] Purchase update received:
Total: ${purchaseDetailsList.length} | Cleared: $_transactionsCleared
Pending: ${statusCounts['pending']} | Restored: ${statusCounts['restored']} | Purchased: ${statusCounts['purchased']} | Error: ${statusCounts['error']} | Canceled: ${statusCounts['canceled']}''',
    );

    try {
      for (final purchaseDetails in purchaseDetailsList) {
        final purchaseID = purchaseDetails.purchaseID;
        if (purchaseID != null &&
            _currentlyProcessingIDs.contains(purchaseID)) {
          logger.w(
            '[PurchaseStarCandyState] Skipping already processing purchase: $purchaseID',
          );
          continue;
        }

        if (purchaseID != null) {
          _currentlyProcessingIDs.add(purchaseID);
        }

        try {
          await _processPurchaseDetail(purchaseDetails);
        } finally {
          if (purchaseID != null) {
            _currentlyProcessingIDs.remove(purchaseID);
          }
        }
      }
    } catch (e, s) {
      logger.e(
        '[PurchaseStarCandyState] Error handling purchase update: $e',
        error: e,
        stackTrace: s,
      );
      _loadingKey.currentState?.hide();
      if (navigatorKey.currentContext != null) {
        await _dialogHandler.showErrorDialog(
          AppLocalizations.of(
            navigatorKey.currentContext!,
          ).dialog_message_purchase_failed,
        );
      }
      rethrow;
    }
  }

  /// 상태별 구매 개수 계산
  Map<String, int> _getStatusCounts(List<PurchaseDetails> purchaseDetailsList) {
    return PurchaseHelper.getStatusCounts(purchaseDetailsList);
  }

  /// 개별 구매 상세 처리
  Future<void> _processPurchaseDetail(PurchaseDetails purchaseDetails) async {
    logger.d(
      '[PurchaseStarCandyState] Processing: ${purchaseDetails.status} for ${purchaseDetails.productID}',
    );

    // 순수 관찰: 이 상품의 구매 증거가 도착했다. 아래의 어떤 게이트에서
    // 이벤트가 버려지든, 90초 안전망의 "사실상 취소" 판정(팝업 생략)은
    // 구매 흔적이 하나라도 있으면 절대 내려지면 안 된다.
    //
    // 단, 이 화면의 시도와 무관한 이벤트(초기화 정리의 restored, 과거
    // 구매의 재전달 orphan)까지 기록하면 latch 가 미래 시도를 오염시켜
    // 정당한 취소 억제가 무력화된다 (Sol 2차 재검증 MEDIUM-2). 런치 관찰이
    // 이미 있거나(별칭 포함) 이 상품의 attempt 가 살아 있는 이벤트만
    // 관찰한다. 게이트에 걸려 놓친 증거의 결과는 "팝업 생략 조건이 하나 덜
    // 채워짐" = 팝업 표시 쪽이므로 안전 방향이다.
    if ((purchaseDetails.status == PurchaseStatus.pending ||
            purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) &&
        purchaseDetails.productID.isNotEmpty &&
        _storeEventBelongsToLiveObservationOrAttempt(
          purchaseDetails.productID,
        )) {
      _launchLifecycle.recordPurchaseEvidence(purchaseDetails.productID);
    }

    // Android에서 pending 구매를 완료(consume)하는 것은 계약 위반이고,
    // 결제 완료 전 소비 시도가 된다. iOS의 막힌 StoreKit 트랜잭션 정리
    // 용도로만 유지한다.
    if (Platform.isIOS && _shouldForceCompletePending(purchaseDetails)) {
      await _forceCompletePendingPurchase(purchaseDetails);
      return;
    }

    if (purchaseDetails.status == PurchaseStatus.pending &&
        !_purchaseAttempts.contains(purchaseDetails.productID)) {
      logger.i(
        '[PurchaseStarCandyState] Purchase pending for ${purchaseDetails.productID}',
      );
      return;
    }

    if (_shouldIgnoreDuringInit(purchaseDetails)) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // 초기화 중이라도 실결제 이벤트는 버리면 안 된다.
        // (autoConsume 시절 유실 사고의 한 경로) UI 없이 정산만 태운다.
        // iOS도 포함: 여기서 버려진 iOS 결제는 다음 실행의
        // _clearIosPendingTransactions가 검증 없이 finish해 영구 유실된다.
        logger.w(
          '[PurchaseStarCandyState] Purchased event during init - running '
          'headless settlement: ${purchaseDetails.purchaseID}',
        );
        await _settleOrphanPurchase(purchaseDetails);
        return;
      }
      logger.i(
        '[PurchaseStarCandyState] Ignoring ${purchaseDetails.status} during initialization: ${purchaseDetails.productID}',
      );
      return;
    }

    if (_shouldProcessRestored(purchaseDetails)) {
      await _processRestoredPurchase(purchaseDetails);
      return;
    }

    // purchased 이벤트가 런치 확정보다 먼저 도착하는 레이스를 흡수한다 -
    // 유예 없이 orphan으로 보내면 적립은 되지만 영수증 다이얼로그가
    // 생략된다 (iOS 실기기, 2026-07-28).
    final boundAttempt = await _purchaseAttempts.bindWithLaunchGrace(
      purchaseDetails,
    );
    if (boundAttempt == null &&
        purchaseDetails.status != PurchaseStatus.pending) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // 실결제가 끝난 이벤트는 UI 어템프트에 bind되지 않아도(90초 타임아웃
        // 뒤 도착, 화면 재진입, 기기·스토어 시계 오차 등) 반드시 정산까지
        // 태운다. 여기서 버리면 사용자는 과금됐는데 캔디가 영구 미적립된다.
        // iOS 제외 금지: 이 경로를 iOS에서 막았던 동안 모든 iOS 구매가
        // 무한 로딩 + 미적립이었다 (2026-07-28). 성공 다이얼로그만 생략한다.
        logger.w(
          '[PurchaseStarCandyState] Orphan purchased event - running '
          'headless settlement: ${purchaseDetails.purchaseID}',
        );
        await _settleOrphanPurchase(purchaseDetails);
        return;
      }
      if (_isIdentityless(purchaseDetails) &&
          (purchaseDetails.status == PurchaseStatus.error ||
              purchaseDetails.status == PurchaseStatus.canceled)) {
        // Android Play Billing 에러/취소는 productID·purchaseID 없이
        // 도착할 수 있다 (실기기 재현: responseCode 3). 어떤 시도의
        // 것인지 판별할 방법이 없으므로(시간 경계를 증명할 수 없는
        // 발견적 매칭은 다른 시도를 잘못 지울 위험이 있어 폐기했다 -
        // Codex Frontier 리뷰, PR #137) 시도 상태는 건드리지 않는다.
        // 전역 로딩 오버레이만 내려 최소한 화면이 무한정 잠기지는
        // 않게 한다 - 실제로 진행 중인 시도가 있었다면 그 상품의
        // 버튼 로딩·안전망은 그대로 유지되어 자기 완결 경로나 90초
        // 안전망으로 정리된다.
        logger.w(
          '[PurchaseStarCandyState] Identity-less ${purchaseDetails.status} '
          '- releasing global loading only, no attempt touched',
        );
        // 순수 관찰: 어느 시도의 취소인지 증명할 수 없어 상태는 못 지우지만,
        // 90초 안전망이 울릴 때 "구매 증거 없음 + 취소 관측"이면 접수
        // 팝업을 생략하는 근거로는 쓴다 (틀려도 팝업이 한 번 더 뜰 뿐,
        // 상태를 잘못 지우는 위험이 없다).
        _launchLifecycle.recordIdentitylessCancellation();
        if (mounted) _loadingKey.currentState?.hide();
        // 이벤트로는 어느 시도의 것인지 증명할 수 없지만, 스토어 큐를 다시
        // 조회하는 것은 증명이 된다 - 큐가 애초에 비어 있으면 살아 있는
        // 트랜잭션이 하나도 없다는 뜻이라 남은 시도는 UI 상태일 뿐이다.
        // 이걸 안 하면 취소한 상품의 버튼이 90초 안전망까지 스피너로 남고,
        // 사용자가 다른 상품을 사도 그대로다 (실기기 재현, 2026-08-07).
        // 이벤트 처리를 스토어 왕복만큼 지연시키지 않도록 기다리지 않는다.
        //
        // 단, 거래ID 있는 이벤트가 지금 처리 중이면(= 실결제가 정산되는
        // 중이면) 미룬다. 스윕은 발견한 트랜잭션을 스스로 검증·정산하므로,
        // 진행 중인 정산과 겹치면 영수증 다이얼로그를 띄우는 화면 경로 대신
        // 무음으로 처리될 수 있다. 그 경우 정리는 다음 구매 버튼 누름이나
        // 90초 안전망이 이어받는다.
        if (_currentlyProcessingIDs.isEmpty) {
          unawaited(_reconcileStaleAttemptsIfQueueEmpty());
        }
        return;
      }
      logger.w(
        '[PurchaseStarCandyState] Rejecting orphan, restored, stale, or '
        'duplicate transaction: ${purchaseDetails.purchaseID}',
      );
      return;
    }

    if (_shouldProcessActivePurchase(purchaseDetails)) {
      await _processActivePurchase(purchaseDetails, boundAttempt);
      return;
    }

    await _processErrorAndCancel(purchaseDetails, boundAttempt);
  }

  /// 이 스토어 이벤트가 살아 있는 런치 관찰 또는 활성 attempt 의 것인지.
  ///
  /// 이벤트의 productID 는 스토어 표기(iOS 접두사·Android 네임스페이스)일
  /// 수 있으므로, 관찰 별칭 키와 서버 ID 역해석 후보 양쪽으로 조회한다.
  /// 어느 쪽에도 없으면 이 화면의 시도와 무관한 이벤트(초기화 정리의
  /// restored, 과거 구매 재전달)다 - 그런 이벤트를 latch 하면 미래 시도의
  /// 취소 억제를 오염시킨다 (Sol 2차 재검증 MEDIUM-2).
  bool _storeEventBelongsToLiveObservationOrAttempt(String eventProductId) {
    if (_launchLifecycle.hasObservation(eventProductId)) return true;
    return serverProductIdCandidatesForStoreEvent(
      eventProductId,
      iosAppPrefix: Environment.inappAppNamePrefix,
      androidNamespace: Environment.storeQueryNamespace,
    ).any(_purchaseAttempts.contains);
  }

  /// UI 어템프트 없이 도착한 실결제 이벤트의 정산.
  ///
  /// 영수증 검증 → 서버 적립 → (확정 시) 구매 완료(consume)와 지갑 반영까지
  /// 수행하되, 성공 다이얼로그는 띄우지 않는다. 검증 실패 시 구매는
  /// 소비되지 않고 남아 큐/reconcile이 재시도한다.
  Future<void> _settleOrphanPurchase(PurchaseDetails purchaseDetails) async {
    // 이 상품의 시도가 화면에서 진행 중인데 이벤트가 bind에 실패해 orphan으로
    // 떨어진 경우(시계 오차 등), 정산이 끝나는 대로 스피너와 시도 상태를
    // 반드시 풀어 준다 — 안 풀면 90초 안전망까지 무한 로딩으로 보인다.
    final liveAttempt = _purchaseAttempts[purchaseDetails.productID];
    void releaseLiveAttempt() {
      if (liveAttempt == null || !mounted) return;
      _resetProductPurchaseState(
        purchaseDetails.productID,
        attemptId: liveAttempt.attemptId,
        terminal: true,
      );
      _loadingKey.currentState?.hide();
    }

    try {
      await _purchaseService.handleOptimizedPurchase(
        purchaseDetails,
        (result) async {
          _applyWalletSummary(result.wallet);
          releaseLiveAttempt();
          logger.i(
            '[PurchaseStarCandyState] Orphan settlement credited: '
            '${purchaseDetails.purchaseID}',
          );
          // 이 정산은 사용자가 아무 안내도 받지 못한 것이다 — 원 결제가
          // 실패로 끝났다가 서버에서 나중에 정산된 재전달이 대표적이다
          // (1.3.0 베타 STAR200). 금액이 있는 정산이고 스토어가 화면에
          // 있으면 공용 영수증 다이얼로그로 알린다. 이미 제시된 재전달은
          // showSuccessDialog가 재전달 안내로 스스로 라우팅하므로, 받은 적
          // 없는 캔디를 받았다고 두 번 말하는 일은 생기지 않는다.
          // 화면이 없으면 종전대로 무음이다: navigatorKey는 앱 전역이라
          // 스토어 밖에서 영수증을 띄우면 엉뚱한 화면 위로 뜬다.
          if (mounted) {
            await _dialogHandler.showSuccessDialog(
              result: result,
              displayedCampaign: liveAttempt?.displayedCampaign,
            );
          }
        },
        (error) {
          logger.w('[PurchaseStarCandyState] Orphan settlement error: $error');
          releaseLiveAttempt();
        },
        isActualPurchase: true,
        // 이미 서버에서 정산된 재전달이다. 금액이 없으니 지갑은 다시 읽고,
        // 스피너·안전망은 성공과 똑같이 내린다. 성공 다이얼로그를 띄우지
        // 않는 것만 orphan 경로의 기존 정책과 같다.
        onAlreadySettled: () => _settlementStep.settleServerConfirmed(
          safetyManager: _safetyManager,
          attempts: _purchaseAttempts,
          purchaseDetails: purchaseDetails,
          attempt: liveAttempt,
          cleanupAllTimersOnSuccess: _cleanupAllTimersOnSuccess,
          refreshWallet: _refreshWalletSummary,
          isMounted: () => mounted,
          resetProductPurchaseState: _resetProductPurchaseState,
          hideLoading: () => _loadingKey.currentState?.hide(),
        ),
      );
    } catch (e, s) {
      logger.e(
        '[PurchaseStarCandyState] Orphan settlement failed: $e',
        stackTrace: s,
      );
      releaseLiveAttempt();
    }
  }

  /// 초기화 중 pending 구매 강제 완료 여부 확인
  bool _shouldForceCompletePending(PurchaseDetails purchaseDetails) {
    return PurchaseHelper.shouldForceCompletePending(
      isActivePurchasing: _purchaseAttempts.contains(purchaseDetails.productID),
      transactionsCleared: _transactionsCleared,
      purchaseDetails: purchaseDetails,
    );
  }

  /// 초기화 중 무시할 구매 여부 확인
  bool _shouldIgnoreDuringInit(PurchaseDetails purchaseDetails) {
    return PurchaseHelper.shouldIgnoreDuringInit(
      isActivePurchasing: _purchaseAttempts.contains(purchaseDetails.productID),
      transactionsCleared: _transactionsCleared,
      purchaseDetails: purchaseDetails,
    );
  }

  bool _shouldProcessRestored(PurchaseDetails purchaseDetails) {
    return _restoreHandler.shouldProcessRestored(purchaseDetails);
  }

  bool _shouldProcessActivePurchase(PurchaseDetails purchaseDetails) {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    logger.i('[플랫폼별] 📱 $platform 활성 구매 판별: ${purchaseDetails.productID}');

    // 📱 iOS와 🤖 Android 완전 분리 처리
    if (Platform.isIOS) {
      return _shouldProcessActivePurchaseIOS(purchaseDetails);
    } else {
      return _shouldProcessActivePurchaseAndroid(purchaseDetails);
    }
  }

  /// 🍎 iOS 전용 활성 구매 판별 - 유연한 3단계 처리
  bool _shouldProcessActivePurchaseIOS(PurchaseDetails purchaseDetails) {
    return PurchaseHelper.shouldProcessActivePurchaseIOS(
      purchaseDetails: purchaseDetails,
      isActivePurchasing: _purchaseAttempts.contains(purchaseDetails.productID),
      // Transaction identity was already bound by _processPurchaseDetail.
      // Legacy global safety fields must not be transaction authority.
      isSafetyTimeoutTriggered: false,
      safetyTimeoutTime: null,
      isActualPurchaseCheck: (_) => true,
    );
  }

  /// 🤖 Android 전용 활성 구매 판별 - 엄격한 2단계 처리
  bool _shouldProcessActivePurchaseAndroid(PurchaseDetails purchaseDetails) {
    return PurchaseHelper.shouldProcessActivePurchaseAndroid(
      purchaseDetails: purchaseDetails,
      isActivePurchasing: _purchaseAttempts.contains(purchaseDetails.productID),
      isSafetyTimeoutTriggered: false,
      safetyTimeoutTime: null,
      isActualPurchaseCheck: (_) => true,
    );
  }

  /// 초기화 중 pending 구매 강제 완료
  Future<void> _forceCompletePendingPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    await PurchaseProcessor.forceCompletePendingPurchase(
      purchaseDetails: purchaseDetails,
      inAppPurchaseService: _purchaseService.inAppPurchaseService,
    );
  }

  Future<void> _processRestoredPurchase(PurchaseDetails purchaseDetails) async {
    await _restoreHandler.processRestoredPurchase(purchaseDetails);
  }

  /// 활성 구매 처리
  Future<void> _processActivePurchase(
    PurchaseDetails purchaseDetails,
    PurchaseCampaignAttempt? boundAttempt,
  ) async {
    final attempt = boundAttempt;
    if (attempt == null) {
      throw StateError(
        'Actual purchase event has no matching execution context',
      );
    }
    const isActualPurchase = true;

    logger.i(
      '[PurchaseStarCandyState] Processing active purchase: ${purchaseDetails.productID} (actual: $isActualPurchase)',
    );

    await _purchaseService.handleOptimizedPurchase(
      purchaseDetails,
      (result) async {
        await _settlementStep.settle(
          safetyManager: _safetyManager,
          attempts: _purchaseAttempts,
          purchaseDetails: purchaseDetails,
          result: result,
          attempt: attempt,
          cleanupAllTimersOnSuccess: _cleanupAllTimersOnSuccess,
          applyWalletSummary: _applyWalletSummary,
          isMounted: () => mounted,
          resetProductPurchaseState: _resetProductPurchaseState,
          hideLoading: () => _loadingKey.currentState?.hide(),
          receiptDialogs: _dialogHandler,
        );
      },
      (error) async {
        if (mounted) {
          // ✅ UI만 리셋하고 쿨다운은 유지하여 즉시 연속 구매 차단
          _safetyManager.resetUIOnly(reason: '구매 에러/중복 처리 후 UI만 리셋');
          _loadingKey.currentState?.hide();

          final action = PurchaseProcessor.classifyError(error);

          switch (action) {
            case PurchaseErrorAction.showPendingMessage:
              // 정산 단계에서 도착한 중복 판정. 결제는 이미 접수됐으므로
              // "잠시 후 다시 시도해 주세요"(previousTransactionPendingError)로
              // 안내하면 사용자는 같은 소비형 상품을 한 번 더 결제하고, 그
              // 이중 과금은 되돌릴 수 없다. "접수됐고 처리되면 자동 적립된다"로
              // 안내한다. (지급이 확정된 중복은 애초에 여기 오지 않는다 —
              // onAlreadySettled 정산 경로를 탄다.)
              if (navigatorKey.currentContext != null) {
                showSimpleDialog(
                  content: AppLocalizations.of(
                    navigatorKey.currentContext!,
                  ).purchase_payment_accepted_message,
                );
              }
              // 이 상품만 쿨다운으로 막는다 - 다른 상품의 구매는 열려 있다.
              _safetyManager.activateDuplicateCooldown(
                productId: attempt.productId,
                cooldown: const Duration(minutes: 1),
              );
              break;

            case PurchaseErrorAction.showCooldownMessage:
              // 쿨다운 위반도 동일하게 안내만, 추가 쿨타임 미적용
              if (navigatorKey.currentContext != null) {
                showSimpleDialog(
                  content: AppLocalizations.of(
                    navigatorKey.currentContext!,
                  ).previousTransactionPendingError,
                );
              }
              break;

            case PurchaseErrorAction.duplicateWithCooldown:
              // 문자열 기반 중복 케이스도 동일 처리: 안내만
              // iOS 캐시성 중복 신호 완화용 강제 쿨다운(상품별) 60초
              _safetyManager.activateDuplicateCooldown(
                productId: attempt.productId,
                cooldown: const Duration(minutes: 1),
              );
              break;

            case PurchaseErrorAction.showMappedError:
              final errorType = PurchaseProcessor.mapErrorToType(error);

              if (PurchaseProcessor.isSettlementPending(errorType)) {
                // 결제는 접수됐고 정산 결과만 아직 모른다 (타임아웃 · 소켓
                // 오류 · 5xx · 서버의 retryable 응답). 클라이언트 예산은
                // 30초×재시도지만 서버 워커의 리스는 60초이고 실패한
                // 오퍼레이션은 cron 재시도를 타므로, 여기서 종결 실패로
                // 안내하면 **적립 직전의 결제**를 실패로 알리는 셈이 된다.
                // 사용자는 그 안내를 따라 같은 소비형 상품을 한 번 더
                // 결제하고, 그 이중 과금은 되돌릴 수 없다.
                logger.w(
                  '[PurchaseStarCandyState] Settlement still pending: $error',
                );
                // 스피너를 풀고(안 풀면 무한 로딩), 90초 지연 팝업 타이머를
                // 앞당겨 내리고(안 내리면 같은 안내가 두 번 뜬다), 이 상품의
                // 재구매를 쿨다운으로 막는다.
                final alreadyAnnounced = _safetyManager.markSettlementPending(
                  attempt.productId,
                );
                _purchaseAttempts.removeIfMatches(
                  attempt.productId,
                  attempt.attemptId,
                );
                if (mounted) setState(() {});
                // 늦게 도착하는 정산은 유실되지 않는다: bind 되지 않은
                // purchased 이벤트를 _settleOrphanPurchase 가 받아 지갑까지
                // 반영하고 영수증을 띄운다.
                if (!alreadyAnnounced) {
                  await _presentPurchaseFailure(error);
                }
                break;
              }

              logger.e('[PurchaseStarCandyState] Purchase error: $error');
              if (PurchaseProcessor.isTerminalMappedError(errorType)) {
                // 종결 실패에서 어템프트만 지우면 launch 때 armed된 90초
                // 안전망 타이머가 살아남아, 에러 다이얼로그 뒤에 "구매 처리
                // 지연" 팝업을 또 띄운다 (1.3.0 베타). 타이머·활성 상품
                // 상태까지 함께 내린다. 스토어 트랜잭션 보존과 큐 재시도는
                // PurchaseService 쪽에서 결정되므로 여기 UI 정리의 영향을
                // 받지 않는다.
                _resetProductPurchaseState(
                  purchaseDetails.productID,
                  attemptId: attempt.attemptId,
                  terminal: true,
                );
              }
              await _presentPurchaseFailure(error);
              break;
          }
        }
      },
      isActualPurchase: isActualPurchase,
      // 서버가 지급까지 확정한 중복은 성공이다. 실패로 다루던 동안 이 상품의
      // 버튼은 90초 안전망까지 로딩에 잠긴 채 남고(그 뒤 "구매 처리 지연"
      // 팝업), 지갑은 갱신되지 않고, 60초 중복 쿨다운이 재시도까지 막았다.
      onAlreadySettled: () => _settlementStep.settleServerConfirmed(
        safetyManager: _safetyManager,
        attempts: _purchaseAttempts,
        purchaseDetails: purchaseDetails,
        attempt: attempt,
        cleanupAllTimersOnSuccess: _cleanupAllTimersOnSuccess,
        refreshWallet: _refreshWalletSummary,
        isMounted: () => mounted,
        resetProductPurchaseState: _resetProductPurchaseState,
        hideLoading: () => _loadingKey.currentState?.hide(),
        acknowledge: _dialogHandler.showAlreadySettledDialog,
      ),
    );
  }

  /// 에러 및 취소 처리
  Future<void> _processErrorAndCancel(
    PurchaseDetails purchaseDetails,
    PurchaseCampaignAttempt? boundAttempt,
  ) async {
    final attempt = boundAttempt;
    // Android Play Billing 에러/취소는 productID가 빈 채로 도착할 수 있다
    // (실기기 재현: responseCode 3). boundAttempt 가 있으면 그게 바인딩 시점에
    // 판별된 진짜 상품ID이므로 그것을 우선한다 - purchaseDetails.productID를
    // 그대로 쓰면 버튼 로딩·90초 안전망 타이머가 엉뚱한(빈) 키를 리셋해
    // STAR100 쪽은 그대로 남는다.
    final productId = attempt?.productId ?? purchaseDetails.productID;
    if (attempt != null) {
      if (!_purchaseAttempts.finish(purchaseDetails, attempt.attemptId)) {
        _removeAttempt(productId, attempt.attemptId);
      }
    }
    // Android는 결제창을 벗어난 취소를 error가 아니라 canceled 상태로 스트림에
    // 태운다. 이 분기가 error만 처리하던 동안 canceled 이벤트는 로딩도 내리지
    // 않고 상태도 리셋되지 않은 채 조용히 지나가, 90초 안전망까지 무한 로딩으로
    // 보였다 (실기기 재현, 2026-08-05).
    if (purchaseDetails.status == PurchaseStatus.error ||
        purchaseDetails.status == PurchaseStatus.canceled) {
      final isCanceled =
          purchaseDetails.status == PurchaseStatus.canceled ||
          _isPurchaseCanceled(purchaseDetails);

      if (purchaseDetails.status == PurchaseStatus.error) {
        logger.e(
          '[PurchaseStarCandyState] Purchase error: ${purchaseDetails.error?.message}',
        );
      }

      if (mounted) {
        // ✅ 일반 오류: 상품별 쿨타임 적용하지 않음 (초기화는 굳이 강제하지 않음)
        _resetProductPurchaseState(productId);
        _loadingKey.currentState?.hide();

        if (!isCanceled) {
          logger.e(
            '[PurchaseStarCandyState] Actual purchase error - showing dialog',
          );
          await _dialogHandler.showErrorDialog(
            AppLocalizations.of(context).dialog_message_purchase_failed,
          );
        } else {
          // ✅ 취소: 쿨타임 적용하지 않음
          logger.i(
            '[PurchaseStarCandyState] Purchase canceled - no error dialog',
          );
        }
      }
    }

    // 🔥 중요: 에러가 발생하거나 취소된 경우에도 트랜잭션을 완료하여 반복적인 팝업을 방지합니다.
    await PurchaseProcessor.completeFailedTransaction(
      purchaseDetails: purchaseDetails,
      inAppPurchaseService: _purchaseService.inAppPurchaseService,
    );
  }

  /// 🧹 정상 구매 완료 시 모든 타이머 완전 정리
  void _cleanupAllTimersOnSuccess(String productId) {
    PurchaseProcessor.cleanupAllTimersOnSuccess(
      productId: productId,
      safetyManager: _safetyManager,
      restoreHandler: _restoreHandler,
      purchaseService: _purchaseService,
    );
  }

  /// 구매 실패 코드를 사용자 안내로 바꾸는 **유일한** 표시 지점.
  ///
  /// 런치 단계(`initiatePurchase` 결과 맵)와 정산 단계(`onError`)가 모두
  /// 여기로 모인다. 코드를 arb 문장으로 바꾸는 일이 두 곳에 흩어져 있으면
  /// 한쪽이 원문(한국어 하드코딩)을 그대로 띄우는 상태로 남는다.
  Future<void> _presentPurchaseFailure(String errorCode) async {
    if (!mounted) return;
    final dialogContext = navigatorKey.currentContext ?? context;
    final l10n = AppLocalizations.of(dialogContext);
    final type = PurchaseProcessor.mapErrorToType(errorCode);
    final message = _resolveErrorMessage(type, l10n);

    if (PurchaseProcessor.isSettlementPending(type)) {
      // 실패가 아니라 "접수됨" 안내다. 빨간 오류 다이얼로그로 띄우면
      // 사용자는 결제가 무효가 됐다고 읽고 다시 결제한다.
      showSimpleDialog(content: message);
      return;
    }
    await _dialogHandler.showErrorDialog(message);
  }

  /// PurchaseErrorType을 i18n 메시지 문자열로 변환
  String _resolveErrorMessage(PurchaseErrorType type, AppLocalizations l10n) {
    switch (type) {
      case PurchaseErrorType.previousTransactionPending:
        return l10n.previousTransactionPendingError;
      case PurchaseErrorType.receiptVerificationFailed:
        return l10n.error_receipt_verification_failed;
      case PurchaseErrorType.userNotAuthenticated:
        return l10n.error_user_not_authenticated;
      case PurchaseErrorType.productNotFound:
        return l10n.error_product_not_found;
      case PurchaseErrorType.processing:
      case PurchaseErrorType.timeout:
        return l10n.purchase_payment_accepted_message;
      case PurchaseErrorType.networkError:
        return l10n.error_network_connection;
      case PurchaseErrorType.serverError:
        return l10n.network_error_message;
      case PurchaseErrorType.purchaseCancelled:
        return l10n.purchase_cancelled_message;
      case PurchaseErrorType.purchaseInProgress:
        return l10n.purchase_in_progress_message;
      case PurchaseErrorType.purchaseFailed:
        return l10n.dialog_message_purchase_failed;
    }
  }

  void _resetProductPurchaseState(
    String productId, {
    String? attemptId,
    bool terminal = false,
  }) {
    _safetyManager.resetProductState(productId);
    // 타이머가 내려간 시도는 더 이상 타임아웃 문구 판정이 없다 - 관찰 종료.
    _launchLifecycle.clear(productId);
    if (terminal && attemptId != null) {
      _purchaseAttempts.removeIfMatches(productId, attemptId);
    }
    if (mounted) setState(() {});
  }

  void _resetAllPurchaseState() {
    _safetyManager.disposeSafetyTimer();
    _safetyManager.resetInternalState(reason: '명시적 전체 세션 리셋');
    if (mounted) setState(() {});
  }

  Future<void> _handleBuyButtonPressed(
    BuildContext context,
    Map<String, dynamic> serverProduct,
    List<ProductDetails> storeProducts,
  ) async {
    // 로그인 상태를 실시간으로 체크
    final userInfo = ref.read(userInfoProvider);
    final isLoggedIn = userInfo.value != null;

    if (!isLoggedIn) {
      showRequireLoginDialog();
      return;
    }

    if (_isInitializing) {
      logger.w(
        '[PurchaseStarCandyState] Purchase blocked during initialization',
      );
      showSimpleDialog(
        content: AppLocalizations.of(context).purchase_initializing_message,
      );
      return;
    }

    final productId = serverProduct['id'] as String;
    await _reconcileStaleAttemptsIfQueueEmpty();
    if (!context.mounted) return;

    if (!_canPurchase(productId: productId)) {
      return;
    }

    // 🔒 구매 확인 다이얼로그 표시
    final campaigns = ref.read(
      activePromotionCampaignProvider(PromotionSurface.store),
    );
    final displayedCampaign = campaigns.value?.items
        .where((campaign) => campaign.showInStore)
        .firstOrNull;
    if (_purchaseAttempts.contains(productId)) {
      await _dialogHandler.showPurchaseAlreadyPendingDialog();
      return;
    }
    final confirmed = await _dialogHandler.showPurchaseConfirmDialog(
      serverProduct: serverProduct,
      storeProducts: storeProducts,
      displayedCampaign: displayedCampaign,
    );

    if (confirmed == true && context.mounted) {
      final attempt = PurchaseCampaignAttempt(
        attemptId: const Uuid().v4(),
        productId: productId,
        displayedCampaign: displayedCampaign,
      );
      if (!_purchaseAttempts.begin(attempt)) {
        await _dialogHandler.showPurchaseAlreadyPendingDialog();
        return;
      }
      try {
        await _processPurchase(
          context,
          serverProduct,
          storeProducts,
          attemptId: attempt.attemptId,
        );
      } catch (_) {
        _removeAttempt(productId, attempt.attemptId);
        rethrow;
      }
    }
  }

  // 🎯 실제 구매 처리 로직
  Future<void> _processPurchase(
    BuildContext context,
    Map<String, dynamic> serverProduct,
    List<ProductDetails> storeProducts, {
    required String attemptId,
  }) async {
    // 🛡️ 복원 정리 완료 대기 가드
    //
    // 게이트가 닫혀 있으면 **지금 다시 검증한다**. 진입 시 스윕 한 번의
    // 결과를 그대로 래치하면, 로그인 전에 스토어를 열었거나(notSignedIn)
    // 부팅 직후 조회가 실패한 사용자는 안내문("잠시 후 다시 시도해주세요")과
    // 달리 아무리 다시 눌러도 영구히 막힌다 - iOS 첫 구매 시도에 "초기화
    // 중입니다"가 뜨던 경로다 (2026-08-07). 재검증도 실패하면 예전과 똑같이
    // 막는다: "확인하지 못했다"는 여전히 구매 허용 사유가 아니다.
    if (!_restoreHandler.isProactiveCleanupCompleted) {
      final l10n = AppLocalizations.of(context);
      _loadingKey.currentState?.show();
      final verified = await _restoreHandler.ensureProactiveCleanupCompleted();
      if (!verified || !mounted) {
        _loadingKey.currentState?.hide();
        _removeAttempt(serverProduct['id'] as String, attemptId);
        if (verified || !mounted) return;
        logger.w('🛡️ 복원 정리가 재검증에도 실패 - 구매 차단');
        setState(() {});
        showSimpleDialog(content: l10n.purchase_initializing_message);
        return;
      }
      logger.i('🛡️ 복원 정리 재검증 통과 - 구매 진행');
    }

    _setPurchaseStartState(serverProduct['id']);

    try {
      logger.i(
        '[PurchaseStarCandyState] Starting purchase for: ${serverProduct['id']} (복원 정리 완료 확인됨)',
      );
      final purchaseStartTime = DateTime.now();

      if (!context.mounted) {
        _removeAttempt(serverProduct['id'] as String, attemptId);
        return;
      }
      _loadingKey.currentState?.show();

      // 즉시 구매 시작
      logger.i(
        '[PurchaseStarCandyState] Starting purchase immediately - no pre-processing',
      );
      final preparationTime = DateTime.now();
      final preparationDuration = preparationTime.difference(purchaseStartTime);
      logger.i(
        '[PurchaseStarCandyState] Purchase preparation completed - Duration: ${preparationDuration.inMilliseconds}ms',
      );

      _transactionsCleared = true;

      // 런치 결과는 반환된 맵 하나로만 보고된다 - onError 콜백을 함께
      // 받던 동안 하나의 런치 실패에 다이얼로그가 두 장 겹쳐 떴다
      // (콜백에서 한 번, _handlePurchaseResult → PurchaseSafetyManager
      // .handlePurchaseResult 에서 또 한 번).
      final purchaseResult = await _purchaseService.initiatePurchase(
        serverProduct['id'],
      );

      await _handlePurchaseResult(
        purchaseResult,
        productId: serverProduct['id'] as String,
        attemptId: attemptId,
      );
    } catch (e, s) {
      logger.e(
        '[PurchaseStarCandyState] Error starting purchase: $e',
        error: e,
        stackTrace: s,
      );
      _resetProductPurchaseState(
        serverProduct['id'] as String,
        attemptId: attemptId,
        terminal: true,
      );
      if (mounted) {
        _loadingKey.currentState?.hide();
        if (navigatorKey.currentContext != null) {
          await _dialogHandler.showErrorDialog(
            AppLocalizations.of(
              navigatorKey.currentContext!,
            ).dialog_message_purchase_failed,
          );
        }
      }
      rethrow;
    }
  }

  /// 거래ID 없는 취소/실패 이벤트(양쪽 플랫폼 다 흔하다 - iOS는
  /// transactionIdentifier가 실패/취소 트랜잭션엔 거의 항상 없고, Android
  /// Play Billing responseCode 3은 productID까지 없을 수 있다) 때문에 90초
  /// 안전망까지 레지스트리에 남아있는 시도를, 스토어 큐를 실측해 정리한다.
  ///
  /// **상품 하나가 아니라 남아 있는 시도 전부**를 본다. 예전에는 사용자가
  /// 누른 그 상품만 봤고, 그래서 상품 A 를 취소한 뒤 상품 B 를 사면 A 의
  /// 버튼(`_purchaseAttempts.contains(A)`)이 90초 안전망이 울릴 때까지
  /// 로딩 스피너로 남았다 (실기기 재현, 2026-08-07). 취소 이벤트를 A 에
  /// 귀속시키는 것이 아니다 - 그 불변식(식별자 없는 이벤트는 attempt 를
  /// 지우지 못한다)은 그대로다. 판단 근거는 오직 "스토어 큐를 다시 조회해
  /// 보니 애초에 아무것도 없었다"이고, 그렇다면 어떤 상품에도 살아 있는
  /// 트랜잭션이 없다는 뜻이다.
  ///
  /// 조회가 실패하거나, 뭔가 남아 있거나, 스윕이 그 자리에서 실결제를
  /// 정산했다면 아무것도 지우지 않는다 - `_canPurchase` 가 기존 안내로 막고
  /// 90초 안전망이 제 일을 한다.
  ///
  /// 같은 시점에 여러 경로(구매 버튼, 식별자 없는 취소 이벤트)가 부를 수
  /// 있으므로 단일 비행으로 묶어 스토어 왕복을 중복시키지 않는다.
  Future<void> _reconcileStaleAttemptsIfQueueEmpty() {
    if (_purchaseAttempts.isEmpty) return Future<void>.value();
    return _staleAttemptReconcile ??= _runStaleAttemptReconcile();
  }

  Future<void>? _staleAttemptReconcile;

  Future<void> _runStaleAttemptReconcile() async {
    try {
      final cleared = await reconcileStaleAttemptsIfQueueEmpty(
        attempts: _purchaseAttempts,
        verifyStoreQueueEmpty: _restoreHandler.verifyStoreQueueEmpty,
        isStillLive: () => mounted,
      );
      if (cleared.isEmpty) return;
      for (final attempt in cleared) {
        _safetyManager.resetProductState(attempt.productId);
        // 타이머가 내려간 시도는 더 이상 타임아웃 문구 판정이 없다 - 관찰을
        // 남겨 두면 다음 시도의 취소 억제 판정을 오염시킨다.
        _launchLifecycle.clear(attempt.productId);
        logger.i(
          '🧹 남은 시도 정리: ${attempt.productId} (스토어 큐가 비어 있음을 확인)',
        );
      }
      // 정리된 상품의 버튼 스피너를 실제로 내리는 것은 이 리페인트다.
      if (mounted) setState(() {});
    } finally {
      _staleAttemptReconcile = null;
    }
  }

  /// 구매 가능 여부 확인 (상품별 쿨타임 적용)
  bool _canPurchase({required String productId}) {
    if (_purchaseAttempts.contains(productId)) {
      logger.w('[PurchaseStarCandyState] Product purchase already in progress');
      showSimpleDialog(
        content: AppLocalizations.of(context).purchase_in_progress_message,
      );
      return false;
    }

    if (!_safetyManager.canAttemptPurchaseForProduct(productId)) {
      logger.w(
        '[PurchaseStarCandyState] Purchase cooldown active (per product)',
      );
      final l10n = AppLocalizations.of(context);
      // 여기 도달했다는 것은 이 상품에 **명시적** 쿨다운이 걸려 있다는 뜻이다:
      // 서버 정산이 진행 중이거나, 지급이 확인되지 않은 중복이 관측된 상태.
      // 두 문구 모두 그 상태에 대해 사실이다. 정산이 끝난 구매는 더 이상 이
      // 가드에 걸리지 않는다 — 걸리던 동안 소비형 상품의 정상적인 연속 구매가
      // "이전 결제가 스토어에서 처리 중입니다" 라는 거짓 안내로 막혔다
      // (1.3.0 TestFlight patch 8). 자세한 근거는
      // PurchaseSafetyManager.canAttemptPurchaseForProduct 주석.
      //
      // 정산 진행 중으로 막은 쿨다운은 "잠시 후 다시 시도하세요"의 반대를
      // 안내해야 한다 - 이미 결제된 소비형 상품을 다시 결제하면 안 된다.
      showSimpleDialog(
        content: _safetyManager.isSettlementPending(productId)
            ? l10n.purchase_payment_accepted_message
            : l10n.previousTransactionPendingError,
      );
      return false;
    }

    return true;
  }

  /// 구매 시작 상태 설정
  void _setPurchaseStartState(String productId) {
    // 🛡️ 구매 시도 기록 시 상품 ID도 함께 전달
    _safetyManager.recordPurchaseAttempt(productId: productId);
  }

  /// 구매 결과 처리 - 취소와 에러를 구분
  Future<void> _handlePurchaseResult(
    Map<String, dynamic> purchaseResult, {
    required String productId,
    required String attemptId,
  }) async {
    if (purchaseResult['wasCancelled'] == true) {
      if (mounted) {
        _resetProductPurchaseState(productId);
        _loadingKey.currentState?.hide();
        // 사용자가 직접 취소한 경우 팝업 표시
        showSimpleDialog(
          content: AppLocalizations.of(context).purchase_cancelled_message,
        );
      }
      _purchaseAttempts.applyLaunchResult(productId, attemptId, purchaseResult);
      return;
    }

    _purchaseAttempts.applyLaunchResult(productId, attemptId, purchaseResult);

    if (purchaseResult['success'] == true) {
      // 런치가 성공했다 = 스토어 결제 시트가 이제 사용자 앞에 있다(Android).
      // 이 시점 이후의 resumed 수신 여부가 "시트를 닫고 나왔는지"의 근거다.
      // 스토어 이벤트는 서버 ID 가 아니라 스토어 상품 ID(iOS 앱 접두사,
      // Android dev 네임스페이스)로 도착하므로, 그 표기를 별칭으로 함께
      // 등록해야 구매 증거가 이 시도로 모인다.
      _launchLifecycle.recordLaunch(
        productId,
        storeAliases: [
          PaymentProductIdPolicy.effectiveProductId(
            environment: Environment.currentEnvironment,
            isAndroid: Platform.isAndroid,
            paymentNamespace: Environment.storeQueryNamespace,
            serverProductId: productId,
            iosAppPrefix: Environment.inappAppNamePrefix,
          ),
        ],
      );
    }

    await _safetyManager.handlePurchaseResult(
      purchaseResult,
      _purchaseAttempts.contains(productId),
      // errorMessage 는 에러 코드다 (arb 매핑은 _presentPurchaseFailure).
      _presentPurchaseFailure,
      productId: productId,
      attemptId: attemptId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 로그인 상태를 실시간으로 감시
    final userInfo = ref.watch(userInfoProvider);
    final isLoggedIn = userInfo.value != null;

    return LoadingOverlayWithIcon(
      key: _loadingKey,
      iconAssetPath: 'assets/app_icon_128.png',
      enableScale: true,
      enableFade: true,
      enableRotation: false,
      minScale: 0.98,
      maxScale: 1.02,
      showProgressIndicator: false,
      child: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.read(userInfoProvider.notifier).getUserProfiles();
          // 파우치(별사탕 파우치)는 walletSummaryProvider 가 그린다. 프로필만
          // 다시 읽으면 파우치가 실패해 있을 때 화면을 당겨도 회복되지 않는다.
          await ref.read(walletSummaryProvider.notifier).refresh();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: ListView(
            children: [
              const SizedBox(height: 16),
              StorePointInfo(
                title: AppLocalizations.of(context).label_star_candy_pouch,
                width: double.infinity,
                height: 120,
                refreshController: _rotationController,
                onRefresh: isLoggedIn
                    ? () {
                        _rotationController.forward(from: 0);
                        ref.read(userInfoProvider.notifier).getUserProfiles();
                        ref.read(walletSummaryProvider.notifier).refresh();
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.grey200, height: 32),
              _buildProductsList(),
              const Divider(color: AppColors.grey200, height: 32),
              _buildFooterSection(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).text_purchase_vat_included,
          style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildProductsList() {
    final serverProductsAsyncValue = ref.watch(serverProductsProvider);
    final storeProductsAsyncValue = ref.watch(storeProductsProvider);

    return serverProductsAsyncValue.when(
      loading: () => _buildShimmer(),
      error: (error, stackTrace) =>
          buildErrorView(context, error: error, stackTrace: stackTrace),
      data: (serverProducts) {
        return storeProductsAsyncValue.when(
          loading: () => _buildShimmer(),
          // raw 예외 문자열('Exception: Exception: ...')이 그대로 노출되던
          // 자리다. 원인은 이미 provider 가 로깅하므로 사용자에게는
          // 로컬라이즈된 안내와 재시도만 보여준다.
          error: (error, stackTrace) => _buildStoreProductsError(),
          data: (storeProducts) =>
              _buildProductList(serverProducts, storeProducts),
        );
      },
    );
  }

  Widget _buildStoreProductsError() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).message_store_products_load_failed,
              textAlign: TextAlign.center,
              style: getTextStyle(AppTypo.body14M, AppColors.grey600),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () {
                ref.invalidate(storeProductsProvider);
              },
              child: Text(
                AppLocalizations.of(context).label_retry,
                style: getTextStyle(AppTypo.body14B, AppColors.primary500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => _buildShimmerItem(),
        separatorBuilder: (context, index) =>
            const Divider(color: AppColors.grey200, height: 32),
        itemCount: 5,
      ),
    );
  }

  Widget _buildShimmerItem() {
    return ListTile(
      leading: Container(width: 48.w, height: 48, color: Colors.white),
      title: Container(height: 16, color: Colors.white),
      subtitle: Container(height: 16, color: Colors.white),
    );
  }

  Widget _buildProductList(
    List<Map<String, dynamic>> serverProducts,
    List<ProductDetails> storeProducts,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) =>
          _buildProductItem(serverProducts[index], storeProducts),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(color: AppColors.grey200, height: 24),
      itemCount: serverProducts.length,
    );
  }

  Widget _buildProductItem(
    Map<String, dynamic> serverProduct,
    List<ProductDetails> storeProducts,
  ) {
    final productId = serverProduct['id'] as String;
    // 스토어 ID 는 정책에 따라 변형된다 (Android 는 소문자 SKU, iOS 는
    // 접두사). 서버 ID 와의 raw 비교는 Android 에서 구조적으로 false 라
    // (서버 STARxxx vs Play starxxx) 버튼이 전부 죽는다 — 반드시
    // 카탈로그 조회·구매 매칭과 같은 정책 함수로 판정한다.
    final hasStoreProduct = const PurchaseServiceHelper().storeHasProduct(
      storeProducts: storeProducts,
      serverProductId: productId,
      isAndroid: Platform.isAndroid,
      inappAppNamePrefix: Environment.inappAppNamePrefix,
      environment: Environment.currentEnvironment,
      paymentProductNamespace: Environment.storeQueryNamespace,
    );
    final isButtonEnabled =
        hasStoreProduct &&
        !_isInitializing &&
        !_purchaseAttempts.contains(productId);
    final isCurrentProductLoading = _purchaseAttempts.contains(productId);
    final campaign = ref
        .watch(activePromotionCampaignProvider(PromotionSurface.store))
        .value
        ?.items
        .where((item) => item.showInStore)
        .firstOrNull;

    return StoreListTile(
      icon: Image.asset(
        package: 'picnic_lib',
        'assets/icons/store/currency_star_candy.png',
        width: 48.w,
        height: 48,
      ),
      title: Text(
        serverProduct['id'],
        style: getTextStyle(AppTypo.body16B, AppColors.grey900),
      ),
      subtitle: RewardBreakdown(
        baseAmount: (serverProduct['star_candy'] as num?)?.toInt() ?? 0,
        // Supabase products uses `star_candy_bonus`; keep the API spelling as
        // a fallback for older/web catalog payloads.
        bonusAmount:
            ((serverProduct['star_candy_bonus'] ??
                        serverProduct['bonus_star_candy'])
                    as num?)
                ?.toInt() ??
            0,
      ),
      badge: campaign == null ? null : CandyBoostBadge(campaign: campaign),
      isLoading: isCurrentProductLoading,
      buttonText: '${serverProduct['price']} \$',
      buttonOnPressed: isButtonEnabled
          ? () => _handleBuyButtonPressed(context, serverProduct, storeProducts)
          : null,
    );
  }
}
