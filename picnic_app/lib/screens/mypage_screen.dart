import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/top/top_right_common.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class MyPageScreen extends ConsumerWidget {
  static const String routeName = '/mypage';

  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final userInfoState = ref.watch(userInfoProvider);

    String pageName;
    try {
      pageName =
          (navigationInfo.drawerNavigationStack?.peek() as dynamic).pageName;
    } catch (e) {
      if (e is NoSuchMethodError) {
        pageName = '';
      } else {
        rethrow;
      }
    }

    return Scaffold(
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
            padding: EdgeInsets.only(left: 16.cw),
            width: 24.cw,
            height: 24,
            child: SvgPicture.asset(
              'assets/icons/arrow_left_style=line.svg',
              width: 24.cw,
              height: 24,
            ),
          ),
        ),
        title: Text(Intl.message(pageName),
            style: getTextStyle(AppTypo.body16B, AppColors.grey900)),
        centerTitle: true,
        leadingWidth: 40.cw,
        actions: [
          userInfoState.when(
              data: (data) => data != null && data.is_admin
                  ? const TopRightCommon()
                  : Container(),
              loading: () => Container(),
              error: (error, stackTrace) => Container()),
          SizedBox(width: 16.cw),
        ],
      ),
      body: const DrawerAnimatedSwitcher(),
    );
  }
}
