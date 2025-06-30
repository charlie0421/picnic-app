import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_result_content.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/providers/community/compatibility_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_card.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_error.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_logo_widget.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_score_widget.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_summary_widget.dart';
// ignore: unused_import
import 'package:picnic_lib/presentation/widgets/community/compatibility/fortune_divider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

class CompatibilityResultPage extends ConsumerStatefulWidget {
  const CompatibilityResultPage({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel compatibility;

  @override
  ConsumerState<CompatibilityResultPage> createState() =>
      _CompatibilityResultPageState();
}

class _CompatibilityResultPageState
    extends ConsumerState<CompatibilityResultPage> {
  final GlobalKey _saveKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  final styleController = ExpansibleController();
  final activityController = ExpansibleController();
  final tipController = ExpansibleController();
  late final PurchaseService _purchaseService;
  bool _isSaving = false;
  bool _isSharing = false;
  final ScrollController _scrollController =
      ScrollController(); // Add ScrollController
  static const _animationDuration = Duration(milliseconds: 300);
  static const _scrollCurve = Curves.easeOut;

  // 🔧 연타 방지만 - 단순화
  DateTime? _lastPurchaseTime;
  static const Duration _purchaseCooldown = Duration(milliseconds: 300);

  // 🔄 Transaction clear 이후 플래그
  bool _transactionsCleared = false;

  // late final에서 getter로 변경하여 항상 최신 아티스트 정보 사용
  String get _shareMessage {
    final artistName = getLocaleTextFromJson(widget.compatibility.artist.name);
    logger.d('🎯 아티스트 이름: "$artistName"');
    final message =
        t('compatibility_share_message', {'artistName': artistName});
    logger.d('🎯 공유 메시지: "$message"');
    return message;
  }

  @override
  void initState() {
    super.initState();
    logger.d('CompatibilityResultPage initState called');

    _purchaseService = PurchaseService(
      ref: ref,
      inAppPurchaseService: InAppPurchaseService(),
      receiptVerificationService: ReceiptVerificationService(),
      analyticsService: AnalyticsService(),
      duplicatePreventionService: DuplicatePreventionService(ref),
      onPurchaseUpdate: _handlePurchaseUpdated,
    );

    // 🔄 구매 페이지 초기화 시 pending 구매 클리어
    _clearPendingPurchases();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    try {
      for (final purchaseDetails in purchaseDetailsList) {
        logger.d('Purchase updated: ${purchaseDetails.status}');

        // pending 상태일 때는 계속 로딩바 유지
        if (purchaseDetails.status == PurchaseStatus.pending) {
          continue;
        }

        try {
          // 🔄 Transaction clear 이후에는 모든 구매(restored 포함)를 신규 구매로 처리
          if (_transactionsCleared) {
            logger.i(
                '🎯 Transaction clear 이후 구매 감지: ${purchaseDetails.productID} - ${purchaseDetails.status}');
            logger.i('   → 신규 구매로 간주하여 영수증 검증 수행');

            if (purchaseDetails.status == PurchaseStatus.purchased ||
                purchaseDetails.status == PurchaseStatus.restored) {
              // handlePurchase 호출 전 mounted 체크
              if (!mounted) return;

              await _purchaseService.handlePurchase(
                purchaseDetails,
                () async {
                  if (mounted) {
                    OverlayLoadingProgress.stop();
                    _openCompatibility(widget.compatibility.id);
                  }
                },
                (error) async {
                  if (mounted) {
                    OverlayLoadingProgress.stop();
                    await _showErrorDialog(t('dialog_message_purchase_failed'));
                  }
                },
              );

              // handlePurchase 호출 후 mounted 체크
              if (!mounted) return;
            }
          } else {
            // Transaction clear 이전의 구매들은 기존 로직 유지

            // 복원된 구매는 조용히 처리하고 완료
            if (purchaseDetails.status == PurchaseStatus.restored) {
              logger.d('복원된 구매 감지됨. 조용히 완료 처리: ${purchaseDetails.productID}');

              // completePurchase 호출 전 mounted 체크
              if (!mounted) return;

              await _purchaseService.inAppPurchaseService
                  .completePurchase(purchaseDetails);

              // completePurchase 호출 후 mounted 체크
              if (!mounted) return;

              // 복원된 구매는 영수증 검증 없이 조용히 처리
              continue;
            }

            // 신규 구매만 영수증 검증 수행
            if (purchaseDetails.status == PurchaseStatus.purchased) {
              logger.d('신규 구매 감지: ${purchaseDetails.productID} - 영수증 검증 시작');

              // handlePurchase 호출 전 mounted 체크
              if (!mounted) return;

              await _purchaseService.handlePurchase(
                purchaseDetails,
                () async {
                  if (mounted) {
                    OverlayLoadingProgress.stop();
                    _openCompatibility(widget.compatibility.id);
                  }
                },
                (error) async {
                  if (mounted) {
                    OverlayLoadingProgress.stop();
                    await _showErrorDialog(t('dialog_message_purchase_failed'));
                  }
                },
              );

              // handlePurchase 호출 후 mounted 체크
              if (!mounted) return;
            }
          }

          // 공통 에러 및 취소 처리
          if (purchaseDetails.status == PurchaseStatus.error) {
            if (mounted) {
              OverlayLoadingProgress.stop();
              // 취소가 아닌 실제 오류일 때만 에러 다이얼로그 표시
              if (purchaseDetails.error?.message
                      .toLowerCase()
                      .contains('canceled') !=
                  true) {
                await _showErrorDialog(purchaseDetails.error?.message ??
                    t('dialog_message_purchase_failed'));
              }
            }
          } else if (purchaseDetails.status == PurchaseStatus.canceled) {
            // 구매 취소 시 구매 정보 정리하고 로딩바만 숨김
            if (mounted) {
              await _purchaseService.inAppPurchaseService
                  .completePurchase(purchaseDetails);

              // completePurchase 호출 후 mounted 체크
              if (!mounted) return;

              OverlayLoadingProgress.stop();
            }
          }

          // 모든 상태 처리 후 구매 완료 처리
          if (purchaseDetails.pendingCompletePurchase) {
            // pendingCompletePurchase 호출 전 mounted 체크
            if (!mounted) return;

            await _purchaseService.inAppPurchaseService
                .completePurchase(purchaseDetails);

            // pendingCompletePurchase 호출 후 mounted 체크
            if (!mounted) return;
          }
        } finally {
          // 구매 처리 완료
          logger.d('🔄 구매 처리 완료: ${purchaseDetails.productID}');
        }
      }
    } catch (e, s) {
      logger.e('Error handling purchase update', error: e, stackTrace: s);
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(t('dialog_message_purchase_failed'));
      }
      rethrow;
    }
  }

  Future<bool> _buyProduct(Map<String, dynamic> product) async {
    // 연타 방지
    if (_lastPurchaseTime != null) {
      final timeSince = DateTime.now().difference(_lastPurchaseTime!);
      if (timeSince < _purchaseCooldown) {
        return false; // 연타 차단
      }
    }
    _lastPurchaseTime = DateTime.now();

    try {
      // 이전 구매 상태 초기화
      await _purchaseService.inAppPurchaseService.clearTransactions();
      if (!mounted) return false;

      // 구매 시작 시 로딩바 표시
      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

      final purchaseResult = await _purchaseService.initiatePurchase(
        product['id'],
        onSuccess: () {
          if (mounted) {
            _openCompatibility(widget.compatibility.id);
          }
        },
        onError: (message) {
          if (mounted) {
            _showErrorDialog(message);
          }
        },
      );

      if (!mounted) {
        OverlayLoadingProgress.stop();
        return false;
      }

      final success = purchaseResult['success'] as bool;
      final wasCancelled = purchaseResult['wasCancelled'] as bool;
      final errorMessage = purchaseResult['errorMessage'] as String?;

      if (wasCancelled) {
        OverlayLoadingProgress.stop();
        return false;
      } else if (!success) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(
            errorMessage ?? t('dialog_message_purchase_failed'));
        return false;
      }

      return true;
    } catch (e, s) {
      logger.e('Error buying product', error: e, stackTrace: s);
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(t('message_error_occurred'));
      }
      return false;
    }
  }

  Future<void> _showErrorDialog(String message) async {
    showSimpleErrorDialog(context, message);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      await ref
          .read(compatibilityProvider.notifier)
          .loadCompatibility(widget.compatibility.id, forceRefresh: true);

      // 비동기 작업 후 mounted 체크
      if (!mounted) return;

      if (widget.compatibility.isPending) {
        ref.read(compatibilityLoadingProvider.notifier).state = true;
      }

      if (widget.compatibility.isCompleted) {
        await _refreshData();
      }
    } catch (e, stack) {
      logger.e('Error initializing data', error: e, stackTrace: stack);
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    try {
      await ref
          .read(compatibilityProvider.notifier)
          .loadCompatibility(widget.compatibility.id, forceRefresh: true);

      // 비동기 작업 후 mounted 체크
      if (!mounted) return;
    } catch (e, stack) {
      logger.e('Error refreshing compatibility data',
          error: e, stackTrace: stack);
    }
  }

  void _updateNavigation() {
    Future(() {
      // Future 콜백 내에서 mounted 체크
      if (mounted) {
        ref.read(navigationInfoProvider.notifier).settingNavigation(
              showPortal: true,
              showTopMenu: true,
              topRightMenu: TopRightType.board,
              showBottomNavigation: false,
              pageTitle: t('compatibility_page_title'),
            );
      }
    });
  }

  Widget _buildResultContent(CompatibilityModel compatibility) {
    return CompatibilityResultContent(
      compatibility: compatibility,
      isSaving: _isSaving,
      onSave: _handleSave,
      onShare: _handleShare,
      onOpenCompatibility: _openCompatibility,
      onBuyProduct: _buyProduct,
    );
  }

  void _openCompatibility(String compatibilityId) async {
    try {
      // 호환성 결과 열기 전에 로딩바 표시
      if (!mounted) return;

      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

      // 첫 번째 비동기 작업 전 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      final userProfile =
          await ref.read(userInfoProvider.notifier).getUserProfiles();

      // 첫 번째 비동기 작업 후 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      if (userProfile == null) {
        OverlayLoadingProgress.stop();
        showSimpleDialog(
          content: t('message_error_occurred'),
          onOk: () {
            if (mounted) {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCommunityCurrentPage(StorePage());
              Navigator.of(context).pop();
            }
          },
        );
        return;
      }

      if ((userProfile.starCandy ?? 0) < 100) {
        OverlayLoadingProgress.stop();
        showSimpleDialog(
          title: t('fortune_lack_of_star_candy_title'),
          content: t('fortune_lack_of_star_candy_message'),
          onOk: () {
            if (mounted) {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCommunityCurrentPage(StorePage());
              Navigator.of(context).pop();
            }
          },
        );
        return;
      }

      // Supabase 함수 호출 전 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      await supabase.functions.invoke('open-compatibility', body: {
        'userId': userProfile.id,
        'compatibilityId': compatibilityId,
      });

      // Supabase 함수 호출 후 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      final updatedProfile =
          await ref.read(userInfoProvider.notifier).getUserProfiles();

      // 두 번째 getUserProfiles 호출 후 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      if (updatedProfile == null) {
        throw Exception('Failed to get updated user profile');
      }

      await _refreshData();

      // 모든 비동기 작업 완료 후 mounted 체크
      if (!mounted) {
        OverlayLoadingProgress.stop();
        return;
      }

      OverlayLoadingProgress.stop();
      showSimpleDialog(
        contentWidget: Column(
          children: [
            Text(t('compatibility_remain_star_candy')),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                    package: 'picnic_lib',
                    'assets/icons/store/star_100.png',
                    width: 36),
                Text(
                  '${updatedProfile.starCandy}',
                  style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e, s) {
      logger.e('Error opening compatibility', error: e, stackTrace: s);
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(t('message_error_occurred'));
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final compatibilityState = ref.watch(compatibilityProvider);

      return compatibilityState.when(
        data: (compatibility) {
          if (compatibility == null) {
            return _buildLoadingIndicator();
          }

          return CustomScrollView(
            controller: _scrollController, // Add the ScrollController here

            slivers: [
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  key: _saveKey,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary500.withValues(alpha: .7),
                          AppColors.secondary500.withValues(alpha: .7),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        RepaintBoundary(
                          key: _shareKey,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _isSharing
                                  ? LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primary500
                                            .withValues(alpha: .7),
                                        AppColors.secondary500
                                            .withValues(alpha: .7),
                                      ],
                                    )
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(height: 24),
                                CompatibilityLogoWidget(),
                                SizedBox(height: 36),
                                CompatibilityCard(
                                  artist: compatibility.artist,
                                  ref: ref,
                                  birthDate: compatibility.birthDate,
                                  birthTime: compatibility.birthTime,
                                  compatibility: compatibility,
                                  gender: compatibility.gender,
                                ),
                                SizedBox(height: 24),
                                CompatibilitySummaryWidget(
                                    localizedResult:
                                        compatibility.getLocalizedResult(
                                            getLocaleLanguage())),
                                SizedBox(height: 24),
                                CompatibilityScoreWidget(
                                  compatibility: compatibility,
                                ),
                                SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              if (compatibility.hasError)
                                CompatibilityErrorView(
                                  error: compatibility.errorMessage ??
                                      t('error_unknown'),
                                )
                              else if (compatibility.isCompleted)
                                _buildResultContent(compatibility)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => _buildLoadingIndicator(),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: getTextStyle(AppTypo.body14R, AppColors.grey500),
          ),
        ),
      );
    } catch (e, stack) {
      logger.e('Error building compatibility result page',
          error: e, stackTrace: stack);
      return Center(
        child: Text(
          'Error: $e',
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: MediumPulseLoadingIndicator(),
    );
  }

  Future<Future<bool>> _handleSave(CompatibilityModel compatibility) async {
    return ShareUtils.saveImage(
      _saveKey,
      context: context,
      onStart: () {
        setState(() {
          _isSaving = true;
        });
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        styleController.expand();
        activityController.expand();
        tipController.expand();
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() {
          _isSaving = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: _animationDuration,
            curve: _scrollCurve,
          );
        });
      },
    );
  }

  Future<Future<bool>> _handleShare(CompatibilityModel compatibility) async {
    logger.i('Share to Twitter');
    final artistName = getLocaleTextFromJson(compatibility.artist.name);
    final hashtag =
        t('compatibility_share_hashtag', {'artistName': artistName});
    logger.d('🎯 해시태그 - 아티스트 이름: "$artistName", 결과: "$hashtag"');

    return ShareUtils.shareToSocial(
      _shareKey,
      message: _shareMessage,
      hashtag: hashtag,
      downloadLink: await createBranchLink(
          getLocaleTextFromJson(compatibility.artist.name),
          '${Environment.appLinkPrefix}/community/compatibility/${compatibility.artist.id}'),
      onStart: () {
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        setState(() {
          _isSharing = true;
        });
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() {
          _isSharing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: _animationDuration,
            curve: _scrollCurve,
          );
        });
      },
    );
  }

  /// 구매 페이지 시작 시 pending 상태의 구매들을 모두 클리어합니다.
  /// 이후 발생하는 모든 구매는 신규 구매로 간주됩니다.
  Future<void> _clearPendingPurchases() async {
    try {
      logger.i('🧹 구매 페이지 초기화: pending 구매 클리어 시작');
      await _purchaseService.inAppPurchaseService.clearTransactions();
      logger.i('✅ pending 구매 클리어 완료');
      _transactionsCleared = true;
    } catch (e) {
      logger.e('❌ pending 구매 클리어 실패: $e');
    }
  }
}
