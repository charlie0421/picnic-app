import 'package:flutter/material.dart';
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
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

@Riverpod(keepAlive: true)
class NavigationInfo extends _$NavigationInfo {
  Navigation setting = Navigation();

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
    if (portalType == PortalType.vote) {
      currentScreen = const VoteHomeScreen();
      currentPage = votePages[state.voteBottomNavigationIndex].pageWidget;
    } else if (portalType == PortalType.pic) {
      currentScreen = const PicHomeScreen();
      currentPage = picPages[state.picBottomNavigationIndex].pageWidget;
    } else if (portalType == PortalType.community) {
      currentScreen = const CommunityHomeScreen();
      currentPage =
          communityPages[state.communityBottomNavigationIndex].pageWidget;
    } else if (portalType == PortalType.novel) {
      currentScreen = const NovelHomeScreen();
      currentPage = novelPages[state.novelBottomNavigationIndex].pageWidget;
    } else {
      currentScreen = const VoteHomeScreen();
      currentPage = votePages[state.voteBottomNavigationIndex].pageWidget;
    }

    state = state.copyWith(
      portalType: portalType,
      currentScreen: currentScreen,
      topNavigationStack: NavigationStack()..push(currentPage),
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
    logger.d('setBottomNavigationIndex: $index');
    state = state.copyWith(
      showTopMenu: true,
    );
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

  setPicBottomNavigationIndex(int index) {
    state = state.copyWith(
      picBottomNavigationIndex: index,
    );
    state = state.copyWith(
      topNavigationStack: NavigationStack()..push(picPages[index].pageWidget),
    );
    globalStorage.saveData('picBottomNavigationIndex', index.toString());
  }

  setVoteBottomNavigationIndex(int index) {
    state = state.copyWith(
        voteBottomNavigationIndex: index,
        topNavigationStack: NavigationStack()
          ..push(votePages[index].pageWidget));
    globalStorage.saveData('voteBottomNavigationIndex', index.toString());
  }

  setCommunityBottomNavigationIndex(int index) {
    state = state.copyWith(
        communityBottomNavigationIndex: index,
        topNavigationStack: NavigationStack()
          ..push(communityPages[index].pageWidget));
    globalStorage.saveData('communityBottomNavigationIndex', index.toString());
  }

  setNovelBottomNavigationIndex(int index) {
    state = state.copyWith(
        novelBottomNavigationIndex: index,
        topNavigationStack: NavigationStack()
          ..push(novelPages[index].pageWidget));
    globalStorage.saveData('novelBottomNavigationIndex', index.toString());
  }

  setCurrentPage(Widget page,
      {bool showTopMenu = false, bool showBottomNavigation = true}) {
    final NavigationStack? topNavigationStack = state.topNavigationStack;

    if (topNavigationStack == null) {
      print('Error: No pages available in the navigation stack.');
      return;
    }

    if (topNavigationStack.isEmpty) {
      print('Error: No pages available in the navigation stack.');
      return;
    }

    if (topNavigationStack.peek() == page) {
      return;
    }

    topNavigationStack.push(page);
    state = state.copyWith(
      topNavigationStack: topNavigationStack,
      showTopMenu: showTopMenu,
      showBottomNavigation: showBottomNavigation,
    );
    // topNavigationStack.length == 1 ? showPortal() : hidePortal();
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
    final NavigationStack? navigationStack = state.drawerNavigationStack;

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
    final NavigationStack? navigationStack = state.signUpNavigationStack;

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
    final NavigationStack? topNavigationStack = state.topNavigationStack;
    topNavigationStack?.pop();

    state = state.copyWith(topNavigationStack: topNavigationStack);

    topNavigationStack != null && topNavigationStack.length == 1
        ? showPortal()
        : hidePortal();
  }

  goBackMy() {
    final NavigationStack? navigationStack = state.drawerNavigationStack;
    navigationStack?.pop();

    state = state.copyWith(drawerNavigationStack: navigationStack);
  }

  goBackSignUp() {
    final NavigationStack? navigationStack = state.signUpNavigationStack;
    navigationStack?.pop();

    state = state.copyWith(signUpNavigationStack: navigationStack);
  }

  hidePortal() {
    state = state.copyWith(
      showTopMenu: false,
    );
  }

  showPortal() {
    state = state.copyWith(
      showTopMenu: true,
    );
  }
}

@reflector
class Navigation {
  PortalType portalType = PortalType.vote;
  int picBottomNavigationIndex = 0;
  int voteBottomNavigationIndex = 0;
  int communityBottomNavigationIndex = 0;
  int novelBottomNavigationIndex = 0;
  Widget currentScreen = const VoteHomeScreen();
  bool showTopMenu = true;
  bool showBottomNavigation = true;
  NavigationStack? topNavigationStack = NavigationStack()
    ..push(const VoteHomePage());
  NavigationStack? drawerNavigationStack = NavigationStack()
    ..push(const MyPage());
  NavigationStack? signUpNavigationStack = NavigationStack()
    ..push(const LoginPage());

  Navigation();

  Future<void> load() async {
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

    if (portalString == PortalType.vote.name.toString()) {
      currentScreen = const VoteHomeScreen();
      topNavigationStack = NavigationStack()
        ..push(
            votePages[int.parse(voteBottomNavigationIndexString!)].pageWidget);
    } else if (portalString == PortalType.pic.name.toString()) {
      currentScreen = const PicHomeScreen();
      topNavigationStack = NavigationStack()
        ..push(picPages[int.parse(picBottomNavigationIndexString!)].pageWidget);
    } else if (portalString == PortalType.community.name.toString()) {
      currentScreen = const CommunityHomeScreen();
      topNavigationStack = NavigationStack()
        ..push(communityPages[int.parse(communityBottomNavigationIndexString!)]
            .pageWidget);
    } else if (portalString == PortalType.novel.name.toString()) {
      currentScreen = const NovelHomeScreen();
      topNavigationStack = NavigationStack()
        ..push(novelPages[int.parse(novelBottomNavigationIndexString!)]
            .pageWidget);
    } else if (portalString == PortalType.mypage.name.toString()) {
      currentScreen = const MyPageScreen();
      topNavigationStack = NavigationStack()..push(const MyPage());
    }

    portalType = PortalTypeExtension.fromString(
        portalString ?? PortalType.vote.name.toString());
    voteBottomNavigationIndex = int.parse(voteBottomNavigationIndexString!);
    picBottomNavigationIndex = int.parse(picBottomNavigationIndexString!);
    communityBottomNavigationIndex =
        int.parse(communityBottomNavigationIndexString!);
    novelBottomNavigationIndex = int.parse(novelBottomNavigationIndexString!);
    drawerNavigationStack = drawerNavigationStack;
  }

  Navigation copyWith({
    PortalType? portalType,
    int? picBottomNavigationIndex,
    int? voteBottomNavigationIndex,
    int? communityBottomNavigationIndex,
    int? novelBottomNavigationIndex,
    Widget? currentScreen,
    bool? showTopMenu,
    bool? showBottomNavigation,
    NavigationStack? topNavigationStack,
    NavigationStack? drawerNavigationStack,
    NavigationStack? signUpNavigationStack,
  }) {
    return Navigation()
      ..portalType = portalType ?? this.portalType
      ..picBottomNavigationIndex =
          picBottomNavigationIndex ?? this.picBottomNavigationIndex
      ..voteBottomNavigationIndex =
          voteBottomNavigationIndex ?? this.voteBottomNavigationIndex
      ..communityBottomNavigationIndex =
          communityBottomNavigationIndex ?? this.communityBottomNavigationIndex
      ..novelBottomNavigationIndex =
          novelBottomNavigationIndex ?? this.novelBottomNavigationIndex
      ..currentScreen = currentScreen ?? this.currentScreen
      ..showTopMenu = showTopMenu ?? this.showTopMenu
      ..showBottomNavigation = showBottomNavigation ?? this.showBottomNavigation
      ..topNavigationStack = topNavigationStack ?? this.topNavigationStack
      ..drawerNavigationStack =
          drawerNavigationStack ?? this.drawerNavigationStack
      ..signUpNavigationStack =
          signUpNavigationStack ?? this.signUpNavigationStack;
  }
}
