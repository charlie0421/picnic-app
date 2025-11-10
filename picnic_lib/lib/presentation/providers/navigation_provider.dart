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
import 'package:picnic_lib/presentation/pages/community/compatibility_list_page.dart';
import 'package:picnic_lib/presentation/screens/community/community_home_screen.dart';
import 'package:picnic_lib/presentation/screens/goong_hap/goong_hap_home_screen.dart';
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
      logger.d('📱 Going back to page: ${currentPage.runtimeType}');
      logger.d('📱 Stack length after pop: ${voteNavigationStack.length}');

      final isAtRoot = voteNavigationStack.length <= 1;
      state = state.copyWith(
        voteNavigationStack: voteNavigationStack,
        currentScreen: currentPage,
        // 루트로 돌아오면 포탈/탑메뉴/바텀네비 복원
        showPortal: isAtRoot ? true : state.showPortal,
        showTopMenu: isAtRoot ? true : state.showTopMenu,
        showBottomNavigation: isAtRoot ? true : state.showBottomNavigation,
      );
    } else {
      logger.d('📱 Cannot go back: stack has only one page or is null');
    }
  }

  Future<void> goBackPic() async {
    // PIC은 현재 vote 스택을 사용
    final voteNavigationStack = state.voteNavigationStack;

    if (voteNavigationStack != null && voteNavigationStack.length > 1) {
      voteNavigationStack.pop();
      final currentPage = voteNavigationStack.peek();
      logger.d('🖼️ Going back to PIC page: ${currentPage.runtimeType}');
      logger.d('🖼️ Stack length after pop: ${voteNavigationStack.length}');

      final isAtRoot = voteNavigationStack.length <= 1;
      state = state.copyWith(
        voteNavigationStack: voteNavigationStack,
        currentScreen: currentPage,
        showPortal: isAtRoot ? true : state.showPortal,
        showTopMenu: isAtRoot ? true : state.showTopMenu,
        showBottomNavigation: isAtRoot ? true : state.showBottomNavigation,
      );
    } else {
      logger.d('🖼️ Cannot go back: PIC stack has only one page or is null');
    }
  }

  Future<void> goBackNovel() async {
    // NOVEL도 현재 vote 스택을 사용
    final voteNavigationStack = state.voteNavigationStack;

    if (voteNavigationStack != null && voteNavigationStack.length > 1) {
      voteNavigationStack.pop();
      final currentPage = voteNavigationStack.peek();
      logger.d('📚 Going back to NOVEL page: ${currentPage.runtimeType}');
      logger.d('📚 Stack length after pop: ${voteNavigationStack.length}');

      final isAtRoot = voteNavigationStack.length <= 1;
      state = state.copyWith(
        voteNavigationStack: voteNavigationStack,
        currentScreen: currentPage,
        showPortal: isAtRoot ? true : state.showPortal,
        showTopMenu: isAtRoot ? true : state.showTopMenu,
        showBottomNavigation: isAtRoot ? true : state.showBottomNavigation,
      );
    } else {
      logger.d('📚 Cannot go back: NOVEL stack has only one page or is null');
    }
  }

  Future<void> goBackCommunity() async {
    final communityNavigationStack = state.communityNavigationStack;

    if (communityNavigationStack != null &&
        communityNavigationStack.length > 1) {
      communityNavigationStack.pop();
      final currentPage = communityNavigationStack.peek();
      logger.d('🔙 Going back to page: ${currentPage.runtimeType}');
      logger.d('🔙 Stack length after pop: ${communityNavigationStack.length}');

      final isAtRoot = communityNavigationStack.length <= 1;
      state = state.copyWith(
        communityNavigationStack: communityNavigationStack,
        currentScreen: currentPage,
        showPortal: isAtRoot ? true : state.showPortal,
        showTopMenu: isAtRoot ? true : state.showTopMenu,
        showBottomNavigation: isAtRoot ? true : state.showBottomNavigation,
      );
    } else {
      logger.d('🔙 Cannot go back: stack has only one page or is null');
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
      case PortalType.goongHap:
        return const GoongHapHomeScreen();
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
    logger.d('🎯 Portal switching from ${state.portalType} to $portalType');

    // 먼저 포털 타입을 변경
    state = state.copyWith(portalType: portalType);
    logger.d('🎯 Portal type updated successfully');

    // 포털에 따라 기본 페이지를 해당 NavigationStack에 설정
    switch (portalType) {
      case PortalType.vote:
        final votePage = NavigationConfigs.getPageWidget(PortalType.vote, 0) ??
            const VoteHomePage();
        logger
            .d('📱 Setting VOTE portal, page widget: ${votePage.runtimeType}');

        // VOTE 포털로 전환 시 항상 새로운 스택으로 초기화
        state = state.copyWith(
          voteBottomNavigationIndex: 0, // 첫 번째 탭으로 초기화
          voteNavigationStack: NavigationStack()..push(votePage),
          currentScreen: const VoteHomeScreen(),
        );
        logger.d('📱 VOTE portal set successfully with fresh stack');
        break;

      case PortalType.goongHap:
        final goongHapPage =
            NavigationConfigs.getPageWidget(PortalType.goongHap, 0) ??
                const CompatibilityListPage();
        logger.d(
            '💕 Setting GOONG-HAP portal, page widget: ${goongHapPage.runtimeType}');

        // GOONG-HAP 포털로 전환 시 항상 새로운 스택으로 초기화
        state = state.copyWith(
          communityBottomNavigationIndex: 0, // 첫 번째 탭으로 초기화
          communityNavigationStack: NavigationStack()..push(goongHapPage),
          currentScreen: const GoongHapHomeScreen(),
        );
        logger.d('💕 GOONG-HAP portal set successfully with fresh stack');
        break;

      case PortalType.community:
        final communityPage =
            NavigationConfigs.getPageWidget(PortalType.community, 0) ??
                const CommunityHomePage();
        logger.d(
            '🏘️ Setting COMMUNITY portal, page widget: ${communityPage.runtimeType}');

        // COMMUNITY 포털로 전환 시 항상 새로운 스택으로 초기화
        state = state.copyWith(
          communityBottomNavigationIndex: 0, // 첫 번째 탭으로 초기화
          communityNavigationStack: NavigationStack()..push(communityPage),
          currentScreen: const CommunityHomeScreen(),
        );
        logger.d('🏘️ COMMUNITY portal set successfully with fresh stack');
        break;

      case PortalType.pic:
        final picPage = NavigationConfigs.getPageWidget(PortalType.pic, 0) ??
            const PicHomePage();
        logger.d('🖼️ Setting PIC portal, page widget: ${picPage.runtimeType}');

        // PIC 포털로 전환 시 항상 새로운 스택으로 초기화
        state = state.copyWith(
          picBottomNavigationIndex: 0, // 첫 번째 탭으로 초기화
          voteNavigationStack: NavigationStack()..push(picPage),
          currentScreen: const PicHomeScreen(),
        );
        logger.d('🖼️ PIC portal set successfully with fresh stack');
        break;

      case PortalType.novel:
        final novelPage =
            NavigationConfigs.getPageWidget(PortalType.novel, 0) ?? Container();
        logger.d(
            '📚 Setting NOVEL portal, page widget: ${novelPage.runtimeType}');

        // NOVEL 포털로 전환 시 항상 새로운 스택으로 초기화
        state = state.copyWith(
          novelBottomNavigationIndex: 0, // 첫 번째 탭으로 초기화
          voteNavigationStack: NavigationStack()..push(novelPage),
          currentScreen: const NovelHomeScreen(),
        );
        logger.d('📚 NOVEL portal set successfully with fresh stack');
        break;

      default:
        logger.d(
            '⚠️ Unknown portal type: $portalType, falling back to VoteHomeScreen');
        state = state.copyWith(currentScreen: const VoteHomeScreen());
    }

    globalStorage.saveData('portalString', portalType.name.toString());
    logger.d('🎯 Portal switching completed successfully to $portalType');
  }

  void setShowBottomNavigation(bool showBottomNavigation) {
    state = state.copyWith(showBottomNavigation: showBottomNavigation);
  }

  int getBottomNavigationIndex() {
    if (state.portalType == PortalType.vote) {
      return state.voteBottomNavigationIndex;
    } else if (state.portalType == PortalType.goongHap) {
      return state.communityBottomNavigationIndex; // goongHap은 communityNavigationStack 사용
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
    logger.d(
        '🎯 Setting bottom navigation index: $index for portal: ${state.portalType}');

    if (state.portalType == PortalType.vote) {
      setVoteBottomNavigationIndex(index);
    } else if (state.portalType == PortalType.goongHap) {
      setCommunityBottomNavigationIndex(index); // goongHap은 communityNavigationStack 사용
    } else if (state.portalType == PortalType.pic) {
      setPicBottomNavigationIndex(index);
    } else if (state.portalType == PortalType.community) {
      setCommunityBottomNavigationIndex(index);
    } else if (state.portalType == PortalType.novel) {
      setNovelBottomNavigationIndex(index);
    }

    logger.d('🎯 Bottom navigation index set successfully');
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

    logger.d('🖼️ Setting PIC bottom navigation index: $index');
    logger.d('🖼️ Page widget: ${pageWidget.runtimeType}');

    state = state.copyWith(
      picBottomNavigationIndex: index,
      voteNavigationStack: NavigationStack()..push(pageWidget),
      currentScreen: const PicHomeScreen(), // Screen으로 설정
    );

    logger.d('🖼️ PIC navigation index updated successfully');
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

    logger.d('📚 Setting NOVEL bottom navigation index: $index');
    logger.d('📚 Page widget: ${pageWidget.runtimeType}');

    state = state.copyWith(
      novelBottomNavigationIndex: index,
      voteNavigationStack: NavigationStack()..push(pageWidget),
      currentScreen: const NovelHomeScreen(), // Screen으로 설정
    );

    logger.d('📚 NOVEL navigation index updated successfully');
    globalStorage.saveData('novelBottomNavigationIndex', index.toString());
  }

  void setCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    final voteNavigationStack = state.voteNavigationStack ?? NavigationStack();

    voteNavigationStack.push(page);
    logger.d('📱 Pushing page to voteNavigationStack: ${page.runtimeType}');
    logger.d('📱 Stack length after push: ${voteNavigationStack.length}');

    state = state.copyWith(
      voteNavigationStack: voteNavigationStack,
      showBottomNavigation: showBottomNavigation,
      currentScreen: page,
    );

    logger.d(
        '📱 Vote navigation state updated with new page: ${page.runtimeType}');
  }

  /// 현재 Screen을 유지한 채 voteNavigationStack에 페이지만 푸시합니다.
  /// VoteHomeScreen 같은 Screen 컨테이너를 유지해야 할 때 사용합니다.
  void pushVotePageKeepScreen(Widget page) {
    final voteNavigationStack = state.voteNavigationStack ?? NavigationStack();
    voteNavigationStack.push(page);
    logger.d('📱 (keepScreen) Pushing page to voteNavigationStack: ${page.runtimeType}');
    logger.d('📱 (keepScreen) Stack length after push: ${voteNavigationStack.length}');

    // currentScreen은 변경하지 않고 스택만 갱신
    state = state.copyWith(
      voteNavigationStack: voteNavigationStack,
    );
  }

  void setPicCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    // PIC은 현재 vote 스택을 사용
    final voteNavigationStack = state.voteNavigationStack ?? NavigationStack();

    voteNavigationStack.push(page);
    logger.d(
        '🖼️ Pushing page to PIC navigation (vote stack): ${page.runtimeType}');
    logger.d('🖼️ Stack length after push: ${voteNavigationStack.length}');

    state = state.copyWith(
      voteNavigationStack: voteNavigationStack,
      showBottomNavigation: showBottomNavigation,
      currentScreen: page,
    );

    logger.d(
        '🖼️ PIC navigation state updated with new page: ${page.runtimeType}');
  }

  void setNovelCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    // NOVEL도 현재 vote 스택을 사용
    final voteNavigationStack = state.voteNavigationStack ?? NavigationStack();

    voteNavigationStack.push(page);
    logger.d(
        '📚 Pushing page to NOVEL navigation (vote stack): ${page.runtimeType}');
    logger.d('📚 Stack length after push: ${voteNavigationStack.length}');

    state = state.copyWith(
      voteNavigationStack: voteNavigationStack,
      showBottomNavigation: showBottomNavigation,
      currentScreen: page,
    );

    logger.d(
        '📚 NOVEL navigation state updated with new page: ${page.runtimeType}');
  }

  void setCommunityCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    final communityNavigationStack =
        state.communityNavigationStack ?? NavigationStack();

    communityNavigationStack.push(page);
    logger
        .d('🚀 Pushing page to communityNavigationStack: ${page.runtimeType}');
    logger.d('🚀 Stack length after push: ${communityNavigationStack.length}');

    state = state.copyWith(
      communityNavigationStack: communityNavigationStack,
      showBottomNavigation: showBottomNavigation,
      currentScreen: page,
    );

    logger.d('🚀 Navigation state updated with new page: ${page.runtimeType}');
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
    final navigationStack = state.drawerNavigationStack;

    if (navigationStack?.peek() == page) {
      logger.i('🎯 Page already on top of stack, skipping');
      return;
    }

    navigationStack?.push(page);

    state = state.copyWith(
        drawerNavigationStack: navigationStack,
        showTopMenu: true,
        showBottomNavigation: true);
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
