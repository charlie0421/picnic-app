import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/menu.dart';
import 'package:picnic_app/navigation_stack.dart';
import 'package:picnic_app/pages/common/mypage.dart';
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
  Navigation setting = Navigation()..load();

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
      currentPage = communityPages[state.picBottomNavigationIndex].pageWidget;
    } else if (portalType == PortalType.novel) {
      currentScreen = const NovelHomeScreen();
      currentPage = novelPages[state.picBottomNavigationIndex].pageWidget;
    } else if (portalType == PortalType.vote) {
      currentScreen = const VoteHomeScreen();
      currentPage = votePages[state.voteBottomNavigationIndex].pageWidget;
    } else if (portalType == PortalType.mypage) {
      currentScreen = const MyPageScreen();
      currentPage = const MyPage();
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
      {bool showTopMenu = true, bool showBottomNavigation = true}) {
    final NavigationStack? topNavigationStack = state.topNavigationStack;

    if (topNavigationStack?.peek() == page) {
      return;
    }

    topNavigationStack?.push(page);
    state = state.copyWith(
      topNavigationStack: topNavigationStack,
      showTopMenu: showTopMenu,
      showBottomNavigation: showBottomNavigation,
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

  goBack() {
    final NavigationStack? navigationStack = state.topNavigationStack;
    navigationStack?.pop();

    state = state.copyWith(topNavigationStack: navigationStack);
  }

  goBackMy() {
    final NavigationStack? navigationStack = state.drawerNavigationStack;
    navigationStack?.pop();

    state = state.copyWith(drawerNavigationStack: navigationStack);
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

  Navigation();

  Future<Navigation> load() async {
    String? portalString = await globalStorage.loadData('portalString', 'vote');
    String? voteBottomNavigationIndex =
        await globalStorage.loadData('voteBottomNavigationIndex', '0');
    String? picBottomNavigationIndex =
        await globalStorage.loadData('picBottomNavigationIndex', '0');
    String? communityBottomNavigationIndex =
        await globalStorage.loadData('communityBottomNavigationIndex', '0');
    String? novelBottomNavigationIndex =
        await globalStorage.loadData('novelBottomNavigationIndex', '0');

    Widget currentScreen = Container();

    logger.d('portalString: $portalString');
    if (portalString == PortalType.vote.name.toString()) {
      currentScreen = const VoteHomeScreen();
      topNavigationStack = NavigationStack()
        ..push(votePages[int.parse(voteBottomNavigationIndex!)].pageWidget);
    } else if (portalString == PortalType.pic.name.toString()) {
      currentScreen = const PicHomeScreen();
      topNavigationStack = NavigationStack()
        ..push(picPages[int.parse(picBottomNavigationIndex!)].pageWidget);
    } else if (portalString == PortalType.community.name.toString()) {
      currentScreen = const CommunityHomeScreen();
      topNavigationStack = NavigationStack()
        ..push(communityPages[int.parse(communityBottomNavigationIndex!)]
            .pageWidget);
    } else if (portalString == PortalType.novel.name.toString()) {
      currentScreen = const NovelHomeScreen();
      topNavigationStack = NavigationStack()
        ..push(novelPages[int.parse(novelBottomNavigationIndex!)].pageWidget);
    } else if (portalString == PortalType.mypage.name.toString()) {
      currentScreen = const MyPageScreen();
      topNavigationStack = NavigationStack()..push(const MyPage());
    }

    return Navigation()
      ..portalType = portalType
      ..voteBottomNavigationIndex = int.parse(voteBottomNavigationIndex!)
      ..picBottomNavigationIndex = int.parse(picBottomNavigationIndex!)
      ..communityBottomNavigationIndex =
          int.parse(communityBottomNavigationIndex!)
      ..novelBottomNavigationIndex = int.parse(novelBottomNavigationIndex!)
      ..currentScreen = currentScreen
      ..topNavigationStack = topNavigationStack
      ..drawerNavigationStack = drawerNavigationStack;
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
          drawerNavigationStack ?? this.drawerNavigationStack;
  }
}
