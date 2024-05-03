import 'package:flutter/material.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/pages/home_page.dart';
import 'package:prame_app/reflector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_provider.g.dart';

@riverpod
class NavigationInfo extends _$NavigationInfo {
  Navigation setting = Navigation(); // 초기 값이 필요하다면 임시로 할당

  @override
  Navigation build() {
    return setting;
  }

  Future<void> loadSettings() async {
    setting = await Navigation.load();
    state = state.copyWith(
        portalString: setting.portalString,
        bottomNavigationIndex: setting.bottomNavigationIndex);
  }

  setState({
    String? portalString,
    int? bottomNavigationIndex,
    Widget? currentPage,
  }) {
    state = state.copyWith(
      portalString: portalString ?? state.portalString,
      bottomNavigationIndex:
          bottomNavigationIndex ?? state.bottomNavigationIndex,
      currentPage: currentPage ?? state.currentPage,
    );
  }

  setPortalString(String portalString) {
    state = state.copyWith(portalString: portalString);
    globalStorage.saveData('portalString', portalString);
  }

  setBottomNavigationIndex(int index) {
    state = state.copyWith(bottomNavigationIndex: index);
    globalStorage.saveData('bottomNavigationIndex', index.toString());
  }

  setCurrentPage(Widget page) {
    logger.d('setCurrentPage: $page');
    state = state.copyWith(currentPage: page);
  }
}

@reflector
class Navigation {
  String portalString = 'vote';
  int bottomNavigationIndex = 0;
  Widget? currentPage;

  Navigation();

  static Future<Navigation> load() async {
    String? portalString = await globalStorage.loadData('portalString', 'vote');
    String? bottomNavigationIndex =
        await globalStorage.loadData('bottomNavigationIndex', '0');
    return Navigation()
      ..portalString = portalString!
      ..bottomNavigationIndex = int.parse(bottomNavigationIndex!);
  }

  Navigation copyWith({
    String? portalString,
    int? bottomNavigationIndex,
    Widget? currentPage,
  }) {
    return Navigation()
      ..portalString = portalString ?? this.portalString
      ..bottomNavigationIndex =
          bottomNavigationIndex ?? this.bottomNavigationIndex
      ..currentPage = currentPage ?? this.currentPage;
  }
}
