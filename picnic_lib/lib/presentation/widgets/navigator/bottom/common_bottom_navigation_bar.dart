import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/community/board_list_page.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/pages/community/community_my_page.dart';
import 'package:picnic_lib/presentation/pages/pic/gallery_page.dart';
import 'package:picnic_lib/presentation/pages/pic/library_page.dart';
import 'package:picnic_lib/presentation/pages/pic/pic_home_page.dart';
import 'package:picnic_lib/presentation/pages/vote/pic_chart_page.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_media_list_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/menu_item.dart';

class CommonBottomNavigationBar extends ConsumerWidget {
  const CommonBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final userInfoState = ref.watch(userInfoProvider);

    // 각 포털 타입에 따른 ScreenInfo 객체 생성
    final Map<String, ScreenInfo> screenInfoMap = {
      PortalType.vote.name: ScreenInfo(
        type: PortalType.vote,
        color: voteMainColor,
        pages: const [
          BottomNavigationItem(
            title: 'nav_vote',
            assetPath: 'assets/icons/bottom/vote.svg',
            index: 0,
            pageWidget: VoteHomePage(),
            needLogin: false,
          ),
          BottomNavigationItem(
            title: 'nav_picchart',
            assetPath: 'assets/icons/bottom/pic_chart.svg',
            index: 1,
            pageWidget: PicChartPage(),
            needLogin: false,
          ),
          BottomNavigationItem(
            title: 'nav_media',
            assetPath: 'assets/icons/bottom/media.svg',
            index: 2,
            pageWidget: VoteMediaListPage(),
            needLogin: false,
          ),
          BottomNavigationItem(
            title: 'nav_store',
            assetPath: 'assets/icons/bottom/store.svg',
            index: 3,
            pageWidget: StorePage(),
            needLogin: false,
          ),
        ],
      ),
      PortalType.pic.name: ScreenInfo(
        type: PortalType.pic,
        color: picMainColor,
        pages: const [
          BottomNavigationItem(
            title: 'nav_home',
            assetPath: 'assets/icons/bottom/home.svg',
            index: 0,
            pageWidget: PicHomePage(),
            needLogin: false,
          ),
          BottomNavigationItem(
            title: 'nav_gallery',
            assetPath: 'assets/icons/bottom/gallery.svg',
            index: 1,
            pageWidget: GalleryPage(),
            needLogin: false,
          ),
          BottomNavigationItem(
            title: 'nav_library',
            assetPath: 'assets/icons/bottom/library.svg',
            index: 3,
            pageWidget: LibraryPage(),
            needLogin: false,
          ),
        ],
      ),
      PortalType.community.name: ScreenInfo(
        type: PortalType.community,
        color: communityMainColor,
        pages: const [
          BottomNavigationItem(
            title: 'nav_home',
            assetPath: 'assets/icons/bottom/media.svg',
            index: 0,
            pageWidget: CommunityHomePage(),
            needLogin: false,
          ),
          BottomNavigationItem(
            title: 'nav_board',
            assetPath: 'assets/icons/bottom/board.svg',
            index: 1,
            pageWidget: BoardListPage(),
            needLogin: false,
          ),
          BottomNavigationItem(
            title: 'nav_my',
            assetPath: 'assets/icons/bottom/my.svg',
            index: 2,
            pageWidget: CommunityMyPage(),
            needLogin: true,
          ),
        ],
      ),
    };

    final screenInfo = screenInfoMap[navigationInfo.portalType.name];

    if (screenInfo == null) {
      return const SizedBox();
    }

    return userInfoState.when(
      data: (data) {
        return Container(
          margin: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: 0,
          ),
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
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            decoration: ShapeDecoration(
              color: screenInfo.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              shadows: [
                BoxShadow(
                  color: const Color(0x3F000000),
                  blurRadius: 8,
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
                        needLogin: e.needLogin,
                      ))
                  .toList(),
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (e, s) {
        return const SizedBox();
      },
    );
  }
}
