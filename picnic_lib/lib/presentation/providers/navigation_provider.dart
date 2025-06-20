import 'package:flutter/material.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/navigator/navigation_configs.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/pages/community/community_home_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/pic/pic_home_page.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
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
    final navigation = Navigation.initial();
    // 초기 화면을 설정
    return navigation.copyWith(currentScreen: const VoteHomeScreen());
  }

  Future<void> goBack() async {
    final voteNavigationStack = state.voteNavigationStack;

    if (voteNavigationStack != null && voteNavigationStack.length > 1) {
      voteNavigationStack.pop();
      final currentPage = voteNavigationStack.peek();
      state = state.copyWith(
        voteNavigationStack: voteNavigationStack,
        currentScreen: currentPage,
      );
    } else {
      logger.d('Cannot go back: stack has only one page or is null');
    }
  }

  Future<void> goBackCommunity() async {
    final communityNavigationStack = state.communityNavigationStack;

    if (communityNavigationStack != null &&
        communityNavigationStack.length > 1) {
      communityNavigationStack.pop();
      final currentPage = communityNavigationStack.peek();
      state = state.copyWith(
        communityNavigationStack: communityNavigationStack,
        currentScreen: currentPage,
      );
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
    // 먼저 포털 타입을 변경
    state = state.copyWith(portalType: portalType);

    // 포털에 따라 기본 페이지를 해당 NavigationStack에 설정
    switch (portalType) {
      case PortalType.vote:
        final votePage = NavigationConfigs.getPageWidget(PortalType.vote, 0) ??
            const VoteHomePage();
        if (state.voteNavigationStack == null ||
            state.voteNavigationStack!.isEmpty) {
          state = state.copyWith(
            voteNavigationStack: NavigationStack()..push(votePage),
            currentScreen: const VoteHomeScreen(),
          );
        } else {
          state = state.copyWith(currentScreen: const VoteHomeScreen());
        }
        break;

      case PortalType.community:
        final communityPage =
            NavigationConfigs.getPageWidget(PortalType.community, 0) ??
                const CommunityHomePage();
        if (state.communityNavigationStack == null ||
            state.communityNavigationStack!.isEmpty) {
          state = state.copyWith(
            communityNavigationStack: NavigationStack()..push(communityPage),
            currentScreen: const CommunityHomeScreen(),
          );
        } else {
          state = state.copyWith(currentScreen: const CommunityHomeScreen());
        }
        break;

      case PortalType.pic:
        final picPage = NavigationConfigs.getPageWidget(PortalType.pic, 0) ??
            const PicHomePage();
        if (state.voteNavigationStack == null ||
            state.voteNavigationStack!.isEmpty) {
          state = state.copyWith(
            voteNavigationStack: NavigationStack()..push(picPage),
            currentScreen: const PicHomeScreen(),
          );
        } else {
          state = state.copyWith(currentScreen: const PicHomeScreen());
        }
        break;

      case PortalType.novel:
        final novelPage =
            NavigationConfigs.getPageWidget(PortalType.novel, 0) ?? Container();
        if (state.voteNavigationStack == null ||
            state.voteNavigationStack!.isEmpty) {
          state = state.copyWith(
            voteNavigationStack: NavigationStack()..push(novelPage),
            currentScreen: const NovelHomeScreen(),
          );
        } else {
          state = state.copyWith(currentScreen: const NovelHomeScreen());
        }
        break;

      default:
        state = state.copyWith(currentScreen: const VoteHomeScreen());
    }

    globalStorage.saveData('portalString', portalType.name.toString());
  }

  void setShowBottomNavigation(bool showBottomNavigation) {
    state = state.copyWith(showBottomNavigation: showBottomNavigation);
  }

  int getBottomNavigationIndex() {
    if (state.portalType == PortalType.vote) {
      return state.voteBottomNavigationIndex;
    } else if (state.portalType == PortalType.pic) {
      return state.picBottomNavigationIndex;
    } else if (state.portalType == PortalType.community) {
      return state.communityBottomNavigationIndex;
    } else if (state.portalType == PortalType.novel) {
      return state.novelBottomNavigationIndex;
    } else {
      return 0;
    }
  }

  void setBottomNavigationIndex(int index) {
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

  void setPicBottomNavigationIndex(int index) {
    final pageWidget = NavigationConfigs.getPageWidget(PortalType.pic, index);
    if (pageWidget == null) return;

    state = state.copyWith(
      picBottomNavigationIndex: index,
      voteNavigationStack: NavigationStack()..push(pageWidget),
      currentScreen: pageWidget,
    );
    globalStorage.saveData('picBottomNavigationIndex', index.toString());
  }

  void setVoteBottomNavigationIndex(int index) {
    final pageWidget = NavigationConfigs.getPageWidget(PortalType.vote, index);
    if (pageWidget == null) return;

    state = state.copyWith(
      voteBottomNavigationIndex: index,
      voteNavigationStack: NavigationStack()..push(pageWidget),
      currentScreen: pageWidget,
    );
    globalStorage.saveData('voteBottomNavigationIndex', index.toString());
  }

  void setCommunityBottomNavigationIndex(int index) {
    final pageWidget =
        NavigationConfigs.getPageWidget(PortalType.community, index);
    if (pageWidget == null) return;

    state = state.copyWith(
      communityBottomNavigationIndex: index,
      communityNavigationStack: NavigationStack()..push(pageWidget),
      currentScreen: pageWidget,
    );
    globalStorage.saveData('communityBottomNavigationIndex', index.toString());
  }

  void setNovelBottomNavigationIndex(int index) {
    final pageWidget = NavigationConfigs.getPageWidget(PortalType.novel, index);
    if (pageWidget == null) return;

    state = state.copyWith(
      novelBottomNavigationIndex: index,
      voteNavigationStack: NavigationStack()..push(pageWidget),
      currentScreen: pageWidget,
    );
    globalStorage.saveData('novelBottomNavigationIndex', index.toString());
  }

  void setCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    final voteNavigationStack = state.voteNavigationStack;

    voteNavigationStack?.push(page);
    state = state.copyWith(
      voteNavigationStack: voteNavigationStack,
      showBottomNavigation: showBottomNavigation,
      currentScreen: page,
    );
  }

  void setCommunityCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    final communityNavigationStack = state.communityNavigationStack;

    communityNavigationStack?.push(page);
    logger.d('communityNavigationStack: $communityNavigationStack');
    state = state.copyWith(
      communityNavigationStack: communityNavigationStack,
      showBottomNavigation: showBottomNavigation,
      currentScreen: page,
    );
    logger.d('communityNavigationStack: $communityNavigationStack');
  }

  void setResetStackMyPage() {
    state = state.copyWith(
      drawerNavigationStack: NavigationStack()..push(const MyPage()),
    );
  }

  void setResetStackSignUp() {
    state = state.copyWith(
      signUpNavigationStack: NavigationStack()..push(const LoginPage()),
    );
  }

  void setCurrentMyPage(Widget page) {
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
