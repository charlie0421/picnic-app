import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/menu.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';

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
        final bool isAdmin = data == null ? false : data.is_admin;
        return Container(
          height: 102.h,
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 50).r,
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
            height: 52.h,
            padding: const EdgeInsets.symmetric(horizontal: 24).r,
            decoration: ShapeDecoration(
              color: widget.screenInfo.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20).r,
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

class MenuItem extends ConsumerWidget {
  final String title;
  final String assetPath;
  final int index;

  const MenuItem({
    super.key,
    required this.title,
    required this.assetPath,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationNotifier = ref.read(navigationInfoProvider.notifier);

    final index = navigationNotifier.getBottomNavigationIndex();
    final bool isSelected = index == this.index;

    return SizedBox(
      height: 42.h,
      child: InkWell(
        onTap: () => navigationNotifier.setBottomNavigationIndex(this.index),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
                width: 24.w,
                height: 24.w,
                child: SvgPicture.asset(
                  assetPath,
                  colorFilter: ColorFilter.mode(
                      isSelected ? AppColors.Grey900 : AppColors.Grey400,
                      BlendMode.srcIn),
                )),
            Text(
              Intl.message(title),
              style: getTextStyle(
                isSelected ? AppTypo.CAPTION12B : AppTypo.CAPTION12R,
                isSelected ? AppColors.Grey900 : AppColors.Grey400,
              ),
            )
          ],
        ),
      ),
    );
  }
}
