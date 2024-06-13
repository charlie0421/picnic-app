import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/menu.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: BottomAppBar(
        elevation: 0,
        padding: EdgeInsets.zero,
        height: 52.h,
        child: Container(
          height: 42.h,
          padding: const EdgeInsets.symmetric(horizontal: 32).r,
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
      ),
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
      height: 52.h,
      child: InkWell(
        onTap: () => WidgetsBinding.instance.addPostFrameCallback(
            (_) => navigationNotifier.setBottomNavigationIndex(this.index)),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
                width: 20.w,
                height: 20.h,
                child: SvgPicture.asset(
                  assetPath,
                  colorFilter: ColorFilter.mode(
                      isSelected ? AppColors.Grey900 : AppColors.Grey400,
                      BlendMode.srcIn),
                )),
            Text(
              Intl.message(title),
              style: getTextStyle(
                AppTypo.CAPTION12R,
                isSelected ? AppColors.Grey900 : AppColors.Grey400,
              ),
            )
          ],
        ),
      ),
    );
  }
}
