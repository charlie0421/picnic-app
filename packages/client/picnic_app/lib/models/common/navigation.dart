import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/navigation_stack.dart';
import 'package:picnic_app/pages/mypage/mypage.dart';
import 'package:picnic_app/pages/signup/login_page.dart';
import 'package:picnic_app/pages/vote/vote_home_page.dart';
import 'package:picnic_app/reflector.dart';
import 'package:picnic_app/screens/community/community_home_screen.dart';
import 'package:picnic_app/screens/mypage_screen.dart';
import 'package:picnic_app/screens/novel/novel_home_screen.dart';
import 'package:picnic_app/screens/pic/pic_home_screen.dart';
import 'package:picnic_app/screens/vote/vote_home_screen.dart';

part 'navigation.freezed.dart';

enum TopRightType { none, common, board }

@reflector
@freezed
class Navigation with _$Navigation {
  const Navigation._();

  const factory Navigation({
    @Default(PortalType.vote) PortalType portalType,
    @Default(0) int picBottomNavigationIndex,
    @Default(0) int voteBottomNavigationIndex,
    @Default(0) int communityBottomNavigationIndex,
    @Default(0) int novelBottomNavigationIndex,
    @Default(VoteHomeScreen()) Widget currentScreen,
    @Default(true) bool showPortal,
    @Default(true) bool showTopMenu,
    @Default(TopRightType.common) TopRightType topRightMenu,
    @Default(true) bool showBottomNavigation,
    @Default('') String pageTitle,
    @Default(0) int currentArtistId,
    @Default('') String currentBoardId,
    NavigationStack? voteNavigationStack,
    NavigationStack? drawerNavigationStack,
    NavigationStack? signUpNavigationStack,
  }) = _Navigation;

  factory Navigation.initial() {
    return Navigation(
      voteNavigationStack: NavigationStack()..push(const VoteHomePage()),
      drawerNavigationStack: NavigationStack()..push(const MyPage()),
      signUpNavigationStack: NavigationStack()..push(const LoginPage()),
    );
  }

  Future<Navigation> load() async {
    String? portalString = await globalStorage.loadData(
        'portalString', PortalType.vote.name.toString());
    String? voteBottomNavigationIndexString =
        await globalStorage.loadData('voteBottomNavigationIndex', '0');
    String? picBottomNavigationIndexString =
        await globalStorage.loadData('picBottomNavigationIndex', '0');
    String? communityBottomNavigationIndexString =
        await globalStorage.loadData('communityBottomNavigationIndex', '0');
    String? novelBottomNavigationIndexString =
        await globalStorage.loadData('novelBottomNavigationIndex', '0');

    PortalType newPortalType = PortalTypeExtension.fromString(
        portalString ?? PortalType.vote.name.toString());
    int newVoteBottomNavigationIndex =
        int.parse(voteBottomNavigationIndexString!);
    int newPicBottomNavigationIndex =
        int.parse(picBottomNavigationIndexString!);
    int newCommunityBottomNavigationIndex =
        int.parse(communityBottomNavigationIndexString!);
    int newNovelBottomNavigationIndex =
        int.parse(novelBottomNavigationIndexString!);

    Widget newCurrentScreen;
    NavigationStack newVoteNavigationStack;

    switch (newPortalType) {
      case PortalType.vote:
        newCurrentScreen = const VoteHomeScreen();
        newVoteNavigationStack = NavigationStack()
          ..push(votePages[newVoteBottomNavigationIndex].pageWidget);
        break;
      case PortalType.pic:
        newCurrentScreen = const PicHomeScreen();
        newVoteNavigationStack = NavigationStack()
          ..push(picPages[newPicBottomNavigationIndex].pageWidget);
        break;
      case PortalType.community:
        newCurrentScreen = const CommunityHomeScreen();
        newVoteNavigationStack = NavigationStack()
          ..push(communityPages[newCommunityBottomNavigationIndex].pageWidget);
        break;
      case PortalType.novel:
        newCurrentScreen = const NovelHomeScreen();
        newVoteNavigationStack = NavigationStack()
          ..push(novelPages[newNovelBottomNavigationIndex].pageWidget);
        break;
      case PortalType.mypage:
        newCurrentScreen = const MyPageScreen();
        newVoteNavigationStack = NavigationStack()..push(const MyPage());
        break;
      default:
        newCurrentScreen = const VoteHomeScreen();
        newVoteNavigationStack = NavigationStack()..push(const VoteHomePage());
    }

    return copyWith(
      portalType: newPortalType,
      picBottomNavigationIndex: newPicBottomNavigationIndex,
      voteBottomNavigationIndex: newVoteBottomNavigationIndex,
      communityBottomNavigationIndex: newCommunityBottomNavigationIndex,
      novelBottomNavigationIndex: newNovelBottomNavigationIndex,
      currentScreen: newCurrentScreen,
      voteNavigationStack: newVoteNavigationStack,
    );
  }

  int getBottomNavigationIndex() {
    switch (portalType) {
      case PortalType.vote:
        return voteBottomNavigationIndex;
      case PortalType.pic:
        return picBottomNavigationIndex;
      case PortalType.community:
        return communityBottomNavigationIndex;
      case PortalType.novel:
        return novelBottomNavigationIndex;
      default:
        return 0;
    }
  }
}
