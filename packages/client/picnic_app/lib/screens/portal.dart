import 'package:animated_digit/animated_digit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/appinfo.dart';
import 'package:picnic_app/components/ui/gradient-border-painter.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/logined_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user-info-provider.dart';
import 'package:picnic_app/screens/login_screen.dart';
import 'package:picnic_app/screens/vote/vote_home_screen.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import 'community/community_home_screen.dart';
import 'novel/novel_home_screen.dart';
import 'pic/pic_home_screen.dart';

class Portal extends ConsumerStatefulWidget {
  static const String routeName = '/landing';

  const Portal({super.key});

  @override
  ConsumerState<Portal> createState() => _PortalState();
}

class _PortalState extends ConsumerState<Portal> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);

    Widget currentScreen = navigationInfo.currentScreen;

    if (navigationInfo.portalString == 'vote') {
      currentScreen = const VoteHomeScreen();
    } else if (navigationInfo.portalString == 'pic') {
      currentScreen = const PicHomeScreen();
    } else if (navigationInfo.portalString == 'community') {
      currentScreen = const CommunityHomeScreen();
    } else if (navigationInfo.portalString == 'novel') {
      currentScreen = const NovelHomeScreen();
    } else {
      currentScreen = const SizedBox.shrink();
    }

    final bool logined = ref.watch(loginedProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: logined
            ? GestureDetector(
                onTap: () =>
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      navigationInfoNotifier.setCurrentPage(
                        const AppInfo(),
                      );
                    }),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(
                      imageUrl: Supabase.instance.client.auth.currentUser
                          ?.userMetadata?['avatar_url'],
                      placeholder: (context, url) => buildPlaceholderImage(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ))
            : GestureDetector(
                onTap: () =>
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  navigationInfoNotifier.setCurrentPage(
                    const LoginScreen(),
                  );
                }),
                child: const Icon(Icons.person),
              ),
        title: SizedBox(
          width: double.infinity,
          child: SizedBox(
            height: 24.h,
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      PortalMenuItem(
                          navigationInfoNotifier: navigationInfoNotifier,
                          navigationInfo: navigationInfo,
                          portalString: 'vote'),
                      SizedBox(width: 20.w),
                      PortalMenuItem(
                          navigationInfoNotifier: navigationInfoNotifier,
                          navigationInfo: navigationInfo,
                          portalString: 'pic'),
                      SizedBox(width: 20.w),
                      PortalMenuItem(
                          navigationInfoNotifier: navigationInfoNotifier,
                          navigationInfo: navigationInfo,
                          portalString: 'community'),
                      SizedBox(width: 20.w),
                      PortalMenuItem(
                          navigationInfoNotifier: navigationInfoNotifier,
                          navigationInfo: navigationInfo,
                          portalString: 'novel'),
                      SizedBox(width: 20.w),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (ref.watch(
              navigationInfoProvider.select((value) => value.showTopMenu)))
            const Top(),
          Expanded(child: currentScreen),
        ],
      ),
    );
  }
}

class Top extends ConsumerStatefulWidget {
  const Top({
    super.key,
  });

  @override
  ConsumerState<Top> createState() => _TopState();
}

class _TopState extends ConsumerState<Top> {
  @override
  void initState() {
    super.initState();
    _setupRealtime();
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);
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
          CustomPaint(
            painter: GradientBorderPainter(
                borderRadius: 21.r, borderWidth: 1.r, gradient: commonGradient),
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
                              textStyle: getTextStyle(
                                  AppTypo.CAPTION12B, AppColors.Primary500)
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
    logger.d('Setting up realtime for profiles');
    final subscription = Supabase.instance.client
        .channel('realtime')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'user_profiles',
            callback: handleUserInfo)
        .subscribe((status, payload) {
      logger.d(status);
    }, Duration(seconds: 1));

    logger.d(Supabase.instance.client.auth.currentUser?.id);

    logger.d('Realtime setup complete');
  }
}

class PortalMenuItem extends StatelessWidget {
  const PortalMenuItem({
    super.key,
    required this.navigationInfoNotifier,
    required this.navigationInfo,
    required this.portalString,
  });

  final NavigationInfo navigationInfoNotifier;
  final Navigation navigationInfo;
  final String portalString;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () {
        navigationInfoNotifier.setPortalString(portalString);
      },
      child: Container(
        height: 24.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.Gray900,
            width: 0.5.r,
          ),
          color: navigationInfo.portalString == portalString
              ? AppColors.Gray00
              : Colors.transparent,
        ),
        child: Center(
          child: Text(
            portalString.toUpperCase(),
            style: navigationInfo.portalString == portalString
                ? getTextStyle(AppTypo.BODY14B, AppColors.Gray900)
                : getTextStyle(AppTypo.BODY14R, AppColors.Gray900),
          ),
        ),
      ),
    );
  }
}
