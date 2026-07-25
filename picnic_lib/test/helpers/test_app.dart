import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

import 'mock_providers.dart';
import 'test_environment.dart';

/// 기존 테스트들이 기대해 온 하네스 기본 디자인 크기.
///
/// 프로덕션(`kAppDesignSize` = 393x892, `splitScreenMode: true`)과 다르다.
/// 800개 넘는 테스트가 이 기준으로 작성돼 있어 기본값은 그대로 두고, 실제 앱과
/// 같은 기하를 재야 하는 테스트만 [buildTestApp] 의 `designSize` /
/// `splitScreenMode` 인자로 프로덕션 값을 넘긴다.
const Size kLegacyTestDesignSize = Size(375, 812);

/// Riverpod ProviderScope + ScreenUtilInit + MaterialApp 래퍼
///
/// 모든 매개변수는 defaultProviderOverrides에 전달됩니다.
/// 동일 provider의 중복 override를 방지합니다.
///
/// [designSize] / [splitScreenMode] 는 ScreenUtil 환산 배율(`.w` / `.h` / `.r`)을
/// 결정한다. 기본값은 하위 호환을 위한 [kLegacyTestDesignSize] 이고, 레이아웃
/// 회귀 테스트는 `designSize: kAppDesignSize, splitScreenMode: kAppSplitScreenMode`
/// 를 넘겨 프로덕션과 같은 기하를 측정해야 한다.
Widget buildTestApp(
  Widget child, {
  Navigation? navigation,
  UserProfilesModel? userProfile,
  Setting? setting,
  MediaQueryData? mediaQueryData,
  CommunityState? communityState,
  bool loggedIn = true,
  List<dynamic> extraOverrides = const [],
  Locale locale = const Locale('ko'),
  Size designSize = kLegacyTestDesignSize,
  bool splitScreenMode = false,
}) {
  return ProviderScope(
    overrides: [
      ...defaultProviderOverrides(
        navigation: navigation,
        userProfile: userProfile,
        setting: setting,
        mediaQueryData: mediaQueryData,
        communityState: communityState,
        loggedIn: loggedIn,
      ),
      ...extraOverrides,
    ],
    child: ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: splitScreenMode,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// 페이지 전체를 테스트할 때 사용 (Scaffold 없이)
Widget buildTestAppPage(
  Widget page, {
  Navigation? navigation,
  UserProfilesModel? userProfile,
  Setting? setting,
  MediaQueryData? mediaQueryData,
  CommunityState? communityState,
  bool loggedIn = true,
  List<dynamic> extraOverrides = const [],
  Locale locale = const Locale('ko'),
}) {
  return ProviderScope(
    overrides: [
      ...defaultProviderOverrides(
        navigation: navigation,
        userProfile: userProfile,
        setting: setting,
        mediaQueryData: mediaQueryData,
        communityState: communityState,
        loggedIn: loggedIn,
      ),
      ...extraOverrides,
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
}

/// 커스텀 Navigation 상태로 테스트할 때 사용 (하위 호환)
Widget buildTestAppWithNavigation(
  Widget child, {
  required Navigation navigation,
  Locale locale = const Locale('ko'),
}) {
  return buildTestApp(child, navigation: navigation, locale: locale);
}

/// 테스트 전 공통 초기화
void initTestEnvironment() {
  initTestColors();
}
