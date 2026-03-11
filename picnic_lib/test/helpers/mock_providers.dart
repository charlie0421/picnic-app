import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

import 'mock_data.dart';

/// 기본 provider override 세트
///
/// 모든 ConsumerWidget 테스트에 필요한 핵심 provider들을
/// mock 데이터로 override합니다.
List<dynamic> defaultProviderOverrides({
  Navigation? navigation,
  UserProfilesModel? userProfile,
  Setting? setting,
  MediaQueryData? mediaQueryData,
  CommunityState? communityState,
  bool loggedIn = true,
}) {
  final nav = navigation ?? MockData.navigation();
  return [
    // Navigation (68 usages - overrideWith로 notifier 접근 가능)
    navigationInfoProvider.overrideWith(() => MockNavigationInfo(nav)),

    // User Info (62 usages)
    userInfoProvider.overrideWith(
      () => MockUserInfo(loggedIn ? (userProfile ?? MockData.userProfile()) : null),
    ),

    // App Setting (32 usages)
    appSettingProvider.overrideWith(() => MockAppSetting(setting ?? MockData.setting())),

    // Global Media Query (11 usages)
    globalMediaQueryProvider.overrideWith(
      () => MockGlobalMediaQuery(mediaQueryData ?? MockData.mediaQueryData()),
    ),

    // Community State (13 usages)
    communityStateInfoProvider.overrideWith(
      () => MockCommunityStateInfo(communityState ?? MockData.communityState()),
    ),
  ];
}

/// 비로그인 상태 override 세트
List<dynamic> loggedOutProviderOverrides() {
  return defaultProviderOverrides(loggedIn: false);
}

/// NavigationInfo mock notifier
class MockNavigationInfo extends NavigationInfo {
  final Navigation _initial;

  MockNavigationInfo(this._initial);

  @override
  Navigation build() => _initial;

  @override
  void setPortal(PortalType portalType) {
    state = state.copyWith(portalType: portalType);
  }
}

/// UserInfo mock notifier (AsyncNotifier)
class MockUserInfo extends UserInfo {
  final UserProfilesModel? _profile;

  MockUserInfo(this._profile);

  @override
  Future<UserProfilesModel?> build() async => _profile;
}

/// AppSetting mock notifier
class MockAppSetting extends AppSetting {
  final Setting _initial;

  MockAppSetting(this._initial);

  @override
  Setting build() => _initial;
}

/// GlobalMediaQuery mock notifier
class MockGlobalMediaQuery extends GlobalMediaQuery {
  final MediaQueryData _initial;

  MockGlobalMediaQuery(this._initial);

  @override
  MediaQueryData build() => _initial;
}

/// CommunityStateInfo mock notifier
class MockCommunityStateInfo extends CommunityStateInfo {
  final CommunityState _initial;

  MockCommunityStateInfo(this._initial);

  @override
  CommunityState build() => _initial;
}
