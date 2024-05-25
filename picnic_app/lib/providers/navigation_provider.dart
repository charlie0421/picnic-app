import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/menu.dart';
import 'package:picnic_app/pages/vote/vote_home.dart';
import 'package:picnic_app/reflector.dart';
import 'package:picnic_app/screens/community/community_home_screen.dart';
import 'package:picnic_app/screens/fan/fan_home_screen.dart';
import 'package:picnic_app/screens/novel/novel_home_screen.dart';
import 'package:picnic_app/screens/vote/vote_home_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

@riverpod
class NavigationInfo extends _$NavigationInfo {
  Navigation setting = Navigation(); // 초기 값이 필요하다면 임시로 할당

  @override
  Navigation build() {
    loadSettings();
    return setting;
  }

  Future<void> loadSettings() async {
    setting = await Navigation.load();
  }

  setState({
    String? portalString,
    int? fanBottomNavigationIndex,
    int? voteBottomNavigationIndex,
    int? communityBottomNavigationIndex,
    int? novelBottomNavigationIndex,
    Widget? currentPage,
  }) {
    state = state.copyWith(
      portalString: portalString ?? state.portalString,
      fanBottomNavigationIndex:
          fanBottomNavigationIndex ?? state.fanBottomNavigationIndex,
      voteBottomNavigationIndex:
          voteBottomNavigationIndex ?? state.voteBottomNavigationIndex,
      communityBottomNavigationIndex: communityBottomNavigationIndex ??
          state.communityBottomNavigationIndex,
      novelBottomNavigationIndex:
          novelBottomNavigationIndex ?? state.novelBottomNavigationIndex,
      currentPage: currentPage ?? state.currentPage,
    );
  }

  setPortalString(String portalString) {
    logger.d('setPortalString: $portalString');

    Widget currentPage;
    if (portalString == 'vote') {
      currentPage = voteScreens[state.voteBottomNavigationIndex];
    } else if (portalString == 'fan') {
      currentPage = fanScreens[state.fanBottomNavigationIndex];
    } else if (portalString == 'community') {
      currentPage = communityScreens[state.fanBottomNavigationIndex];
    } else if (portalString == 'novel') {
      currentPage = novelScreens[state.fanBottomNavigationIndex];
    } else {
      return const SizedBox.shrink();
    }

    state = state.copyWith(
      portalString: portalString,
      currentPage: currentPage,
    );
    globalStorage.saveData('portalString', portalString);
  }

  setFanBottomNavigationIndex(int index) {
    state = state.copyWith(fanBottomNavigationIndex: index);
    globalStorage.saveData('fanBottomNavigationIndex', index.toString());
  }

  setVoteBottomNavigationIndex(int index) {
    state = state.copyWith(voteBottomNavigationIndex: index);
    globalStorage.saveData('voteBottomNavigationIndex', index.toString());
  }

  setCurrentPage(Widget page) {
    setting.previousPage = setting.currentPage;
    setting.currentPage = page;
    state = state.copyWith(
        previousPage: setting.previousPage, currentPage: setting.currentPage);
  }

  bool canBack() {
    return setting.previousPage != null;
  }

  goBack() {
    if (setting.previousPage != null &&
        setting.currentPage != setting.previousPage) {
      setting.currentPage = setting.previousPage;
      state = state.copyWith(
          previousPage: setting.previousPage, currentPage: setting.currentPage);
    }
  }
}

@reflector
class Navigation {
  String portalString = 'vote';
  int fanBottomNavigationIndex = 0;
  int voteBottomNavigationIndex = 0;
  int communityBottomNavigationIndex = 0;
  int novelBottomNavigationIndex = 0;
  Widget currentScreen = const VoteHomeScreen();
  Widget currentPage = const VoteHomePage();
  Widget previousPage = Container();

  Navigation();

  static Future<Navigation> load() async {
    String? portalString = await globalStorage.loadData('portalString', 'vote');
    String? fanBottomNavigationIndex =
        await globalStorage.loadData('fanBottomNavigationIndex', '0');
    String? voteBottomNavigationIndex =
        await globalStorage.loadData('voteBottomNavigationIndex', '0');
    String? communityBottomNavigationIndex =
        await globalStorage.loadData('communityBottomNavigationIndex', '0');
    String? novelBottomNavigationIndex =
        await globalStorage.loadData('novelBottomNavigationIndex', '0');

    logger.d('portalString: $portalString');

    Widget currentScreen = Container();
    Widget currentPage = Container();

    if (portalString == 'vote') {
      currentScreen = const VoteHomeScreen();
      currentPage = voteScreens[int.parse(voteBottomNavigationIndex!)];
    } else if (portalString == 'fan') {
      currentScreen = const FanHomeScreen();
      currentPage = fanScreens[int.parse(fanBottomNavigationIndex!)];
    } else if (portalString == 'community') {
      currentScreen = const CommunityHomeScreen();
      currentPage =
          communityScreens[int.parse(communityBottomNavigationIndex!)];
    } else if (portalString == 'novel') {
      currentScreen = const NovelHomeScreen();
      currentPage = novelScreens[int.parse(novelBottomNavigationIndex!)];
    }

    logger.d('currentScreen: $currentScreen');
    logger.d('currentPage: $currentPage');
    return Navigation()
      ..portalString = portalString!
      ..fanBottomNavigationIndex = int.parse(fanBottomNavigationIndex!)
      ..voteBottomNavigationIndex = int.parse(voteBottomNavigationIndex!)
      ..communityBottomNavigationIndex =
          int.parse(communityBottomNavigationIndex!)
      ..novelBottomNavigationIndex = int.parse(novelBottomNavigationIndex!)
      ..currentScreen = currentScreen
      ..currentPage = currentPage;
  }

  Navigation copyWith({
    String? portalString,
    int? fanBottomNavigationIndex,
    int? voteBottomNavigationIndex,
    int? communityBottomNavigationIndex,
    int? novelBottomNavigationIndex,
    Widget? currentScreen,
    Widget? previousPage,
    Widget? currentPage,
  }) {
    return Navigation()
      ..portalString = portalString ?? this.portalString
      ..fanBottomNavigationIndex =
          fanBottomNavigationIndex ?? this.fanBottomNavigationIndex
      ..voteBottomNavigationIndex =
          voteBottomNavigationIndex ?? this.voteBottomNavigationIndex
      ..communityBottomNavigationIndex =
          communityBottomNavigationIndex ?? this.communityBottomNavigationIndex
      ..novelBottomNavigationIndex =
          novelBottomNavigationIndex ?? this.novelBottomNavigationIndex
      ..currentScreen = currentScreen ?? this.currentScreen
      ..previousPage = previousPage ?? this.previousPage
      ..currentPage = currentPage ?? this.currentPage;
  }
}
