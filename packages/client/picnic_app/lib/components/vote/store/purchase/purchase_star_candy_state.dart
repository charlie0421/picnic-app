import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/purchase/analytics_service.dart';
import 'package:picnic_app/components/vote/store/purchase/in_app_purchase_service.dart';
import 'package:picnic_app/components/vote/store/purchase/purchase_star_candy.dart';
import 'package:picnic_app/components/vote/store/purchase/receipt_verification_service.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/components/vote/store/usagePolicyDialog.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/product_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy> {
  final InAppPurchaseService _inAppPurchaseService = InAppPurchaseService();
  final ReceiptVerificationService _receiptVerificationService =
      ReceiptVerificationService();
  final AnalyticsService _analyticsService = AnalyticsService();

  List<ProductDetails> _storeProducts = [];

  @override
  void initState() {
    super.initState();
    _inAppPurchaseService.init(_handlePurchaseUpdated);
  }

  @override
  void dispose() {
    _inAppPurchaseService.dispose();
    super.dispose();
  }

  Future<void> _handlePurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    try {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          // Handle pending status
          break;
        case PurchaseStatus.error:
          await _handlePurchaseError(purchaseDetails);
          OverlayLoadingProgress.stop();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchaseDetails);
          OverlayLoadingProgress.stop();
          break;
        case PurchaseStatus.canceled:
          await _handleCanceledPurchase();
          OverlayLoadingProgress.stop();
          break;
        default:
          // Handle other statuses
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchaseService.completePurchase(purchaseDetails);
      }
    } catch (e, s) {
      logger.e('Error handling purchase: $e', stackTrace: s);
      if (mounted) {
        await _showErrorDialog(S.of(context).dialog_message_purchase_failed);
      }
    } finally {
      // OverlayLoadingProgress.stop();
    }
  }

  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    logger.e('Purchase error: ${purchaseDetails.error!.message}');
    await _showErrorDialog(S.of(context).dialog_message_purchase_failed);
  }

  Future<void> _handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails) async {
    try {
      await _receiptVerificationService.verifyReceipt(
        purchaseDetails.verificationData.serverVerificationData,
        purchaseDetails.productID,
        supabase.auth.currentUser!.id,
        await _receiptVerificationService.getEnvironment(),
      );

      // AnalyticsService 연동 추가
      final productDetails = _storeProducts.firstWhere(
        (product) => product.id == purchaseDetails.productID,
        orElse: () => throw Exception('Product not found'),
      );
      await _analyticsService.logPurchaseEvent(productDetails);

      await ref.read(userInfoProvider.notifier).getUserProfiles();
      if (mounted) {
        await _showSuccessDialog();
      }
    } catch (e) {
      logger.e('Error in handleSuccessfulPurchase: $e');
      if (mounted) {
        await _showErrorDialog(S.of(context).dialog_message_purchase_failed);
      }
    }
  }

  Future<void> _handleCanceledPurchase() async {
    await _showErrorDialog(S.of(context).dialog_message_purchase_canceled);
  }

  Future<void> _handleBuyButtonPressed(
      BuildContext context,
      Map<String, dynamic> serverProduct,
      List<ProductDetails> storeProducts) async {
    OverlayLoadingProgress.start(context,
        barrierDismissible: false, color: AppColors.Primary500);

    if (!supabase.isLogged) {
      showRequireLoginDialog(context: context);
    }
    try {
      final productDetails = storeProducts.firstWhere(
        (element) => Platform.isAndroid
            ? element.id.toUpperCase() == serverProduct['id']
            : element.id == serverProduct['id'],
        orElse: () => throw Exception('Product not found in store products'),
      );

      await _inAppPurchaseService.buyConsumable(productDetails);
    } catch (e) {
      logger.e('Error during buy button press: $e');
      if (mounted) {
        await _showErrorDialog(S.of(context).dialog_message_purchase_failed);
      }
    } finally {}
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    final context = this.context;
    showSimpleDialog(context: context, content: message);
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) return;
    final context = this.context;
    showSimpleDialog(
        context: context,
        content: S.of(context).dialog_message_purchase_success);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView(
        children: [
          if (supabase.isLogged) ...[
            SizedBox(height: 36),
            StorePointInfo(
              title: S.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 70,
            ),
          ],
          SizedBox(height: 36),
          _buildProductsList(),
          const Divider(color: AppColors.Grey200, height: 32),
          Text(S.of(context).text_purchase_vat_included,
              style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          SizedBox(height: 2),
          GestureDetector(
            onTap: () => showUsagePolicyDialog(context, ref),
            child: Text(S.of(context).candy_usage_policy_guide,
                style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          ),
          SizedBox(height: 36),
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
          Text('Error loading server products: $error'),
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
            const Divider(color: AppColors.Grey200, height: 32),
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
    _storeProducts = storeProducts; // 여기에 추가
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) =>
          _buildProductItem(serverProducts[index], storeProducts),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(color: AppColors.Grey200, height: 32),
      itemCount: storeProducts.length,
    );
  }

  Widget _buildProductItem(
      Map<String, dynamic> serverProduct, List<ProductDetails> storeProducts) {
    return StoreListTile(
      icon: Image.asset(
        'assets/icons/store/star_${serverProduct['id'].replaceAll('STAR', '')}.png',
        width: 48.w,
        height: 48,
      ),
      title: Text(serverProduct['id'],
          style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: getLocaleTextFromJson(serverProduct['description']),
              style: getTextStyle(AppTypo.CAPTION12B, AppColors.Point900),
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
