import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/purchase_product_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/common_theme.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class PurchaseStarCandy extends ConsumerStatefulWidget {
  const PurchaseStarCandy({super.key});

  @override
  ConsumerState createState() => _PurchaseStarCandyState();
}

class _PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  bool _available = true;
  List<ProductDetails> _products = [];
  bool _purchasePending = false;
  final List<String> _productIds = [
    'STAR100',
    'STAR300',
    'STAR600',
    'STAR1000',
    'STAR2000',
    'STAR3000',
    'STAR4000',
    'STAR5000'
  ];

  void _buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          _purchasePending = true;
        });
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          setState(() {
            _purchasePending = false;
          });
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          // Verify purchase and deliver the product
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    });
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      // Handle the error
      print('Store is not available');
      return;
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds.toSet());

    if (response.error != null) {
      // Handle the error
      print('Error fetching products: ${response.error}');
      return;
    }

    if (response.productDetails.isEmpty) {
      // Handle the error
      print('No products found');
      return;
    }

    setState(() {
      _products = response.productDetails;
    });
  }

  Future<void> verifyReceipt(String receipt) async {
    final response = await supabase.functions.invoke('verify_receipt',
        body: {'receipt': receipt, 'platform': Platform.isIOS});

    if (response.status == 200) {
      // 영수증이 유효함
      final data = json.decode(response.data);
      print('Receipt is valid: ${data['data']}');
    } else {
      // 영수증이 유효하지 않음
      print('Receipt is invalid: ${response.data}');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        verifyReceipt(purchase.verificationData.serverVerificationData);
      }
      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProductList = ref.watch(purchaseProductListProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          SizedBox(height: 36.w),
          StorePointInfo(
              title: S.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 100.w),
          SizedBox(height: 36.w),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) => StoreListTile(
              icon: Image.asset(
                'assets/icons/store/star_${purchaseProductList[index].star_candy ?? ''}.png',
                width: 48.w,
                height: 48.w,
              ),
              title: Text(purchaseProductList[index].title ?? '',
                  style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text:
                            '${formatNumberWithComma(purchaseProductList[index].star_candy)} +${S.of(context).label_bonus} ${formatNumberWithComma(purchaseProductList[index].bonus_star_candy)}',
                        style: getTextStyle(
                            AppTypo.CAPTION12B, AppColors.Point900)),
                  ],
                ),
              ),
              buttonText: '${purchaseProductList[index].price} \$',
              buttonOnPressed: () {
                final purchaseProduct = purchaseProductList[index];

                supabase.isLogged
                    ? _buyProduct(ProductDetails(
                        id: purchaseProduct.id,
                        title: purchaseProduct.title,
                        description: purchaseProduct.id,
                        price: purchaseProduct.price.toString(),
                        rawPrice: purchaseProduct.price,
                        currencyCode: 'US'))
                    : showSimpleDialog(
                        context: context,
                        content: S.of(context).dialog_content_ads_loading,
                        onOk: () {
                          Navigator.of(context).pop();
                        },
                      );
              },
            ),
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(color: AppColors.Grey200, height: 32),
            itemCount: purchaseProductList.length,
          ),
          const Divider(color: AppColors.Grey200, height: 32),
          Text(S.of(context).text_purchase_vat_included,
              style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          SizedBox(height: 2.w),
          GestureDetector(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => LargePopupWidget(
                        width: getPlatformScreenSize(context).width - 32.w,
                        content: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 40.w, vertical: 64.w),
                          child: Column(children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                    'assets/icons/play_style=fill.svg',
                                    width: 16.w,
                                    height: 16.w,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.Primary500,
                                      BlendMode.srcIn,
                                    )),
                                SizedBox(width: 8.w),
                                Text(
                                  S.of(context).candy_usage_policy_title,
                                  style: getTextStyle(
                                      AppTypo.BODY14B, AppColors.Primary500),
                                ),
                                SizedBox(width: 8.w),
                                Transform.rotate(
                                  angle: 3.14,
                                  child: SvgPicture.asset(
                                      'assets/icons/play_style=fill.svg',
                                      width: 16.w,
                                      height: 16.w,
                                      colorFilter: const ColorFilter.mode(
                                        AppColors.Primary500,
                                        BlendMode.srcIn,
                                      )),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.w),
                            Markdown(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              data: S.of(context).candy_usage_policy_contents,
                              styleSheet: commonMarkdownStyleSheet,
                            ),
                            SizedBox(height: 16.w),
                            StorePointInfo(
                                title: S.of(context).label_star_candy_pouch,
                                width: 231.w,
                                titlePadding: 10.w,
                                height: 78.w)
                          ]),
                        ),
                      ));
            },
            child: Text(S.of(context).candy_usage_policy_guide,
                style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          ),
          SizedBox(height: 36.w),
        ],
      ),
    );
  }
}
