import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
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

  // 상태 관리
  String? _pendingProductId;
  bool _transactionsCleared = false;
  bool _isActivePurchasing = false;
  bool _isInitializing = true;
  bool _isUserRequestedRestore = false;
  bool _isPurchasing = false;

  // 시간 관리
  DateTime? _initializationCompletedAt;
  DateTime? _lastPurchaseAttempt;

  // 성능 최적화 상수
  static const Duration _purchaseCooldown = Duration(seconds: 2);
  static const Duration _purchaseTimeout = Duration(seconds: 30);
  static const Duration _restoreResetDelay = Duration(seconds: 5);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });
  }

  /// 페이지 초기화 (즉시 완료)
  Future<void> _initializePage() async {
    final initStartTime = DateTime.now();
    logger.i('[PurchaseStarCandyState] Starting fast initialization');

    if (!mounted) return;

    try {
      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

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
        OverlayLoadingProgress.stop();
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] Initialization failed: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initializationCompletedAt = DateTime.now();
          _transactionsCleared = true;
        });
        OverlayLoadingProgress.stop();
      }
    }
  }

  @override
  void dispose() {
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
        'dismiss'
      ];

      final cancelErrorCodes = [
        'PAYMENT_CANCELED',
        'USER_CANCELED',
        '2',
        'SKErrorPaymentCancelled',
        'BILLING_RESPONSE_USER_CANCELED'
      ];

      for (final keyword in cancelKeywords) {
        if (errorMessage.contains(keyword)) {
          logger
              .i('[PurchaseStarCandyState] Cancel keyword detected: $keyword');
          return true;
        }
      }

      for (final code in cancelErrorCodes) {
        if (errorCode.contains(code)) {
          logger
              .i('[PurchaseStarCandyState] Cancel error code detected: $code');
          return true;
        }
      }
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
      OverlayLoadingProgress.stop();
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
    return _isActivePurchasing &&
        (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored);
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

    logger.i(
        '[PurchaseStarCandyState] Processing active purchase: ${purchaseDetails.productID} (actual: $isActualPurchase)');

    await _purchaseService.handleOptimizedPurchase(
      purchaseDetails,
      () async {
        logger.i('[PurchaseStarCandyState] Purchase successful');
        await ref.read(userInfoProvider.notifier).getUserProfiles();

        if (mounted) {
          _resetPurchaseState();
          OverlayLoadingProgress.stop();
          await _showSuccessDialog();
        }
      },
      (error) async {
        if (mounted) {
          _resetPurchaseState();
          OverlayLoadingProgress.stop();

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
        OverlayLoadingProgress.stop();

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
        OverlayLoadingProgress.stop();
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
    setState(() {
      _isActivePurchasing = false;
      _pendingProductId = null;
      _isPurchasing = false;
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
      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

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

      final purchaseInitiated = await _purchaseService.initiatePurchase(
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
            OverlayLoadingProgress.stop();
            await _showErrorDialog(message);
          }
        },
      );

      await _handlePurchaseResult(purchaseInitiated);
    } catch (e, s) {
      logger.e('[PurchaseStarCandyState] Error starting purchase: $e',
          error: e, stackTrace: s);
      _resetPurchaseState();
      if (mounted) {
        OverlayLoadingProgress.stop();
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

  /// 구매 결과 처리
  Future<void> _handlePurchaseResult(bool purchaseInitiated) async {
    if (!purchaseInitiated) {
      _resetPurchaseState();
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(t('dialog_message_purchase_failed'));
      }
    } else {
      logger.i('[PurchaseStarCandyState] Purchase initiated successfully');

      // 타임아웃 설정
      Timer(_purchaseTimeout, () {
        if (_isActivePurchasing && mounted) {
          logger.w('[PurchaseStarCandyState] Purchase timeout');
          _resetPurchaseState();
          OverlayLoadingProgress.stop();
          _showErrorDialog('구매 시간이 초과되었습니다. 다시 시도해주세요.');
        }
      });
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
      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

      await _purchaseService.inAppPurchaseService.restorePurchases();
      await ref.read(userInfoProvider.notifier).getUserProfiles();

      logger.i('[PurchaseStarCandyState] Purchase restoration completed');

      if (mounted) {
        OverlayLoadingProgress.stop();
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
        OverlayLoadingProgress.stop();
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
      logger.i('[PurchaseStarCandyState] Checking pending cleanup status');

      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

      final status =
          await _purchaseService.inAppPurchaseService.getPendingCleanupStatus();

      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showPendingStatusDialog(status);
      }
    } catch (e) {
      logger.e('[PurchaseStarCandyState] Failed to check pending status: $e');

      if (mounted) {
        OverlayLoadingProgress.stop();
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
        OverlayLoadingProgress.stop();
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
    return Container(
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
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildRefreshButton(),
        if (kDebugMode) ...[
          const SizedBox(width: 8),
          _buildRestoreButton(),
          const SizedBox(width: 8),
          _buildForceResetButton(),
          const SizedBox(width: 8),
          _buildPendingCheckButton(),
        ],
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

  Widget _buildRestoreButton() {
    return GestureDetector(
      onTap: _handleRestorePurchases,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary500.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primary500.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restore, size: 16, color: AppColors.primary500),
            SizedBox(width: 4),
            Text(
              '구매복원',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForceResetButton() {
    return GestureDetector(
      onTap: _handleForceReset,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 16, color: Colors.red),
            SizedBox(width: 4),
            Text(
              '상태리셋',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCheckButton() {
    return GestureDetector(
      onTap: _handleCheckPendingStatus,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text(
              'Pending확인',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
}
