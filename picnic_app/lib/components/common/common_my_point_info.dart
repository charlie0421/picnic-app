import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/ui/gradient_border_painter.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';

class CommonMyPoint extends ConsumerStatefulWidget {
  const CommonMyPoint({
    super.key,
  });

  @override
  ConsumerState<CommonMyPoint> createState() => _CommonMyPointState();
}

class _CommonMyPointState extends ConsumerState<CommonMyPoint> {
  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);

    return SizedBox(
      child: CustomPaint(
        painter: GradientBorderPainter(
            borderRadius: 21.r, borderWidth: 1.r, gradient: commonGradient),
        child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8).r,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/header/star.png',
                  width: 20.w,
                  height: 20.h,
                ),
                Stack(
                  children: [
                    Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(bottom: 3).r,
                      height: 18.h,
                      constraints: BoxConstraints(minWidth: 80.w),
                      child: AnimatedDigitWidget(
                          value: userInfo.value?.star_candy ?? 0,
                          duration: const Duration(milliseconds: 500),
                          enableSeparator: true,
                          curve: Curves.easeInOut,
                          textStyle: getTextStyle(
                              AppTypo.CAPTION12B, AppColors.Primary500)
                          // .copyWith(
                          // foreground: Paint()
                          //   ..style = PaintingStyle.stroke
                          //   ..strokeWidth = .3
                          //   ..color = AppColors.Grey900,
                          // )
                          ),
                    ),
                    // Positioned(
                    //   right: 0,
                    //   child: AnimatedDigitWidget(
                    //     value: userInfo.value?.star_candy ?? 0,
                    //     duration: const Duration(milliseconds: 500),
                    //     curve: Curves.easeInOut,
                    //     textStyle: getTextStyle(
                    //             AppTypo.CAPTION12B, AppColors.Primary500)
                    //         .copyWith(shadows: [
                    //       Shadow(
                    //           color: AppColors.Grey900.withOpacity(.5),
                    //           offset: const Offset(0, 5),
                    //           blurRadius: 10)
                    //     ]),
                    //   ),
                    // ),
                  ],
                ),
                Divider(
                  color: AppColors.Grey900,
                  thickness: 1.r,
                  indent: 6.w,
                ),
                Container(
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: AppColors.Grey00,
                    borderRadius: BorderRadius.circular(20.r),
                    // boxShadow: [
                    //   BoxShadow(
                    //     offset: const Offset(0, 4),
                    //     color: AppColors.Grey500.withOpacity(0.5),
                    //     blurRadius: 2,
                    //   ),
                    // ],
                  ),
                  child: Image.asset(
                    'assets/icons/header/plus.png',
                    width: 16.67.w,
                    height: 16.67.h,
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
