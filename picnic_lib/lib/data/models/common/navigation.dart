import 'package:flutter/material.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/navigator/navigation_configs.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/extensions/portal_type_extension.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';

enum TopRightType { none, common, board, postView, community }

class Navigation {
  final PortalType portalType;
  final int picBottomNavigationIndex;
  final int voteBottomNavigationIndex;
  final int communityBottomNavigationIndex;
  final int novelBottomNavigationIndex;
  final Widget? currentScreen;
  final bool showPortal;
  final bool showTopMenu;
  final bool showMyPoint;
  final TopRightType topRightMenu;
  final bool showBottomNavigation;
  final String pageTitle;
  final String myPageTitle;
  final NavigationStack? voteNavigationStack;
  final NavigationStack? communityNavigationStack;
  final NavigationStack? drawerNavigationStack;
  final NavigationStack? signUpNavigationStack;

  const Navigation({
    this.portalType = PortalType.vote,
    this.picBottomNavigationIndex = 0,
    this.voteBottomNavigationIndex = 0,
    this.communityBottomNavigationIndex = 0,
    this.novelBottomNavigationIndex = 0,
    this.currentScreen,
    this.showPortal = true,
    this.showTopMenu = true,
    this.showMyPoint = true,
    this.topRightMenu = TopRightType.common,
    this.showBottomNavigation = true,
    this.pageTitle = '',
    this.myPageTitle = '',
    this.voteNavigationStack,
    this.communityNavigationStack,
    this.drawerNavigationStack,
    this.signUpNavigationStack,
  });

  Navigation copyWith({
    PortalType? portalType,
    int? picBottomNavigationIndex,
    int? voteBottomNavigationIndex,
    int? communityBottomNavigationIndex,
    int? novelBottomNavigationIndex,
    Widget? currentScreen,
    bool? showPortal,
    bool? showTopMenu,
    bool? showMyPoint,
    TopRightType? topRightMenu,
    bool? showBottomNavigation,
    String? pageTitle,
    String? myPageTitle,
    NavigationStack? voteNavigationStack,
    NavigationStack? communityNavigationStack,
    NavigationStack? drawerNavigationStack,
    NavigationStack? signUpNavigationStack,
  }) {
    return Navigation(
      portalType: portalType ?? this.portalType,
      picBottomNavigationIndex: picBottomNavigationIndex ?? this.picBottomNavigationIndex,
      voteBottomNavigationIndex: voteBottomNavigationIndex ?? this.voteBottomNavigationIndex,
      communityBottomNavigationIndex: communityBottomNavigationIndex ?? this.communityBottomNavigationIndex,
      novelBottomNavigationIndex: novelBottomNavigationIndex ?? this.novelBottomNavigationIndex,
      currentScreen: currentScreen ?? this.currentScreen,
      showPortal: showPortal ?? this.showPortal,
      showTopMenu: showTopMenu ?? this.showTopMenu,
      showMyPoint: showMyPoint ?? this.showMyPoint,
      topRightMenu: topRightMenu ?? this.topRightMenu,
      showBottomNavigation: showBottomNavigation ?? this.showBottomNavigation,
      pageTitle: pageTitle ?? this.pageTitle,
      myPageTitle: myPageTitle ?? this.myPageTitle,
      voteNavigationStack: voteNavigationStack ?? this.voteNavigationStack,
      communityNavigationStack: communityNavigationStack ?? this.communityNavigationStack,
      drawerNavigationStack: drawerNavigationStack ?? this.drawerNavigationStack,
      signUpNavigationStack: signUpNavigationStack ?? this.signUpNavigationStack,
    );
  }

  factory Navigation.initial() {
    // 초기 투표 페이지는 인덱스 0에 해당하는 페이지를 로드
    final initialVotePage =
        NavigationConfigs.getPageWidget(PortalType.vote, 0) ??
        const VoteHomePage();

    return Navigation(
      voteNavigationStack: NavigationStack()..push(initialVotePage),
      drawerNavigationStack: NavigationStack()..push(const MyPage()),
      signUpNavigationStack: NavigationStack()..push(const LoginPage()),
    );
  }

  Future<Navigation> load() async {
    String? portalString = await globalStorage.loadData(
      'portalString',
      PortalType.vote.name.toString(),
    );
    String? voteBottomNavigationIndexString = await globalStorage.loadData(
      'voteBottomNavigationIndex',
      '0',
    );
    String? picBottomNavigationIndexString = await globalStorage.loadData(
      'picBottomNavigationIndex',
      '0',
    );
    String? communityBottomNavigationIndexString = await globalStorage.loadData(
      'communityBottomNavigationIndex',
      '0',
    );
    String? novelBottomNavigationIndexString = await globalStorage.loadData(
      'novelBottomNavigationIndex',
      '0',
    );

    PortalType newPortalType = PortalTypeExtension.fromString(
      portalString ?? PortalType.vote.name.toString(),
    );
    int newVoteBottomNavigationIndex = int.parse(
      voteBottomNavigationIndexString!,
    );
    int newPicBottomNavigationIndex = int.parse(
      picBottomNavigationIndexString!,
    );
    int newCommunityBottomNavigationIndex = int.parse(
      communityBottomNavigationIndexString!,
    );
    int newNovelBottomNavigationIndex = int.parse(
      novelBottomNavigationIndexString!,
    );

    // 저장된 인덱스에 맞는 페이지를 로드
    final savedVotePage =
        NavigationConfigs.getPageWidget(
          PortalType.vote,
          newVoteBottomNavigationIndex,
        ) ??
        const VoteHomePage();

    return Navigation(
      portalType: newPortalType,
      picBottomNavigationIndex: newPicBottomNavigationIndex,
      voteBottomNavigationIndex: newVoteBottomNavigationIndex,
      communityBottomNavigationIndex: newCommunityBottomNavigationIndex,
      novelBottomNavigationIndex: newNovelBottomNavigationIndex,
      voteNavigationStack: NavigationStack()..push(savedVotePage),
      drawerNavigationStack: NavigationStack()..push(const MyPage()),
      signUpNavigationStack: NavigationStack()..push(const LoginPage()),
    );
  }

  int getBottomNavigationIndex() {
    switch (portalType) {
      case PortalType.vote:
        return voteBottomNavigationIndex;
      case PortalType.goongHap:
        return communityBottomNavigationIndex; // goongHap은 communityNavigationStack 사용
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
