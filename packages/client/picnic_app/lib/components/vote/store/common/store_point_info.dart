import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/star_candy_info_text.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class StorePointInfo extends ConsumerWidget {
  const StorePointInfo(
      {super.key,
      required this.title,
      this.width = 48,
      this.height = 36,
      this.titlePadding});

  final double? width;
  final double? height;
  final String title;
  final double? titlePadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Container(
          height: height,
          width: width,
          margin: EdgeInsets.only(top: 24, left: 16.cw, right: 16.cw),
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
          child: const StarCandyInfoText(),
        ),
        Positioned.fill(
            child: Container(
                alignment: Alignment.topCenter,
                padding: EdgeInsets.symmetric(horizontal: 33.cw),
                child: VoteCommonTitle(title: title))),
      ],
    );
  }
}
