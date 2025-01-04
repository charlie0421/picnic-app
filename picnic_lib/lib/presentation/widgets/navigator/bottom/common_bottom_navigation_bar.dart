import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/navigator/screen_info.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/menu_item.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/core/utils/ui.dart';

class CommonBottomNavigationBar extends ConsumerStatefulWidget {
  final ScreenInfo screenInfo;

  const CommonBottomNavigationBar({super.key, required this.screenInfo});

  @override
  ConsumerState<CommonBottomNavigationBar> createState() =>
      _CommonBottomNavigationBarState();
}

class _CommonBottomNavigationBarState
    extends ConsumerState<CommonBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    ref.watch(appSettingProvider.select((value) => value.locale));
    final userInfoState = ref.watch(userInfoProvider);
    return userInfoState.when(
      data: (data) {
        return Container(
          margin: EdgeInsets.only(
            left: 16.cw,
            right: 16.cw,
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
            padding: EdgeInsets.symmetric(horizontal: 24.cw),
            decoration: ShapeDecoration(
              color: widget.screenInfo.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadows: [
                BoxShadow(
                  color: const Color(0x3F000000),
                  blurRadius: 8.r,
                  offset: const Offset(0, 0),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widget.screenInfo.pages
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
        // showSimpleDialog(context: context, content: e.toString());
        // showSimpleDialog(context: context, content: s.toString());
        return const SizedBox();
      },
    );
  }
}
