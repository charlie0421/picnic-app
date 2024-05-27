import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    int currentIndex;
    if (screenInfo.type == 'vote') {
      currentIndex = ref.watch(navigationInfoProvider
          .select((value) => value.voteBottomNavigationIndex));
    } else if (screenInfo.type == 'fan') {
      currentIndex = ref.watch(navigationInfoProvider
          .select((value) => value.fanBottomNavigationIndex));
    } else if (screenInfo.type == 'community') {
      currentIndex = ref.watch(navigationInfoProvider
          .select((value) => value.communityBottomNavigationIndex));
    } else if (screenInfo.type == 'novel') {
      currentIndex = ref.watch(navigationInfoProvider
          .select((value) => value.novelBottomNavigationIndex));
    } else {
      currentIndex = 0;
    }

    var setter;
    if (screenInfo.type == 'vote') {
      setter = ref
          .read(navigationInfoProvider.notifier)
          .setVoteBottomNavigationIndex;
    } else if (screenInfo.type == 'fan') {
      setter =
          ref.read(navigationInfoProvider.notifier).setFanBottomNavigationIndex;
    } else if (screenInfo.type == 'community') {
      setter = ref
          .read(navigationInfoProvider.notifier)
          .setCommunityBottomNavigationIndex;
    } else if (screenInfo.type == 'novel') {
      setter = ref
          .read(navigationInfoProvider.notifier)
          .setNovelBottomNavigationIndex;
    } else {
      setter = () {};
    }

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
                .map((e) => Item(
                      title: e.title,
                      icon: e.icon,
                      index: e.index,
                      isSelected: e.index == currentIndex,
                      setter: setter,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class Item extends ConsumerWidget {
  final String title;
  final IconData icon;
  final int index;
  bool isSelected = false;
  Function setter;

  Item({
    super.key,
    required this.title,
    required this.icon,
    required this.index,
    required this.isSelected,
    required this.setter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationNotifier = ref.read(navigationInfoProvider.notifier);

    return Container(
      height: 52.h,
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) {
          setter(index);
        }),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: Icon(
                icon,
                size: 24.w,
                color: isSelected ? AppColors.Gray900 : AppColors.Gray400,
              ),
            ),
            Text(
              title,
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
