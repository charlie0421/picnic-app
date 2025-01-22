import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/gradient_border_painter.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/ui.dart';

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
    final starCandy =
        ref.watch(userInfoProvider.select((value) => value.value?.starCandy)) ??
            0;
    final starCandyBonus = ref.watch(
            userInfoProvider.select((value) => value.value?.starCandyBonus)) ??
        0;

    return GestureDetector(
      onTap: () {
        final votePages =
            ref.read(screenInfosProvider).value?[PortalType.vote.name]?.pages;

        if ( votePages == null ) {
          return;
        }
        ref
            .read(navigationInfoProvider.notifier)
            .setVoteBottomNavigationIndex(votePages.length - 1);
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
                package: 'picnic_lib',
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
                package: 'picnic_lib',
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
