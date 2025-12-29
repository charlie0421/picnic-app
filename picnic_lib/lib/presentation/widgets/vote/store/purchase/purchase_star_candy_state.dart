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
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';

import 'handlers/restore_purchase_handler.dart';
import 'handlers/purchase_safety_manager.dart';
import 'handlers/purchase_dialog_handler.dart';

class PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy>
    with SingleTickerProviderStateMixin {
  late final PurchaseService _purchaseService;
  late final AnimationController _rotationController;
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
      GlobalKey<LoadingOverlayWithIconState>();

  late final RestorePurchaseHandler _restoreHandler;
  late final PurchaseSafetyManager _safetyManager;
  late final PurchaseDialogHandler _dialogHandler;
  String? _pendingProductId;
  bool _transactionsCleared = false;
  bool _isActivePurchasing = false;
  bool _isInitializing = true;
  bool _isPurchasing = false;
  final Set<String> _currentlyProcessingIDs = {};

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
        _resetPurchaseState();
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

      // 🍎 iOS: JWS 멱등 캐시 초기화 (이전 영수증 캐시로 인한 409 에러 방지)
      if (Platform.isIOS) {
        await _purchaseService.receiptVerificationService.clearIdemCache();
      }

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
    if (purchaseDetails.status == PurchaseStatus.canceled) {
      return true;
    }

    if (purchaseDetails.status == PurchaseStatus.error) {
      final errorMessage = purchaseDetails.error?.message.toLowerCase() ?? '';
      final errorCode = purchaseDetails.error?.code ?? '';

      final cancelKeywords = [
        'cancel',
        'cancelled',
        'canceled',
        'user cancel',
        'abort',
        'dismiss',
        'authentication',
        'touch id',
        'face id',
        'biometric',
        'passcode',
        'unauthorized',
        'permission denied',
        'operation was cancelled',
        'user cancelled',
        'user denied',
        'authentication failed',
        'authentication cancelled',
        'user interaction required',
        'interaction not allowed',
        'declined',
        'rejected',
        'stopped',
        'interrupted',
        'terminated',
        'aborted',
        'transaction has been cancelled',
        'cancelled by the user',
        'purchase was cancelled',
        'user has cancelled',
        'transaction cancelled',
        'purchase cancelled',
        'payment cancelled',
        'cancelled transaction',
        'user cancellation',
        'cancelled by user',
      ];

      final cancelErrorCodes = [
        'PAYMENT_CANCELED',
        'USER_CANCELED',
        '2',
        'SKErrorPaymentCancelled',
        'BILLING_RESPONSE_USER_CANCELED',
        '-1000',
        '-1001',
        '-1002',
        '-1003',
        '-1004',
        '-1005',
        '-1006',
        '-1007',
        '-1008',
        '-1',
        '-2',
        '-3',
        '-4',
        '-5',
        '-6',
        '-7',
        '-8',
        '-9',
        '-10',
        '-11',
        '-1001',
        '2',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '10',
        '11',
        'SKError2',
        'SKError1002',
        'LAError2',
        'LAError4',
        'LAError5',
        'LAError8',
        'storekit2_purchase_cancelled',
        'storekit2_user_cancelled',
        'storekit2_cancelled',
        'purchase_cancelled',
        'transaction_cancelled',
        'user_cancelled_purchase',
        'cancelled_by_user',
        'platform_cancelled',
        'platform_user_cancelled',
        'ios_purchase_cancelled',
        'ios_user_cancelled',
      ];

      for (final keyword in cancelKeywords) {
        if (errorMessage.contains(keyword)) {
          logger.i(
            '[PurchaseStarCandyState] Cancel keyword detected: $keyword in "$errorMessage"',
          );
          return true;
        }
      }

      for (final code in cancelErrorCodes) {
        if (errorCode.contains(code) || errorMessage.contains(code)) {
          logger.i(
            '[PurchaseStarCandyState] Cancel error code detected: $code (errorCode: "$errorCode", errorMessage: "$errorMessage")',
          );
          return true;
        }
      }
      logger.w(
        '''[PurchaseStarCandyState] ⚠️ UNDETECTED ERROR - Please check if this should be treated as cancellation:
Error Code: "$errorCode"
Error Message: "$errorMessage"
Full Error: ${purchaseDetails.error}
''',
      );
    }

    return false;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    final statusCounts = _getStatusCounts(purchaseDetailsList);

    logger.d(
      '''[PurchaseStarCandyState] Purchase update received:
Total: ${purchaseDetailsList.length} | Active: $_isActivePurchasing | Cleared: $_transactionsCleared
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
    return {
      'pending': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.pending)
          .length,
      'restored': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.restored)
          .length,
      'purchased': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.purchased)
          .length,
      'error': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.error)
          .length,
      'canceled': purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.canceled)
          .length,
    };
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
        !_isActivePurchasing) {
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

    if (_shouldProcessActivePurchase(purchaseDetails)) {
      await _processActivePurchase(purchaseDetails);
      return;
    }

    await _processErrorAndCancel(purchaseDetails);
  }

  /// 초기화 중 pending 구매 강제 완료 여부 확인
  bool _shouldForceCompletePending(PurchaseDetails purchaseDetails) {
    return !_isActivePurchasing &&
        !_transactionsCleared &&
        purchaseDetails.status == PurchaseStatus.pending;
  }

  /// 초기화 중 무시할 구매 여부 확인
  bool _shouldIgnoreDuringInit(PurchaseDetails purchaseDetails) {
    return !_isActivePurchasing &&
        !_transactionsCleared &&
        (purchaseDetails.status == PurchaseStatus.restored ||
            purchaseDetails.status == PurchaseStatus.purchased);
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
    // 🍎 1단계: 현재 활성 구매인지 확인
    if (_isActivePurchasing &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      logger.i('[iOS] 🍎 1단계: 현재 활성 구매 확인');
      return true;
    }

    // 🍎 2단계: 타임아웃 후 늦은 구매 성공 (iOS 특화)
    if (_safetyManager.isSafetyTimeoutTriggered &&
        _safetyManager.safetyTimeoutTime != null &&
        !_isActivePurchasing &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      final timeSinceTimeout = DateTime.now().difference(
        _safetyManager.safetyTimeoutTime!,
      );

      if (timeSinceTimeout.inMinutes <= 2) {
        final isActual = _safetyManager.isActualPurchase(
          purchaseDetails: purchaseDetails,
          isActivePurchasing: _isActivePurchasing,
          pendingProductId: _pendingProductId,
        );

        if (isActual) {
          logger.w(
            '[iOS] 🍎 2단계: 늦은 구매 성공 감지 (${timeSinceTimeout.inSeconds}초)',
          );
          return true;
        }
      }
    }

    // 🍎 3단계: iOS 안전 fallback - 정상 구매가 차단되지 않도록!
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      final isActual = _safetyManager.isActualPurchase(
        purchaseDetails: purchaseDetails,
        isActivePurchasing: _isActivePurchasing,
        pendingProductId: _pendingProductId,
      );

      if (isActual) {
        final statusText = purchaseDetails.status == PurchaseStatus.restored
            ? 'restored→정상 구매'
            : '정상 구매';
        logger.i('[iOS] 🍎 3단계: iOS 안전 fallback - $statusText 감지, 영수증 검증 진행');
        return true;
      }
    }

    logger.w('[iOS] 🍎 iOS 차단: 활성 구매 아님');
    return false;
  }

  /// 🤖 Android 전용 활성 구매 판별 - 엄격한 2단계 처리
  bool _shouldProcessActivePurchaseAndroid(PurchaseDetails purchaseDetails) {
    // 🤖 1단계: 현재 활성 구매인지 확인 (엄격)
    if (_isActivePurchasing &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      logger.i('[Android] 🤖 1단계: 현재 활성 구매 확인');
      return true;
    }

    // 🤖 2단계: 타임아웃 후 짧은 지연만 허용 (Android 특화)
    if (_safetyManager.isSafetyTimeoutTriggered &&
        _safetyManager.safetyTimeoutTime != null &&
        !_isActivePurchasing &&
        purchaseDetails.status == PurchaseStatus.purchased) {
      // restored 제외
      final timeSinceTimeout = DateTime.now().difference(
        _safetyManager.safetyTimeoutTime!,
      );

      // 🤖 Android는 1분만 허용 (더 엄격)
      if (timeSinceTimeout.inMinutes <= 1) {
        final isActual = _safetyManager.isActualPurchase(
          purchaseDetails: purchaseDetails,
          isActivePurchasing: _isActivePurchasing,
          pendingProductId: _pendingProductId,
        );

        if (isActual) {
          logger.w(
            '[Android] 🤖 2단계: 짧은 지연 허용 (${timeSinceTimeout.inSeconds}초)',
          );
          return true;
        }
      }
    }

    // 🤖 3단계: Android는 fallback 없음 - 엄격 차단
    logger.w('[Android] 🤖 Android 엄격 차단: 활성 구매 아님');
    return false;
  }

  /// 초기화 중 pending 구매 강제 완료
  Future<void> _forceCompletePendingPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    logger.i(
      '[PurchaseStarCandyState] Force completing pending purchase: ${purchaseDetails.productID}',
    );

    try {
      final startTime = DateTime.now();
      await _purchaseService.inAppPurchaseService.completePurchase(
        purchaseDetails,
      );
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      logger.i(
        '[PurchaseStarCandyState] Pending purchase completed: ${duration}ms',
      );
    } catch (e) {
      logger.e(
        '[PurchaseStarCandyState] Failed to complete pending purchase: $e',
      );
    }
  }

  Future<void> _processRestoredPurchase(PurchaseDetails purchaseDetails) async {
    await _restoreHandler.processRestoredPurchase(purchaseDetails);
  }

  /// 활성 구매 처리
  Future<void> _processActivePurchase(PurchaseDetails purchaseDetails) async {
    final isActualPurchase = _safetyManager.isActualPurchase(
      purchaseDetails: purchaseDetails,
      isActivePurchasing: _isActivePurchasing,
      pendingProductId: _pendingProductId,
    );

    final isLatePurchase = _safetyManager.isLatePurchase(_isActivePurchasing);

    logger.i(
      '[PurchaseStarCandyState] Processing active purchase: ${purchaseDetails.productID} (actual: $isActualPurchase, late: $isLatePurchase)',
    );

    await _purchaseService.handleOptimizedPurchase(
      purchaseDetails,
      () async {
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

        await ref.read(userInfoProvider.notifier).getUserProfiles();

        if (mounted) {
          _resetPurchaseState();
          _loadingKey.currentState?.hide();

          if (isLatePurchase) {
            await _dialogHandler.showLatePurchaseSuccessDialog();
          } else {
            await _dialogHandler.showSuccessDialog();
          }
        }
      },
      (error) async {
        if (mounted) {
          // ✅ UI만 리셋하고 쿨다운은 유지하여 즉시 연속 구매 차단
          _safetyManager.resetUIOnly(reason: '구매 에러/중복 처리 후 UI만 리셋');
          _loadingKey.currentState?.hide();
          setState(() => _isPurchasing = false);
          if (error == PurchaseConstants.errPrevTransactionPending) {
            // 엣지(서버)에서 중복 처리됨 → '스토어 처리 중' 안내만, 쿨타임 미적용
            setState(() => _isPurchasing = false);
            if (navigatorKey.currentContext != null) {
              showSimpleDialog(
                content: AppLocalizations.of(
                  navigatorKey.currentContext!,
                ).previousTransactionPendingError,
              );
            }
            // iOS JWS 반복 중복 완화: 강제 쿨다운(상품별) 60초 적용하여 루프 차단
            if (_pendingProductId != null) {
              _safetyManager.activateDuplicateCooldown(
                productId: _pendingProductId,
                cooldown: const Duration(minutes: 1),
              );
            }
          } else if (error == PurchaseConstants.errCooldownActive) {
            // 쿨다운 위반도 동일하게 안내만, 추가 쿨타임 미적용
            setState(() => _isPurchasing = false);
            if (navigatorKey.currentContext != null) {
              showSimpleDialog(
                content: AppLocalizations.of(
                  navigatorKey.currentContext!,
                ).previousTransactionPendingError,
              );
            }
          } else if (_isDuplicateError(error)) {
            // 문자열 기반 중복 케이스도 동일 처리: 안내만, 쿨타임 미적용
            setState(() => _isPurchasing = false);
            // iOS 캐시성 중복 신호 완화용 강제 쿨다운(상품별) 60초
            if (_pendingProductId != null) {
              _safetyManager.activateDuplicateCooldown(
                productId: _pendingProductId,
                cooldown: const Duration(minutes: 1),
              );
            }
          } else {
            logger.e('[PurchaseStarCandyState] Purchase error: $error');
            // 코드 → i18n 직접 매핑 (상수 메시지/헬퍼 미사용)
            final l10n = AppLocalizations.of(navigatorKey.currentContext!);
            String msg;
            switch (error) {
              case PurchaseConstants.errPrevTransactionPending:
              case PurchaseConstants.errCooldownActive:
                msg = l10n.previousTransactionPendingError;
                break;
              case 'RECEIPT_VERIFICATION_FAILED':
                msg = l10n.error_receipt_verification_failed;
                break;
              case 'USER_NOT_AUTHENTICATED':
                msg = l10n.error_user_not_authenticated;
                break;
              case 'PRODUCT_NOT_FOUND':
                msg = l10n.error_product_not_found;
                break;
              case PurchaseConstants.errTimeout:
                msg = l10n.purchase_timeout_message;
                break;
              case PurchaseConstants.errAuthTimeout:
                msg = l10n.dialog_message_purchase_failed;
                break;
              case PurchaseConstants.errNetwork:
                msg = l10n.error_network_connection;
                break;
              case PurchaseConstants.errServer:
                msg = l10n.network_error_message;
                break;
              case PurchaseConstants.errPurchaseCanceled:
                msg = l10n.purchase_cancelled_message;
                break;
              case PurchaseConstants.errInProgress:
                msg = l10n.purchase_in_progress_message;
                break;
              case PurchaseConstants.errConcurrent:
                msg = l10n.purchase_in_progress_message;
                break;
              case PurchaseConstants.errTooSoon:
              case PurchaseConstants.errRecentPurchase:
              case PurchaseConstants.errRequestDuplicate:
                msg = l10n.previousTransactionPendingError;
                break;
              default:
                msg = l10n.dialog_message_purchase_failed;
            }
            await _dialogHandler.showErrorDialog(msg);
          }
        }
      },
      isActualPurchase: isActualPurchase,
    );
  }

  /// 에러 및 취소 처리
  Future<void> _processErrorAndCancel(PurchaseDetails purchaseDetails) async {
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
    if (purchaseDetails.pendingCompletePurchase) {
      logger.i(
        '[PurchaseStarCandyState] Completing failed/canceled transaction to prevent re-delivery.',
      );
      await _purchaseService.inAppPurchaseService.completePurchase(
        purchaseDetails,
      );
    }
  }

  /// 중복 에러 확인
  bool _isDuplicateError(String error) {
    return error.contains('StoreKit 캐시 문제') ||
        error.contains('중복 영수증') ||
        error.contains('이미 처리된 구매') ||
        error.contains('Duplicate') ||
        error.toLowerCase().contains('reused');
  }

  /// 🧹 정상 구매 완료 시 모든 타이머 완전 정리
  void _cleanupAllTimersOnSuccess(String productId) {
    logger.i('[PurchaseStarCandyState] 🧹 모든 타이머 정리 시작: $productId');

    try {
      // 1️⃣ PurchaseSafetyManager 타이머 정리 (추가 정리)
      _safetyManager.cleanupAllTimersOnSuccess();

      // 2️⃣ RestorePurchaseHandler 타이머 정리
      _restoreHandler.cleanupTimersOnPurchaseSuccess();

      // 3️⃣ InAppPurchaseService 타이머 정리
      _purchaseService.inAppPurchaseService.cleanupTimersOnPurchaseSuccess(
        productId,
      );

      logger.i('[PurchaseStarCandyState] 🧹 ✅ 모든 타이머 정리 완료: $productId');
    } catch (e) {
      logger.w('[PurchaseStarCandyState] 🧹 ⚠️ 타이머 정리 중 경고: $e');
      // 타이머 정리 실패해도 구매는 이미 성공했으므로 계속 진행
    }
  }

  void _resetPurchaseState() {
    _safetyManager.disposeSafetyTimer();
    _safetyManager.resetInternalState(reason: '전체 상태 리셋'); // 🚨 내부 상태도 완전 리셋!

    setState(() {
      _isActivePurchasing = false;
      _pendingProductId = null;
      _isPurchasing = false;
    });

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
    final confirmed = await _dialogHandler.showPurchaseConfirmDialog(
      serverProduct: serverProduct,
      storeProducts: storeProducts,
    );

    if (confirmed == true && context.mounted) {
      await _processPurchase(context, serverProduct, storeProducts);
    }
  }

  // 🎯 실제 구매 처리 로직
  Future<void> _processPurchase(
    BuildContext context,
    Map<String, dynamic> serverProduct,
    List<ProductDetails> storeProducts,
  ) async {
    // 🛡️ 복원 정리 완료 대기 가드
    if (!_restoreHandler.isProactiveCleanupCompleted) {
      logger.w('🛡️ 복원 정리가 아직 완료되지 않음 - 구매 차단');
      if (mounted) {
        showSimpleDialog(
          content: 'Purchase preparation in progress. Please try again later.',
        );
      }
      return;
    }

    _setPurchaseStartState(serverProduct['id']);

    try {
      logger.i(
        '[PurchaseStarCandyState] Starting purchase for: ${serverProduct['id']} (복원 정리 완료 확인됨)',
      );
      final purchaseStartTime = DateTime.now();

      if (!context.mounted) return;
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

      _isActivePurchasing = true;
      _pendingProductId = serverProduct['id'];
      _transactionsCleared = true;

      final purchaseResult = await _purchaseService.initiatePurchase(
        serverProduct['id'],
        onSuccess: () async {
          logger.i('[PurchaseStarCandyState] Purchase success callback');
          setState(() => _isPurchasing = false);
        },
        onError: (message) async {
          logger.e(
            '[PurchaseStarCandyState] Purchase error callback: $message',
          );
          _resetPurchaseState();
          if (mounted) {
            _loadingKey.currentState?.hide();
            await _dialogHandler.showErrorDialog(message);
          }
        },
      );

      await _handlePurchaseResult(purchaseResult);
    } catch (e, s) {
      logger.e(
        '[PurchaseStarCandyState] Error starting purchase: $e',
        error: e,
        stackTrace: s,
      );
      _resetPurchaseState();
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
    if (_isPurchasing) {
      logger.w('[PurchaseStarCandyState] Purchase already in progress');
      showSimpleDialog(
        content: AppLocalizations.of(context).purchase_in_progress_message,
      );
      return false;
    }

    // 🍎 iOS: 쿨타임 체크 비활성화 (이전 결제 문제 해결)
    if (!Platform.isIOS && !_safetyManager.canAttemptPurchaseForProduct(productId)) {
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
    setState(() {
      _isPurchasing = true;
    });
    // 🛡️ 구매 시도 기록 시 상품 ID도 함께 전달
    _safetyManager.recordPurchaseAttempt(productId: productId);
  }

  /// 구매 결과 처리 - 취소와 에러를 구분
  Future<void> _handlePurchaseResult(
    Map<String, dynamic> purchaseResult,
  ) async {
    if (purchaseResult['wasCancelled'] == true) {
      if (mounted) {
        _resetPurchaseState();
        _loadingKey.currentState?.hide();
        // 사용자가 직접 취소한 경우 팝업 표시
        showSimpleDialog(
          content: AppLocalizations.of(context).purchase_cancelled_message,
        );
      }
      return;
    }

    await _safetyManager.handlePurchaseResult(
      purchaseResult,
      _isActivePurchasing,
      (errorMessage) async {
        if (mounted) {
          await _dialogHandler.showErrorDialog(errorMessage);
        }
      },
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
    final isButtonEnabled = !_isInitializing && !_isPurchasing;
    final isCurrentProductLoading =
        _isPurchasing && _pendingProductId == serverProduct['id'];

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
      isLoading: isCurrentProductLoading,
      buttonText: '${serverProduct['price']} \$',
      buttonOnPressed: isButtonEnabled
          ? () => _handleBuyButtonPressed(context, serverProduct, storeProducts)
          : null,
    );
  }
}
