import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';

class MyPageScreen extends ConsumerWidget {
  static const String routeName = '/mypage';

  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerNavigationStack = ref.watch(
        navigationInfoProvider.select((value) => value.drawerNavigationStack));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.Grey00,
        foregroundColor: AppColors.Grey900,
        leading: GestureDetector(
          onTap: () {
            if (drawerNavigationStack != null &&
                drawerNavigationStack.length > 1) {
              ref.read(navigationInfoProvider.notifier).goBackMy();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            padding: EdgeInsets.only(left: 16.w),
            width: 24.w,
            height: 24.w,
            child: SvgPicture.asset(
              'assets/icons/arrow_left_style=line.svg',
              width: 24.w,
              height: 24.w,
            ),
          ),
        ),
        leadingWidth: 40.w,
        actions: [
          SvgPicture.asset(
            'assets/icons/calendar_style=line.svg',
            width: 24.w,
            height: 24.w,
          ),
          SizedBox(width: 16.w),
          SvgPicture.asset(
            'assets/icons/alarm_style=line.svg',
            width: 24.w,
            height: 24.w,
          ),
          SizedBox(width: 16.w),
        ],
      ),
      body: const DrawerAnimatedSwitcher(),
    );
  }
}
