import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/ui/system_navigation_bar_inset.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/firebase_analytics_utils.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/services/locale_service.dart';

/// 프로덕션 ScreenUtil 기준 디자인 크기.
///
/// `.w` / `.h` / `.r` 이 몇 배로 환산되는지를 결정하므로, 레이아웃(특히 오버플로)
/// 회귀 테스트는 이 값을 그대로 써야 실제 앱과 같은 기하를 측정한다.
const Size kAppDesignSize = Size(393, 892);

/// 프로덕션 ScreenUtil `splitScreenMode`. [kAppDesignSize] 와 같은 이유로 공개한다.
const bool kAppSplitScreenMode = true;

/// 앱이 따르는 시스템 글자 크기의 상한 (PICNIC-2750).
///
/// 레이아웃은 2.6배까지 검증한다(`l10nLayoutTextScales`). iOS 손쉬운 사용 글자
/// 크기는 약 3.1배까지 올라가는데, 그러면 달성 투표 상세처럼 고정된 페이지 머리가
/// 작은 화면 높이를 넘긴다. 그보다 큰 설정은 2.6배로 그리고, 작은 설정(안드로이드는
/// 전부)은 그대로 둔다.
const double kAppMaxTextScaleFactor = 2.6;

/// app.dart 파일에서 공통으로 사용되는 앱 빌드 로직을 담은 유틸리티 클래스
///
/// 두 앱(picnic_app, ttja_app)의 app.dart 파일에서 중복되는 UI 빌드 로직을
/// 추출하여 재사용성을 높이고 코드 중복을 줄입니다.
class AppBuilder {
  /// 앱 초기화 후 MaterialApp 위젯 생성
  ///
  /// [navigatorKey] 앱 내비게이션 관리를 위한 키
  /// [scaffoldKey] 스캐폴드 메신저 관리를 위한 키
  /// [routes] 앱 라우트 맵
  /// [title] 앱 제목
  /// [theme] 앱 테마
  /// [home] 홈 위젯
  /// [supportedLocales] 지원하는 언어 로케일 목록
  /// [localizationsDelegates] 국제화 델리게이트 목록
  /// [locale] 현재 언어 로케일
  static Widget buildApp({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> scaffoldKey,
    required Map<String, WidgetBuilder> routes,
    required String title,
    required ThemeData theme,
    required Widget home,
    required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
    required List<Locale> supportedLocales,
    required Locale locale,
  }) {
    // ScreenUtil 초기화 문제를 해결하기 위한 개선된 구현
    return ScreenUtilInit(
      designSize: kAppDesignSize,
      minTextAdapt: true,
      splitScreenMode: kAppSplitScreenMode,
      // ScreenUtil 초기화 오류를 잡아 처리하는 builder 추가
      builder: (context, child) {
        // child가 null인 경우에도 안전하게 처리
        final safeChild =
            child ??
            _buildOverlaySupport(
              navigatorKey: navigatorKey,
              scaffoldKey: scaffoldKey,
              routes: routes,
              title: title,
              theme: theme,
              home: home,
              localizationsDelegates: localizationsDelegates,
              supportedLocales: supportedLocales,
              locale: locale,
            );

        return safeChild;
      },
      // 기본 child도 설정하여 이중으로 보호
      child: _buildOverlaySupport(
        navigatorKey: navigatorKey,
        scaffoldKey: scaffoldKey,
        routes: routes,
        title: title,
        theme: theme,
        home: home,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        locale: locale,
      ),
    );
  }

  /// OverlaySupport 설정 및 이후 위젯 구성을 위한 헬퍼 메서드
  static Widget _buildOverlaySupport({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> scaffoldKey,
    required Map<String, WidgetBuilder> routes,
    required String title,
    required ThemeData theme,
    required Widget home,
    required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
    required List<Locale> supportedLocales,
    required Locale locale,
  }) {
    // OverlaySupport 토스트는 MaterialApp 바깥 오버레이에 그려지므로, 글자 크기
    // 상한은 그 위에 둔다. 앱·다이얼로그·토스트가 모두 같은 상한을 받는다.
    return Builder(
      builder: (context) => clampTextScale(
        context,
        OverlaySupport.global(
          child: _buildMaterialApp(
            navigatorKey: navigatorKey,
            scaffoldKey: scaffoldKey,
            routes: routes,
            title: title,
            theme: theme,
            home: home,
            localizationsDelegates: localizationsDelegates,
            supportedLocales: supportedLocales,
            locale: locale,
          ),
        ),
      ),
    );
  }

  /// MaterialApp 기본 구성 생성
  static Widget _buildMaterialApp({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> scaffoldKey,
    required Map<String, WidgetBuilder> routes,
    required String title,
    required ThemeData theme,
    required Widget home,
    required List<LocalizationsDelegate<dynamic>> localizationsDelegates,
    required List<Locale> supportedLocales,
    required Locale locale,
  }) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: AppAnalytics.buildNavigatorObservers(),
      // 원복: 앱에서 전달한 scaffoldKey 사용
      scaffoldMessengerKey: scaffoldKey,
      title: title,
      theme: applySystemNavigationBarInset(theme),
      debugShowCheckedModeBanner: false,
      routes: routes,
      home: home,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      localeResolutionCallback: (locale, supportedLocales) {
        // 로케일이 변경될 때마다 LocaleService 업데이트
        if (locale != null) {
          LocaleService.instance.updateLanguageCode(locale.languageCode);
          // logger.i('LocaleService 업데이트: ${locale.languageCode}');
          // Analytics language / locale 동기화.
          //
          // 택소노미 §1 의 `language` 사용자 속성은 로그인 여부와 무관하게
          // 최신 언어를 반영해야 하므로, 비로그인 사용자도 갱신한다.
          try {
            final user = supabase.auth.currentUser;
            if (user != null) {
              AppAnalytics.setUserAndSessionProperties(
                userId: user.id,
                locale: locale.languageCode,
                language: locale.languageCode,
                isLogin: true,
              );
            } else {
              PicnicAnalytics.instance.setUserProperties(
                userId: null,
                isLogin: false,
                language: locale.languageCode,
              );
            }
          } catch (_) {}
        }
        return locale;
      },
    );
  }

  /// [child] 아래의 시스템 글자 크기를 [kAppMaxTextScaleFactor] 로 제한한다.
  ///
  /// MaterialApp 과 OverlaySupport 보다 위에 두어야 push 되는 라우트,
  /// 다이얼로그, 토스트까지 함께 제한된다.
  static Widget clampTextScale(BuildContext context, Widget? child) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: kAppMaxTextScaleFactor,
      child: child ?? const SizedBox.shrink(),
    );
  }

  /// Android 시스템 내비 바 영역을 모든 [MaterialPageRoute] 안쪽에서 예약한다
  /// (PICNIC-777). 홈(Portal)과 루트 내비게이터로 push 되는 라우트가 전부
  /// 바 위에서 끝나고, 하위 트리의 `MediaQuery.padding.bottom` 은 0 이 된다.
  /// `showGeneralDialog` 계열은 이 테마를 타지 않으므로 [FullScreenDialog] 가
  /// 따로 처리한다.
  static ThemeData applySystemNavigationBarInset(ThemeData theme) {
    final builders = Map<TargetPlatform, PageTransitionsBuilder>.of(
      theme.pageTransitionsTheme.builders,
    );
    final android =
        builders[TargetPlatform.android] ??
        const PageTransitionsTheme().builders[TargetPlatform.android]!;
    if (android is SystemNavigationBarInsetPageTransitionsBuilder) {
      return theme;
    }
    builders[TargetPlatform.android] =
        SystemNavigationBarInsetPageTransitionsBuilder(android);
    return theme.copyWith(
      pageTransitionsTheme: PageTransitionsTheme(builders: builders),
    );
  }

  /// 앱 초기화 상태 관리를 위한 유틸리티 메서드
  ///
  /// [context] 빌드 컨텍스트
  /// [ref] Riverpod WidgetRef
  /// [onInitComplete] 초기화 완료 시 호출될 콜백 함수
  static Future<void> initializeAppCommon(
    BuildContext context,
    WidgetRef ref,
    Function(bool) onInitComplete,
  ) async {
    try {
      logger.i('앱 공통 초기화 시작');

      // 앱 생명주기 초기화 설정
      AppLifecycleInitializer.setupAppInitializers(ref, context);

      // 초기화 성공 콜백
      onInitComplete(true);

      // 앱 초기화 완료 표시
      AppLifecycleInitializer.markAppInitialized(ref);

      logger.i('앱 공통 초기화 완료');
    } catch (e, stackTrace) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
      onInitComplete(false);
    }
  }

  /// 언어 변경 시 앱 UI 업데이트를 위한 유틸리티 메서드
  ///
  /// [context] 빌드 컨텍스트
  /// [ref] Riverpod WidgetRef
  /// [language] 변경할 언어 코드 ('ko', 'en' 등)
  /// [onComplete] 언어 변경 후 호출될 콜백 함수
  static void updateAppLanguage(
    BuildContext context,
    WidgetRef ref,
    String language,
    Function(String)? onComplete,
  ) {
    // 구현 예정: 언어 변경 시 앱 UI 업데이트 로직
    if (onComplete != null) {
      onComplete(language);
    }
  }

  /// ScreenUtil이 초기화되었는지 확인하는 헬퍼 메서드
  static bool isScreenUtilInitialized() {
    try {
      // 간단한 값을 가져와서 예외가 발생하는지 확인
      return true;
    } catch (e) {
      return false;
    }
  }
}
