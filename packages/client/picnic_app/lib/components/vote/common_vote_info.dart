import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/ui/style.dart';

class CommonPointInfo extends StatelessWidget {
  const CommonPointInfo({super.key, required this.point});

  final int point;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 100.h,
          margin: const EdgeInsets.only(top: 24, left: 16, right: 16).r,
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
          child: Container(
            padding: const EdgeInsets.only(top: 16).r,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icons/header/star.png',
                    width: 48.w, height: 48.w),
                Text('$point',
                    style: getTextStyle(AppTypo.BODY16B, AppColors.Gray900)),
              ],
            ),
          ),
        ),
        Positioned.fill(
            child: Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.symmetric(horizontal: 57).w,
                child: VoteCommonTitle(title: '별사탕 주머니'))),
      ],
    );
  }
}
