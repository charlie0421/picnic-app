import 'package:flutter/material.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/menu.dart';
import 'package:prame_app/pages/vote/vote_home.dart';
import 'package:prame_app/reflector.dart';
import 'package:prame_app/screens/developer/developer_home_screen.dart';
import 'package:prame_app/screens/prame/prame_home_screen.dart';
import 'package:prame_app/screens/vote/home_screen.dart';
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
    state = state.copyWith(
        portalString: setting.portalString,
        fanBottomNavigationIndex: setting.fanBottomNavigationIndex,
        voteBottomNavigationIndex: setting.voteBottomNavigationIndex);
  }

  setState({
    String? portalString,
    int? fanBottomNavigationIndex,
    int? voteBottomNavigationIndex,
    int? developerBottomNavigationIndex,
    Widget? currentPage,
  }) {
    state = state.copyWith(
      portalString: portalString ?? state.portalString,
      fanBottomNavigationIndex:
          fanBottomNavigationIndex ?? state.fanBottomNavigationIndex,
      voteBottomNavigationIndex:
          voteBottomNavigationIndex ?? state.voteBottomNavigationIndex,
      developerBottomNavigationIndex: developerBottomNavigationIndex ??
          state.developerBottomNavigationIndex,
      currentPage: currentPage ?? state.currentPage,
    );
  }

  setPortalString(String portalString) {
    logger.d('setPortalString: $portalString');

    Widget currentScreen;
    if (portalString == 'vote') {
      currentScreen = const VoteHomeScreen();
    } else if (portalString == 'fan') {
      currentScreen = const PrameHomeScreen();
    } else if (portalString == 'developer') {
      currentScreen = const DeveloperHomeScreen();
    } else {
      return const SizedBox.shrink();
    }

    Widget currentPage;
    if (portalString == 'vote') {
      currentPage = voteScreens[state.voteBottomNavigationIndex];
    } else if (portalString == 'fan') {
      currentPage = prameScreens[state.fanBottomNavigationIndex];
    } else if (portalString == 'developer') {
      currentPage = developerScreens[state.developerBottomNavigationIndex];
    } else {
      return const SizedBox.shrink();
    }

    state = state.copyWith(
      portalString: portalString,
      currentScreen: currentScreen,
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

  setDeveloperBottomNavigationIndex(int index) {
    state = state.copyWith(developerBottomNavigationIndex: index);
    globalStorage.saveData('developerBottomNavigationIndex', index.toString());
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
  int developerBottomNavigationIndex = 0;
  Widget? currentScreen = const VoteHomeScreen();
  Widget? currentPage = const VoteHomePage();
  Widget? previousPage;

  Navigation();

  static Future<Navigation> load() async {
    String? portalString = await globalStorage.loadData('portalString', 'vote');
    String? bottomNavigationIndex =
        await globalStorage.loadData('bottomNavigationIndex', '0');

    logger.d('portalString: $portalString');
    logger.d('bottomNavigationIndex: $bottomNavigationIndex');
    return Navigation()
      ..portalString = portalString!
      ..fanBottomNavigationIndex = int.parse(bottomNavigationIndex!)
      ..voteBottomNavigationIndex = int.parse(bottomNavigationIndex!)
      ..developerBottomNavigationIndex = int.parse(bottomNavigationIndex!);
  }

  Navigation copyWith({
    String? portalString,
    int? fanBottomNavigationIndex,
    int? voteBottomNavigationIndex,
    int? developerBottomNavigationIndex,
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
      ..developerBottomNavigationIndex =
          developerBottomNavigationIndex ?? this.developerBottomNavigationIndex
      ..currentScreen = currentScreen ?? this.currentScreen
      ..previousPage = previousPage ?? this.previousPage
      ..currentPage = currentPage ?? this.currentPage;
  }
}
