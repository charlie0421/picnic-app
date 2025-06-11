import 'package:flutter/material.dart';
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

class NavigationConfigs {
  static final Map<PortalType, ScreenInfo> _screenInfoMap = {
    PortalType.vote: ScreenInfo(
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
    PortalType.pic: ScreenInfo(
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
    PortalType.community: ScreenInfo(
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
    PortalType.novel: ScreenInfo(
      type: PortalType.novel,
      color: novelMainColor,
      pages: [
        BottomNavigationItem(
          title: 'nav_home',
          assetPath: 'assets/icons/bottom/media.svg',
          index: 0,
          pageWidget: Container(),
          needLogin: false,
        ),
      ],
    ),
  };

  /// 특정 포털 타입의 ScreenInfo를 반환
  static ScreenInfo? getScreenInfo(PortalType portalType) {
    return _screenInfoMap[portalType];
  }

  /// 특정 포털 타입의 페이지 목록을 반환
  static List<BottomNavigationItem> getPages(PortalType portalType) {
    return _screenInfoMap[portalType]?.pages ?? [];
  }

  /// 특정 포털 타입과 인덱스에 해당하는 페이지 위젯을 반환
  static Widget? getPageWidget(PortalType portalType, int index) {
    final pages = getPages(portalType);
    if (index >= 0 && index < pages.length) {
      return pages[index].pageWidget;
    }
    return null;
  }

  /// 모든 ScreenInfo 맵을 반환 (기존 호환성을 위해)
  static Map<String, ScreenInfo> get screenInfoMap {
    return _screenInfoMap.map((key, value) => MapEntry(key.name, value));
  }
}
