import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/simple_dialog.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/components/vote/store/store_list_tile.dart';
import 'package:picnic_app/providers/purchase_product_provider.dart';
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
          const StorePointInfo(),
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
              showSimpleDialog(
                context: context,
                title: Intl.message('text_star_candy_usage_policy_title'),
                contentWidget: Markdown(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    data: Intl.message('text_star_candy_usage_policy')),
              );
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
