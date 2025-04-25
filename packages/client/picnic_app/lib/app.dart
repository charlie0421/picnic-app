// ignore_for_file: unused_field, unused_element

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/main.dart' as main_file;
import 'package:picnic_app/presentation/screens/portal.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/l10n.dart';
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
import 'package:picnic_lib/core/config/environment.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/services/localization_service.dart';

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

  // MaterialApp 리빌드를 위한 키 추가
  Key _materialAppKey = UniqueKey();

  // 지원되는 언어 목록
  static const List<Locale> _supportedLocales = [
    Locale('ko'), // 한국어 (기본값)
    Locale('en'), // 영어
    Locale('ja'), // 일본어
    Locale('zh'), // 중국어
    Locale('id'), // 인도네시아어
  ];

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

      // 언어 및 국제화 초기화 - 이 과정이 완료되길 기다림
      await _initializeLocalization();
      logger.i('언어 및 국제화 초기화 완료');

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

      // 최종 언어가 제대로 설정되었는지 확인
      final currentLanguage = ref.read(appSettingProvider).language;
      logger.i('앱 초기화 완료 후 최종 언어 확인: $currentLanguage');

      // 앱 초기화 완료 플래그 설정
      if (mounted) {
        setState(() {
          _isAppInitialized = true;
          _materialAppKey = UniqueKey(); // 새 키로 MaterialApp 강제 리빌드
          logger.i('_isAppInitialized 상태를 true로 변경, 앱 UI 리빌드 트리거');
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

  // 언어 및 국제화 초기화
  Future<void> _initializeLocalization() async {
    try {
      logger.i('언어 및 국제화 초기화 시작');

      // main.dart에서 이미 초기화된 전역 언어 상태 확인
      final mainInitialized =
          main_file.isLanguageInitialized; // main.dart에서 선언된 전역 변수
      logger.i('main.dart 언어 초기화 상태: $mainInitialized');

      // 현재 언어 확인 (전역 변수 또는 저장소에서 가져옴)
      String finalLanguage = main_file.currentLanguage; // main.dart에서 설정된 전역 변수
      logger.i('main.dart에서 설정된 언어: $finalLanguage');

      // 앱 설정에 현재 언어 설정 반영 - 저장은 이미 main.dart에서 수행됨
      final appSettingNotifier = ref.read(appSettingProvider.notifier);
      await appSettingNotifier.loadSettings();
      appSettingNotifier.setLanguage(finalLanguage);
      logger.i('앱 설정에 언어 반영: $finalLanguage');

      // LocalizationService 및 Crowdin이 이미 초기화되었으므로 여기서는 PicnicLibL10n 초기화만 필요
      await PicnicLibL10n.initialize(ref.read(appSettingProvider.notifier),
          ProviderScope.containerOf(context));
      logger.i('PicnicLibL10n 초기화 완료');

      // 필요한 경우에만 추가 번역 로드 (언어가 변경된 경우)
      if (ref.read(appSettingProvider).language != finalLanguage) {
        logger.i('언어 불일치 감지. 추가 번역 로드 필요');

        // PicnicLibL10n에 현재 언어 설정
        PicnicLibL10n.setCurrentLocale(finalLanguage);
        logger.i('PicnicLibL10n 언어 설정 완료: $finalLanguage');

        // 테스트용 번역 확인
        final testKey = 'app_name';
        final testTranslation = t(testKey);
        logger.i('번역 테스트: $testKey -> $testTranslation');
      } else {
        logger.i('언어 설정 일치 확인됨: $finalLanguage. 추가 로드 불필요');
      }

      logger.i('언어 및 국제화 초기화 완료');
    } catch (e, stackTrace) {
      logger.e('언어 및 국제화 초기화 오류', error: e, stackTrace: stackTrace);

      // 오류 발생 시 기본값으로 복구
      try {
        await globalStorage.saveData('language', 'ko');
        Intl.defaultLocale = 'ko';
        await S.load(const Locale('ko'));
        PicnicLibL10n.setCurrentLocale('ko');
        logger.i('오류 복구: 한국어로 기본 설정');
      } catch (recoveryError) {
        logger.e('오류 복구 중 추가 오류 발생', error: recoveryError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(appInitializationProvider);
    final appSettingState = ref.watch(appSettingProvider);

    // 언어 변경 감지 리스너
    ref.listen<Setting>(
      appSettingProvider,
      (previous, current) {
        if (previous?.language != current.language) {
          logger.i('언어 변경 감지: ${previous?.language} -> ${current.language}');

          // 비동기 처리를 위해 별도 메서드로 분리
          _applyLanguageChange(current.language);
        }
      },
    );

    // 언어 상태 정보 로깅 (main.dart의 상태와 현재 앱 상태 비교)
    final mainLanguage = main_file.currentLanguage;
    final appLanguage = appSettingState.language;
    final isLanguageConsistent = mainLanguage == appLanguage;

    logger.i('''
build 메서드 상태:
- initState: $initState
- _isAppInitialized: $_isAppInitialized
- main.dart 언어: $mainLanguage
- app 언어: $appLanguage
- 언어 일치 여부: $isLanguageConsistent
- currentLocale: ${Locale(appSettingState.language)}
- materialAppKey: $_materialAppKey
''');

    // 언어가 일치하지 않으면 동기화
    if (!isLanguageConsistent && _isAppInitialized) {
      logger.w('언어 불일치 감지. 동기화 필요: main=$mainLanguage, app=$appLanguage');

      // 다음 프레임에서 언어 변경 적용 (build 중에 setState 호출 방지)
      Future.microtask(() {
        if (mainLanguage != appLanguage) {
          // appSettingState 업데이트가 우선순위
          ref.read(appSettingProvider.notifier).setLanguage(mainLanguage);
        }
      });
    }

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
      currentScreen = const Portal();
    }

    // 현재 언어 정보 로깅
    final currentLocale = Locale(appSettingState.language);
    logger.i('현재 언어: ${currentLocale.languageCode}');

    return MaterialApp(
      key:
          ValueKey('${_materialAppKey.toString()}_${appSettingState.language}'),
      navigatorKey: navigatorKey,
      title: 'TTJA',
      theme: _getCurrentTheme(ref),
      themeMode: appSettingState.themeMode,
      locale: Locale(appSettingState.language),
      localizationsDelegates: [
        ...LocalizationService.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: _supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        // 지원하지 않는 로케일이 요청된 경우 기본값(한국어)으로 대체
        if (locale != null) {
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        // 기본 로케일 반환(한국어)
        return const Locale('ko');
      },
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

  Future<void> _applyLanguageChange(String language) async {
    try {
      logger.i('언어 변경 시작: $language');

      // 언어 변경 중에는 화면을 스플래시 화면으로 돌려놓아 PagingController 오류 방지
      if (mounted) {
        setState(() {
          _isAppInitialized = false; // 앱 초기화 상태를 false로 설정하여 스플래시 화면 표시
          logger.i('언어 변경 중 일시적으로 스플래시 화면으로 전환');
        });
      }

      // 비동기 작업이 완료될 시간 확보
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. main.dart의 전역 변수 업데이트 - 앱 전체에서 일관된 언어 상태 유지
      main_file.currentLanguage = language;
      logger.i('main.dart 전역 변수 업데이트: $language');

      // 2. 모든 번역 리소스 초기화
      try {
        // LocalizationService를 통해 Crowdin 번역 로드
        await LocalizationService.loadTranslations(Locale(language));
        logger.i('Crowdin 번역 로드 완료: $language');

        // Intl.defaultLocale 설정 (정확한 언어 표시에 중요)
        Intl.defaultLocale = language;
        logger.i('Intl.defaultLocale 설정: $language');

        // 앱 내 생성된 S 클래스 번역 로드
        await S.load(Locale(language));
        logger.i('S.load() 완료: $language');

        // PicnicLibL10n 설정
        PicnicLibL10n.setCurrentLocale(language);
        logger.i('PicnicLibL10n.setCurrentLocale 완료: $language');
      } catch (translationError) {
        logger.e('번역 리소스 로드 오류', error: translationError);
      }

      // 3. 강제 리빌드를 위해 MaterialApp 키 변경 및 앱 재초기화
      if (mounted) {
        setState(() {
          // 키를 변경하여 MaterialApp이 완전히 새로 빌드되도록 함
          _materialAppKey = UniqueKey();
          _isAppInitialized = true; // 앱 초기화 완료 상태로 변경
          logger.i('MaterialApp 키 갱신 및 앱 초기화 완료: $language');
        });
      }
    } catch (e) {
      // 오류가 발생해도 앱 초기화 상태 복구
      if (mounted) {
        setState(() {
          _isAppInitialized = true;
        });
      }
      logger.e('언어 변경 처리 중 오류 발생', error: e);
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
