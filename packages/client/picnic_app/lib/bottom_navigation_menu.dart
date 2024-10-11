import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/pages/community/board_page.dart';
import 'package:picnic_app/pages/community/community_home_page.dart';
import 'package:picnic_app/pages/community/community_my_page.dart';
import 'package:picnic_app/pages/pic/gallery_page.dart';
import 'package:picnic_app/pages/pic/library_page.dart';
import 'package:picnic_app/pages/pic/pic_home_page.dart';
import 'package:picnic_app/pages/vote/pic_chart_page.dart';
import 'package:picnic_app/pages/vote/store_page.dart';
import 'package:picnic_app/pages/vote/vote_home_page.dart';
import 'package:picnic_app/pages/vote/vote_media_list_page.dart';

ScreenInfo voteScreenInfo = ScreenInfo(
  type: PortalType.vote,
  color: voteMainColor,
  pages: votePages,
);

ScreenInfo picScreenInfo = ScreenInfo(
  type: PortalType.pic,
  color: picMainColor,
  pages: picPages,
);

ScreenInfo communityScreenInfo = ScreenInfo(
  type: PortalType.community,
  color: communityMainColor,
  pages: communityPages,
);

ScreenInfo novelScreenInfo = ScreenInfo(
  type: PortalType.novel,
  color: novelMainColor,
  pages: novelPages,
);

List<BottomNavigationItem> votePages = [
  const BottomNavigationItem(
    title: 'nav_vote',
    assetPath: 'assets/icons/bottom/vote.svg',
    index: 0,
    pageWidget: VoteHomePage(),
  ),
  const BottomNavigationItem(
    title: 'nav_picchart',
    assetPath: 'assets/icons/bottom/pic_chart.svg',
    index: 1,
    pageWidget: PicChartPage(),
  ),
  const BottomNavigationItem(
    title: 'nav_media',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 2,
    pageWidget: VoteMediaListPage(),
  ),
  const BottomNavigationItem(
    title: 'nav_store',
    assetPath: 'assets/icons/bottom/store.svg',
    index: 3,
    pageWidget: StorePage(),
  ),
];

List<BottomNavigationItem> picPages = [
  const BottomNavigationItem(
    title: 'nav_home',
    assetPath: 'assets/icons/bottom/home.svg',
    index: 0,
    pageWidget: PicHomePage(),
  ),
  const BottomNavigationItem(
    title: 'nav_gallery',
    assetPath: 'assets/icons/bottom/gallery.svg',
    index: 1,
    pageWidget: GalleryPage(),
  ),
  BottomNavigationItem(
    title: 'nav_subscription',
    assetPath: 'assets/icons/bottom/subscription.svg',
    index: 2,
    pageWidget: Container(),
  ),
  const BottomNavigationItem(
    title: 'nav_library',
    assetPath: 'assets/icons/bottom/library.svg',
    index: 3,
    pageWidget: LibraryPage(),
  ),
];

List<BottomNavigationItem> communityPages = [
  const BottomNavigationItem(
    title: 'nav_home',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 0,
    pageWidget: CommunityHomePage(),
  ),
  const BottomNavigationItem(
    title: 'nav_board',
    assetPath: 'assets/icons/bottom/board.svg',
    index: 1,
    pageWidget: BoardPage(),
  ),
  const BottomNavigationItem(
    title: 'nav_my',
    assetPath: 'assets/icons/bottom/my.svg',
    index: 2,
    pageWidget: CommunityMyPage(),
  ),
];

List<BottomNavigationItem> novelPages = [
  BottomNavigationItem(
    title: 'nav_home',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 0,
    pageWidget: Container(),
  ),
];

class BottomNavigationItem {
  final String title;
  final String assetPath;
  final int index;
  final Widget pageWidget;

  const BottomNavigationItem({
    required this.title,
    required this.assetPath,
    required this.index,
    required this.pageWidget,
  });
}

class ScreenInfo {
  PortalType type;
  Color color;
  List<BottomNavigationItem> pages;

  ScreenInfo({required this.type, required this.color, required this.pages});
}
