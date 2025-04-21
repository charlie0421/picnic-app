import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/providers/locale_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/menu_item.dart';

class CommonBottomNavigationBar extends ConsumerWidget {
  const CommonBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final screenInfoMap = ref.watch(screenInfosProvider).value ?? {};

    final screenInfo = screenInfoMap[navigationInfo.portalType.name.toString()];
    ref.watch(localeStateProvider);

    if (screenInfo == null) {
      return const SizedBox();
    }

    final userInfoState = ref.watch(userInfoProvider);

    return userInfoState.when(
      data: (data) {
        return Container(
          margin: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: 0,
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
        );
      },
      loading: () => const SizedBox(),
      error: (e, s) {
        return const SizedBox();
      },
    );
  }
}
