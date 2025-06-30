import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
// 🔥 복잡한 가드 시스템 제거됨
import 'package:picnic_lib/core/utils/logger.dart';
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
import 'dart:async';

class PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy>
    with SingleTickerProviderStateMixin {
  late final PurchaseService _purchaseService;
  late final AnimationController _rotationController;
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
      GlobalKey<LoadingOverlayWithIconState>();

  // 상태 관리
  String? _pendingProductId;
  bool _transactionsCleared = false;
  bool _isActivePurchasing = false;
  bool _isInitializing = true;
  bool _isUserRequestedRestore = false;
  bool _isPurchasing = false;

  // 🛡️ 구매 가드 토큰 관리는 PurchaseService에서 처리

  // 시간 관리
  DateTime? _initializationCompletedAt;
  DateTime? _lastPurchaseAttempt;

  // 🛡️ 안전망 타이머 관리
  Timer? _safetyTimer;

  // 🛡️ 안전망 발동 후 늦은 구매 성공 감지용
  bool _safetyTimeoutTriggered = false;
  DateTime? _safetyTimeoutTime;

  // 성능 최적화 상수
  static const Duration _purchaseCooldown = Duration(seconds: 2);
  static const Duration _restoreResetDelay = Duration(seconds: 5);

  // 🛡️ 안전망 타임아웃: Touch ID/Face ID 인증 시간 충분히 고려 (90초)
  static const Duration _safetyTimeout = Duration(seconds: 90);

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
      onPurchaseUpdate: _onPurchaseUpdate,
    );

    // 🧹 타임아웃 시 UI 상태 리셋 콜백 설정
    _purchaseService.onTimeoutUIReset = _handleTimeoutUIReset;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });

    // 🧪 디버그 모드에서만 보이는 디버그 기능 활성화
    if (kDebugMode) {
      logger.i('🧪 디버그 모드에서 타임아웃 테스트 기능 활성화');
    }
  }

  /// 페이지 초기화 (즉시 완료)
  Future<void> _initializePage() async {
    final initStartTime = DateTime.now();
    logger.i('[PurchaseStarCandyState] Starting fast initialization');

    if (!mounted) return;

    try {
      _loadingKey.currentState?.show();

      // 즉시 완료 - 백그라운드에서만 정리
      logger.i(
          '[PurchaseStarCandyState] Skipping initialization cleanup - background only');

      final initEndTime = DateTime.now();
      final initDuration = initEndTime.difference(initStartTime);
      logger.i(
          '[PurchaseStarCandyState] Initialization completed - Duration: ${initDuration.inMilliseconds}ms');

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationCompletedAt = DateTime.now();
          _transactionsCleared = true;
        });
        _loadingKey.currentState?.hide();
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] Initialization failed: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationCompletedAt = DateTime.now();
          _transactionsCleared = true;
        });
        _loadingKey.currentState?.hide();
      }
    }
  }

  @override
  void dispose() {
    // 🛡️ 안전망 타이머 정리
    _safetyTimer?.cancel();
    _safetyTimer = null;

    _rotationController.dispose();
    _purchaseService.inAppPurchaseService.dispose();
    super.dispose();
  }

  /// 🧹 타임아웃 발생 시 UI 상태 리셋
  void _handleTimeoutUIReset() {
    logger.w('🧹 타임아웃으로 인한 UI 상태 리셋 시작');

    if (!mounted) {
      logger.w('🧹 Widget이 dispose된 상태 - UI 리셋 건너뛰기');
      return;
    }

    try {
      // 1. 로딩 오버레이 숨기기
      _loadingKey.currentState?.hide();
      logger.i('🧹 로딩 오버레이 숨김 완료');

      // 2. 구매 상태 리셋
      _resetPurchaseState();
      logger.i('🧹 구매 상태 리셋 완료');

      // 3. 안전망 타이머 정리
      _safetyTimer?.cancel();
      _safetyTimer = null;
      logger.i('🧹 안전망 타이머 정리 완료');

      // 4. 타임아웃 에러 다이얼로그 표시 (비동기로 실행하여 블로킹 방지)
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _showTimeoutErrorDialog();
        }
      });

      logger.w('🧹 타임아웃 UI 상태 리셋 완료');
    } catch (e) {
      logger.e('🧹 타임아웃 UI 상태 리셋 중 오류 발생: $e');
    }
  }

  /// 🧹 타임아웃 에러 다이얼로그 표시
  Future<void> _showTimeoutErrorDialog() async {
    logger.w('🧹 타임아웃 에러 다이얼로그 표시');

    const timeoutMessage = '''구매 처리 시간이 초과되었습니다.

네트워크 상태를 확인한 후 다시 시도해주세요.
만약 결제가 완료되었다면 잠시 후 자동으로 반영됩니다.''';

    await _showErrorDialog(timeoutMessage);
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
        // iOS 인증 관련 취소 키워드 추가
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
        // 추가 일반적인 취소 키워드
        'declined',
        'rejected',
        'stopped',
        'interrupted',
        'terminated',
        'aborted',
        // StoreKit 2 취소 메시지들 추가
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
        '2', // SKErrorPaymentCancelled
        'SKErrorPaymentCancelled',
        'BILLING_RESPONSE_USER_CANCELED',
        // iOS 추가 에러 코드들
        '-1000', // SKErrorUnknown
        '-1001', // SKErrorClientInvalid
        '-1002', // SKErrorPaymentCancelled
        '-1003', // SKErrorPaymentInvalid
        '-1004', // SKErrorPaymentNotAllowed
        '-1005', // SKErrorStoreProductNotAvailable
        '-1006', // SKErrorCloudServicePermissionDenied
        '-1007', // SKErrorCloudServiceNetworkConnectionFailed
        '-1008', // SKErrorCloudServiceRevoked
        // LocalAuthentication 에러 코드들
        '-1', // LAErrorAuthenticationFailed
        '-2', // LAErrorUserCancel
        '-3', // LAErrorUserFallback
        '-4', // LAErrorSystemCancel
        '-5', // LAErrorPasscodeNotSet
        '-6', // LAErrorBiometryNotAvailable
        '-7', // LAErrorBiometryNotEnrolled
        '-8', // LAErrorBiometryLockout
        '-9', // LAErrorAppCancel
        '-10', // LAErrorInvalidContext
        '-11', // LAErrorBiometryDisconnected
        '-1001', // LAErrorNotInteractive
        '2', '4', '5', '6', '7', '8', '9', '10', '11', // 문자열 버전
        'SKError2', 'SKError1002', // SKError 변형들
        'LAError2', 'LAError4', 'LAError5', 'LAError8', // LAError 변형들
        // StoreKit 2 취소 관련 에러 코드들 추가
        'storekit2_purchase_cancelled',
        'storekit2_user_cancelled',
        'storekit2_cancelled',
        'purchase_cancelled',
        'transaction_cancelled',
        'user_cancelled_purchase',
        'cancelled_by_user',
        // Platform Exception 관련 취소 코드들
        'platform_cancelled',
        'platform_user_cancelled',
        'ios_purchase_cancelled',
        'ios_user_cancelled'
      ];

      // 키워드 검사
      for (final keyword in cancelKeywords) {
        if (errorMessage.contains(keyword)) {
          logger.i(
              '[PurchaseStarCandyState] Cancel keyword detected: $keyword in "$errorMessage"');
          return true;
        }
      }

      // 에러 코드 검사
      for (final code in cancelErrorCodes) {
        if (errorCode.contains(code) || errorMessage.contains(code)) {
          logger.i(
              '[PurchaseStarCandyState] Cancel error code detected: $code (errorCode: "$errorCode", errorMessage: "$errorMessage")');
          return true;
        }
      }

      // 🚨 디버그: 감지되지 않은 에러 로깅 (취소 감지 개선용)
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
      await _showErrorDialog(t('dialog_message_purchase_failed'));
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

    // 초기화 중 pending 구매 강제 완료
    if (_shouldForceCompletePending(purchaseDetails)) {
      await _forceCompletePendingPurchase(purchaseDetails);
      return;
    }

    // 일반 pending 처리
    if (purchaseDetails.status == PurchaseStatus.pending &&
        !_isActivePurchasing) {
      logger.i(
          '[PurchaseStarCandyState] Purchase pending for ${purchaseDetails.productID}');
      return;
    }

    // 초기화 중 복원/구매 무시
    if (_shouldIgnoreDuringInit(purchaseDetails)) {
      logger.i(
          '[PurchaseStarCandyState] Ignoring ${purchaseDetails.status} during initialization: ${purchaseDetails.productID}');
      return;
    }

    // 복원 구매 처리
    if (_shouldProcessRestored(purchaseDetails)) {
      await _processRestoredPurchase(purchaseDetails);
      return;
    }

    // 활성 구매 처리
    if (_shouldProcessActivePurchase(purchaseDetails)) {
      await _processActivePurchase(purchaseDetails);
      return;
    }

    // 에러 및 취소 처리
    await _processErrorAndCancel(purchaseDetails);

    // 구매 완료 처리
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

  /// 복원 구매 처리 여부 확인
  bool _shouldProcessRestored(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status != PurchaseStatus.restored ||
        _isActivePurchasing) {
      return false;
    }

    if (!_transactionsCleared) return false;

    final timeSinceInit = _initializationCompletedAt != null
        ? DateTime.now().difference(_initializationCompletedAt!).inSeconds
        : 0;

    return _isUserRequestedRestore || timeSinceInit > 10;
  }

  /// 활성 구매 처리 여부 확인
  bool _shouldProcessActivePurchase(PurchaseDetails purchaseDetails) {
    // 🛡️ 일반 활성 구매 처리
    if (_isActivePurchasing &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      return true;
    }

    // 🛡️ 늦은 구매 성공 감지 (안전망 발동 후 2분 이내 구매 성공)
    if (_safetyTimeoutTriggered &&
        _safetyTimeoutTime != null &&
        !_isActivePurchasing &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored)) {
      final timeSinceTimeout = DateTime.now().difference(_safetyTimeoutTime!);

      // 안전망 발동 후 2분 이내의 구매 성공은 늦은 성공으로 처리
      if (timeSinceTimeout.inMinutes <= 2) {
        logger.w(
            '🛡️ 늦은 구매 성공 감지! 안전망 발동 후 ${timeSinceTimeout.inSeconds}초 만에 구매 완료: ${purchaseDetails.productID}');

        // 늦은 구매 성공 상태 리셋
        _safetyTimeoutTriggered = false;
        _safetyTimeoutTime = null;

        return true;
      }
    }

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

  /// 복원 구매 처리
  Future<void> _processRestoredPurchase(PurchaseDetails purchaseDetails) async {
    final timeSinceInit = _initializationCompletedAt != null
        ? DateTime.now().difference(_initializationCompletedAt!).inSeconds
        : 0;

    logger.i(
        '[PurchaseStarCandyState] Processing restored purchase (user requested: $_isUserRequestedRestore, time since init: ${timeSinceInit}s): ${purchaseDetails.productID}');

    await _purchaseService.handleOptimizedPurchase(
      purchaseDetails,
      () async {
        logger.i('[PurchaseStarCandyState] Restored purchase successful');
        await ref.read(userInfoProvider.notifier).getUserProfiles();
        _isUserRequestedRestore = false;
      },
      (error) async {
        logger.e('[PurchaseStarCandyState] Restored purchase error: $error');
        _isUserRequestedRestore = false;
      },
      isActualPurchase: false,
    );
  }

  /// 활성 구매 처리
  Future<void> _processActivePurchase(PurchaseDetails purchaseDetails) async {
    final isActualPurchase =
        _isActivePurchasing && purchaseDetails.productID == _pendingProductId;

    // 🛡️ 늦은 구매 성공 감지
    final isLatePurchase = !_isActivePurchasing &&
        _safetyTimeoutTriggered &&
        _safetyTimeoutTime != null;

    logger.i(
        '[PurchaseStarCandyState] Processing active purchase: ${purchaseDetails.productID} (actual: $isActualPurchase, late: $isLatePurchase)');

    await _purchaseService.handleOptimizedPurchase(
      purchaseDetails,
      () async {
        logger.i('[PurchaseStarCandyState] Purchase successful');

        // 🛡️ 구매 성공 처리는 PurchaseService에서 자동 관리

        await ref.read(userInfoProvider.notifier).getUserProfiles();

        if (mounted) {
          _resetPurchaseState();
          _loadingKey.currentState?.hide();

          // 🛡️ 늦은 구매 성공 시 특별한 안내
          if (isLatePurchase) {
            await _showLatePurchaseSuccessDialog();
          } else {
            await _showSuccessDialog();
          }
        }
      },
      (error) async {
        // 🛡️ 구매 실패 처리는 PurchaseService에서 자동 관리

        if (mounted) {
          _resetPurchaseState();
          _loadingKey.currentState?.hide();

          if (_isDuplicateError(error)) {
            await _showUnexpectedDuplicateDialog();
          } else {
            logger.e('[PurchaseStarCandyState] Purchase error: $error');
            await _showErrorDialog(error);
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
          await _showErrorDialog(t('dialog_message_purchase_failed'));
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

  /// 구매 상태 리셋
  void _resetPurchaseState() {
    // 🛡️ 토큰 관리는 PurchaseService에서 처리하므로 UI는 상태만 리셋

    // 🛡️ 안전망 타이머 취소
    _safetyTimer?.cancel();
    _safetyTimer = null;

    setState(() {
      _isActivePurchasing = false;
      _pendingProductId = null;
      _isPurchasing = false;

      // 🛡️ 늦은 구매 감지 상태 리셋 (새로운 구매 시작 시)
      _safetyTimeoutTriggered = false;
      _safetyTimeoutTime = null;
    });
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
      showSimpleDialog(content: '초기화 중입니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    if (!_canPurchase()) {
      return;
    }

    _setPurchaseStartState();

    try {
      logger.i(
          '[PurchaseStarCandyState] Starting purchase for: ${serverProduct['id']}');
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
            await _showErrorDialog(message);
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
        await _showErrorDialog(t('dialog_message_purchase_failed'));
      }
      rethrow;
    }
  }

  /// 구매 가능 여부 확인
  bool _canPurchase() {
    final now = DateTime.now();

    if (_isPurchasing) {
      logger.w('[PurchaseStarCandyState] Purchase already in progress');
      showSimpleDialog(content: '구매가 진행 중입니다. 잠시만 기다려주세요.');
      return false;
    }

    if (_lastPurchaseAttempt != null &&
        now.difference(_lastPurchaseAttempt!) < _purchaseCooldown) {
      logger.w('[PurchaseStarCandyState] Purchase cooldown active');
      showSimpleDialog(content: '잠시 후 다시 시도해주세요.');
      return false;
    }

    return true;
  }

  /// 구매 시작 상태 설정
  void _setPurchaseStartState() {
    setState(() {
      _isPurchasing = true;
      _lastPurchaseAttempt = DateTime.now();
    });
  }

  /// 구매 결과 처리 - 취소와 에러를 구분
  Future<void> _handlePurchaseResult(
      Map<String, dynamic> purchaseResult) async {
    final success = purchaseResult['success'] as bool;
    final wasCancelled = purchaseResult['wasCancelled'] as bool;
    final errorMessage = purchaseResult['errorMessage'] as String?;

    if (wasCancelled) {
      // 🚫 구매 취소 - 조용히 처리 (에러 팝업 없음)
      logger.i('[PurchaseStarCandyState] Purchase was cancelled by user');
      _resetPurchaseState();
      if (mounted) {
        _loadingKey.currentState?.hide();
      }
    } else if (!success) {
      // ❌ 실제 에러 - 에러 팝업 표시
      logger.e('[PurchaseStarCandyState] Purchase failed: $errorMessage');
      _resetPurchaseState();
      if (mounted) {
        _loadingKey.currentState?.hide();
        await _showErrorDialog(
            errorMessage ?? t('dialog_message_purchase_failed'));
      }
    } else {
      // ✅ 구매 시작 성공
      logger.i('[PurchaseStarCandyState] Purchase initiated successfully');

      // 🛡️ 안전망 타이머 설정: 무한 로딩 방지용 (InAppPurchaseService 타임아웃이 로그만 출력하는 경우 대비)
      _safetyTimer?.cancel();
      _safetyTimer = Timer(_safetyTimeout, () {
        if (_isActivePurchasing && mounted && _safetyTimer != null) {
          logger.w(
              '[PurchaseStarCandyState] 🛡️ Safety timeout triggered after ${_safetyTimeout.inSeconds}s');
          logger.w(
              'InAppPurchaseService timeout detected but no proper handling - applying safety net');

          // 🛡️ 안전망 발동 기록 (늦은 구매 성공 감지용)
          _safetyTimeoutTriggered = true;
          _safetyTimeoutTime = DateTime.now();

          _resetPurchaseState();
          _loadingKey.currentState?.hide();
          _showErrorDialog('구매 처리 시간이 너무 오래 걸리고 있습니다.\n잠시 후 다시 시도해주세요.');
        }
      });

      logger.i(
          '[PurchaseStarCandyState] Safety timeout set for ${_safetyTimeout.inSeconds}s (infinite loading prevention)');
    }
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;

    try {
      final envInfo = await _purchaseService.receiptVerificationService
          .getEnvironmentInfo();
      final isTestFlight = envInfo['environment'] == 'sandbox' &&
          !envInfo['isDebugMode'] &&
          (envInfo['installerStore'] == 'com.apple.testflight' ||
              envInfo['installerStore'] == null);
      final shouldShowDebugInfo = kDebugMode || isTestFlight;

      if (shouldShowDebugInfo) {
        final debugInfo = '''
환경: ${envInfo['environment']}
플랫폼: ${envInfo['platform']}
설치 스토어: ${envInfo['installerStore'] ?? 'null'}
앱 이름: ${envInfo['appName']}
버전: ${envInfo['version']} (${envInfo['buildNumber']})
디버그 모드: ${envInfo['isDebugMode']}

오류: $message
''';
        showSimpleDialog(content: debugInfo, type: DialogType.error);
      } else {
        showSimpleDialog(content: message, type: DialogType.error);
      }
    } catch (e) {
      showSimpleDialog(content: message, type: DialogType.error);
    }
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) {
      logger.w(
          '[PurchaseStarCandyState] Cannot show success dialog - widget not mounted');
      return;
    }

    logger.i('[PurchaseStarCandyState] Showing success dialog');
    final message = t('dialog_message_purchase_success');
    showSimpleDialog(content: message);
  }

  Future<void> _showLatePurchaseSuccessDialog() async {
    if (!mounted) {
      logger.w(
          '[PurchaseStarCandyState] Cannot show late purchase success dialog - widget not mounted');
      return;
    }

    logger.i('[PurchaseStarCandyState] Showing late purchase success dialog');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 구매 완료'),
        content: Text('''구매가 성공적으로 완료되었습니다!

⏰ 인증이 예상보다 오래 걸려서 타임아웃 안내가 표시되었지만, 실제로는 정상적으로 구매가 처리되었습니다.

✅ 스타캔디가 정상적으로 지급되었습니다
✅ 구매 내역이 서버에 기록되었습니다

이는 Touch ID/Face ID 인증 시 발생할 수 있는 정상적인 상황입니다.'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnexpectedDuplicateDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('서버 처리 중 문제 발생'),
        content: Text('''서버에서 소모성 상품 중복 검사를 완화했지만 여전히 오류가 발생했습니다.

가능한 원인:
1. 서버 배포가 아직 완전히 적용되지 않음
2. 다른 종류의 네트워크 오류
3. 잠시 후 다시 시도하면 해결될 가능성

해결 방법:
1. 1-2분 후 다시 시도 (서버 배포 완료 대기)
2. 그래도 안 되면 앱 재시작
3. 문제가 지속되면 고객지원 문의

소모성 상품이므로 중복 구매가 정상적으로 허용되어야 합니다.'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestorePurchases() async {
    if (_isActivePurchasing || _isPurchasing) {
      logger
          .w('[PurchaseStarCandyState] Cannot restore during active purchase');
      showSimpleDialog(content: '구매가 진행 중입니다. 완료 후 다시 시도해주세요.');
      return;
    }

    final shouldRestore = await _showRestoreConfirmationDialog();
    if (shouldRestore != true) return;

    try {
      logger.i(
          '[PurchaseStarCandyState] Starting user-requested purchase restoration');

      setState(() => _isUserRequestedRestore = true);

      if (!context.mounted) return;
      _loadingKey.currentState?.show();

      await _purchaseService.inAppPurchaseService.restorePurchases();
      await ref.read(userInfoProvider.notifier).getUserProfiles();

      logger.i('[PurchaseStarCandyState] Purchase restoration completed');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(content: '구매 복원이 완료되었습니다.\n스타캔디 잔액을 확인해주세요.');

        Timer(_restoreResetDelay, () {
          if (mounted) {
            setState(() => _isUserRequestedRestore = false);
          }
        });
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] Purchase restoration failed: $e');

      setState(() => _isUserRequestedRestore = false);

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: '구매 복원 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
          type: DialogType.error,
        );
      }
    }
  }

  Future<bool?> _showRestoreConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('구매 복원'),
        content: Text('''이전에 구매한 상품을 복원하시겠습니까?

주의사항:
• 이미 처리된 구매는 중복으로 지급되지 않습니다
• 복원 과정에서 일시적으로 알림이 나타날 수 있습니다
• 스타캔디가 누락된 경우에만 사용해주세요'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('복원'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckPendingStatus() async {
    if (!kDebugMode) return;

    try {
      logger.i('[PurchaseStarCandyState] Pending 상태 확인 시작');

      _loadingKey.currentState?.show();

      final status =
          await _purchaseService.inAppPurchaseService.getPendingCleanupStatus();

      if (mounted) {
        _loadingKey.currentState?.hide();
        await _showPendingStatusDialog(status);
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] Pending 상태 확인 실패: $e');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: 'Pending 상태 확인 중 오류가 발생했습니다: $e',
          type: DialogType.error,
        );
      }
    }
  }

  Future<void> _showPendingStatusDialog(Map<String, dynamic> status) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pending 구매 정리 상태'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('통계 정보:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• 현재 pending: ${status['currentPendingCount']}개'),
              Text('• 총 발견한 pending: ${status['totalPendingFound']}개'),
              Text('• 총 정리한 pending: ${status['totalPendingCleared']}개'),
              Text('• 마지막 정리: ${status['lastCleanupTime'] ?? '없음'}'),
              SizedBox(height: 12),
              if (status['currentPendingItems'] != null &&
                  (status['currentPendingItems'] as List).isNotEmpty) ...[
                Text('현재 pending 구매들:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...(status['currentPendingItems'] as List).map(
                  (item) => Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                        '• ${item['productID']} (${item['transactionDate']})'),
                  ),
                ),
              ] else ...[
                Text('현재 pending 구매 없음',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ],
              SizedBox(height: 12),
              Text(
                  '정리 성공률: ${status['totalPendingFound'] > 0 ? ((status['totalPendingCleared'] / status['totalPendingFound'] * 100).toStringAsFixed(1)) : '0'}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSandboxAuthReset() async {
    if (!kDebugMode) return;

    final shouldReset = await _showSandboxAuthResetDialog();
    if (shouldReset != true) return;

    try {
      logger.w('[PurchaseStarCandyState] Sandbox 인증창 초기화 시작');

      _loadingKey.currentState?.show();

      // Sandbox 인증창 강제 초기화 실행
      await _purchaseService.inAppPurchaseService.forceSandboxAuthReset();

      logger.w('[PurchaseStarCandyState] Sandbox 인증창 초기화 완료');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: '''Sandbox 인증창 초기화가 완료되었습니다!

다음 구매 시도 시:
• Touch ID/Face ID 인증창이 다시 표시됩니다
• 이전 인증 상태가 모두 리셋되었습니다
• 모든 pending 구매가 정리되었습니다''',
        );
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] Sandbox 인증창 초기화 실패: $e');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: 'Sandbox 인증창 초기화 중 오류가 발생했습니다: $e',
          type: DialogType.error,
        );
      }
    }
  }

  Future<void> _handleSandboxDiagnosis() async {
    if (!kDebugMode) return;

    try {
      logger.i('[PurchaseStarCandyState] Sandbox 환경 진단 시작');

      _loadingKey.currentState?.show();

      final diagnosis = await _purchaseService.inAppPurchaseService
          .diagnoseSandboxEnvironment();

      if (mounted) {
        _loadingKey.currentState?.hide();
        await _showSandboxDiagnosisDialog(diagnosis);
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] Sandbox 진단 실패: $e');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: 'Sandbox 진단 중 오류가 발생했습니다: $e',
          type: DialogType.error,
        );
      }
    }
  }

  Future<void> _handleNuclearReset() async {
    if (!kDebugMode) return;

    final shouldReset = await _showNuclearResetDialog();
    if (shouldReset != true) return;

    try {
      logger.w('[PurchaseStarCandyState] 핵폭탄급 리셋 시작');

      _loadingKey.currentState?.show();

      // 핵폭탄급 Sandbox 인증 시스템 완전 리셋 실행
      await _purchaseService.inAppPurchaseService.nuclearSandboxReset();

      logger.w('[PurchaseStarCandyState] 핵폭탄급 리셋 완료');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: '''💥 핵폭탄급 Sandbox 리셋 완료!

실행된 작업:
• 모든 StoreKit 연결 완전 끊기 (5초 대기)
• 시스템 캐시 완전 무효화 (10회 시도)
• 핵폭탄급 pending 구매 정리 (5라운드)
• 긴 시스템 안정화 대기 (10초)
• 완전 새로운 구매 스트림 생성

이제 구매를 다시 시도해보세요!''',
        );
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] 핵폭탄급 리셋 실패: $e');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: '핵폭탄급 리셋 중 오류가 발생했습니다: $e',
          type: DialogType.error,
        );
      }
    }
  }

  Future<void> _showSandboxDiagnosisDialog(
      Map<String, dynamic> diagnosis) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🏥 Sandbox 환경 진단 결과'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('진단 시간: ${diagnosis['timestamp'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🔍 시스템 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 플랫폼: ${diagnosis['platform'] ?? 'Unknown'}'),
              Text('• 디버그 모드: ${diagnosis['isDebugMode'] ?? 'Unknown'}'),
              Text(
                  '• StoreKit 사용 가능: ${diagnosis['storeKitAvailable'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('📱 구매 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• 현재 pending 구매: ${diagnosis['currentPendingCount'] ?? 'Unknown'}개'),
              Text(
                  '• 총 구매 업데이트: ${diagnosis['totalPurchaseUpdates'] ?? 'Unknown'}개'),
              Text(
                  '• 제품 쿼리 성공: ${diagnosis['productQuerySuccessful'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('🔄 스트림 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• 스트림 초기화됨: ${diagnosis['streamInitialized'] ?? 'Unknown'}'),
              Text(
                  '• 구매 컨트롤러 활성: ${diagnosis['purchaseControllerActive'] ?? 'Unknown'}'),
              if (diagnosis['error'] != null) ...[
                SizedBox(height: 8),
                Text('❌ 에러:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                Text('${diagnosis['error']}',
                    style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showNuclearResetDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('💥 핵폭탄급 Sandbox 리셋'),
        content: Text('''⚠️ 최후의 수단입니다! ⚠️

이 기능은 모든 StoreKit 시스템을 완전히 리셋합니다.

실행할 작업:
💥 모든 StoreKit 연결 완전 끊기 (5초 대기)
💥 시스템 캐시 완전 무효화 (10회 시도)
💥 핵폭탄급 pending 구매 정리 (5라운드)
💥 긴 시스템 안정화 대기 (10초)
💥 완전 새로운 구매 스트림 생성

주의사항:
• 이 과정은 최대 30초 소요됩니다
• 모든 기존 구매 상태가 완전히 리셋됩니다
• 일반 초기화로 해결되지 않는 경우에만 사용하세요

정말로 실행하시겠습니까?'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('💥 핵리셋', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showSandboxAuthResetDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sandbox 인증창 초기화'),
        content: Text('''Sandbox 환경에서 인증창이 생략되는 문제를 해결합니다.

실행할 작업:
🔄 StoreKit 캐시 완전 초기화 (3회 시도)
🧹 모든 pending 구매 강제 완료
⏰ 시스템 안정화 대기
🔄 구매 스트림 재시작

효과:
✅ Touch ID/Face ID 인증창 재활성화
✅ 이전 인증 상태 완전 리셋
✅ 구매 프로세스 정상화

주의: Sandbox 환경에서만 사용하세요.'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('초기화', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleForceReset() async {
    if (!kDebugMode) return;

    final shouldReset = await _showForceResetDialog();
    if (shouldReset != true) return;

    try {
      logger.w('[PurchaseStarCandyState] Force reset initiated');

      setState(() {
        _isActivePurchasing = false;
        _isPurchasing = false;
        _isInitializing = false;
        _pendingProductId = null;
        _transactionsCleared = true;
        _lastPurchaseAttempt = null;
        _isUserRequestedRestore = false;
        _initializationCompletedAt = DateTime.now();
      });

      try {
        _loadingKey.currentState?.hide();
      } catch (e) {
        logger.d('Loading state stop error (ignored): $e');
      }

      try {
        await _purchaseService.inAppPurchaseService.clearTransactions();
        await Future.delayed(Duration(seconds: 1));
        await _purchaseService.inAppPurchaseService.refreshStoreKitCache();
        await Future.delayed(Duration(seconds: 1));
        await _purchaseService.inAppPurchaseService.clearTransactions();
      } catch (e) {
        logger.w('StoreKit cache clear error: $e');
      }

      logger.w('[PurchaseStarCandyState] Force reset completed');

      if (mounted) {
        showSimpleDialog(content: '모든 구매 상태가 리셋되었습니다.\n이제 새로운 구매를 시도할 수 있습니다.');
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] Force reset failed: $e');

      if (mounted) {
        showSimpleDialog(
          content: '강제 리셋 중 오류가 발생했습니다: $e',
          type: DialogType.error,
        );
      }
    }
  }

  Future<bool?> _showForceResetDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('디버그: 강제 상태 리셋'),
        content: Text('''모든 구매 관련 상태를 강제로 리셋합니다.

주의: 이 기능은 디버그 모드에서만 사용 가능합니다.

리셋할 항목:
• 구매 진행 상태
• 트랜잭션 캐시
• 로딩 상태
• 에러 상태'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('강제 리셋', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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

  // 🧪 디버그 기능들 (kDebugMode에서만 활성화)
  Widget _buildDebugButtons() {
    if (!kDebugMode) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧪 디버그 및 시뮬레이션 도구',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),

          // 🎯 강제 타임아웃 (가장 확실한 방법)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎯 강제 타임아웃 (100% 확실)',
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
                            content: Text(
                                '🎯 강제 타임아웃 ON - 이제 구매하면 3초 후 100% 타임아웃 발생!'),
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
                          SnackBar(content: Text('🎯 강제 타임아웃 OFF - 정상 구매 진행')),
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

          // 일반 타임아웃 모드들
          Text('⏰ 타임아웃 시간 설정', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    SnackBar(content: Text('⏰ 즉시 타임아웃 (100ms)')),
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
                    SnackBar(content: Text('⏰ 초고속 타임아웃 (500ms)')),
                  );
                },
                child: Text('500ms', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  _purchaseService.setTimeoutMode('debug');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('⏰ 디버그 타임아웃 (3초)')),
                  );
                },
                child: Text('3초', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  _purchaseService.setTimeoutMode('normal');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('⏰ 정상 타임아웃 (30초)')),
                  );
                },
                child: Text('30초', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          SizedBox(height: 12),

          // 구매 지연 시뮬레이션
          Text('🐌 구매 지연 시뮬레이션', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    SnackBar(content: Text('🐌 구매 지연 ON - 5초 지연')),
                  );
                },
                child: Text('지연 ON', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: () {
                  _purchaseService.disableSlowPurchase();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🐌 구매 지연 OFF')),
                  );
                },
                child: Text('지연 OFF', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          SizedBox(height: 12),

          // 구매 상태 관리
          Text('🎮 구매 상태 관리', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500.withValues(alpha: 0.9),
                ),
                onPressed: _handleRestorePurchases,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restore, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('구매복원',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _handleSandboxAuthReset,
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
                onPressed: _handleSandboxDiagnosis,
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
                onPressed: _handleNuclearReset,
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
                onPressed: _handleCheckPendingStatus,
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

          // 🔍 인증 문제 해결 (새로운 섹션)
          Text('🔍 인증 문제 해결', style: TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: _handleAuthenticationDiagnosis,
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
                onPressed: _handleUltimateAuthReset,
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

  /// 🔍 새로운 인증 상태 진단 기능
  Future<void> _handleAuthenticationDiagnosis() async {
    if (!kDebugMode) return;

    try {
      logger.i('[PurchaseStarCandyState] 인증 상태 진단 시작');

      _loadingKey.currentState?.show();

      final diagnosis = await _purchaseService.inAppPurchaseService
          .diagnoseAuthenticationState();

      if (mounted) {
        _loadingKey.currentState?.hide();
        await _showAuthenticationDiagnosisDialog(diagnosis);
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] 인증 상태 진단 실패: $e');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: '인증 상태 진단 중 오류가 발생했습니다: $e',
          type: DialogType.error,
        );
      }
    }
  }

  /// 🔥 궁극적인 인증창 복구 (최후의 수단)
  Future<void> _handleUltimateAuthReset() async {
    if (!kDebugMode) return;

    final shouldReset = await _showUltimateAuthResetDialog();
    if (shouldReset != true) return;

    try {
      logger.w('[PurchaseStarCandyState] 궁극적인 인증창 복구 시작');

      _loadingKey.currentState?.show();

      // 궁극적인 인증창 복구 실행
      await _purchaseService.inAppPurchaseService.ultimateAuthenticationReset();

      logger.w('[PurchaseStarCandyState] 궁극적인 인증창 복구 완료');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: '''🔥 궁극적인 인증창 복구 완료!

실행된 작업:
• 모든 StoreKit 연결 완전 해제 (5초 대기)
• 시스템 레벨 캐시 완전 무효화 (10회 시도)
• 완전히 새로운 구매 환경 재구성
• 최대 20초간의 안정화 과정

⚠️ 이제 다음을 시도해보세요:
1. 앱을 완전 재시작하거나
2. iOS 설정 > App Store 로그아웃/재로그인하거나
3. 디바이스 재부팅 후 테스트

이 방법으로도 안 되면 iOS 시스템 레벨 이슈입니다.''',
        );
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] 궁극적인 인증창 복구 실패: $e');

      if (mounted) {
        _loadingKey.currentState?.hide();
        showSimpleDialog(
          content: '궁극적인 인증창 복구 중 오류가 발생했습니다: $e',
          type: DialogType.error,
        );
      }
    }
  }

  /// 🔍 인증 상태 진단 결과 다이얼로그
  Future<void> _showAuthenticationDiagnosisDialog(
      Map<String, dynamic> diagnosis) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔍 인증 상태 진단 결과'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('진단 시간: ${diagnosis['timestamp'] ?? 'Unknown'}'),
              SizedBox(height: 12),
              Text('🔍 시스템 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 플랫폼: ${diagnosis['platform'] ?? 'Unknown'}'),
              Text('• 디버그 모드: ${diagnosis['isDebugMode'] ?? 'Unknown'}'),
              Text(
                  '• StoreKit 사용 가능: ${diagnosis['storeKitAvailable'] ?? 'Unknown'}'),
              SizedBox(height: 8),
              Text('📱 구매 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• 현재 pending: ${diagnosis['currentPendingCount'] ?? 'Unknown'}개'),
              Text('• 총 업데이트: ${diagnosis['totalUpdatesCount'] ?? 'Unknown'}개'),
              SizedBox(height: 8),
              Text('🔍 제품 쿼리:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 쿼리 성공: ${diagnosis['productQuerySuccess'] ?? 'Unknown'}'),
              Text('• 제품 개수: ${diagnosis['productCount'] ?? 'Unknown'}개'),
              SizedBox(height: 8),
              Text('🔄 스트림 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• 스트림 초기화: ${diagnosis['streamInitialized'] ?? 'Unknown'}'),
              Text('• 컨트롤러 활성: ${diagnosis['controllerActive'] ?? 'Unknown'}'),
              if (diagnosis['error'] != null) ...[
                SizedBox(height: 8),
                Text('❌ 오류:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                Text('${diagnosis['error']}',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
              if (diagnosis['recommendedSolutions'] != null) ...[
                SizedBox(height: 12),
                Text('💡 권장 해결책:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue)),
                ...((diagnosis['recommendedSolutions'] as List<String>))
                    .map((solution) => Padding(
                          padding: EdgeInsets.only(left: 8, top: 2),
                          child: Text('• $solution',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blue[700])),
                        )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 🔥 궁극적인 인증창 복구 확인 다이얼로그
  Future<bool?> _showUltimateAuthResetDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔥 궁극적인 인증창 복구'),
        content: Text('''⚠️ 최후의 수단입니다! ⚠️

이것은 모든 StoreKit 시스템을 완전히 리셋하는 가장 강력한 방법입니다.

실행할 작업:
🔥 모든 StoreKit 연결 완전 해제 (5초 대기)
🔥 시스템 레벨 캐시 완전 무효화 (10회 시도, 총 10초)
🔥 완전히 새로운 구매 환경 재구성 (3초 안정화)
🔥 최종 검증 (1초)

⏰ 총 소요 시간: 약 20초

주의사항:
• 가장 강력한 인증 상태 리셋입니다
• 이 과정은 최대 20초 소요됩니다
• 모든 기존 구매 상태가 완전히 리셋됩니다
• 일반 방법으로 해결되지 않는 경우에만 사용하세요

완료 후 권장사항:
1. 앱 완전 재시작
2. iOS 설정 > App Store 로그아웃/재로그인
3. 디바이스 재부팅

정말로 실행하시겠습니까?'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('🔥 궁극 복구', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }
}
