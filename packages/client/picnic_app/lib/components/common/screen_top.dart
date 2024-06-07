import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/ui/gradient-border-painter.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user-info-provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScreenTop extends ConsumerStatefulWidget {
  const ScreenTop({
    super.key,
  });

  @override
  ConsumerState<ScreenTop> createState() => _TopState();
}

class _TopState extends ConsumerState<ScreenTop> {
  @override
  void initState() {
    super.initState();
    _setupRealtime();
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.watch(navigationInfoProvider.notifier);
    return Container(
      height: 54.h,
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            color: AppColors.Gray500.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          navigationInfo.navigationStack.length > 1
              ? GestureDetector(
                  onTap: () {
                    navigationInfoNotifier.goBack();
                  },
                  child: const Icon(Icons.arrow_back_ios),
                )
              : CustomPaint(
                  painter: GradientBorderPainter(
                      borderRadius: 21.r,
                      borderWidth: 1.r,
                      gradient: commonGradient),
                  child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
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
                                height: 20.h,
                                constraints: BoxConstraints(minWidth: 80.w),
                                alignment: Alignment.topRight,
                                child: AnimatedDigitWidget(
                                    value: userInfo.value?.star_candy ?? 0,
                                    duration: const Duration(milliseconds: 500),
                                    enableSeparator: true,
                                    curve: Curves.easeInOut,
                                    textStyle: getTextStyle(AppTypo.CAPTION12B,
                                        AppColors.Primary500)
                                    // .copyWith(
                                    // foreground: Paint()
                                    //   ..style = PaintingStyle.stroke
                                    //   ..strokeWidth = .3
                                    //   ..color = AppColors.Gray900,
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
                              //           color: AppColors.Gray900.withOpacity(.5),
                              //           offset: const Offset(0, 5),
                              //           blurRadius: 10)
                              //     ]),
                              //   ),
                              // ),
                            ],
                          ),
                          Divider(
                            color: AppColors.Gray900,
                            thickness: 1.r,
                            indent: 6.w,
                          ),
                          Container(
                            height: 18.h,
                            decoration: BoxDecoration(
                              color: AppColors.Gray00,
                              borderRadius: BorderRadius.circular(20.r),
                              // boxShadow: [
                              //   BoxShadow(
                              //     offset: const Offset(0, 4),
                              //     color: AppColors.Gray500.withOpacity(0.5),
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
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/header/daily_check.svg',
                width: 24.w,
                height: 24.h,
              ),
              Divider(
                color: AppColors.Gray900,
                thickness: 1.r,
                indent: 16.w,
              ),
              SvgPicture.asset(
                'assets/icons/header/alarm.svg',
                width: 24.w,
                height: 24.h,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void handleUserInfo(PostgresChangePayload payload) {
    logger.d('Change received! $payload');
    int starCandy = payload.newRecord['star_candy'];
    logger.d('Star candy: $starCandy');
    ref.read(userInfoProvider.notifier).setStarCandy(starCandy);
  }

  void _setupRealtime() {
    final subscription = Supabase.instance.client
        .channel('realtime')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'user_profiles',
            callback: handleUserInfo)
        .subscribe((status, payload) {
      logger.d(status);
    }, const Duration(seconds: 1));
  }
}
