import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/analytics_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/in_app_purchase_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/receipt_verification_service.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/i18n.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy> {
  late final PurchaseService _purchaseService;

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
  }

  @override
  void dispose() {
    _purchaseService.inAppPurchaseService.dispose();
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
              await ref.read(userInfoProvider.notifier).getUserProfiles();
              if (mounted) {
                OverlayLoadingProgress.stop();
                await _showSuccessDialog();
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
              await _showErrorDialog(
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

  Future<void> _handleBuyButtonPressed(
    BuildContext context,
    Map<String, dynamic> serverProduct,
    List<ProductDetails> storeProducts,
  ) async {
    if (!supabase.isLogged) {
      showRequireLoginDialog();
      return;
    }

    try {
      // 이전 구매 상태 초기화
      await _purchaseService.inAppPurchaseService.clearTransactions();

      OverlayLoadingProgress.start(
        context,
        barrierDismissible: false,
        color: AppColors.primary500,
      );

      final purchaseInitiated = await _purchaseService.initiatePurchase(
        serverProduct['id'],
        onSuccess: () async {
          await _showSuccessDialog();
        },
        onError: (message) async {
          await _showErrorDialog(message);
        },
      );

      if (!purchaseInitiated) {
        if (mounted) {
          OverlayLoadingProgress.stop();
          await _showErrorDialog(
              Intl.message('dialog_message_purchase_failed'));
        }
      }
    } catch (e, s) {
      logger.e('Error starting purchase', error: e, stackTrace: s);
      if (mounted) {
        OverlayLoadingProgress.stop();
        await _showErrorDialog(Intl.message('dialog_message_purchase_failed'));
      }
      rethrow;
    }
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    showSimpleDialog(type: DialogType.error, content: message);
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) return;
    showSimpleDialog(content: Intl.message('dialog_message_purchase_success'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.cw),
      child: ListView(
        children: [
          if (supabase.isLogged) ...[
            const SizedBox(height: 36),
            StorePointInfo(
              title: Intl.message('label_star_candy_pouch'),
              width: double.infinity,
              height: 90,
            ),
          ],
          const SizedBox(height: 36),
          _buildProductsList(),
          const Divider(color: AppColors.grey200, height: 32),
          Text(Intl.message('text_purchase_vat_included'),
              style: getTextStyle(AppTypo.caption12M, AppColors.grey600)),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () => showUsagePolicyDialog(context, ref),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: Intl.message('candy_usage_policy_guide'),
                    style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: Intl.message('candy_usage_policy_guide_button'),
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
        width: 48.cw,
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
          const Divider(color: AppColors.grey200, height: 32),
      itemCount: storeProducts.length,
    );
  }

  Widget _buildProductItem(
      Map<String, dynamic> serverProduct, List<ProductDetails> storeProducts) {
    return StoreListTile(
      icon: Image.asset(
        package: 'picnic_lib',
        'assets/icons/store/star_${serverProduct['id'].replaceAll('STAR', '')}.png',
        width: 48.cw,
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
      buttonText: '${serverProduct['price']} \$',
      buttonOnPressed: () =>
          _handleBuyButtonPressed(context, serverProduct, storeProducts),
    );
  }
}
