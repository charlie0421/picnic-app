import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/top/top_right_common.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';
import 'package:picnic_lib/ui/style.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  static const String routeName = '/mypage';

  const MyPageScreen({super.key});

  @override
  MyPageScreenState createState() => MyPageScreenState();
}

class MyPageScreenState extends ConsumerState<MyPageScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final userInfoState = ref.watch(userInfoProvider);

    String pageName = navigationInfo.myPageTitle;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        logger.d('PopScope onPopInvokedWithResult: $didPop, $result');
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.grey00,
          foregroundColor: AppColors.grey900,
          leading: GestureDetector(
            onTap: () {
              if (navigationInfo.drawerNavigationStack != null &&
                  navigationInfo.drawerNavigationStack!.length > 1) {
                ref.read(navigationInfoProvider.notifier).goBackMy();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Container(
              padding: EdgeInsets.only(left: 16.w),
              width: 24.w,
              height: 24,
              child: SvgPicture.asset(
                package: 'picnic_lib',
                'assets/icons/arrow_left_style=line.svg',
                width: 24.w,
                height: 24,
              ),
            ),
          ),
          title: Text(t(pageName),
              style: getTextStyle(AppTypo.body16B, AppColors.grey900)),
          centerTitle: true,
          leadingWidth: 40.w,
          actions: [
            userInfoState.when(
                data: (data) => data != null && (data.isAdmin ?? false)
                    ? const TopRightCommon()
                    : Container(),
                loading: () => Container(),
                error: (error, stackTrace) => Container()),
            SizedBox(width: 16.w),
          ],
        ),
        body: const DrawerAnimatedSwitcher(),
      ),
    );
  }
}
