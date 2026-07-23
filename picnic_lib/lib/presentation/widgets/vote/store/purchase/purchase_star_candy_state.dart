import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_badge.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'handlers/restore_purchase_handler.dart';
import 'handlers/purchase_safety_manager.dart';
import 'handlers/purchase_dialog_handler.dart';
import 'purchase_helper.dart';
import 'purchase_processor.dart';
import 'purchase_campaign_attempt.dart';

class PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy>
    with SingleTickerProviderStateMixin {
  late final PurchaseService _purchaseService;
  late final AnimationController _rotationController;
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
      GlobalKey<LoadingOverlayWithIconState>();

  late final RestorePurchaseHandler _restoreHandler;
  late final PurchaseSafetyManager _safetyManager;
  late final PurchaseDialogHandler _dialogHandler;
  bool _transactionsCleared = false;
  bool _isInitializing = true;
  final Set<String> _currentlyProcessingIDs = {};
  final PurchaseCampaignAttemptRegistry _purchaseAttempts =
      PurchaseCampaignAttemptRegistry();
  final PurchaseSettlementPresentation _settlementPresentation =
      const PurchaseSettlementPresentation();

  void _removeAttempt(String productId, String attemptId) {
    _purchaseAttempts.removeIfMatches(productId, attemptId);
  }

  @override
  void initState() {
    super.initState();
    logger.d('[PurchaseStarCandyState] initState called');

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _purchaseService = PurchaseService(
      ref: ref,
      inAppPurchaseService: InAppPurchaseService(),
      receiptVerificationService: ReceiptVerificationService(),
      analyticsService: AnalyticsService(),
      duplicatePreventionService: DuplicatePreventionService(ref),
      onPurchaseUpdate: _onPurchaseUpdate,
    );

    _restoreHandler = RestorePurchaseHandler(
      purchaseService: _purchaseService,
      loadingKey: _loadingKey,
      context: context,
    );

    _safetyManager = PurchaseSafetyManager(
      loadingKey: _loadingKey,
      resetPurchaseState: _resetPurchaseState,
    );

    _dialogHandler = PurchaseDialogHandler(
      context: context,
      purchaseService: _purchaseService,
    );

    // 🎯 복원 핸들러와 안전망 매니저 연결 (연속 구매 보호)
    _restoreHandler.setSafetyManager(_safetyManager);

    // 🎯 심플 타임아웃 처리: 직접 콜백 설정
    _safetyManager.onTimeoutUIReset = () {
      if (mounted) {
        setState(() {});
        _loadingKey.currentState?.hide();
        final l10n = AppLocalizations.of(context);
        showSimpleDialog(content: l10n.purchase_timeout_message);
      }
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
  void dispose() {
    _restoreHandler.dispose();
    _safetyManager.disposeSafetyTimer();
    _rotationController.dispose();
    _purchaseService.inAppPurchaseService.dispose();
    super.dispose();
  }

  /// 구매 취소 감지
  bool _isPurchaseCanceled(PurchaseDetails purchaseDetails) {
    return PurchaseHelper.isPurchaseCanceled(purchaseDetails);
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
      _resetPurchaseState();
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

    if (_shouldForceCompletePending(purchaseDetails)) {
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
      logger.i(
        '[PurchaseStarCandyState] Ignoring ${purchaseDetails.status} during initialization: ${purchaseDetails.productID}',
      );
      return;
    }

    if (_shouldProcessRestored(purchaseDetails)) {
      await _processRestoredPurchase(purchaseDetails);
      return;
    }

    final boundAttempt =
        _purchaseAttempts.bind(purchaseDetails) ??
        _purchaseAttempts.currentTerminalWithoutId(purchaseDetails);
    if (boundAttempt == null &&
        purchaseDetails.status != PurchaseStatus.pending) {
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

    final isLatePurchase = _safetyManager.isLatePurchase(true);

    logger.i(
      '[PurchaseStarCandyState] Processing active purchase: ${purchaseDetails.productID} (actual: $isActualPurchase, late: $isLatePurchase)',
    );

    await _purchaseService.handleOptimizedPurchase(
      purchaseDetails,
      (result) async {
        logger.i('[PurchaseStarCandyState] Purchase successful');

        // 🛡️ 구매 세션 완료 기록으로 중복 방지 (이미 내부적으로 안전망 타이머 정리함)
        _safetyManager.completePurchaseSession(purchaseDetails.productID);

        // 🧹 모든 타이머 완전 정리 (정상 구매 완료 시)
        _cleanupAllTimersOnSuccess(purchaseDetails.productID);

        // 🧹 구매 완료 후 클린 작업 수행 (동기 처리로 완전성 보장)
        final transactionId =
            purchaseDetails.purchaseID ??
            '${purchaseDetails.productID}_${DateTime.now().millisecondsSinceEpoch}';

        // 🧹 동기로 클린 작업 실행 - 완료까지 기다림 (확실성 우선)
        await _safetyManager.performPostPurchaseCleanup(
          productId: purchaseDetails.productID,
          transactionId: transactionId,
          completedPurchase: purchaseDetails,
        );

        ref.read(walletSummaryProvider.notifier).setSummary(result.wallet);
        if (mounted) {
          _resetPurchaseState();
          _loadingKey.currentState?.hide();

          await _settlementPresentation.present(
            result: result,
            attempt: attempt,
            isLate: isLatePurchase,
            showSuccess: (sameResult, displayedCampaign) =>
                _dialogHandler.showSuccessDialog(
                  result: sameResult,
                  displayedCampaign: displayedCampaign,
                ),
            showLateSuccess: (sameResult, displayedCampaign) =>
                _dialogHandler.showLatePurchaseSuccessDialog(
                  result: sameResult,
                  displayedCampaign: displayedCampaign,
                ),
          );
        }
        _purchaseAttempts.finish(purchaseDetails, attempt.attemptId);
      },
      (error) async {
        if (mounted) {
          // ✅ UI만 리셋하고 쿨다운은 유지하여 즉시 연속 구매 차단
          _safetyManager.resetUIOnly(reason: '구매 에러/중복 처리 후 UI만 리셋');
          _loadingKey.currentState?.hide();

          final action = PurchaseProcessor.classifyError(error);

          switch (action) {
            case PurchaseErrorAction.showPendingMessage:
              // 엣지(서버)에서 중복 처리됨 → '스토어 처리 중' 안내만
              if (navigatorKey.currentContext != null) {
                showSimpleDialog(
                  content: AppLocalizations.of(
                    navigatorKey.currentContext!,
                  ).previousTransactionPendingError,
                );
              }
              // iOS JWS 반복 중복 완화: 강제 쿨다운(상품별) 60초 적용하여 루프 차단
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
              logger.e('[PurchaseStarCandyState] Purchase error: $error');
              final errorType = PurchaseProcessor.mapErrorToType(error);
              if (errorType != PurchaseErrorType.timeout &&
                  errorType != PurchaseErrorType.networkError) {
                _removeAttempt(purchaseDetails.productID, attempt.attemptId);
              }
              final l10n = AppLocalizations.of(navigatorKey.currentContext!);
              final msg = _resolveErrorMessage(errorType, l10n);
              await _dialogHandler.showErrorDialog(msg);
              break;
          }
        }
      },
      isActualPurchase: isActualPurchase,
    );
  }

  /// 에러 및 취소 처리
  Future<void> _processErrorAndCancel(
    PurchaseDetails purchaseDetails,
    PurchaseCampaignAttempt? boundAttempt,
  ) async {
    final attempt = boundAttempt;
    if (attempt != null) {
      if (!_purchaseAttempts.finish(purchaseDetails, attempt.attemptId)) {
        _removeAttempt(purchaseDetails.productID, attempt.attemptId);
      }
    }
    if (purchaseDetails.status == PurchaseStatus.error) {
      logger.e(
        '[PurchaseStarCandyState] Purchase error: ${purchaseDetails.error?.message}',
      );

      final isCanceled = _isPurchaseCanceled(purchaseDetails);

      if (mounted) {
        // ✅ 일반 오류: 상품별 쿨타임 적용하지 않음 (초기화는 굳이 강제하지 않음)
        _resetPurchaseState();
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
      case PurchaseErrorType.timeout:
        return l10n.purchase_timeout_message;
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

  void _resetPurchaseState() {
    _safetyManager.disposeSafetyTimer();
    _safetyManager.resetInternalState(reason: '전체 상태 리셋'); // 🚨 내부 상태도 완전 리셋!

    setState(() {});

    _safetyManager.resetLatePurchaseSuccess();
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

    if (!_canPurchase(productId: serverProduct['id'] as String)) {
      return;
    }

    // 🔒 구매 확인 다이얼로그 표시
    final campaigns = ref.read(
      activePromotionCampaignProvider(PromotionSurface.store),
    );
    final displayedCampaign = campaigns.value?.items
        .where((campaign) => campaign.showInStore)
        .firstOrNull;
    final productId = serverProduct['id'] as String;
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
    if (!_restoreHandler.isProactiveCleanupCompleted) {
      logger.w('🛡️ 복원 정리가 아직 완료되지 않음 - 구매 차단');
      if (mounted) {
        showSimpleDialog(
          content: 'Purchase preparation in progress. Please try again later.',
        );
      }
      _removeAttempt(serverProduct['id'] as String, attemptId);
      return;
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

      final purchaseResult = await _purchaseService.initiatePurchase(
        serverProduct['id'],
        onSuccess: () async {
          if (_purchaseAttempts[serverProduct['id']]?.attemptId != attemptId) {
            throw StateError('Stale purchase launch callback');
          }
          logger.i('[PurchaseStarCandyState] Purchase success callback');
        },
        onError: (message) async {
          if (_purchaseAttempts[serverProduct['id']]?.attemptId != attemptId) {
            return;
          }
          logger.e(
            '[PurchaseStarCandyState] Purchase error callback: $message',
          );
          _removeAttempt(serverProduct['id'] as String, attemptId);
          _resetPurchaseState();
          if (mounted) {
            _loadingKey.currentState?.hide();
            await _dialogHandler.showErrorDialog(message);
          }
        },
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
      _resetPurchaseState();
      _removeAttempt(serverProduct['id'] as String, attemptId);
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
      // 일반 쿨다운 문구 제거 → 스토어 처리 중 문구로 통일
      showSimpleDialog(
        content: AppLocalizations.of(context).previousTransactionPendingError,
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
        _resetPurchaseState();
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

    await _safetyManager.handlePurchaseResult(
      purchaseResult,
      _purchaseAttempts.contains(productId),
      (errorMessage) async {
        if (mounted) {
          await _dialogHandler.showErrorDialog(errorMessage);
        }
      },
      productId: productId,
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
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: ListView(
            children: [
              const SizedBox(height: 16),
              if (isLoggedIn) ...[
                _buildHeaderSection(),
                const SizedBox(height: 8),
              ],
              StorePointInfo(
                title: AppLocalizations.of(context).label_star_candy_pouch,
                width: double.infinity,
                height: 120,
              ),
              const SizedBox(height: 12),
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

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [_buildRefreshButton()],
    );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: () {
        _rotationController.forward(from: 0);
        ref.read(userInfoProvider.notifier).getUserProfiles();
      },
      child: RotationTransition(
        turns: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        ),
        child: SvgPicture.asset(
          package: 'picnic_lib',
          'assets/icons/reset_style=line.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
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
          error: (error, stackTrace) =>
              Text('Error loading store products: $error'),
          data: (storeProducts) =>
              _buildProductList(serverProducts, storeProducts),
        );
      },
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
      itemCount: storeProducts.length,
    );
  }

  Widget _buildProductItem(
    Map<String, dynamic> serverProduct,
    List<ProductDetails> storeProducts,
  ) {
    final productId = serverProduct['id'] as String;
    final isButtonEnabled =
        !_isInitializing && !_purchaseAttempts.contains(productId);
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
        'assets/icons/store/star_${serverProduct['id'].replaceAll('STAR', '')}.png',
        width: 48.w,
        height: 48,
      ),
      title: Text(
        serverProduct['id'],
        style: getTextStyle(AppTypo.body16B, AppColors.grey900),
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: getLocaleTextFromJson(serverProduct['description']),
              style: getTextStyle(AppTypo.caption12B, AppColors.point900),
            ),
          ],
        ),
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
