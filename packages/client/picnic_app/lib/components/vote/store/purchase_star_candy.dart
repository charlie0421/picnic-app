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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/product_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/common_theme.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseStarCandy extends ConsumerStatefulWidget {
  const PurchaseStarCandy({super.key});

  @override
  ConsumerState createState() => _PurchaseStarCandyState();
}

class _PurchaseStarCandyState extends ConsumerState<PurchaseStarCandy> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  @override
  void initState() {
    super.initState();
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    purchaseUpdated.listen(_listenToPurchaseUpdated);

    // 미완료 트랜잭션 확인
    _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    });
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

  Future<String> getEnvironment() async {
    if (kDebugMode) {
      return 'sandbox';
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String buildNumber = packageInfo.buildNumber;

    // TestFlight 빌드 번호는 일반적으로 1.0.0 형식이 아닙니다.
    // 여기서는 간단히 점(.)이 포함되어 있는지로 구분합니다.
    bool isTestFlight = buildNumber.contains('.');
    logger.i(isTestFlight);

    return isTestFlight ? 'sandbox' : 'production';
  }

  Future<void> verifyReceipt(String receipt, String productId) async {
    try {
      final environment = await getEnvironment();
      print('Current environment: $environment'); // Log the environment

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

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Map<String, dynamic>>>>(serverProductsProvider,
        (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) => logger.e('Server products error: $error'),
        data: (data) => logger.i('Server products loaded: ${data.length}'),
      );
    });

    ref.listen<AsyncValue<List<ProductDetails>>>(storeProductsProvider,
        (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) => logger.e('Store products error: $error'),
        data: (data) => logger.i('Store products loaded: ${data.length}'),
      );
    });

    final serverProductsAsyncValue = ref.watch(serverProductsProvider);
    final storeProductsAsyncValue = ref.watch(storeProductsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          SizedBox(height: 36.w),
          StorePointInfo(
            title: S.of(context).label_star_candy_pouch,
            width: double.infinity,
            height: 100.w,
          ),
          SizedBox(height: 36.w),
          serverProductsAsyncValue.when(
            loading: () => _buildShimmer(),
            error: (error, stackTrace) =>
                Text('Error loading server products: $error'),
            data: (serverProducts) {
              return storeProductsAsyncValue.when(
                loading: () => _buildShimmer(),
                error: (error, stackTrace) =>
                    Text('Error loading store products: $error'),
                data: (storeProducts) {
                  return _buildProductList(
                      context, ref, serverProducts, storeProducts);
                },
              );
            },
          ),
          const Divider(color: AppColors.Grey200, height: 32),
          Text(S.of(context).text_purchase_vat_included,
              style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          SizedBox(height: 2.w),
          GestureDetector(
            onTap: () => _showCandyUsagePolicy(context),
            child: Text(S.of(context).candy_usage_policy_guide,
                style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          ),
          SizedBox(height: 36.w),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 48.w,
              height: 48.w,
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
        },
        separatorBuilder: (context, index) =>
            const Divider(color: AppColors.Grey200, height: 32),
        itemCount: 5,
      ),
    );
  }

  Widget _buildProductList(
      BuildContext context,
      WidgetRef ref,
      List<Map<String, dynamic>> serverProducts,
      List<ProductDetails> storeProducts) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) => StoreListTile(
        icon: Image.asset(
          'assets/icons/store/star_${serverProducts[index]['id'].replaceAll('STAR', '')}.png',
          width: 48.w,
          height: 48.w,
        ),
        title: Text(serverProducts[index]['id'],
            style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
        subtitle: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: serverProducts[index]['description']
                      [Intl.getCurrentLocale()],
                  style: getTextStyle(AppTypo.CAPTION12B, AppColors.Point900)),
            ],
          ),
        ),
        buttonText: '${serverProducts[index]['price']} \$',
        buttonOnPressed: () {
          final productDetails = storeProducts[index];
          supabase.isLogged
              ? _buyProduct(productDetails)
              : showRequireLoginDialog(context: context);
        },
      ),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(color: AppColors.Grey200, height: 32),
      itemCount: storeProducts.length,
    );
  }

  void _buyProduct(ProductDetails productDetails) {
    logger.i('Trying to buy product: ${productDetails.id}');
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  void _showCandyUsagePolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LargePopupWidget(
        width: getPlatformScreenSize(context).width - 32.w,
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 64.w),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/play_style=fill.svg',
                    width: 16.w,
                    height: 16.w,
                    colorFilter: const ColorFilter.mode(
                        AppColors.Primary500, BlendMode.srcIn),
                  ),
                  SizedBox(width: 8.w),
                  Text(S.of(context).candy_usage_policy_title,
                      style:
                          getTextStyle(AppTypo.BODY14B, AppColors.Primary500)),
                  SizedBox(width: 8.w),
                  Transform.rotate(
                    angle: 3.14,
                    child: SvgPicture.asset(
                      'assets/icons/play_style=fill.svg',
                      width: 16.w,
                      height: 16.w,
                      colorFilter: const ColorFilter.mode(
                          AppColors.Primary500, BlendMode.srcIn),
                    ),
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
                height: 78.w,
              )
            ],
          ),
        ),
      ),
    );
  }
}
