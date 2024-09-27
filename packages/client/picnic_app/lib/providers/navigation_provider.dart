import 'package:flutter/material.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/navigation_stack.dart';
import 'package:picnic_app/pages/mypage/mypage.dart';
import 'package:picnic_app/pages/signup/login_page.dart';
import 'package:picnic_app/screens/community/community_home_screen.dart';
import 'package:picnic_app/screens/novel/novel_home_screen.dart';
import 'package:picnic_app/screens/pic/pic_home_screen.dart';
import 'package:picnic_app/screens/vote/vote_home_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

@Riverpod(keepAlive: true)
class NavigationInfo extends _$NavigationInfo {
  Navigation setting = Navigation.initial();

  NavigationInfo() {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    await setting.load();
  }

  @override
  Navigation build() {
    return setting;
  }

  setPortal(PortalType portalType) {
    Widget currentScreen;
    Widget currentPage;
    switch (portalType) {
      case PortalType.vote:
        currentScreen = const VoteHomeScreen();
        currentPage = votePages[state.voteBottomNavigationIndex].pageWidget;
        break;
      case PortalType.pic:
        currentScreen = const PicHomeScreen();
        currentPage = picPages[state.picBottomNavigationIndex].pageWidget;
        break;
      case PortalType.community:
        currentScreen = const CommunityHomeScreen();
        currentPage =
            communityPages[state.communityBottomNavigationIndex].pageWidget;
        break;
      case PortalType.novel:
        currentScreen = const NovelHomeScreen();
        currentPage = novelPages[state.novelBottomNavigationIndex].pageWidget;
        break;
      default:
        currentScreen = const VoteHomeScreen();
        currentPage = votePages[state.voteBottomNavigationIndex].pageWidget;
    }

    state = state.copyWith(
      portalType: portalType,
      currentScreen: currentScreen,
      voteNavigationStack: NavigationStack()..push(currentPage),
    );
    globalStorage.saveData('portalString', portalType.name.toString());
  }

  setShowBottomNavigation(bool showBottomNavigation) {
    state = state.copyWith(showBottomNavigation: showBottomNavigation);
  }

  getBottomNavigationIndex() {
    if (state.portalType == PortalType.vote) {
      return state.voteBottomNavigationIndex;
    } else if (state.portalType == PortalType.pic) {
      return state.picBottomNavigationIndex;
    } else if (state.portalType == PortalType.community) {
      return state.communityBottomNavigationIndex;
    } else if (state.portalType == PortalType.novel) {
      return state.novelBottomNavigationIndex;
    }
  }

  setBottomNavigationIndex(int index) {
    if (state.portalType == PortalType.vote) {
      setVoteBottomNavigationIndex(index);
    } else if (state.portalType == PortalType.pic) {
      setPicBottomNavigationIndex(index);
    } else if (state.portalType == PortalType.community) {
      setCommunityBottomNavigationIndex(index);
    } else if (state.portalType == PortalType.novel) {
      setNovelBottomNavigationIndex(index);
    }
  }

  void settingNavigation({
    required bool showPortal,
    required bool showBottomNavigation,
    required bool showTopMenu,
    TopRightType? topRightMenu,
    String? pageTitle,
  }) {
    state = state.copyWith(
      showPortal: showPortal,
      showBottomNavigation: showBottomNavigation,
      showTopMenu: showTopMenu,
      topRightMenu: topRightMenu ?? TopRightType.common,
      pageTitle: pageTitle ?? '',
    );
  }

  void setCurrentArtistId(int artistId, String artistName) {
    state = state.copyWith(
      currentArtistId: artistId,
    );
  }

  setPicBottomNavigationIndex(int index) {
    state = state.copyWith(
      picBottomNavigationIndex: index,
    );
    state = state.copyWith(
      voteNavigationStack: NavigationStack()..push(picPages[index].pageWidget),
    );
    globalStorage.saveData('picBottomNavigationIndex', index.toString());
  }

  setVoteBottomNavigationIndex(int index) {
    state = state.copyWith(
        voteBottomNavigationIndex: index,
        voteNavigationStack: NavigationStack()
          ..push(votePages[index].pageWidget));
    globalStorage.saveData('voteBottomNavigationIndex', index.toString());
  }

  setCommunityBottomNavigationIndex(int index) {
    state = state.copyWith(
        communityBottomNavigationIndex: index,
        voteNavigationStack: NavigationStack()
          ..push(communityPages[index].pageWidget));
    globalStorage.saveData('communityBottomNavigationIndex', index.toString());
  }

  setNovelBottomNavigationIndex(int index) {
    state = state.copyWith(
        novelBottomNavigationIndex: index,
        voteNavigationStack: NavigationStack()
          ..push(novelPages[index].pageWidget));
    globalStorage.saveData('novelBottomNavigationIndex', index.toString());
  }

  setCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    final voteNavigationStack = state.voteNavigationStack;

    voteNavigationStack?.push(page);
    logger.d('voteNavigationStack: $voteNavigationStack');
    state = state.copyWith(
      voteNavigationStack: voteNavigationStack,
      showBottomNavigation: showBottomNavigation,
    );
    logger.d('voteNavigationStack: $voteNavigationStack');
  }

  setResetStackMyPage() {
    state = state.copyWith(
      drawerNavigationStack: NavigationStack()..push(const MyPage()),
    );
  }

  setResetStackSignUp() {
    state = state.copyWith(
      signUpNavigationStack: NavigationStack()..push(const LoginPage()),
    );
  }

  setCurrentMyPage(Widget page) {
    final navigationStack = state.drawerNavigationStack;

    if (navigationStack?.peek() == page) {
      return;
    }

    navigationStack?.push(page);

    state = state.copyWith(
        drawerNavigationStack: navigationStack,
        showTopMenu: true,
        showBottomNavigation: true);
  }

  setCurrentSignUpPage(Widget page) {
    final navigationStack = state.signUpNavigationStack;

    if (navigationStack?.peek() == page) {
      return;
    }

    navigationStack?.push(page);

    state = state.copyWith(
        signUpNavigationStack: navigationStack,
        showTopMenu: true,
        showBottomNavigation: true);
  }

  goBack() {
    final voteNavigationStack = state.voteNavigationStack;

    if (voteNavigationStack == null || voteNavigationStack.length <= 1) {
      return;
    }
    voteNavigationStack.pop();

    state = state.copyWith(voteNavigationStack: voteNavigationStack);
  }

  goBackMy() {
    final navigationStack = state.drawerNavigationStack;
    navigationStack?.pop();

    state = state.copyWith(drawerNavigationStack: navigationStack);
  }

  goBackSignUp() {
    final navigationStack = state.signUpNavigationStack;
    navigationStack?.pop();

    state = state.copyWith(signUpNavigationStack: navigationStack);
  }
}
