import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/area_selector.dart';
import 'package:picnic_lib/presentation/common/common_my_point_info.dart';
import 'package:picnic_lib/presentation/common/top/top_right_community.dart';
import 'package:picnic_lib/presentation/common/top/top_right_post.dart';
import 'package:picnic_lib/presentation/common/top/top_right_post_view.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';
import 'package:picnic_lib/navigation_stack.dart';

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

  bool _isVotePage(NavigationStack? stack) {
    if (stack == null) return false;
    final currentPage = stack.peek();
    return currentPage is VoteHomePage || currentPage is VoteListPage;
  }

  bool _shouldShowBackButton(Navigation navigationInfo) {
    switch (navigationInfo.portalType) {
      case PortalType.vote:
      case PortalType.pic:
      case PortalType.novel:
        return navigationInfo.voteNavigationStack != null &&
            navigationInfo.voteNavigationStack!.length > 1;
      case PortalType.community:
        return navigationInfo.communityNavigationStack != null &&
            navigationInfo.communityNavigationStack!.length > 1;
      default:
        return false;
    }
  }

  void _handleBackButtonTap(Navigation navigationInfo, navigationInfoNotifier) {
    switch (navigationInfo.portalType) {
      case PortalType.vote:
        navigationInfoNotifier.goBack();
        break;
      case PortalType.pic:
        navigationInfoNotifier.goBackPic();
        break;
      case PortalType.novel:
        navigationInfoNotifier.goBackNovel();
        break;
      case PortalType.community:
        navigationInfoNotifier.goBackCommunity();
        break;
      default:
        navigationInfoNotifier.goBack();
    }
  }

  Widget _buildTopRightMenu(Navigation navigationInfo) {
    if (navigationInfo.topRightMenu == TopRightType.none) {
      return Container();
    }

    if (navigationInfo.topRightMenu == TopRightType.common &&
        navigationInfo.portalType == PortalType.vote &&
        _isVotePage(navigationInfo.voteNavigationStack)) {
      return const AreaSelector();
    }

    if (navigationInfo.topRightMenu == TopRightType.board) {
      return const TopRightPost();
    }

    if (navigationInfo.topRightMenu == TopRightType.community) {
      return const TopRightCommunity();
    }

    if (navigationInfo.topRightMenu == TopRightType.postView) {
      return const TopRightPostView();
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.watch(navigationInfoProvider.notifier);

    // 로그인 상태를 감시하여 로그인 상태 변화 시 UI가 업데이트되도록 함
    final userInfo = ref.watch(userInfoProvider);
    final isLoggedIn = userInfo.value != null;

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
                pageName,
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _shouldShowBackButton(navigationInfo)
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _handleBackButtonTap(
                          navigationInfo, navigationInfoNotifier);
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
                : (navigationInfo.showMyPoint && isLoggedIn)
                    ? const CommonMyPoint()
                    : Container(),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildTopRightMenu(navigationInfo),
          ),
        ],
      ),
    );
  }
}
