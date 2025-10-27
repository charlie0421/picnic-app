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
    final safeBottom = MediaQuery.of(context).padding.bottom;
    // 홈 인디케이터가 있는 기기(iOS 최신 등)에도 최소 여백을 준다
    final double dynamicBottomMargin = safeBottom > 0 ? 16.h : 16.h;
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
