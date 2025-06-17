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
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy>
    with SingleTickerProviderStateMixin {
  late final PurchaseService _purchaseService;
  late final AnimationController _rotationController;
  String? _pendingProductId; // 복원 구매 후 재시도할 상품 ID
  bool _purchaseInProgress = false;

  // 🔄 Transaction clear 이후 플래그
  bool _transactionsCleared = false;

  // 실제 구매 진행 중 플래그
  bool _isActivePurchasing = false;

  // 초기화 중 로딩 상태
  bool _isInitializing = true;

  bool _isPurchasing = false;
  DateTime? _lastPurchaseAttempt;
  static const Duration _purchaseCooldown = Duration(seconds: 2);

  // 테스트 환경 다이얼로그 표시 상태 추적
  static const String _testDialogShownKey = 'test_environment_dialog_shown';
  bool _testDialogAlreadyShown = false;

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
    _loadTestDialogState(); // 다이얼로그 표시 상태 로드
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

  Future<void> _onPurchaseUpdate(
      List<PurchaseDetails> purchaseDetailsList) async {
    logger.d(
        'Purchase update received: ${purchaseDetailsList.length} transactions');
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

        // 초기화 기간 중의 restored 구매 처리
        if (!_isActivePurchasing && !_transactionsCleared) {
          if (purchaseDetails.status == PurchaseStatus.restored) {
            logger.i(
                '🔄 [INIT] Restored purchase detected during initialization: ${purchaseDetails.productID}');
            logger.i('   → Processing silently without popup or verification');

            // 초기화 시 복원된 구매는 완전히 조용히 처리
            try {
              await _purchaseService.inAppPurchaseService
                  .completePurchase(purchaseDetails);
              logger.i('✅ [INIT] Restored purchase completed silently');
            } catch (e) {
              logger.w('⚠️ [INIT] Error completing restored purchase: $e');
            }
            continue;
          }

          // 초기화 기간 중 예상치 못한 purchased 상태는 로그만 남기고 무시
          if (purchaseDetails.status == PurchaseStatus.purchased) {
            logger.w(
                '⚠️ [INIT] Unexpected purchased status during initialization: ${purchaseDetails.productID}');
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
                  _isActivePurchasing = false;
                  _pendingProductId = null;
                  OverlayLoadingProgress.stop();
                  logger.i('🎉 성공 다이얼로그 표시');
                  await _showSuccessDialog();
                }
              },
              (error) async {
                logger.e('❌ 구매 오류: $error');

                if (mounted) {
                  _isActivePurchasing = false;
                  _pendingProductId = null;
                  OverlayLoadingProgress.stop();

                  // 이미 처리된 구매인지 확인
                  if (error.contains('이미 처리된 구매')) {
                    logger.i('🔄 이미 처리된 구매 - 사용자에게 안내');

                    // Apple 테스트 환경에서는 앱 재시작 권장 (한 번만)
                    final isTestEnv = await _isTestEnvironment();
                    if (isTestEnv && !_testDialogAlreadyShown) {
                      await _showTestEnvironmentRestartDialog();
                      await _saveTestDialogState(); // 표시 상태 저장
                    } else {
                      // 이미 다이얼로그를 본 경우 또는 프로덕션 환경
                      if (isTestEnv && _testDialogAlreadyShown) {
                        await _showErrorDialog(
                            '$error\n\n💡 앱을 재시작하면 새로운 구매가 가능합니다.');
                      } else {
                        await _showErrorDialog('$error\n새로운 구매를 시도해주세요.');
                      }
                    }
                  } else {
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
            _isActivePurchasing = false;
            _pendingProductId = null;
            OverlayLoadingProgress.stop();

            // 취소가 아닌 실제 오류일 때만 에러 다이얼로그 표시
            if (purchaseDetails.error?.message
                    ?.toLowerCase()
                    .contains('canceled') !=
                true) {
              await _showErrorDialog(t('dialog_message_purchase_failed'));
            }
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          logger.i('❌ Purchase canceled: ${purchaseDetails.productID}');
          if (mounted) {
            _isActivePurchasing = false;
            _pendingProductId = null;
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
        _isActivePurchasing = false;
        _pendingProductId = null;
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

      // ⭐ 이전 구매 상태 즉시 초기화 (JWT 재사용 방지)
      logger.i('🔥 Clearing all previous purchase states...');
      await _purchaseService.inAppPurchaseService.clearTransactions();

      // ⭐ Apple StoreKit 복원 처리로 이전 구매 정리
      logger.i('🍎 Apple StoreKit 복원으로 이전 구매 정리...');
      try {
        await _purchaseService.inAppPurchaseService.restorePurchases();
        await Future.delayed(Duration(seconds: 2));
        logger.i('✅ Apple StoreKit 복원 완료 - 이전 구매 상태 정리됨');
      } catch (e) {
        logger.w('⚠️ Apple StoreKit 복원 중 일부 오류 (계속 진행): $e');
      }

      // ⭐ 더욱 강력한 캐시 무효화 (5초 대기 + 다중 클리어)
      logger.i('⏳ Performing aggressive cache invalidation...');
      await Future.delayed(Duration(seconds: 2));

      // 🔄 추가 캐시 클리어 라운드
      await _purchaseService.inAppPurchaseService.refreshStoreKitCache();
      await Future.delayed(Duration(seconds: 1));

      // 🔄 최종 캐시 클리어
      await _purchaseService.inAppPurchaseService.clearTransactions();
      await Future.delayed(Duration(seconds: 2));

      logger
          .i('✅ Aggressive cache invalidation completed - JWT should be fresh');

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
          _isActivePurchasing = false;
          _pendingProductId = null;
          // 🔄 구매 상태 리셋
          setState(() {
            _isPurchasing = false;
          });
          if (mounted) {
            OverlayLoadingProgress.stop();
            await _showErrorDialog(message);
          }
        },
      );

      if (!purchaseInitiated) {
        _isActivePurchasing = false;
        _pendingProductId = null;
        // 🔄 구매 상태 리셋
        setState(() {
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
            _isActivePurchasing = false;
            _pendingProductId = null;
            // 🔄 구매 상태 리셋
            setState(() {
              _isPurchasing = false;
            });
            OverlayLoadingProgress.stop();
            _showErrorDialog('구매 시간이 초과되었습니다. 다시 시도해주세요.');
          }
        });
      }
    } catch (e, s) {
      logger.e('Error starting purchase', error: e, stackTrace: s);
      _isActivePurchasing = false;
      _pendingProductId = null;
      // 🔄 구매 상태 리셋
      setState(() {
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

  /// Apple 테스트 환경인지 확인
  Future<bool> _isTestEnvironment() async {
    try {
      final envInfo = await _purchaseService.receiptVerificationService
          .getEnvironmentInfo();
      final environment = envInfo['environment'];
      final isDebugMode = envInfo['isDebugMode'];
      final installerStore = envInfo['installerStore'];

      // Sandbox 환경이거나 TestFlight 환경이면 테스트 환경으로 판단
      return environment == 'sandbox' ||
          isDebugMode == true ||
          installerStore == 'com.apple.testflight';
    } catch (e) {
      logger.w('⚠️ 환경 정보 확인 실패: $e');
      return false; // 기본값으로 프로덕션 환경으로 가정
    }
  }

  /// Apple 테스트 환경에서 앱 재시작을 권장하는 다이얼로그
  Future<void> _showTestEnvironmentRestartDialog() async {
    if (!mounted) return;

    final shouldRestart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🍎 Apple 테스트 환경 감지'),
        content: Text('''Apple 테스트 환경에서는 구매 영수증이 재사용될 수 있습니다.

새로운 구매를 시도하려면:
1. 앱을 완전히 종료 후 재시작
2. 또는 기다리신 후 다시 시도

앱을 지금 종료하시겠습니까?'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('나중에'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('앱 종료'),
          ),
        ],
      ),
    );

    if (shouldRestart == true) {
      logger.i('🔄 사용자 요청으로 앱 종료 중...');
      // iOS에서는 exit(0)를 사용하지 않는 것이 권장되므로
      // 백그라운드로 이동하는 방식 사용
      if (Platform.isIOS) {
        // iOS에서는 앱을 백그라운드로 보냄
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('앱 종료'),
            content: Text('홈 버튼을 눌러 앱을 종료한 후\n앱 스위처에서 앱을 완전히 종료해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('확인'),
              ),
            ],
          ),
        );
      } else {
        // Android에서는 앱 종료
        exit(0);
      }
    }
  }

  /// 테스트 다이얼로그 표시 상태 로드
  Future<void> _loadTestDialogState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _testDialogAlreadyShown = prefs.getBool(_testDialogShownKey) ?? false;
    } catch (e) {
      logger.w('⚠️ 테스트 다이얼로그 상태 로드 실패: $e');
    }
  }

  /// 테스트 다이얼로그 표시 상태 저장
  Future<void> _saveTestDialogState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_testDialogShownKey, true);
      _testDialogAlreadyShown = true;
    } catch (e) {
      logger.w('⚠️ 테스트 다이얼로그 상태 저장 실패: $e');
    }
  }

  /// 테스트 다이얼로그 상태 리셋 (개발자용)
  Future<void> _resetTestDialogState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_testDialogShownKey);
      _testDialogAlreadyShown = false;
      logger.i('🔄 테스트 다이얼로그 상태 리셋됨');
    } catch (e) {
      logger.w('⚠️ 테스트 다이얼로그 상태 리셋 실패: $e');
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
    final isButtonEnabled = !_isInitializing;

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
      buttonText: _isInitializing ? '초기화 중...' : '${serverProduct['price']} \$',
      buttonOnPressed: isButtonEnabled
          ? () => _handleBuyButtonPressed(context, serverProduct, storeProducts)
          : null, // 버튼 비활성화
    );
  }
}
