import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/pages/fan/fan_home_page.dart';
import 'package:picnic_app/pages/fan/gallery_page.dart';
import 'package:picnic_app/pages/fan/landing_page.dart';
import 'package:picnic_app/pages/vote/vote_home.dart';
import 'package:picnic_app/screens/fan/fan_screen.dart';

ScreenInfo voteScreenInfo = ScreenInfo(
  type: 'vote',
  color: voteMainColor,
  pages: votePages,
);

ScreenInfo fanScreenInfo = ScreenInfo(
  type: 'fan',
  color: fanMainColor,
  pages: fanPages,
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

class ScreenInfo {
  String type;
  Color color;
  List<BottomNavigationItem> pages;

  ScreenInfo({required this.type, required this.color, required this.pages});
}

List<BottomNavigationItem> votePages = [
  const BottomNavigationItem(
    title: 'nav_home',
    icon: Icons.home,
    index: 0,
    pageWidget: VoteHomePage(),
  ),
  const BottomNavigationItem(
    title: '투표',
    icon: Icons.how_to_vote_sharp,
    index: 1,
    pageWidget: SizedBox.shrink(),
  ),
  const BottomNavigationItem(
    title: '상점',
    icon: Icons.storefront,
    index: 2,
    pageWidget: SizedBox.shrink(),
  ),
  const BottomNavigationItem(
    title: '미디어',
    icon: Icons.photo,
    index: 3,
    pageWidget: SizedBox.shrink(),
  ),
];

List<BottomNavigationItem> fanPages = [
  const BottomNavigationItem(
    title: 'nav_home',
    icon: Icons.home,
    index: 0,
    pageWidget: FanHomePage(),
  ),
  const BottomNavigationItem(
    title: 'nav_gallery',
    icon: Icons.photo,
    index: 1,
    pageWidget: GalleryPage(),
  ),
  const BottomNavigationItem(
    title: 'nav_library',
    icon: Icons.library_books,
    index: 2,
    pageWidget: FanScreen(),
  ),
  const BottomNavigationItem(
    title: 'nav_purchases',
    icon: Icons.wallet,
    index: 3,
    pageWidget: SizedBox.shrink(),
  ),
  const BottomNavigationItem(
    title: 'nav_setting',
    icon: Icons.settings,
    index: 4,
    pageWidget: const LandingPage(),
  ),
];

List<BottomNavigationItem> communityPages = [
  const BottomNavigationItem(
    title: 'nav_home',
    icon: Icons.home,
    index: 0,
    pageWidget: SizedBox.shrink(),
  ),
];

List<BottomNavigationItem> novelPages = [
  const BottomNavigationItem(
    title: 'nav_home',
    icon: Icons.home,
    index: 0,
    pageWidget: SizedBox.shrink(),
  ),
];

class BottomNavigationItem {
  final String title;
  final IconData icon;
  final int index;
  final Widget pageWidget;

  const BottomNavigationItem({
    required this.title,
    required this.icon,
    required this.index,
    required this.pageWidget,
  });
}
