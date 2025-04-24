// ignore_for_file: unused_field, unused_element

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_app/presentation/screens/portal.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/force_update_overlay.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/pages/oauth_callback_page.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_protector_provider.dart';
import 'package:picnic_lib/presentation/providers/update_checker.dart';
import 'package:picnic_lib/presentation/screens/ban_screen.dart';
import 'package:picnic_lib/presentation/screens/network_error_screen.dart';
import 'package:picnic_lib/presentation/screens/pic/pic_camera_screen.dart';
import 'package:picnic_lib/presentation/screens/privacy.dart';
import 'package:picnic_lib/presentation/screens/purchase.dart';
import 'package:picnic_lib/presentation/screens/signup/signup_screen.dart';
import 'package:picnic_lib/presentation/screens/terms.dart';
import 'package:picnic_lib/presentation/widgets/splash_image.dart';
import 'package:picnic_lib/ui/community_theme.dart';
import 'package:picnic_lib/ui/mypage_theme.dart';
import 'package:picnic_lib/ui/novel_theme.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/vote_theme.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/core/config/environment.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late Future<void> _initializationFuture;
  Widget? initScreen;
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  StreamSubscription? _authSubscription;
  StreamSubscription? _appLinksSubscription;

  // 앱이 이미 초기화되었는지 여부를 추적하는 플래그
  bool _isAppInitialized = false;

  // 앱이 초기화된 후의 화면을 캐시하기 위한 변수
  Widget? _initializedAppScreen;

  static final Map<String, WidgetBuilder> _routes = {
    Portal.routeName: (context) => const Portal(),
    SignUpScreen.routeName: (context) => const SignUpScreen(),
    '/pic-camera': (context) => const PicCameraScreen(),
    TermsScreen.routeName: (context) => const TermsScreen(),
    PrivacyScreen.routeName: (context) => const PrivacyScreen(),
    PurchaseScreen.routeName: (context) => const PurchaseScreen(),
  };

  @override
  void initState() {
    super.initState();
    logger.i('App initState 호출됨');

    // 초기화 로직을 initState()에서 수행
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    logger.i('_initializeApp 시작');

    // 앱이 이미 초기화되었다면 바로 반환
    if (_isAppInitialized) {
      logger.i('앱이 이미 초기화됨. 초기화 과정 스킵');
      return;
    }

    try {
      // 기본 초기화
      logger.i('기본 초기화 시작');
      await AppInitializer.initializeBasics();
      logger.i('기본 초기화 완료');

      // 환경 초기화
      logger.i('환경 초기화 시작');
      await AppInitializer.initializeEnvironment(
          Environment.currentEnvironment);
      logger.i('환경 초기화 완료');

      // 모바일 환경에서만 시스템 UI 초기화
      if (UniversalPlatform.isMobile && !kIsWeb) {
        logger.i('시스템 UI 초기화 시작');
        await AppInitializer.initializeSystemUI();
        logger.i('시스템 UI 초기화 완료');
      }

      if (!mounted) {
        logger.e('앱 초기화 중 위젯이 dispose됨');
        _isAppInitialized = false;
        return;
      }

      // 스크린 정보 설정 제거 (각 화면에서 직접 정의하므로 여기서는 필요 없음)
      logger.i('스크린 정보 초기화 필요 없음 - 직접 정의 방식으로 변경됨');

      // 앱 초기화
      logger.i('앱 초기화 시작');
      if (UniversalPlatform.isMobile) {
        await AppInitializer.initializeAppWithSplash(context, ref);
      } else {
        await AppInitializer.initializeWebApp(context, ref);
      }
      logger.i('앱 초기화 완료');

      if (!mounted) {
        logger.e('앱 초기화 완료 후 위젯이 dispose됨');
        _isAppInitialized = false;
        return;
      }

      // 앱 초기화 완료 플래그 설정
      if (mounted) {
        setState(() {
          _isAppInitialized = true;
          logger.i('_isAppInitialized 상태를 true로 변경');
        });
      }

      logger.i('_initializeApp 완료');
    } catch (e, stackTrace) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isAppInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(appInitializationProvider);
    final appSettingState = ref.watch(appSettingProvider);

    logger.i('''
build 메서드 상태:
- initState: $initState
- _isAppInitialized: $_isAppInitialized
- appSettingState: $appSettingState
''');

    // ScreenUtil 초기화
    ScreenUtil.init(
      context,
      designSize: const Size(393, 892),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    Widget currentScreen;
    if (!_isAppInitialized) {
      logger.i('앱이 초기화되지 않음 - 스플래시 화면 표시');
      currentScreen = const SplashImage();
    } else if (!initState.hasNetwork) {
      logger.i('네트워크 오류 - 네트워크 오류 화면 표시');
      currentScreen = NetworkErrorScreen(onRetry: _retryConnection);
    } else if (initState.isBanned) {
      logger.i('밴 상태 - 밴 화면 표시');
      currentScreen = const BanScreen();
    } else if (initState.updateInfo?.status == UpdateStatus.updateRequired &&
        !kIsWeb) {
      logger.i('업데이트 필요 - 업데이트 화면 표시');
      currentScreen = ForceUpdateOverlay(updateInfo: initState.updateInfo!);
    } else {
      logger.i('정상 상태 - 포털 화면 표시');
      final currentScreenInfoState = ref.read(screenInfosProvider);
      logger.i('포털 표시 직전 screenInfosProvider 상태: $currentScreenInfoState');
      currentScreen = const Portal();
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TTJA',
      theme: _getCurrentTheme(ref),
      themeMode: appSettingState.themeMode,
      locale: PicnicLibL10n.getCurrentLocale(),
      localizationsDelegates: PicnicLibL10n.localizationsDelegates,
      supportedLocales: PicnicLibL10n.supportedLocales,
      routes: _buildRoutes(),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        final path = uri.path;

        if (path.startsWith('/auth/callback')) {
          logger.i('OAuth callback: $uri');
          return MaterialPageRoute(
            builder: (_) => OAuthCallbackPage(callbackUri: uri),
            settings: settings,
          );
        }
        return MaterialPageRoute(builder: (_) => const Portal());
      },
      navigatorObservers: [observer],
      builder: (context, child) {
        return OverlaySupport.global(
          child: UniversalPlatform.isWeb
              ? MediaQuery(
                  data: ref
                      .watch(globalMediaQueryProvider)
                      .copyWith(size: const Size(600, 800)),
                  child: UpdateDialog(child: child ?? currentScreen),
                )
              : UpdateDialog(child: child ?? currentScreen),
        );
      },
      home: currentScreen,
    );
  }

  // 앱의 메인 화면 구성
  Widget _buildMainApp() {
    logger.i('_buildMainApp 호출됨');
    return _buildNextScreen();
  }

  Future<void> _retryConnection() async {
    await AppInitializer.retryConnection(ref);
  }

  Widget _buildNextScreen() {
    logger.i('_buildNextScreen 호출됨 - 앱 초기화 완료');
    final initState = ref.watch(appInitializationProvider);

    // 스크린 정보 상태 확인 (현재 상태 로깅)
    final screenInfos = ref.read(screenInfosProvider);
    logger.i('_buildNextScreen에서 스크린 정보 상태: $screenInfos');

    if (!initState.hasNetwork) {
      return NetworkErrorScreen(onRetry: _retryConnection);
    }

    if (initState.isBanned) {
      return const BanScreen();
    }

    if (initState.updateInfo?.status == UpdateStatus.updateRequired &&
        !kIsWeb) {
      return ForceUpdateOverlay(updateInfo: initState.updateInfo!);
    }

    return ScreenUtilInit(
      designSize: const Size(393, 892),
      minTextAdapt: true,
      splitScreenMode: true,
      child: OverlaySupport.global(
        child: Consumer(
          builder: (context, ref, child) {
            final isScreenProtector = ref.watch(isScreenProtectorProvider);
            _updateScreenProtector(isScreenProtector);

            return UniversalPlatform.isWeb
                ? MediaQuery(
                    data: ref
                        .watch(globalMediaQueryProvider)
                        .copyWith(size: const Size(600, 800)),
                    child: UpdateDialog(child: initScreen ?? const Portal()),
                  )
                : UpdateDialog(child: initScreen ?? const Portal());
          },
        ),
      ),
    );
  }

  void _updateScreenProtector(bool isScreenProtector) {
    // 웹에서는 스크린 프로텍터 기능 사용하지 않음
    if (!kIsWeb && UniversalPlatform.isMobile) {
      if (isScreenProtector) {
        ScreenProtector.protectDataLeakageWithColor(AppColors.primary500);
        ScreenProtector.preventScreenshotOn();
      } else {
        ScreenProtector.protectDataLeakageWithColorOff();
        ScreenProtector.preventScreenshotOff();
      }
    }
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return _routes;
  }

  ThemeData _getCurrentTheme(WidgetRef ref) {
    final currentPortal = ref.watch(navigationInfoProvider);
    switch (currentPortal.portalType) {
      case PortalType.vote:
        return voteThemeLight;
      case PortalType.pic:
        return picThemeLight;
      case PortalType.community:
        return communityThemeLight;
      case PortalType.novel:
        return novelThemeLight;
      case PortalType.mypage:
        return mypageThemeLight;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _appLinksSubscription?.cancel();
    if (!kIsWeb) {
      ScreenProtector.preventScreenshotOff();
    }
    super.dispose();
  }
}
