import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/menu.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';

class CommonBottomNavigationBar extends ConsumerWidget {
  final ScreenInfo screenInfo;

  const CommonBottomNavigationBar({super.key, required this.screenInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appSettingProvider.select((value) => value.locale));

    int navigationIndex = getCurrentIndex(screenInfo.type, ref);
    Function navigationIndexSetter = getIndexSetter(screenInfo.type, ref);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0).r,
      child: BottomAppBar(
        elevation: 0,
        padding: EdgeInsets.zero,
        height: 52.h,
        child: Container(
          height: 42.h,
          padding: const EdgeInsets.symmetric(horizontal: 32).r,
          decoration: ShapeDecoration(
            color: screenInfo.color,
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
            children: screenInfo.pages
                .map((e) => MenuItem(
                      title: e.title,
                      assetPath: e.assetPath,
                      index: e.index,
                      isSelected: e.index == navigationIndex,
                      indexSetter: navigationIndexSetter,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  int getCurrentIndex(String type, WidgetRef ref) {
    final provider = navigationInfoProvider.select((value) => type == 'vote'
        ? value.voteBottomNavigationIndex
        : type == 'fan'
            ? value.fanBottomNavigationIndex
            : type == 'community'
                ? value.communityBottomNavigationIndex
                : type == 'novel'
                    ? value.novelBottomNavigationIndex
                    : 0);
    return ref.watch(provider);
  }

  Function getIndexSetter(String type, WidgetRef ref) {
    var notifier = ref.read(navigationInfoProvider.notifier);

    return type == 'vote'
        ? notifier.setVoteBottomNavigationIndex
        : type == 'fan'
            ? notifier.setFanBottomNavigationIndex
            : type == 'community'
                ? notifier.setCommunityBottomNavigationIndex
                : type == 'novel'
                    ? notifier.setNovelBottomNavigationIndex
                    : () {};
  }
}

class MenuItem extends ConsumerWidget {
  final String title;
  final String assetPath;
  final int index;
  bool isSelected = false;
  Function indexSetter;

  MenuItem({
    super.key,
    required this.title,
    required this.assetPath,
    required this.index,
    required this.isSelected,
    required this.indexSetter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationNotifier = ref.read(navigationInfoProvider.notifier);

    return Container(
      height: 52.h,
      child: InkWell(
        onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
          indexSetter(index);
        }),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
                width: 24.w,
                height: 24.h,
                child: SvgPicture.asset(
                  assetPath,
                  color: isSelected ? AppColors.Gray900 : AppColors.Gray400,
                )),
            Text(
              Intl.message(title),
              style: getTextStyle(
                context,
                AppTypo.CAPTION12R,
                isSelected ? AppColors.Gray900 : AppColors.Gray400,
              ),
            )
          ],
        ),
      ),
    );
  }
}
