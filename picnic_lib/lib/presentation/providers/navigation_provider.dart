import 'package:flutter/material.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/navigator/navigation_configs.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/screens/community/community_home_screen.dart';
import 'package:picnic_lib/presentation/screens/novel/novel_home_screen.dart';
import 'package:picnic_lib/presentation/screens/pic/pic_home_screen.dart';
import 'package:picnic_lib/presentation/screens/vote/vote_home_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/navigation_provider.g.dart';

@Riverpod(keepAlive: true)
class NavigationInfo extends _$NavigationInfo {
  @override
  Navigation build() {
    return Navigation.initial();
  }

  Future<void> goBack() async {
    final voteNavigationStack = state.voteNavigationStack;

    if (voteNavigationStack != null && voteNavigationStack.length > 1) {
      voteNavigationStack.pop();
      state = state.copyWith(voteNavigationStack: voteNavigationStack);
    } else {
      logger.d('Cannot go back: stack has only one page or is null');
    }
  }

  Future<void> goBackCommunity() async {
    final communityNavigationStack = state.communityNavigationStack;

    if (communityNavigationStack != null &&
        communityNavigationStack.length > 1) {
      communityNavigationStack.pop();
      state =
          state.copyWith(communityNavigationStack: communityNavigationStack);
    } else {
      logger.d('Cannot go back: stack has only one page or is null');
    }
  }

  Future<void> goBackMyPage() async {
    final drawerNavigationStack = state.drawerNavigationStack;

    if (drawerNavigationStack != null && drawerNavigationStack.length > 1) {
      drawerNavigationStack.pop();
      state = state.copyWith(drawerNavigationStack: drawerNavigationStack);
    } else {
      logger.d('Cannot go back: stack has only one page or is null');
    }
  }

  Widget getScreen() {
    switch (state.portalType) {
      case PortalType.vote:
        return const VoteHomeScreen();
      case PortalType.pic:
        return const PicHomeScreen();
      case PortalType.community:
        return const CommunityHomeScreen();
      case PortalType.novel:
        return const NovelHomeScreen();
      default:
        return const VoteHomeScreen();
    }
  }

  void setPortal(PortalType portalType) {
    state = state.copyWith(portalType: portalType);
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
    bool? showMyPoint,
    TopRightType? topRightMenu,
    String? pageTitle,
  }) {
    state = state.copyWith(
      showPortal: showPortal,
      showBottomNavigation: showBottomNavigation,
      showTopMenu: showTopMenu,
      showMyPoint: showMyPoint ?? true,
      topRightMenu: topRightMenu ?? TopRightType.common,
      pageTitle: pageTitle ?? '',
    );
  }

  void setPageTitle({required String pageTitle}) {
    state = state.copyWith(pageTitle: pageTitle);
  }

  void setMyPageTitle({required String pageTitle}) {
    state = state.copyWith(myPageTitle: pageTitle);
  }

  setPicBottomNavigationIndex(int index) {
    final pageWidget = NavigationConfigs.getPageWidget(PortalType.pic, index);
    if (pageWidget == null) return;

    state = state.copyWith(
      picBottomNavigationIndex: index,
      voteNavigationStack: NavigationStack()..push(pageWidget),
    );
    globalStorage.saveData('picBottomNavigationIndex', index.toString());
  }

  setVoteBottomNavigationIndex(int index) {
    final pageWidget = NavigationConfigs.getPageWidget(PortalType.vote, index);
    if (pageWidget == null) return;

    state = state.copyWith(
      voteBottomNavigationIndex: index,
      voteNavigationStack: NavigationStack()..push(pageWidget),
    );
    globalStorage.saveData('voteBottomNavigationIndex', index.toString());
  }

  setCommunityBottomNavigationIndex(int index) {
    final pageWidget =
        NavigationConfigs.getPageWidget(PortalType.community, index);
    if (pageWidget == null) return;

    state = state.copyWith(
      communityBottomNavigationIndex: index,
      voteNavigationStack: NavigationStack()..push(pageWidget),
    );
    globalStorage.saveData('communityBottomNavigationIndex', index.toString());
  }

  setNovelBottomNavigationIndex(int index) {
    final pageWidget = NavigationConfigs.getPageWidget(PortalType.novel, index);
    if (pageWidget == null) return;

    state = state.copyWith(
      novelBottomNavigationIndex: index,
      voteNavigationStack: NavigationStack()..push(pageWidget),
    );
    globalStorage.saveData('novelBottomNavigationIndex', index.toString());
  }

  setCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    final voteNavigationStack = state.voteNavigationStack;

    voteNavigationStack?.push(page);
    state = state.copyWith(
      voteNavigationStack: voteNavigationStack,
      showBottomNavigation: showBottomNavigation,
    );
  }

  setCommunityCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    final communityNavigationStack = state.voteNavigationStack;

    communityNavigationStack?.push(page);
    logger.d('voteNavigationStack: $communityNavigationStack');
    state = state.copyWith(
      voteNavigationStack: communityNavigationStack,
      showBottomNavigation: showBottomNavigation,
    );
    logger.d('voteNavigationStack: $communityNavigationStack');
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
    logger.i('🎯 setCurrentMyPage called with page: ${page.runtimeType}');
    final navigationStack = state.drawerNavigationStack;

    if (navigationStack?.peek() == page) {
      logger.i('🎯 Page already on top of stack, skipping');
      return;
    }

    logger.i('🎯 Pushing page to drawerNavigationStack');
    navigationStack?.push(page);

    state = state.copyWith(
        drawerNavigationStack: navigationStack,
        showTopMenu: true,
        showBottomNavigation: true);

    logger.i('🎯 Navigation state updated successfully');
  }

  void setCurrentSignUpPage(Widget page) {
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

  void goBackSignUp() {
    final signUpNavigationStack = state.signUpNavigationStack;

    if (signUpNavigationStack != null && signUpNavigationStack.length > 1) {
      signUpNavigationStack.pop();
      state = state.copyWith(signUpNavigationStack: signUpNavigationStack);
    } else {
      logger.d('Cannot go back: stack has only one page or is null');
    }
  }
}
