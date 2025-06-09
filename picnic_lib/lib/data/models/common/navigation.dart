import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/extensions/portal_type_extension.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
import 'package:picnic_lib/reflector.dart';

part '../../../generated/models/common/navigation.freezed.dart';

enum TopRightType { none, common, board, postView, community }

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
    Widget? currentScreen,
    @Default(true) bool showPortal,
    @Default(true) bool showTopMenu,
    @Default(TopRightType.common) TopRightType topRightMenu,
    @Default(true) bool showBottomNavigation,
    @Default('') String pageTitle,
    @Default('') String myPageTitle,
    NavigationStack? voteNavigationStack,
    NavigationStack? communityNavigationStack,
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

    return Navigation(
      portalType: newPortalType,
      picBottomNavigationIndex: newPicBottomNavigationIndex,
      voteBottomNavigationIndex: newVoteBottomNavigationIndex,
      communityBottomNavigationIndex: newCommunityBottomNavigationIndex,
      novelBottomNavigationIndex: newNovelBottomNavigationIndex,
      voteNavigationStack: NavigationStack()..push(const VoteHomePage()),
      drawerNavigationStack: NavigationStack()..push(const MyPage()),
      signUpNavigationStack: NavigationStack()..push(const LoginPage()),
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
