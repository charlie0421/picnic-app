import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/purchase_product_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/common_theme.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseStarCandy extends ConsumerStatefulWidget {
  const PurchaseStarCandy({super.key});

  @override
  ConsumerState createState() => _PurchaseStarCandyState();
}

class _PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<Map<String, dynamic>> _serverProducts = [];
  List<ProductDetails> _storeProducts = [];

  @override
  void initState() {
    super.initState();
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    purchaseUpdated.listen(_listenToPurchaseUpdated);
    _fetchProductsFromSupabase();

    // 미완료 트랜잭션 확인
    _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    });
  }

  void _buyProduct(ProductDetails productDetails) {
    if (_storeProducts.isEmpty) {
      logger.i('Products not loaded');
      return;
    }
    logger.i('Trying to buy product: ${productDetails.id}');
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _startLoading();
      } else {
        try {
          if (purchaseDetails.status == PurchaseStatus.error) {
            showSimpleDialog(
                context: context,
                content: 'Purchase failed: ${purchaseDetails.error!.message}');
          } else if (purchaseDetails.status == PurchaseStatus.purchased ||
              purchaseDetails.status == PurchaseStatus.restored) {
            await verifyReceipt(
                purchaseDetails.verificationData.serverVerificationData,
                purchaseDetails.productID);
            ref.read(userInfoProvider.notifier).getUserProfiles();
          } else if (purchaseDetails.status == PurchaseStatus.canceled) {
            showSimpleDialog(
                context: context, content: 'Purchase was canceled.');
          }
        } catch (e) {
          showSimpleDialog(
              context: context, content: 'Error processing purchase: $e');
        } finally {
          _stopLoading();
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
      }
    });
  }

  int _loadingCounter = 0;

  void _startLoading() {
    setState(() {
      if (_loadingCounter == 0) {
        OverlayLoadingProgress.start(context,
            color: AppColors.Primary500, barrierDismissible: false);
      }
      _loadingCounter++;
    });
  }

  void _stopLoading() {
    setState(() {
      _loadingCounter--;
      if (_loadingCounter <= 0) {
        _loadingCounter = 0;
        OverlayLoadingProgress.stop();
      }
    });
  }

  Future<void> _loadProducts() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        // Store가 사용 가능하지 않음
        logger.i('Store is not available');
        return;
      }

      final productIds =
          _serverProducts.map((product) => product['id'] as String).toSet();
      final response = await _inAppPurchase.queryProductDetails(productIds);

      logger.i(productIds);

      if (response.error != null) {
        // 에러 처리
        logger.i('Error fetching products: ${response.error}');
        return;
      }

      if (response.productDetails.isEmpty) {
        // 제품이 없음
        logger.i('No products found');
        return;
      }

      setState(() {
        _storeProducts = response.productDetails;
      });

      logger.i('Products loaded: $_storeProducts');
    } catch (e, s) {
      logger.i(e, stackTrace: s);
    }
  }

  Future<void> verifyReceipt(String receipt, String productId) async {
    try {
      const environment = kReleaseMode ? 'production' : 'sandbox';

      final response = await Supabase.instance.client.functions
          .invoke('verify_receipt', body: {
        'receipt': receipt,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': productId,
        'user_id': supabase.auth.currentUser!.id,
        'environment': environment, // 환경 정보 전송
      });

      if (response.status == 200) {
        print('response: $response');
        print('response data: ${response.data}');

        // response.data가 이미 Map<String, dynamic> 타입일 수 있으므로 json.decode를 사용하지 않습니다.
        final data = response.data;

        print('Receipt is valid: $data');
        if (data is Map<String, dynamic> && data['success'] == true) {
          showSimpleDialog(context: context, content: 'Purchase successful!');
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Receipt verification failed: ${response.data}');
      }
    } catch (e) {
      print('Error verifying receipt: $e');
      rethrow; // 이 예외는 _listenToPurchaseUpdated에서 잡힙니다.
    }
  }

  Future<void> _fetchProductsFromSupabase() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .order('price', ascending: true);
      logger.i('response: $response');

      final List<Map<String, dynamic>> products =
          List<Map<String, dynamic>>.from(response);

      logger.i(products);

      if (products.isEmpty) {
        logger.i('No products found');
        return;
      }

      setState(() {
        _serverProducts = products;
      });

      logger.i(_serverProducts);

      // 제품 ID를 가져온 후 제품 로드
      await _loadProducts();
    } catch (e) {
      logger.i('Error fetching products: $e');
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
          _storeProducts.isEmpty
              ? Center(child: buildLoadingOverlay())
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) =>
                      StoreListTile(
                    icon: Image.asset(
                      'assets/icons/store/star_${_serverProducts[index]['id'].replaceAll('STAR', '')}.png',
                      width: 48.w,
                      height: 48.w,
                    ),
                    title: Text(_serverProducts[index]['id'],
                        style:
                            getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
                    subtitle: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: _serverProducts[index]['description']
                                  [Intl.getCurrentLocale()],
                              style: getTextStyle(
                                  AppTypo.CAPTION12B, AppColors.Point900)),
                        ],
                      ),
                    ),
                    buttonText: '${_serverProducts[index]['price']} \$',
                    buttonOnPressed: () {
                      final productDetails = _storeProducts[index];
                      supabase.isLogged
                          ? _buyProduct(productDetails)
                          : showRequireLoginDialog(context: context);
                    },
                  ),
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(color: AppColors.Grey200, height: 32),
                  itemCount: _storeProducts.length,
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
                                        AppColors.Primary500, BlendMode.srcIn)),
                                SizedBox(width: 8.w),
                                Text(S.of(context).candy_usage_policy_title,
                                    style: getTextStyle(
                                        AppTypo.BODY14B, AppColors.Primary500)),
                                SizedBox(width: 8.w),
                                Transform.rotate(
                                  angle: 3.14,
                                  child: SvgPicture.asset(
                                      'assets/icons/play_style=fill.svg',
                                      width: 16.w,
                                      height: 16.w,
                                      colorFilter: const ColorFilter.mode(
                                          AppColors.Primary500,
                                          BlendMode.srcIn)),
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
