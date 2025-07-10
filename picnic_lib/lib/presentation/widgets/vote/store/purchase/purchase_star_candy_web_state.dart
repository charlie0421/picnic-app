import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy_web.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PurchaseStarCandyWebState extends ConsumerState<PurchaseStarCandyWeb> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 50),
      child: ListView(
        children: [
          Stack(
            children: [
              Container(
                height: 150,
                margin: EdgeInsets.only(top: 24, left: 8.w, right: 8.w),
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary500,
                      width: 1.5.r,
                    ),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40.r),
                        topRight: Radius.circular(40.r),
                        bottomLeft: Radius.circular(40.r),
                        bottomRight: Radius.circular(40.r))),
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context).purchase_web_message,
                ),
              ),
              Positioned.fill(
                  child: Container(
                      alignment: Alignment.topCenter,
                      padding: EdgeInsets.symmetric(horizontal: 33.w),
                      child: const VoteCommonTitle(title: '수동 결제'))),
            ],
          ),
          const SizedBox(height: 36),
          _buildProductsList(),
          const Divider(color: AppColors.grey200, height: 32),
          Text(
            AppLocalizations.of(context).text_purchase_vat_included,
            style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final serverProductsAsyncValue = ref.watch(serverProductsProvider);

    return serverProductsAsyncValue.when(
      loading: () => _buildShimmer(),
      error: (error, stackTrace) =>
          buildErrorView(context, error: error, stackTrace: stackTrace),
      data: (serverProducts) => _buildProductList(serverProducts),
    );
  }

  Widget _buildProductList(
    List<Map<String, dynamic>> serverProducts,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) =>
          _buildProductItem(serverProducts[index]),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(color: AppColors.grey200, height: 32),
      itemCount: serverProducts.length,
    );
  }

  Widget _buildProductItem(Map<String, dynamic> serverProduct) {
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
      buttonText: '${serverProduct['price']} \$',
      buttonOnPressed: () => _handleBuyButtonPressed(context, serverProduct),
    );
  }

  Future<void> _handleBuyButtonPressed(
    BuildContext context,
    Map<String, dynamic> serverProduct,
  ) async {
    final url = serverProduct['paypal_link'];
    logger.i('Buy button pressed: ${serverProduct['paypal_link']}');
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw AppLocalizations.of(context).update_cannot_open_appstore;
    }
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
}
