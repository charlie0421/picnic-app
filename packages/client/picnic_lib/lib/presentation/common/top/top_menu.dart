import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/presentation/common/common_my_point_info.dart';
import 'package:picnic_lib/presentation/common/top/top_right_common.dart';
import 'package:picnic_lib/presentation/common/top/top_right_community.dart';
import 'package:picnic_lib/presentation/common/top/top_right_post.dart';
import 'package:picnic_lib/presentation/common/top/top_right_post_view.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class TopMenu extends ConsumerStatefulWidget {
  const TopMenu({
    super.key,
  });

  @override
  ConsumerState<TopMenu> createState() => _TopState();
}

class _TopState extends ConsumerState<TopMenu> {
  @override
  void initState() {
    super.initState();
    // _setupRealtime();
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.watch(navigationInfoProvider.notifier);

    final String pageName = navigationInfo.pageTitle;

    return Container(
      height: 54,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Center(
              child: Text(
                Intl.message(pageName),
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: (navigationInfo.voteNavigationStack != null &&
                    navigationInfo.voteNavigationStack!.length > 1)
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      navigationInfoNotifier.goBack();
                    },
                    child: SizedBox(
                      width: 24.w,
                      height: 24,
                      child: SvgPicture.asset(
                        package: 'picnic_lib',
                        'assets/icons/arrow_left_style=line.svg',
                        width: 24.w,
                        height: 24,
                      ),
                    ),
                  )
                : const CommonMyPoint(),
          ),
          Positioned.fill(
              right: 0,
              top: 0,
              bottom: 0,
              child: navigationInfo.topRightMenu == TopRightType.none
                  ? Container()
                  : navigationInfo.topRightMenu == TopRightType.common
                      ? const TopRightCommon()
                      : navigationInfo.topRightMenu == TopRightType.board
                          ? const TopRightPost()
                          : navigationInfo.topRightMenu ==
                                  TopRightType.community
                              ? const TopRightCommunity()
                              : const TopRightPostView()),
        ],
      ),
    );
  }
}
