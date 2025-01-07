import 'dart:async';
import 'dart:ui';

import 'package:bubble_box/bubble_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/common/underlined_widget.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_error.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_info.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/fortune_divider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/in_app_purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/receipt_verification_service.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/providers/community/compatibility_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/i18n.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';

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
  final styleController = ExpansionTileController();
  final activityController = ExpansionTileController();
  final tipController = ExpansionTileController();
  late final PurchaseService _purchaseService;
  bool _isSaving = false;
  bool _isSharing = false;
  final ScrollController _scrollController =
      ScrollController(); // Add ScrollController

  @override
  void initState() {
    super.initState();
    _purchaseService = PurchaseService(
      ref: ref,
      inAppPurchaseService: InAppPurchaseService(),
      receiptVerificationService: ReceiptVerificationService(),
      analyticsService: AnalyticsService(),
      onPurchaseUpdate: _handlePurchaseUpdated,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the ScrollController
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

        // 구매 상태가 청구 가능일 때 영수증 검증 및 처리 진행
        if (purchaseDetails.status == PurchaseStatus.purchased) {
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
                await _showErrorDialog(
                    Intl.message('dialog_message_purchase_failed'));
              }
            },
          );
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          if (mounted) {
            OverlayLoadingProgress.stop();
            // 취소가 아닌 실제 오류일 때만 에러 다이얼로그 표시
            if (purchaseDetails.error?.message
                    .toLowerCase()
                    .contains('canceled') !=
                true) {
              await _showErrorDialog(purchaseDetails.error?.message ??
                  Intl.message('dialog_message_purchase_failed'));
            }
          }
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          // 구매 취소 시 구매 정보 정리하고 로딩바만 숨김
          if (mounted) {
            await _purchaseService.inAppPurchaseService
                .completePurchase(purchaseDetails);
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
        OverlayLoadingProgress.stop();
        await _showErrorDialog(Intl.message('dialog_message_purchase_failed'));
      }
      rethrow;
    }
  }

  Future<bool> _buyProduct(Map<String, dynamic> product) async {
    try {
      // 이전 구매 상태 초기화
      await _purchaseService.inAppPurchaseService.clearTransactions();

      // 구매 시작 시 로딩바 표시
      if (mounted) {
        OverlayLoadingProgress.start(
          context,
          barrierDismissible: false,
          color: AppColors.primary500,
        );
      }

      final purchaseInitiated = await _purchaseService.initiatePurchase(
        product['id'],
        onSuccess: () {
          // 성공 콜백에서는 로딩바를 숨기지 않음 (_handlePurchaseUpdated에서 처리)
          _openCompatibility(widget.compatibility.id);
        },
        onError: (message) {
          // 에러 콜백에서는 로딩바를 숨기지 않음 (_handlePurchaseUpdated에서 처리)
          _showErrorDialog(message);
        },
      );

      // 구매 시도 자체가 실패한 경우에만 여기서 로딩바 숨김
      if (!purchaseInitiated && mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(Intl.message('dialog_message_purchase_failed'));
      }

      return purchaseInitiated;
    } catch (e, s) {
      logger.e('Error buying product', error: e, stackTrace: s);
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(Intl.message('message_error_occurred'));
      }
      return false;
    }
  }

  Future<void> _showErrorDialog(String message) async {
    showSimpleDialog(content: message);
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
    } catch (e, stack) {
      logger.e('Error refreshing compatibility data',
          error: e, stackTrace: stack);
    }
  }

  void _updateNavigation() {
    Future(() {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            topRightMenu: TopRightType.board,
            showBottomNavigation: false,
            pageTitle: Intl.message('compatibility_page_title'),
          );
    });
  }

  Widget _buildStyleItem(BuildContext context, String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(LocalizedCompatibility? localizedResult) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      constraints: const BoxConstraints(maxHeight: 72),
      child: Stack(
        children: [
          if (localizedResult != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              constraints: const BoxConstraints(minHeight: 60),
              child: Center(
                child: Text(
                  localizedResult.compatibilitySummary,
                  style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            top: 10,
            left: 0,
            child: SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/fortune/quote_open.svg',
              width: 20,
              colorFilter: ColorFilter.mode(AppColors.grey00, BlendMode.srcIn),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 0,
            child: SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/fortune/quote_close.svg',
              width: 20,
              colorFilter: ColorFilter.mode(AppColors.grey00, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(String compatibilityId) {
    final compatibility = ref.read(compatibilityProvider).value;
    String language = getLocaleLanguage();
    if (compatibility?.localizedResults?.isEmpty ?? true) {
      return Center(
        child: Text(
          S.of(context).compatibility_result_not_found,
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    final localizedResult = compatibility?.getLocalizedResult(language) ??
        compatibility?.localizedResults?.values.firstOrNull;

    if (localizedResult == null) {
      return Center(
        child: Text(
          S.of(context).compatibility_result_not_found,
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    final style = localizedResult.details?.style;
    final activities = localizedResult.details?.activities;
    final tips = localizedResult.tips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!(compatibility?.isPaid ?? false))
          Stack(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    if (style != null) _buildStyleSection(style),
                    SizedBox(height: 36),
                    if (activities != null) _buildActivitiesSection(activities),
                    SizedBox(height: 36),
                    if (tips.isNotEmpty) _buildTipsSection(tips),
                    if (!_isSaving)
                      ShareSection(
                        saveButtonText: S.of(context).save,
                        shareButtonText: S.of(context).share,
                        onSave: () => _handleSave(compatibility!),
                        onShare: () => _handleShare(compatibility!),
                      ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(height: 32),
                            BubbleBox(
                                backgroundColor: AppColors.grey00,
                                elevation: 2,
                                shape: BubbleShapeBorder(
                                  border: BubbleBoxBorder(
                                    color: AppColors.grey300,
                                    width: 1.5,
                                    style: BubbleBoxBorderStyle.solid,
                                  ),
                                  radius: const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  position: const BubblePosition.center(0),
                                  direction: BubbleDirection.bottom,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      package: 'picnic_lib',
                                      'assets/icons/store/star_100.png',
                                      width: 36,
                                    ),
                                    Text(
                                      '100',
                                      style: getTextStyle(
                                        AppTypo.body16B,
                                        AppColors.grey900,
                                      ),
                                    ),
                                  ],
                                )),
                            SizedBox(height: 8),
                            Container(
                              constraints: BoxConstraints(
                                minWidth: 240,
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  OverlayLoadingProgress.start(context);
                                  _openCompatibility(compatibilityId);
                                  OverlayLoadingProgress.stop();
                                },
                                child: Text(S
                                    .of(context)
                                    .fortune_purchase_by_star_candy),
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              constraints: BoxConstraints(
                                minWidth: 240,
                              ),
                              child: ElevatedButton(
                                style: ButtonStyle(
                                    padding: WidgetStateProperty.all(
                                        EdgeInsets.symmetric(
                                            horizontal: 32.cw, vertical: 0)),
                                    backgroundColor: WidgetStateProperty.all(
                                        AppColors.secondary500),
                                    foregroundColor: WidgetStateProperty.all(
                                        AppColors.grey900),
                                    shape: WidgetStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                            color: AppColors.primary500,
                                            width: 1,
                                            style: BorderStyle.solid),
                                      ),
                                    ),
                                    textStyle: WidgetStateProperty.all(
                                      getTextStyle(
                                        AppTypo.caption12B,
                                        AppColors.grey00,
                                      ),
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap),
                                onPressed: () async {
                                  if (!mounted) return;

                                  try {
                                    OverlayLoadingProgress.start(context);

                                    final productDetail = ref
                                        .read(serverProductsProvider.notifier)
                                        .getProductDetailById('STAR100');

                                    if (productDetail == null) {
                                      throw Exception('상품 정보를 찾을 수 없습니다.');
                                    }

                                    logger.i('Buy product: $productDetail');

                                    // 구매 시도
                                    final purchaseInitiated =
                                        await _buyProduct(productDetail);

                                    // 구매 시도 실패시에만 에러 다이얼로그 표시하고 로딩바 숨김
                                    if (!purchaseInitiated) {
                                      if (!mounted) return;
                                      await _showErrorDialog(
                                          '구매를 시작할 수 없습니다. 잠시 후 다시 시도해 주세요.');
                                      OverlayLoadingProgress.stop();
                                    }
                                    // 구매 시도 성공시에는 로딩바 유지 (실제 구매 완료/실패시 _handlePurchaseUpdated에서 로딩바 숨김)
                                  } catch (e, s) {
                                    logger.e('Error starting purchase',
                                        error: e, stackTrace: s);
                                    if (!mounted) return;
                                    await _showErrorDialog('구매 중 오류가 발생했습니다.');
                                    OverlayLoadingProgress.stop();
                                    rethrow;
                                  }
                                },
                                child: Text(
                                    S.of(context).fortune_purchase_by_one_click,
                                    style: TextStyle(color: AppColors.grey900)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        else ...[
          if (style != null) _buildStyleSection(style),
          SizedBox(height: 36),
          if (activities != null) _buildActivitiesSection(activities),
          SizedBox(height: 36),
          if (tips.isNotEmpty) _buildTipsSection(tips),
          if (!_isSaving)
            ShareSection(
              saveButtonText: S.of(context).save,
              shareButtonText: S.of(context).share,
              onSave: () => _handleSave(compatibility!),
              onShare: () => _handleShare(compatibility!),
            ),
          SizedBox(height: 16),
        ],
      ],
    );
  }

  void _openCompatibility(String compatibilityId) async {
    try {
      // 호환성 결과 열기 전에 로딩바 표시
      if (mounted) {
        OverlayLoadingProgress.start(
          context,
          barrierDismissible: false,
          color: AppColors.primary500,
        );
      }

      final userProfile =
          await ref.read(userInfoProvider.notifier).getUserProfiles();

      if (userProfile == null) {
        if (mounted) {
          OverlayLoadingProgress.stop();
          showSimpleDialog(
            content: Intl.message('message_error_occurred'),
            onOk: () {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCurrentPage(StorePage());
              Navigator.of(context).pop();
            },
          );
        }
        return;
      }

      if ((userProfile.starCandy ?? 0) < 100) {
        if (mounted) {
          OverlayLoadingProgress.stop();
          showSimpleDialog(
            title: Intl.message('fortune_lack_of_star_candy_title'),
            content: Intl.message('fortune_lack_of_star_candy_message'),
            onOk: () {
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCurrentPage(StorePage());
              Navigator.of(context).pop();
            },
          );
        }
        return;
      }

      await supabase.functions.invoke('open-compatibility', body: {
        'userId': userProfile.id,
        'compatibilityId': compatibilityId,
      });

      final updatedProfile =
          await ref.read(userInfoProvider.notifier).getUserProfiles();
      if (updatedProfile == null) {
        throw Exception('Failed to get updated user profile');
      }

      await _refreshData();

      if (mounted) {
        OverlayLoadingProgress.stop();
        showSimpleDialog(
          contentWidget: Column(
            children: [
              Text(Intl.message('compatibility_remain_star_candy')),
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
      }
    } catch (e, s) {
      logger.e('Error opening compatibility', error: e, stackTrace: s);
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(Intl.message('message_error_occurred'));
      }
      rethrow;
    }
  }

  Widget _buildStyleSection(StyleDetails style) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        controller: styleController,
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: SizedBox(
          height: 28,
          child: Row(
            children: [
              UnderlinedWidget(
                underlineGap: 2,
                child: SvgPicture.asset(
                  package: 'picnic_lib',
                  'assets/images/fortune/fortune_style.svg',
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    AppColors.primary500,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              UnderlinedText(
                text: ' ${S.of(context).compatibility_style_title}',
                textStyle: getTextStyle(AppTypo.body16B, AppColors.grey900),
                underlineGap: 1.5,
              ),
            ],
          ),
        ),
        children: [
          InkWell(
            onTap: () => styleController.collapse(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStyleItem(
                    context,
                    S.of(context).compatibility_idol_style,
                    style.idolStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildStyleItem(
                    context,
                    S.of(context).compatibility_user_style,
                    style.userStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildStyleItem(
                    context,
                    S.of(context).compatibility_couple_style,
                    style.coupleStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(ActivitiesDetails activities) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        controller: activityController,
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            UnderlinedWidget(
              underlineGap: 2,
              child: SvgPicture.asset(
                package: 'picnic_lib',
                'assets/images/fortune/fortune_activities.svg',
                width: 24,
                colorFilter: ColorFilter.mode(
                  AppColors.primary500,
                  BlendMode.srcIn,
                ),
              ),
            ),
            UnderlinedText(
              text: ' ${S.of(context).compatibility_activities_title}',
              textStyle: getTextStyle(AppTypo.body16B, AppColors.grey900),
              underlineGap: 1.5,
            ),
          ],
        ),
        children: [
          InkWell(
            onTap: () => activityController.collapse(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.recommended.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      return Text('✔️ ${activities.recommended[index]}',
                          style: getTextStyle(
                            AppTypo.caption12B,
                            AppColors.grey900,
                          ));
                    },
                  ),
                  Text(
                    activities.description.trim(),
                    style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTipsSection(List<String> tips) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        controller: tipController,
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            UnderlinedWidget(
              underlineGap: 2,
              child: SvgPicture.asset(
                package: 'picnic_lib',
                'assets/images/fortune/fortune_tips.svg',
                width: 24,
                colorFilter: ColorFilter.mode(
                  AppColors.primary500,
                  BlendMode.srcIn,
                ),
              ),
            ),
            UnderlinedText(
              text: ' ${S.of(context).compatibility_tips_title}',
              textStyle: getTextStyle(AppTypo.body16B, AppColors.grey900),
              underlineGap: 1.5,
            ),
          ],
        ),
        children: [
          InkWell(
            onTap: () => tipController.collapse(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tips.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Text('✔️ ${tips[index]}',
                          style: getTextStyle(
                            AppTypo.caption12B,
                            AppColors.grey900,
                          ));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final compatibilityState = ref.watch(compatibilityProvider);

      return compatibilityState.when(
        data: (compatibility) {
          if (compatibility == null) {
            return const Center(child: CircularProgressIndicator());
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
                                SizedBox(
                                  height: 20,
                                  child: SvgPicture.asset(
                                    package: 'picnic_lib',
                                    'assets/images/fortune/picnic_logo.svg',
                                    width: 78,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 36),
                                CompatibilityInfo(
                                  artist: compatibility.artist,
                                  ref: ref,
                                  birthDate: compatibility.birthDate,
                                  birthTime: compatibility.birthTime,
                                  compatibility: compatibility,
                                  gender: compatibility.gender,
                                ),
                                SizedBox(height: 24),
                                _buildHeaderSection(compatibility
                                    .getLocalizedResult(getLocaleLanguage())),
                                SizedBox(height: 36),
                              ],
                            ),
                          ),
                        ),
                        FortuneDivider(color: AppColors.grey00),
                        SizedBox(height: 36),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              if (compatibility.hasError)
                                CompatibilityErrorView(
                                  error: compatibility.errorMessage ??
                                      S.of(context).error_unknown,
                                )
                              else if (compatibility.isCompleted)
                                _buildResultContent(compatibility.id)
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
        loading: () => const Center(child: CircularProgressIndicator()),
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

  Future<Future<bool>> _handleSave(CompatibilityModel compatibility) async {
    return ShareUtils.saveImage(
      _saveKey,
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
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      },
    );
  }

  Future<Future<bool>> _handleShare(CompatibilityModel compatibility) async {
    logger.i('Share to Twitter');
    return ShareUtils.shareToSocial(
      _shareKey,
      message: Intl.message('compatibility_share_message',
          args: [getLocaleTextFromJson(compatibility.artist.name)]),
      hashtag: S.of(context).compatibility_share_hashtag,
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
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      },
    );
  }
}
