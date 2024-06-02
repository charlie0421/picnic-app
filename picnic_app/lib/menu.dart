import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/pages/pic/gallery_page.dart';
import 'package:picnic_app/pages/pic/landing_page.dart';
import 'package:picnic_app/pages/pic/library_page.dart';
import 'package:picnic_app/pages/pic/pic_home_page.dart';
import 'package:picnic_app/pages/vote/pick-chart-page.dart';
import 'package:picnic_app/pages/vote/store-page.dart';
import 'package:picnic_app/pages/vote/vote_home_page.dart';

ScreenInfo voteScreenInfo = ScreenInfo(
  type: 'vote',
  color: voteMainColor,
  pages: votePages,
);

ScreenInfo picScreenInfo = ScreenInfo(
  type: 'pic',
  color: picMainColor,
  pages: picPages,
);

ScreenInfo communityScreenInfo = ScreenInfo(
  type: 'community',
  color: communityMainColor,
  pages: communityPages,
);

ScreenInfo novelScreenInfo = ScreenInfo(
  type: 'novel',
  color: novelMainColor,
  pages: novelPages,
);

List<BottomNavigationItem> votePages = [
  const BottomNavigationItem(
    title: '투표',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 0,
    pageWidget: VoteHomePage(),
  ),
  BottomNavigationItem(
    title: '픽차트',
    assetPath: 'assets/icons/bottom/pic-chart.svg',
    index: 1,
    pageWidget: PicChartPage(),
  ),
  BottomNavigationItem(
    title: '미디어',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 2,
    pageWidget: Container(),
  ),
  BottomNavigationItem(
    title: '상점',
    assetPath: 'assets/icons/bottom/store.svg',
    index: 3,
    pageWidget: StorePage(),
  ),
];

List<BottomNavigationItem> picPages = [
  const BottomNavigationItem(
    title: 'nav_home',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 0,
    pageWidget: PicHomePage(),
  ),
  const BottomNavigationItem(
    title: 'nav_gallery',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 1,
    pageWidget: GalleryPage(),
  ),
  const BottomNavigationItem(
    title: 'nav_library',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 2,
    pageWidget: LibraryPage(),
  ),
  BottomNavigationItem(
    title: 'nav_purchases',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 3,
    pageWidget: Container(),
  ),
  const BottomNavigationItem(
    title: 'nav_setting',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 4,
    pageWidget: LandingPage(),
  ),
];

List<BottomNavigationItem> communityPages = [
  BottomNavigationItem(
    title: 'nav_home',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 0,
    pageWidget: Container(),
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
  String type;
  Color color;
  List<BottomNavigationItem> pages;

  ScreenInfo({required this.type, required this.color, required this.pages});
}
