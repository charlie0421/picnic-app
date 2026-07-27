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
///
/// Scaffold 는 일부러 씌우지 않는다 — 프로덕션에서도 페이지들은 자기 Scaffold 를
/// 갖지 않고 앱 셸 안에 얹힌다. 다만 셸이 제공하는 **Material 조상**은 재현해야
/// 한다. 그게 없으면 ListTile 같은 머티리얼 위젯이 "No Material widget found" 로
/// 죽는데, 이건 위젯 결함이 아니라 하네스 결함이다.
/// [MaterialType.transparency] 라서 배경(및 elevation/그림자)은 그리지 않는다
/// (material.dart `_MaterialState.build` 의 `if (type == transparency)` 분기).
///
/// 다만 **기본 텍스트 스타일은 바뀐다** — `Material` 은 type 과 무관하게 자식을
/// 항상 `AnimatedDefaultTextStyle(theme.textTheme.bodyMedium)` 로 감싼다
/// (material.dart:476). 그래도 이게 맞는 하네스다: 프로덕션에서도 페이지는 앱 셸의
/// `Material` 아래에 얹히므로 같은 기본 스타일을 받는다. 즉 이 래핑은 부작용이
/// 아니라 프로덕션 재현이다.
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
        home: Material(type: MaterialType.transparency, child: page),
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
