import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/star_candy_info_text.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';

class StorePointInfo extends ConsumerWidget {
  StorePointInfo(
      {super.key,
      required this.title,
      this.width,
      this.height,
      this.titlePadding});

  double? width = 48.w;
  double? height = 48.h;
  final String title;
  final double? titlePadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starCandy = ref.watch(
        userInfoProvider.select((value) => value.value?.star_candy ?? 0));
    final starCandyBonus = ref.watch(
        userInfoProvider.select((value) => value.value?.star_candy_bonus ?? 0));
    final totlaStarCandy = starCandy + starCandyBonus;

    return Stack(
      children: [
        Container(
          height: height,
          width: width,
          margin: const EdgeInsets.only(top: 32, left: 16, right: 16).r,
          decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.Primary500,
                width: 1.5.r,
              ),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.r),
                  topRight: Radius.circular(40.r),
                  bottomLeft: Radius.circular(40.r),
                  bottomRight: Radius.circular(40.r))),
          alignment: Alignment.center,
          child: const StarCandyInfoText(),
        ),
        Positioned.fill(
            child: Container(
                alignment: Alignment.topCenter,
                padding: EdgeInsets.symmetric(horizontal: 33.w),
                child: VoteCommonTitle(title: title))),
      ],
    );
  }
}
