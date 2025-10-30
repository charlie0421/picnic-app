import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/navigator/navigation_configs.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/menu_item.dart';

class CommonBottomNavigationBar extends ConsumerWidget {
  const CommonBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final userInfoState = ref.watch(userInfoProvider);

    // 디바이스 하단 안전영역에 따라 네비게이션 바의 바닥 마진을 조정
    // Android 15(edge-to-edge)에서는 MediaQuery.padding.bottom이 0이므로
    // viewPadding.bottom을 우선 사용해 제스처 영역까지 고려한다.
    final mediaQuery = MediaQuery.of(context);
    final double safeBottom = mediaQuery.viewPadding.bottom;
    // 기본 여백(디자인 스펙) + 기기 안전 영역
    final double dynamicBottomMargin = 16.h + (safeBottom > 0 ? safeBottom : 0);
    final screenInfo = NavigationConfigs.getScreenInfo(
      navigationInfo.portalType,
    );

    if (screenInfo == null) {
      return const SizedBox();
    }

    return userInfoState.when(
      data: (data) {
        return Container(
          margin: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: dynamicBottomMargin,
          ),
          height: NavBarConstants.bottomNavHeight,
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
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: screenInfo.pages
                .map(
                  (e) => MenuItem(
                    title: e.title,
                    assetPath: e.assetPath,
                    index: e.index,
                    needLogin: e.needLogin,
                  ),
                )
                .toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
