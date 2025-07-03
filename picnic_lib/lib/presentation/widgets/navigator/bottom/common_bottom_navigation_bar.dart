import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/navigator/navigation_configs.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/menu_item.dart';

class CommonBottomNavigationBar extends ConsumerWidget {
  const CommonBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final userInfoState = ref.watch(userInfoProvider);
    final mediaQuery = ref.watch(globalMediaQueryProvider);

    final screenInfo =
        NavigationConfigs.getScreenInfo(navigationInfo.portalType);

    if (screenInfo == null) {
      return const SizedBox();
    }

    return userInfoState.when(
      data: (data) {
        // 하단 padding 값 확인
        final bottomPadding = mediaQuery.padding.bottom;
        final isExcessivePadding = bottomPadding > 30; // 30px 이상이면 과도함

        return Container(
          // 과도한 padding의 경우 직접 제어
          padding: isExcessivePadding
              ? EdgeInsets.only(bottom: 16.h) // 고정값 사용
              : null, // SafeArea에 맡김
          child: isExcessivePadding
              ? Container(
                  margin: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    bottom: 8.h,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(255, 255, 255, 0),
                        Color.fromRGBO(255, 255, 255, 0.8),
                        Color.fromRGBO(255, 255, 255, 1),
                      ],
                      stops: [0.0, 0.62, 0.78],
                    ),
                  ),
                  child: Container(
                    height: 52,
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    decoration: ShapeDecoration(
                      color: screenInfo.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      shadows: [
                        BoxShadow(
                          color: const Color(0x3F000000),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: screenInfo.pages
                          .map((e) => MenuItem(
                                title: e.title,
                                assetPath: e.assetPath,
                                index: e.index,
                                needLogin: e.needLogin,
                              ))
                          .toList(),
                    ),
                  ),
                )
              : SafeArea(
                  // 정상 범위의 경우 SafeArea 사용
                  top: false,
                  left: false,
                  right: false,
                  bottom: true,
                  child: Container(
                    margin: EdgeInsets.only(
                      left: 16.w,
                      right: 16.w,
                      bottom: 8.h,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0),
                          Color.fromRGBO(255, 255, 255, 0.8),
                          Color.fromRGBO(255, 255, 255, 1),
                        ],
                        stops: [0.0, 0.62, 0.78],
                      ),
                    ),
                    child: Container(
                      height: 52,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      decoration: ShapeDecoration(
                        color: screenInfo.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        shadows: [
                          BoxShadow(
                            color: const Color(0x3F000000),
                            blurRadius: 8,
                            offset: const Offset(0, 0),
                            spreadRadius: 0,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: screenInfo.pages
                            .map((e) => MenuItem(
                                  title: e.title,
                                  assetPath: e.assetPath,
                                  index: e.index,
                                  needLogin: e.needLogin,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
        );
      },
      loading: () => const SizedBox(),
      error: (e, s) {
        return const SizedBox();
      },
    );
  }
}
