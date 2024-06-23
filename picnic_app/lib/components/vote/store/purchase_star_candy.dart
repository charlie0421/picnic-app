import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/providers/purchase_product_provider.dart';
import 'package:picnic_app/ui/common_theme.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

class PurchaseStarCandy extends ConsumerWidget {
  const PurchaseStarCandy({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseProductList = ref.watch(purchaseProductListProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          SizedBox(height: 36.w),
          StorePointInfo(
              title: Intl.message('label_star_candy_pouch'),
              width: double.infinity,
              height: 100.w),
          SizedBox(height: 36.w),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) => StoreListTile(
              icon: Image.asset(
                'assets/icons/store/star_${purchaseProductList[index].star_candy}.png',
                width: 48.w,
                height: 48.w,
              ),
              title: Text(purchaseProductList[index].title,
                  style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900)),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text:
                            '${formatNumberWithComma(purchaseProductList[index].star_candy)} +${Intl.message('label_bonus')} ${formatNumberWithComma(purchaseProductList[index].bonus_star_candy)}',
                        style: getTextStyle(
                            AppTypo.CAPTION12B, AppColors.Point900)),
                  ],
                ),
              ),
              buttonText: '${purchaseProductList[index].price} \$',
            ),
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(color: AppColors.Grey200, height: 32),
            itemCount: purchaseProductList.length,
          ),
          const Divider(color: AppColors.Grey200, height: 32),
          Text(Intl.message('text_purchase_vat_included'),
              style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          SizedBox(height: 2.w),
          GestureDetector(
            onTap: () {
              print(Intl.message('text_star_candy_usage_policy'));
              final message = Intl.message('text_star_candy_usage_policy');
              showDialog(
                  context: context,
                  builder: (context) => LargePopupWidget(
                        width: MediaQuery.of(context).size.width - 32.w,
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
                                  Intl.message(
                                      'text_star_candy_usage_policy_title'),
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
                              data: message,
                              styleSheet: commonMarkdownStyleSheet,
                            ),
                            SizedBox(height: 16.w),
                            StorePointInfo(
                                title: Intl.message('label_star_candy_pouch'),
                                width: 231.w,
                                titlePadding: 10.w,
                                height: 78.w)
                          ]),
                        ),
                      ));
            },
            child: Text(Intl.message('text_star_candy_usage_policy_guide'),
                style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey600)),
          ),
          SizedBox(height: 36.w),
        ],
      ),
    );
  }
}
