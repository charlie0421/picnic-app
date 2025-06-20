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
  String? _pendingProductId; // 복원 구매 후 재시도할 상품 ID

  // 🔄 Transaction clear 이후 플래그
  bool _transactionsCleared = false;

  // 실제 구매 진행 중 플래그
  bool _isActivePurchasing = false;

  // 초기화 중 로딩 상태
  bool _isInitializing = true;

  bool _isPurchasing = false;
  DateTime? _lastPurchaseAttempt;
  static const Duration _purchaseCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    logger.d('PurchaseStarCandyState initState called');

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

    // 🔄 구매 페이지 초기화 시 pending 구매 클리어 (로딩바와 함께)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithLoading();
    });
  }

  /// 로딩바와 함께 초기화를 수행합니다.
  Future<void> _initializeWithLoading() async {
    if (!mounted) return;

    try {
      // 로딩바 표시
      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

      logger.i('🎬 구매 페이지 초기화 시작 - 로딩바 표시');

      // pending 구매 클리어
      await _clearPendingPurchases();

      // 초기화 완료 후 잠시 대기하여 초기 복원 구매들이 먼저 처리되도록 함
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        OverlayLoadingProgress.stop();
        logger.i('🎯 구매 페이지 초기화 완료 - 구매 준비됨');
      }
    } catch (e) {
      logger.e('❌ 구매 페이지 초기화 실패: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        OverlayLoadingProgress.stop();
      }
    }
  }

  /// 구매 페이지 시작 시 pending 상태의 구매들을 모두 클리어합니다.
  /// 이후 발생하는 모든 구매는 신규 구매로 간주됩니다.
  Future<void> _clearPendingPurchases() async {
    try {
      logger.i('🧹 구매 페이지 초기화: pending 구매 클리어 시작');
      await _purchaseService.inAppPurchaseService.clearTransactions();
      _transactionsCleared = true; // 플래그 설정
      logger.i('✅ pending 구매 클리어 완료 - 이후 모든 구매는 신규 구매로 처리');
    } catch (e) {
      logger.e('❌ pending 구매 클리어 실패: $e');
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _purchaseService.inAppPurchaseService.dispose();
    super.dispose();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    logger.d(
        'Active purchasing: $_isActivePurchasing, Transactions cleared: $_transactionsCleared');

    try {
      for (final purchaseDetails in purchaseDetailsList) {
        logger.d(
            'Purchase updated: ${purchaseDetails.status} for ${purchaseDetails.productID}');

        // pending 상태일 때는 로딩 상태 유지
        if (purchaseDetails.status == PurchaseStatus.pending) {
          logger.i('📋 Purchase pending for ${purchaseDetails.productID}');
          continue;
        }

        // ⭐ 개선된 초기화 기간 중의 restored 구매 처리
        if (!_isActivePurchasing && !_transactionsCleared) {
          if (purchaseDetails.status == PurchaseStatus.restored) {
            logger.i(
                '🔄 [INIT] Restored purchase detected during initialization: ${purchaseDetails.productID}');
            logger.i('   → ⭐ COMPLETELY IGNORING - NO PROCESSING AT ALL');

            // ⭐ 초기화 시 복원된 구매는 아예 처리하지 않음 (완료도 하지 않음)
            // 이미 처리된 구매일 가능성이 매우 높으므로 모든 처리를 생략
            // 단순히 무시하고 완료 처리도 하지 않음 (중복 검증 방지)
            logger.i(
                '✅ [INIT] Restored purchase completely ignored (no processing, no completion)');
            continue;
          }

          // 초기화 기간 중 예상치 못한 purchased 상태도 완전히 무시
          if (purchaseDetails.status == PurchaseStatus.purchased) {
            logger.w(
                '⚠️ [INIT] Unexpected purchased status during initialization: ${purchaseDetails.productID}');
            logger.w('   → ⭐ COMPLETELY IGNORING - NO PROCESSING AT ALL');

            // ⭐ 예상치 못한 purchased도 아예 처리하지 않음 (완료도 하지 않음)
            logger.i(
                '✅ [INIT] Unexpected purchase completely ignored (no processing, no completion)');
            continue;
          }
        }

        // Transaction clear 이후 또는 실제 구매 중인 경우
        if (_transactionsCleared || _isActivePurchasing) {
          logger.i(
              '🎯 [ACTIVE] Processing purchase during active session: ${purchaseDetails.productID} - ${purchaseDetails.status}');

          if (purchaseDetails.status == PurchaseStatus.purchased ||
              purchaseDetails.status == PurchaseStatus.restored) {
            // 실제 구매 세션 중이면 모든 구매를 신규 구매로 처리
            final isActualPurchase = _isActivePurchasing &&
                purchaseDetails.productID == _pendingProductId;
            logger.i('   → Is actual purchase: $isActualPurchase');

            // ⭐ 중요: 실제 구매 세션 중에는 restored 상태라도 신규 구매로 간주
            final treatAsNewPurchase = _isActivePurchasing &&
                purchaseDetails.productID == _pendingProductId;
            logger.i('   → Treat as new purchase: $treatAsNewPurchase');

            logger.i(
                '''🔄 Processing purchase - determining success dialog display:
   isActualPurchase: $isActualPurchase
   treatAsNewPurchase: $treatAsNewPurchase
   _isActivePurchasing: $_isActivePurchasing
   _pendingProductId: $_pendingProductId''');

            // ⭐ 최적화된 구매 처리: 영수증 검증 + JWT 재사용 문제 해결
            await _purchaseService.handleOptimizedPurchase(
              purchaseDetails,
              () async {
                logger.i('🎯 구매 성공 콜백 - 스타 캔디 지급 완료');
                await ref.read(userInfoProvider.notifier).getUserProfiles();

                if (mounted) {
                  setState(() {
                    _isActivePurchasing = false;
                    _pendingProductId = null;
                    _isPurchasing = false; // 🔄 구매 상태도 완전히 리셋
                  });
                  OverlayLoadingProgress.stop();
                  logger.i('🎉 성공 다이얼로그 표시');
                  await _showSuccessDialog();
                }
              },
              (error) async {
                if (mounted) {
                  setState(() {
                    _isActivePurchasing = false;
                    _pendingProductId = null;
                    _isPurchasing = false; // 🔄 구매 상태도 완전히 리셋
                  });
                  OverlayLoadingProgress.stop();

                  // ⭐ 서버 측 오류 메시지 확인 및 처리
                  if (error.contains('StoreKit 캐시 문제') ||
                      error.contains('중복 영수증') ||
                      error.contains('이미 처리된 구매') ||
                      error.contains('Duplicate') ||
                      error.toLowerCase().contains('reused')) {
                    logger.w('🔄 예상치 못한 중복 감지 - 서버 처리 실패 가능성');

                    // 서버 중복 검사 완화에도 불구하고 여전히 중복 에러가 발생한 경우
                    await _showUnexpectedDuplicateDialog();
                  } else {
                    // 실제 에러 처리
                    logger.e('❌ 구매 오류: $error');
                    await _showErrorDialog(error);
                  }
                }
              },
              isActualPurchase: treatAsNewPurchase,
            );
          }
        }

        // 공통 에러 및 취소 처리
        if (purchaseDetails.status == PurchaseStatus.error) {
          logger.e('❌ Purchase error: ${purchaseDetails.error?.message}');
          if (mounted) {
            setState(() {
              _isActivePurchasing = false;
              _pendingProductId = null;
              _isPurchasing = false; // 🔄 구매 상태도 완전히 리셋
            });
            OverlayLoadingProgress.stop();

            // 취소가 아닌 실제 오류일 때만 에러 다이얼로그 표시
            if (purchaseDetails.error?.message
                    .toLowerCase()
                    .contains('canceled') !=
                true) {
              await _showErrorDialog(t('dialog_message_purchase_failed'));
            }
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          logger.i('❌ Purchase canceled: ${purchaseDetails.productID}');
          if (mounted) {
            setState(() {
              _isActivePurchasing = false;
              _pendingProductId = null;
              _isPurchasing = false; // 🔄 구매 상태도 완전히 리셋
            });
            OverlayLoadingProgress.stop();
          }
        }

        // 모든 상태 처리 후 구매 완료 처리
        if (purchaseDetails.pendingCompletePurchase) {
          await _purchaseService.inAppPurchaseService
              .completePurchase(purchaseDetails);
        }
      }
    } catch (e, s) {
      logger.e('Error handling purchase update', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _isActivePurchasing = false;
          _pendingProductId = null;
          _isPurchasing = false; // 🔄 구매 상태도 완전히 리셋
        });
        OverlayLoadingProgress.stop();
        await _showErrorDialog(t('dialog_message_purchase_failed'));
      }
      rethrow;
    }
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

    // 초기화 중일 때 구매 방지
    if (_isInitializing) {
      logger.w('⏳ 구매 페이지 초기화 중 - 구매 요청 무시');
      showSimpleDialog(content: '초기화 중입니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    // 🔄 중복 구매 방지 체크
    final now = DateTime.now();
    if (_isPurchasing) {
      logger.w('⚠️ Purchase already in progress, ignoring duplicate request');
      showSimpleDialog(content: '구매가 진행 중입니다. 잠시만 기다려주세요.');
      return;
    }

    if (_lastPurchaseAttempt != null &&
        now.difference(_lastPurchaseAttempt!) < _purchaseCooldown) {
      logger.w('⚠️ Purchase cooldown active, ignoring request');
      showSimpleDialog(content: '잠시 후 다시 시도해주세요.');
      return;
    }

    // 🔄 구매 시작 상태 설정
    setState(() {
      _isPurchasing = true;
      _lastPurchaseAttempt = now;
    });

    try {
      logger.i(
          '🎯 [PURCHASE] Starting actual purchase for: ${serverProduct['id']}');

      // ⭐ 먼저 로딩 표시
      if (!context.mounted) return;
      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

      // 🍬 소모성 상품용 기본 캐시 클리어 (서버에서 중복 검사 완화됨)
      logger.i('🍬 소모성 상품용 기본 캐시 클리어 - 서버에서 JWT 재사용 허용됨');

      // 기본 트랜잭션 클리어
      await _purchaseService.inAppPurchaseService.clearTransactions();
      await Future.delayed(Duration(seconds: 1));

      logger.i('✅ 기본 캐시 클리어 완료 - 서버에서 소모성 상품 재사용 허용됨');

      // 실제 구매 시작 플래그 설정
      _isActivePurchasing = true;
      _pendingProductId = serverProduct['id'];
      _transactionsCleared = true;

      final purchaseInitiated = await _purchaseService.initiatePurchase(
        serverProduct['id'],
        onSuccess: () async {
          logger.i('✅ [PURCHASE] Purchase success callback called');
          // 🔄 구매 상태 리셋
          setState(() {
            _isPurchasing = false;
          });
          // 성공 처리는 _onPurchaseUpdate에서 수행됨
        },
        onError: (message) async {
          logger.e('❌ [PURCHASE] Purchase error callback: $message');
          // 🔄 구매 상태 완전 리셋
          setState(() {
            _isActivePurchasing = false;
            _pendingProductId = null;
            _isPurchasing = false;
          });
          if (mounted) {
            OverlayLoadingProgress.stop();
            await _showErrorDialog(message);
          }
        },
      );

      if (!purchaseInitiated) {
        // 🔄 구매 상태 완전 리셋
        setState(() {
          _isActivePurchasing = false;
          _pendingProductId = null;
          _isPurchasing = false;
        });
        if (mounted) {
          OverlayLoadingProgress.stop();
          await _showErrorDialog(t('dialog_message_purchase_failed'));
        }
      } else {
        logger.i(
            '✅ [PURCHASE] Purchase initiated successfully - waiting for completion');

        // 30초 타임아웃 설정
        Timer(Duration(seconds: 30), () {
          if (_isActivePurchasing && mounted) {
            logger.w('⏰ [PURCHASE] Purchase timeout - stopping loading');
            // 🔄 구매 상태 완전 리셋
            setState(() {
              _isActivePurchasing = false;
              _pendingProductId = null;
              _isPurchasing = false;
            });
            OverlayLoadingProgress.stop();
            _showErrorDialog('구매 시간이 초과되었습니다. 다시 시도해주세요.');
          }
        });
      }
    } catch (e, s) {
      logger.e('Error starting purchase', error: e, stackTrace: s);
      // 🔄 구매 상태 완전 리셋
      setState(() {
        _isActivePurchasing = false;
        _pendingProductId = null;
        _isPurchasing = false;
      });
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(t('dialog_message_purchase_failed'));
      }
      rethrow;
    }
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;

    // 디버그 모드 또는 테스트플라이트에서만 디버깅 정보 표시
    try {
      final envInfo = await _purchaseService.receiptVerificationService
          .getEnvironmentInfo();

      // 디버그 모드이거나 테스트플라이트 환경인 경우에만 디버깅 정보 표시
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

        showSimpleDialog(content: debugInfo.toString(), type: DialogType.error);
      } else {
        // 프로덕션 환경에서는 기본 에러 메시지만 표시
        showSimpleDialog(content: message, type: DialogType.error);
      }
    } catch (e) {
      // 환경 정보 가져오기 실패 시 기본 에러 메시지만 표시
      showSimpleDialog(content: message, type: DialogType.error);
    }
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) {
      logger.w('❌ Cannot show success dialog - widget not mounted');
      return;
    }

    logger.i('🎉 Showing success dialog...');
    final message = t('dialog_message_purchase_success');
    showSimpleDialog(content: message);
    logger.i('✅ Success dialog displayed');
  }

  /// 예상치 못한 중복 감지 다이얼로그
  Future<void> _showUnexpectedDuplicateDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🔧 서버 처리 중 문제 발생'),
        content: Text('''서버에서 소모성 상품 중복 검사를 완화했지만 여전히 오류가 발생했습니다.

🚨 가능한 원인:
1. 서버 배포가 아직 완전히 적용되지 않음
2. 다른 종류의 네트워크 오류
3. 잠시 후 다시 시도하면 해결될 가능성

💡 해결 방법:
1. 1-2분 후 다시 시도 (서버 배포 완료 대기)
2. 그래도 안 되면 앱 재시작
3. 문제가 지속되면 고객지원 문의

⭐ 소모성 상품이므로 중복 구매가 정상적으로 허용되어야 합니다.'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 구매 복원 처리 메서드
  Future<void> _handleRestorePurchases() async {
    if (_isActivePurchasing || _isPurchasing) {
      logger.w('⚠️ 구매 진행 중에는 복원할 수 없습니다');
      showSimpleDialog(content: '구매가 진행 중입니다. 완료 후 다시 시도해주세요.');
      return;
    }

    // 확인 다이얼로그 표시
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('구매 복원'),
        content: Text('''이전에 구매한 상품을 복원하시겠습니까?

⚠️ 주의사항:
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

    if (shouldRestore != true) return;

    try {
      logger.i('🔄 사용자 요청으로 구매 복원 시작');

      if (!context.mounted) return;
      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

      // 복원 실행
      await _purchaseService.inAppPurchaseService.restorePurchases();

      // 사용자 프로필 새로고침
      await ref.read(userInfoProvider.notifier).getUserProfiles();

      logger.i('✅ 구매 복원 완료');

      if (mounted) {
        OverlayLoadingProgress.stop();
        showSimpleDialog(
          content: '구매 복원이 완료되었습니다.\n스타캔디 잔액을 확인해주세요.',
        );
      }
    } catch (e) {
      logger.e('❌ 구매 복원 실패: $e');

      if (mounted) {
        OverlayLoadingProgress.stop();
        showSimpleDialog(
          content: '구매 복원 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
          type: DialogType.error,
        );
      }
    }
  }

  /// 🚨 디버그용 강제 상태 리셋 메서드
  Future<void> _handleForceReset() async {
    if (!kDebugMode) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🚨 디버그: 강제 상태 리셋'),
        content: Text('''모든 구매 관련 상태를 강제로 리셋합니다.

⚠️ 주의: 이 기능은 디버그 모드에서만 사용 가능합니다.

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

    if (shouldReset != true) return;

    try {
      logger.w('🚨 [DEBUG] 강제 상태 리셋 시작');

      // 모든 구매 관련 상태 강제 리셋
      setState(() {
        _isActivePurchasing = false;
        _isPurchasing = false;
        _isInitializing = false;
        _pendingProductId = null;
        _transactionsCleared = true;
        _lastPurchaseAttempt = null;
      });

      // 로딩 상태 강제 중지
      try {
        OverlayLoadingProgress.stop();
      } catch (e) {
        logger.d('로딩 상태 중지 시 에러 (무시): $e');
      }

      // StoreKit 캐시 및 트랜잭션 강제 클리어
      try {
        await _purchaseService.inAppPurchaseService.clearTransactions();
        await Future.delayed(Duration(seconds: 1));
        await _purchaseService.inAppPurchaseService.refreshStoreKitCache();
        await Future.delayed(Duration(seconds: 1));
        await _purchaseService.inAppPurchaseService.clearTransactions();
      } catch (e) {
        logger.w('StoreKit 캐시 클리어 중 에러: $e');
      }

      logger.w('✅ [DEBUG] 강제 상태 리셋 완료');

      if (mounted) {
        showSimpleDialog(
          content: '🚨 디버그: 모든 구매 상태가 리셋되었습니다.\n이제 새로운 구매를 시도할 수 있습니다.',
        );
      }
    } catch (e) {
      logger.e('❌ [DEBUG] 강제 상태 리셋 실패: $e');

      if (mounted) {
        showSimpleDialog(
          content: '강제 리셋 중 오류가 발생했습니다: $e',
          type: DialogType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView(
        children: [
          if (isSupabaseLoggedSafely) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  _rotationController.forward(from: 0);
                  ref.read(userInfoProvider.notifier).getUserProfiles();
                },
                child: RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _rotationController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: SvgPicture.asset(
                    package: 'picnic_lib',
                    'assets/icons/reset_style=line.svg',
                    width: 24,
                    height: 24,
                    colorFilter:
                        ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 🐛 디버그 모드에서만 구매복원 버튼 표시
            if (kDebugMode)
              GestureDetector(
                onTap: _handleRestorePurchases,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary500.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restore,
                        size: 16,
                        color: AppColors.primary500,
                      ),
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
              ),
            // ⭐ 디버그용 상태 리셋 버튼 추가 (디버그 모드에서만 표시)
            if (kDebugMode) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _handleForceReset,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 16,
                        color: Colors.red,
                      ),
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
              ),
            ],
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
          Text(t('text_purchase_vat_included'),
              style: getTextStyle(AppTypo.caption12M, AppColors.grey600)),
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
          const SizedBox(height: 36),
        ],
      ),
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
      leading: Container(
        width: 48.w,
        height: 48,
        color: Colors.white,
      ),
      title: Container(
        height: 16,
        color: Colors.white,
      ),
      subtitle: Container(
        height: 16,
        color: Colors.white,
      ),
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
    // 🔄 초기화 중이거나 구매 진행 중일 때 버튼 비활성화
    final isButtonEnabled = !_isInitializing && !_isPurchasing;

    String buttonText;
    if (_isInitializing) {
      buttonText = '초기화 중...';
    } else if (_isPurchasing) {
      buttonText = '구매 진행 중...';
    } else {
      buttonText = '${serverProduct['price']} \$';
    }

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
      buttonText: buttonText,
      buttonOnPressed: isButtonEnabled
          ? () => _handleBuyButtonPressed(context, serverProduct, storeProducts)
          : null, // 버튼 비활성화
    );
  }
}
