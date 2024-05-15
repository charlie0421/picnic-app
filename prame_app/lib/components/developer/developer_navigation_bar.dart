import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/appinfo.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/providers/app_setting_provider.dart';
import 'package:prame_app/providers/navigation_provider.dart';
import 'package:prame_app/ui/style.dart';

class DeveloperBottomNavigationBar extends ConsumerWidget {
  const DeveloperBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appSettingProvider.select((value) => value.locale));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0).r,
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        height: 60.h,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32).r,
          decoration: ShapeDecoration(
            color: Constants.developerMainColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(120).r,
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
            children: <Widget>[
              Item(
                title: Intl.message('nav_app_info'),
                icon: Icons.app_settings_alt,
                index: 0,
              ),
            ],
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

  const Item({
    super.key,
    required this.title,
    required this.icon,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationInfoProvider
        .select((value) => value.fanBottomNavigationIndex));
    final navigationNotifier = ref.read(navigationInfoProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          switch (index) {
            case 0:
              navigationNotifier.setCurrentPage(const AppInfo());
              navigationNotifier.setState(fanBottomNavigationIndex: 0);
              break;

            default:
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              color: currentIndex == index ? AppColors.GP00 : AppColors.Gray300,
            ),
            currentIndex == index
                ? Text(
                    title,
                    style: getTextStyle(
                      context,
                      AppTypo.UI12B,
                      AppColors.GP00,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
