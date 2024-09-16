import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/ui/gradient_border_painter.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

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
    final starCandy = ref.watch(
            userInfoProvider.select((value) => value.value?.star_candy)) ??
        0;
    final starCandyBonus = ref.watch(userInfoProvider
            .select((value) => value.value?.star_candy_bonus)) ??
        0;

    return GestureDetector(
      onTap: () {
        ref
            .read(navigationInfoProvider.notifier)
            .setVoteBottomNavigationIndex(3);
      },
      child: SizedBox(
        child: CustomPaint(
          painter: GradientBorderPainter(
              borderRadius: 21.r, borderWidth: 1.r, gradient: commonGradient),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/store/star_100.png',
                width: 30.cw,
                height: 30,
              ),
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(bottom: 3),
                height: 18,
                constraints: BoxConstraints(minWidth: 60.cw),
                child: AnimatedDigitWidget(
                    value: starCandy + starCandyBonus,
                    duration: const Duration(milliseconds: 500),
                    enableSeparator: true,
                    curve: Curves.easeInOut,
                    textStyle:
                        getTextStyle(AppTypo.caption12B, AppColors.primary500)),
              ),
              SizedBox(width: 8.cw),
              Image.asset(
                'assets/icons/header/plus.png',
                width: 16.cw,
                height: 16,
              ),
              SizedBox(width: 8.cw),
            ],
          ),
        ),
      ),
    );
  }
}
