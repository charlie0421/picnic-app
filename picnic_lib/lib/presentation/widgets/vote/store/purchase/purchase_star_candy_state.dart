import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';

import 'handlers/restore_purchase_handler.dart';
import 'handlers/purchase_safety_manager.dart';
import 'handlers/purchase_dialog_handler.dart';
import 'handlers/debug_dialog_handler.dart';

class PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy>
    with SingleTickerProviderStateMixin {
  late final PurchaseService _purchaseService;
  late final AnimationController _rotationController;
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
      GlobalKey<LoadingOverlayWithIconState>();

  late final RestorePurchaseHandler _restoreHandler;
  late final PurchaseSafetyManager _safetyManager;
  late final PurchaseDialogHandler _dialogHandler;
  late final DebugDialogHandler _debugHandler;
  String? _pendingProductId;
  bool _transactionsCleared = false;
  bool _isActivePurchasing = false;
  bool _isInitializing = true;
  bool _isPurchasing = false;

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

    _debugHandler = DebugDialogHandler(
      context: context,
      purchaseService: _purchaseService,
      loadingKey: _loadingKey,
    );

    // 🎯 심플 타임아웃 처리: 직접 콜백 설정
    _safetyManager.onTimeoutUIReset = () {
      if (mounted) {
        _resetPurchaseState();
        showSimpleDialog(content: '구매 처리 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요.');
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
        '[PurchaseStarCandyState] Starting initialization with proactive restore cleanup (${platform.name})');

    if (!mounted) return;

    try {
      _loadingKey.currentState?.show();

      await _restoreHandler.performProactiveCleanup();

      final initEndTime = DateTime.now();
      final initDuration = initEndTime.difference(initStartTime);
      logger.i(
          '[PurchaseStarCandyState] Initialization completed - Duration: ${initDuration.inMilliseconds}ms');

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
        'cancelled by user'
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
        'ios_user_cancelled'
      ];

      for (final keyword in cancelKeywords) {
        if (errorMessage.contains(keyword)) {
          logger.i(
              '[PurchaseStarCandyState] Cancel keyword detected: $keyword in "$errorMessage"');
          return true;
        }
      }

      for (final code in cancelErrorCodes) {
        if (errorCode.contains(code) || errorMessage.contains(code)) {
          logger.i(
              '[PurchaseStarCandyState] Cancel error code detected: $code (errorCode: "$errorCode", errorMessage: "$errorMessage")');
          return true;
        }
      }
      logger.w(
          '''[PurchaseStarCandyState] ⚠️ UNDETECTED ERROR - Please check if this should be treated as cancellation:
Error Code: "$errorCode"
Error Message: "$errorMessage"
Full Error: ${purchaseDetails.error}
''');
    }

    return false;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    final statusCounts = _getStatusCounts(purchaseDetailsList);

    logger.d('''[PurchaseStarCandyState] Purchase update received:
Total: ${purchaseDetailsList.length} | Active: $_isActivePurchasing | Cleared: $_transactionsCleared
Pending: ${statusCounts['pending']} | Restored: ${statusCounts['restored']} | Purchased: ${statusCounts['purchased']} | Error: ${statusCounts['error']} | Canceled: ${statusCounts['canceled']}''');

    try {
      for (final purchaseDetails in purchaseDetailsList) {
        await _processPurchaseDetail(purchaseDetails);
      }
    } catch (e, s) {
      logger.e('[PurchaseStarCandyState] Error handling purchase update: $e',
          error: e, stackTrace: s);
      _resetPurchaseState();
      _loadingKey.currentState?.hide();
      await _dialogHandler.showErrorDialog(t('dialog_message_purchase_failed'));
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
        '[PurchaseStarCandyState] Processing: ${purchaseDetails.status} for ${purchaseDetails.productID}');

    if (_shouldForceCompletePending(purchaseDetails)) {
      await _forceCompletePendingPurchase(purchaseDetails);
      return;
    }

    if (purchaseDetails.status == PurchaseStatus.pending &&
        !_isActivePurchasing) {
      logger.i(
          '[PurchaseStarCandyState] Purchase pending for ${purchaseDetails.productID}');
      return;
    }

    if (_shouldIgnoreDuringInit(purchaseDetails)) {
      logger.i(
          '[PurchaseStarCandyState] Ignoring ${purchaseDetails.status} during initialization: ${purchaseDetails.productID}');
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
    if (purchaseDetails.pendingCompletePurchase) {
      await _purchaseService.inAppPurchaseService
          .completePurchase(purchaseDetails);
    }
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
      final timeSinceTimeout =
          DateTime.now().difference(_safetyManager.safetyTimeoutTime!);

      if (timeSinceTimeout.inMinutes <= 2) {
        final isActual = _safetyManager.isActualPurchase(
          purchaseDetails: purchaseDetails,
          isActivePurchasing: _isActivePurchasing,
          pendingProductId: _pendingProductId,
        );

        if (isActual) {
          logger
              .w('[iOS] 🍎 2단계: 늦은 구매 성공 감지 (${timeSinceTimeout.inSeconds}초)');
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
      final timeSinceTimeout =
          DateTime.now().difference(_safetyManager.safetyTimeoutTime!);

      // 🤖 Android는 1분만 허용 (더 엄격)
      if (timeSinceTimeout.inMinutes <= 1) {
        final isActual = _safetyManager.isActualPurchase(
          purchaseDetails: purchaseDetails,
          isActivePurchasing: _isActivePurchasing,
          pendingProductId: _pendingProductId,
        );

        if (isActual) {
          logger
              .w('[Android] 🤖 2단계: 짧은 지연 허용 (${timeSinceTimeout.inSeconds}초)');
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
      PurchaseDetails purchaseDetails) async {
    logger.i(
        '[PurchaseStarCandyState] Force completing pending purchase: ${purchaseDetails.productID}');

    try {
      final startTime = DateTime.now();
      await _purchaseService.inAppPurchaseService
          .completePurchase(purchaseDetails);
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      logger.i(
          '[PurchaseStarCandyState] Pending purchase completed: ${duration}ms');
    } catch (e) {
      logger.e(
          '[PurchaseStarCandyState] Failed to complete pending purchase: $e');
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
        '[PurchaseStarCandyState] Processing active purchase: ${purchaseDetails.productID} (actual: $isActualPurchase, late: $isLatePurchase)');

    await _purchaseService.handleOptimizedPurchase(
      purchaseDetails,
      () async {
        logger.i('[PurchaseStarCandyState] Purchase successful');

        // 🛡️ 구매 세션 완료 기록으로 중복 방지
        _safetyManager.completePurchaseSession(purchaseDetails.productID);

        // 🧹 구매 완료 후 클린 작업 수행
        final transactionId = purchaseDetails.purchaseID ??
            '${purchaseDetails.productID}_${DateTime.now().millisecondsSinceEpoch}';

        // 🧹 비동기로 클린 작업 실행 (UI 블로킹 방지)
        unawaited(_safetyManager.performPostPurchaseCleanup(
          productId: purchaseDetails.productID,
          transactionId: transactionId,
          completedPurchase: purchaseDetails,
        ));

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
          _resetPurchaseState();
          _loadingKey.currentState?.hide();

          if (_isDuplicateError(error)) {
            await _dialogHandler.showUnexpectedDuplicateDialog();
          } else {
            logger.e('[PurchaseStarCandyState] Purchase error: $error');
            await _dialogHandler.showErrorDialog(error);
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
          '[PurchaseStarCandyState] Purchase error: ${purchaseDetails.error?.message}');

      final isCanceled = _isPurchaseCanceled(purchaseDetails);

      if (mounted) {
        _resetPurchaseState();
        _loadingKey.currentState?.hide();

        if (!isCanceled) {
          logger.e(
              '[PurchaseStarCandyState] Actual purchase error - showing dialog');
          await _dialogHandler
              .showErrorDialog(t('dialog_message_purchase_failed'));
        } else {
          logger.i(
              '[PurchaseStarCandyState] Purchase canceled - no error dialog');
        }
      }
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      logger.i(
          '[PurchaseStarCandyState] Purchase canceled: ${purchaseDetails.productID}');
      if (mounted) {
        _resetPurchaseState();
        _loadingKey.currentState?.hide();
      }
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
    if (!isSupabaseLoggedSafely) {
      showRequireLoginDialog();
      return;
    }

    if (_isInitializing) {
      logger
          .w('[PurchaseStarCandyState] Purchase blocked during initialization');
      showSimpleDialog(content: t('purchase_initializing_message'));
      return;
    }

    if (!_canPurchase()) {
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
          content: '구매 준비 중입니다. 잠시 후 다시 시도해주세요.',
        );
      }
      return;
    }

    _setPurchaseStartState(serverProduct['id']);

    try {
      logger.i(
          '[PurchaseStarCandyState] Starting purchase for: ${serverProduct['id']} (복원 정리 완료 확인됨)');
      final purchaseStartTime = DateTime.now();

      if (!context.mounted) return;
      _loadingKey.currentState?.show();

      // 즉시 구매 시작
      logger.i(
          '[PurchaseStarCandyState] Starting purchase immediately - no pre-processing');
      final preparationTime = DateTime.now();
      final preparationDuration = preparationTime.difference(purchaseStartTime);
      logger.i(
          '[PurchaseStarCandyState] Purchase preparation completed - Duration: ${preparationDuration.inMilliseconds}ms');

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
          logger
              .e('[PurchaseStarCandyState] Purchase error callback: $message');
          _resetPurchaseState();
          if (mounted) {
            _loadingKey.currentState?.hide();
            await _dialogHandler.showErrorDialog(message);
          }
        },
      );

      await _handlePurchaseResult(purchaseResult);
    } catch (e, s) {
      logger.e('[PurchaseStarCandyState] Error starting purchase: $e',
          error: e, stackTrace: s);
      _resetPurchaseState();
      if (mounted) {
        _loadingKey.currentState?.hide();
        await _dialogHandler
            .showErrorDialog(t('dialog_message_purchase_failed'));
      }
      rethrow;
    }
  }

  /// 구매 가능 여부 확인
  bool _canPurchase() {
    if (_isPurchasing) {
      logger.w('[PurchaseStarCandyState] Purchase already in progress');
      showSimpleDialog(content: t('purchase_in_progress_message'));
      return false;
    }

    if (!_safetyManager.canAttemptPurchase()) {
      logger.w('[PurchaseStarCandyState] Purchase cooldown active');
      showSimpleDialog(content: t('purchase_cooldown_message'));
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
      Map<String, dynamic> purchaseResult) async {
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
    return LoadingOverlayWithIcon(
      key: _loadingKey,
      iconAssetPath: 'assets/app_icon_128.png',
      enableScale: true,
      enableFade: true,
      enableRotation: false,
      minScale: 0.98,
      maxScale: 1.02,
      showProgressIndicator: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ListView(
          children: [
            if (isSupabaseLoggedSafely) ...[
              const SizedBox(height: 16),
              _buildHeaderSection(),
              const SizedBox(height: 8),
              StorePointInfo(
                title: t('label_star_candy_pouch'),
                width: double.infinity,
                height: 80,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: AppColors.grey200, height: 32),
            _buildProductsList(),
            const Divider(color: AppColors.grey200, height: 32),
            _buildFooterSection(),
            const SizedBox(height: 36),
            _buildDebugButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildRefreshButton(),
      ],
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
          t('text_purchase_vat_included'),
          style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () => showUsagePolicyDialog(context, ref),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: t('candy_usage_policy_guide'),
                  style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: t('candy_usage_policy_guide_button'),
                  style: getTextStyle(AppTypo.caption12B, AppColors.grey600)
                      .copyWith(decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildProductList(List<Map<String, dynamic>> serverProducts,
      List<ProductDetails> storeProducts) {
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
      Map<String, dynamic> serverProduct, List<ProductDetails> storeProducts) {
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
      title: Text(serverProduct['id'],
          style: getTextStyle(AppTypo.body16B, AppColors.grey900)),
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

  Widget _buildDebugButtons() {
    if (!kDebugMode) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('디버그 및 시뮬레이션 도구',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('강제 타임아웃 (100% 확실)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red[700])),
                SizedBox(height: 8),
                Text('실제 구매 요청을 보내지 않고 3초 후 무조건 타임아웃만 발생시킵니다:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600]),
                      onPressed: () {
                        _purchaseService.enableForceTimeout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('강제 타임아웃 ON - 이제 구매하면 3초 후 100% 타임아웃 발생!'),
                            backgroundColor: Colors.red[600],
                          ),
                        );
                      },
                      child: Text('강제 타임아웃 ON',
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600]),
                      onPressed: () {
                        _purchaseService.disableForceTimeout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('강제 타임아웃 OFF - 정상 구매 진행')),
                        );
                      },
                      child: Text('강제 타임아웃 OFF',
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text('타임아웃 시간 설정', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('실제 구매를 진행하되 타임아웃 시간을 조절합니다:',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  _purchaseService.setTimeoutMode('instant');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('즉시 타임아웃 (100ms)')),
                  );
                },
                child: Text('100ms', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange),
                onPressed: () {
                  _purchaseService.setTimeoutMode('ultrafast');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('초고속 타임아웃 (500ms)')),
                  );
                },
                child: Text('500ms', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  _purchaseService.setTimeoutMode('debug');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('디버그 타임아웃 (3초)')),
                  );
                },
                child: Text('3초', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  _purchaseService.setTimeoutMode('normal');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('정상 타임아웃 (30초)')),
                  );
                },
                child: Text('30초', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('구매 지연 시뮬레이션', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('구매 요청 자체를 지연시켜서 타임아웃을 유도합니다:',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () {
                  _purchaseService.enableSlowPurchase();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('구매 지연 ON - 5초 지연')),
                  );
                },
                child: Text('지연 ON', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: () {
                  _purchaseService.disableSlowPurchase();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('구매 지연 OFF')),
                  );
                },
                child: Text('지연 OFF', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('구매 상태 관리', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                ),
                onPressed: () {
                  final platform = Theme.of(context).platform;
                  final platformEmoji = platform == TargetPlatform.iOS
                      ? '📱'
                      : platform == TargetPlatform.android
                          ? '🤖'
                          : '🖥️';

                  logger.d(
                      '복원 디버그 버튼 눌림 ($platformEmoji ${platform.name}) - 조용히 무시');

                  if (kDebugMode) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('$platformEmoji ${platform.name}: 복원 무시됨'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_off, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('복원무시',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _debugHandler.handleSandboxAuthReset,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fingerprint, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('인증초기화',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: _debugHandler.handleSandboxDiagnosis,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.healing, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('진단',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: _debugHandler.handleNuclearReset,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dangerous, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('핵리셋',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: _debugHandler.handleCheckPendingStatus,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Pending확인',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('인증 문제 해결', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('인증창이 나타나지 않는 문제를 해결합니다:',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: _debugHandler.handleAuthenticationDiagnosis,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('인증 진단',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
                onPressed: _debugHandler.handleUltimateAuthReset,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('궁극 복구',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
