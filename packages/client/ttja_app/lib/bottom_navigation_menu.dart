import 'package:flutter/material.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/community/board_list_page.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/pages/community/community_my_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/pic/gallery_page.dart';
import 'package:picnic_lib/presentation/pages/pic/library_page.dart';
import 'package:picnic_lib/presentation/pages/pic/pic_home_page.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_media_list_page.dart';

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
    needLogin: false,
  ),
  const BottomNavigationItem(
    title: 'nav_media',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 1,
    pageWidget: VoteMediaListPage(),
    needLogin: false,
  ),
  const BottomNavigationItem(
    title: 'nav_store',
    assetPath: 'assets/icons/bottom/store.svg',
    index: 2,
    pageWidget: StorePage(),
    needLogin: false,
  ),
];

List<BottomNavigationItem> picPages = [
  const BottomNavigationItem(
    title: 'nav_home',
    assetPath: 'assets/icons/bottom/home.svg',
    index: 0,
    pageWidget: PicHomePage(),
    needLogin: false,
  ),
  const BottomNavigationItem(
    title: 'nav_gallery',
    assetPath: 'assets/icons/bottom/gallery.svg',
    index: 1,
    pageWidget: GalleryPage(),
    needLogin: false,
  ),
  BottomNavigationItem(
    title: 'nav_subscription',
    assetPath: 'assets/icons/bottom/subscription.svg',
    index: 2,
    pageWidget: Container(),
    needLogin: false,
  ),
  const BottomNavigationItem(
    title: 'nav_library',
    assetPath: 'assets/icons/bottom/library.svg',
    index: 3,
    pageWidget: LibraryPage(),
    needLogin: false,
  ),
];

List<BottomNavigationItem> communityPages = [
  const BottomNavigationItem(
    title: 'nav_home',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 0,
    pageWidget: CommunityHomePage(),
    needLogin: false,
  ),
  const BottomNavigationItem(
    title: 'nav_board',
    assetPath: 'assets/icons/bottom/board.svg',
    index: 1,
    pageWidget: BoardListPage(),
    needLogin: false,
  ),
  const BottomNavigationItem(
    title: 'nav_my',
    assetPath: 'assets/icons/bottom/my.svg',
    index: 2,
    pageWidget: CommunityMyPage(),
    needLogin: true,
  ),
];

List<BottomNavigationItem> novelPages = [
  BottomNavigationItem(
    title: 'nav_home',
    assetPath: 'assets/icons/bottom/media.svg',
    index: 0,
    pageWidget: Container(),
    needLogin: false,
  ),
];

List<BottomNavigationItem> myPages = [
  const BottomNavigationItem(
    title: 'nav_my',
    assetPath: 'assets/icons/bottom/my.svg',
    index: 0,
    pageWidget: MyPage(),
    needLogin: true,
  ),
];
