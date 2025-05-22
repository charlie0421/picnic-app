import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteCommonTitle extends StatelessWidget {
  final String title;

  const VoteCommonTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
            color: AppColors.secondary500,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary500,
              width: 1.5,
            )),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
                package: 'picnic_lib',
                'assets/icons/play_style=fill.svg',
                width: 16.w,
                height: 16,
                colorFilter:
                    ColorFilter.mode(AppColors.primary500, BlendMode.srcIn)),
            SizedBox(
              width: 2.w,
            ),
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Text(title,
                        style:
                            getTextStyle(AppTypo.body16M, AppColors.primary500)
                                .copyWith(
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 1
                                      ..color = AppColors.primary500
                                      ..strokeJoin = StrokeJoin.miter
                                      ..strokeMiterLimit = 28.96),
                        overflow: TextOverflow.ellipsis),
                    Text(
                      title,
                      style: getTextStyle(AppTypo.body16M, AppColors.grey00),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 2.w,
            ),
            Transform.rotate(
              angle: 3.14,
              child: SvgPicture.asset(
                  package: 'picnic_lib',
                  'assets/icons/play_style=fill.svg',
                  width: 16.w,
                  height: 16,
                  colorFilter:
                      ColorFilter.mode(AppColors.primary500, BlendMode.srcIn)),
            ),
          ],
        ));
  }
}
