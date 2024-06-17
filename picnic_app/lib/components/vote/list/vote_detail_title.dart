import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/ui/style.dart';

class VoteCommonTitle extends StatelessWidget {
  final String title;

  const VoteCommonTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16).r,
        decoration: BoxDecoration(
            color: AppColors.Mint500,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.Primary500,
              width: 1.5,
            )),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'assets/icons/vote/vote_title_left.svg',
              width: 16.w,
              height: 16.w,
            ),
            SizedBox(
              width: 2.w,
            ),
            Expanded(
              child: Container(
                height: 48.w,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Text(title,
                        style:
                            getTextStyle(AppTypo.BODY16M, AppColors.Primary500)
                                .copyWith(
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 1
                                      ..color = AppColors.Primary500
                                      ..strokeJoin = StrokeJoin.miter
                                      ..strokeMiterLimit = 28.96),
                        overflow: TextOverflow.ellipsis),
                    Text(
                      title,
                      style: getTextStyle(AppTypo.BODY16M, AppColors.Grey00),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 2.w,
            ),
            SvgPicture.asset(
              'assets/icons/vote/vote_title_right.svg',
              width: 16.w,
              height: 16.w,
            ),
          ],
        ));
  }
}
