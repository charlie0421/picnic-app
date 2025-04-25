import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/pages/oauth_callback_page.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_protector_provider.dart';
import 'package:picnic_lib/presentation/screens/pic/pic_camera_screen.dart';
import 'package:picnic_lib/presentation/screens/privacy.dart';
import 'package:picnic_lib/presentation/screens/purchase.dart';
import 'package:picnic_lib/presentation/screens/signup/signup_screen.dart';
import 'package:picnic_lib/presentation/screens/terms.dart';
import 'package:picnic_lib/ui/community_theme.dart';
import 'package:picnic_lib/ui/mypage_theme.dart';
import 'package:picnic_lib/ui/novel_theme.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/vote_theme.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:ttja_app/bottom_navigation_menu.dart';
import 'package:ttja_app/presenstation/screens/portal.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/services/localization_service.dart';
import 'package:ttja_app/generated/l10n.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  // MaterialApp 강제 리빌드를 위한 키 추가
  Key _materialAppKey = UniqueKey();

  bool _isAppInitialized = false;
  bool _isLanguageLoaded = false;
  Widget? initScreen;
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  StreamSubscription? _authSubscription;
  StreamSubscription? _appLinksSubscription;

  static final Map<String, WidgetBuilder> _routes = {
    Portal.routeName: (context) => const Portal(),
    SignUpScreen.routeName: (context) => const SignUpScreen(),
    '/pic-camera': (context) => const PicCameraScreen(),
    'terms/ko': (context) => const TermsScreen(),
    'terms/en': (context) => const TermsScreen(),
    'privacy/ko': (context) => const PrivacyScreen(),
    'privacy/en': (context) => const PrivacyScreen(),
    PurchaseScreen.routeName: (context) => const PurchaseScreen(),
  };

  @override
  void initState() {
    super.initState();
    logger.i('App initState 호출됨');

    // Supabase 인증 리스너는 웹과 모바일 모두에서 필요함
    AppInitializer.setupSupabaseAuthListener(ref);

    // Branch 리스너는 모바일에서만 필요
    if (UniversalPlatform.isMobile && !kIsWeb) {
      AppInitializer.setupBranchListener(ref);
    }

    // 초기화 로직을 initState()에서 수행 - 별도 Future로 선언하지 않고 즉시 실행
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    logger.i('_initializeApp 시작');

    // 앱이 이미 초기화되었다면 바로 반환
    if (_isAppInitialized) {
      logger.i('앱이 이미 초기화됨. 초기화 과정 스킵');
      return;
    }

    // 모바일 환경에서만 시스템 UI 초기화
    if (UniversalPlatform.isMobile && !kIsWeb) {
      await AppInitializer.initializeSystemUI();
    }

    if (!mounted) {
      logger.e('앱 초기화 중 위젯이 dispose됨');
      _isAppInitialized = false;
      return;
    }

    // 언어 초기화는 다른 초기화와 병렬로 진행
    _initializeLanguage();

    // 앱 초기화 (모바일/웹 구분)
    try {
      if (UniversalPlatform.isMobile) {
        await AppInitializer.initializeAppWithSplash(context, ref);
      } else {
        await AppInitializer.initializeWebApp(context, ref);
      }

      if (!mounted) return;

      // 스크린 정보 맵 생성
      final screenInfoMap = {
        PortalType.vote.name.toString(): voteScreenInfo,
        PortalType.pic.name.toString(): picScreenInfo,
        PortalType.community.name.toString(): communityScreenInfo,
        PortalType.novel.name.toString(): novelScreenInfo,
      };

      // screenInfosProvider에 스크린 정보 설정
      ref.read(screenInfosProvider.notifier).setScreenInfoMap(screenInfoMap);

      // 앱 초기화 완료 플래그 설정
      if (mounted) {
        setState(() {
          _isAppInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isAppInitialized = false;
        });
      }
    }

    logger.i('_initializeApp 완료');
  }

  // 언어 초기화를 위한 별도 메서드
  Future<void> _initializeLanguage() async {
    try {
      // 현재 언어 설정 로드 (앱 설정에서 가져옴)
      await ref.read(appSettingProvider.notifier).loadSettings();
      String currentLanguage = ref.read(appSettingProvider).language;
      logger.i('설정에서 로드된 현재 언어: $currentLanguage');

      // 언어가 비어있거나 영어인 경우 한국어로 설정
      if (currentLanguage.isEmpty || currentLanguage == 'en') {
        logger.i('언어가 비어있거나 영어로 설정됨, 한국어로 설정');
        currentLanguage = 'ko';
        ref.read(appSettingProvider.notifier).setLanguage('ko');
        await globalStorage.saveData('language', 'ko');
      }

      // Intl.defaultLocale을 반드시 설정 (중요!)
      Intl.defaultLocale = currentLanguage;
      logger.i('Intl.defaultLocale 설정: $currentLanguage');

      // PicnicLibL10n 초기화
      await PicnicLibL10n.initialize(
        ref.read(appSettingProvider.notifier),
        ProviderScope.containerOf(context),
      );
      logger.i('PicnicLibL10n 초기화 완료');

      // LocalizationService를 통한 번역 로드
      await LocalizationService.loadTranslations(Locale(currentLanguage));
      logger.i('$currentLanguage 언어 번역 로드 완료');

      // 앱의 번역 로드
      await S.load(Locale(currentLanguage));
      logger.i('S.load() 완료: $currentLanguage');

      // PicnicLibL10n에 현재 언어 설정
      PicnicLibL10n.setCurrentLocale(currentLanguage);
      logger.i('PicnicLibL10n 언어 설정 완료: $currentLanguage');

      if (mounted) {
        setState(() {
          _isLanguageLoaded = true;
          // MaterialApp 강제 리빌드를 위한 키 갱신
          _materialAppKey = UniqueKey();
          logger.i('언어 로딩 완료 상태 설정됨, MaterialApp 키 갱신됨');
        });
      }
    } catch (e) {
      logger.e('언어 초기화 중 오류 발생', error: e);
      // 오류 발생 시 기본값으로 한국어 설정
      try {
        Intl.defaultLocale = 'ko';
        await S.load(const Locale('ko'));
        PicnicLibL10n.setCurrentLocale('ko');
        if (mounted) {
          setState(() {
            _isLanguageLoaded = true;
          });
        }
      } catch (recoveryError) {
        logger.e('언어 복구 중 추가 오류 발생', error: recoveryError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 언어 변경 감지 및 적용 로직
    ref.listen<Setting>(
      appSettingProvider,
      (previous, current) {
        if (previous?.language != current.language) {
          logger.i('언어 변경 감지: ${previous?.language} -> ${current.language}');
          _applyLanguageChange(current.language);
        }
      },
    );

    return ScreenUtilInit(
      designSize: const Size(393, 892),
      minTextAdapt: true,
      splitScreenMode: true,
      child: OverlaySupport.global(
        child: Consumer(
          builder: (context, ref, child) {
            final appSettingState = ref.watch(appSettingProvider);
            final isScreenProtector = ref.watch(isScreenProtectorProvider);

            // 화면 보호기 업데이트
            _updateScreenProtector(isScreenProtector);

            // 현재 언어 가져오기
            final currentLanguage = appSettingState.language;

            logger.i(
                'MaterialApp 빌드: language=$currentLanguage, isAppInitialized=$_isAppInitialized, isLanguageLoaded=$_isLanguageLoaded');

            return MaterialApp(
              key: _materialAppKey,
              scaffoldMessengerKey: _scaffoldKey,
              navigatorKey: navigatorKey,
              title: 'TTJA',
              theme: _getCurrentTheme(ref),
              themeMode: appSettingState.themeMode,
              locale: Locale(currentLanguage),
              localizationsDelegates: [
                // 앱 자체 로컬라이제이션
                S.delegate,
                // PicnicLib 로컬라이제이션
                ...LocalizationService.localizationDelegates,
                // Flutter 기본 로컬라이제이션
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: LocalizationService.supportedLocales,
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
              builder: UniversalPlatform.isWeb
                  ? (context, child) => MediaQuery(
                        data: ref
                            .watch(globalMediaQueryProvider)
                            .copyWith(size: const Size(600, 800)),
                        child: UpdateDialog(
                            child: child ?? const SizedBox.shrink()),
                      )
                  : (context, child) =>
                      UpdateDialog(child: child ?? const SizedBox.shrink()),
              home: _isAppInitialized && _isLanguageLoaded
                  ? const Portal()
                  : const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }

  // 앱의 메인 화면 구성

  void _updateScreenProtector(bool isScreenProtector) {
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

  // 언어 변경 적용 - 번역을 즉시 로드하고 UI를 업데이트하는 강화된 메서드
  void _applyLanguageChange(String language) {
    logger.d('Language change to $language');
    try {
      setState(() {
        _isAppInitialized = false;
        _isLanguageLoaded = false;
      });

      // 변경된 부분: 언어 변경 순서 최적화
      Intl.defaultLocale = language;

      // 1. PicnicLib의 로케일 설정
      PicnicLibL10n.setCurrentLocale(language);

      // 2. LocalizationService를 통한 번역 로드
      LocalizationService.loadTranslations(Locale(language)).then((_) {
        // 3. 앱의 S 클래스 번역 로드
        S.load(Locale(language)).then((_) {
          if (mounted) {
            setState(() {
              _isLanguageLoaded = true;
              _isAppInitialized = true;
              _materialAppKey = UniqueKey(); // 강제 리빌드
              logger.i('언어 변경 완료: $language, UI 리빌드 트리거');
            });
          }
        });
      }).catchError((e) {
        logger.e('번역 로드 중 오류: $e');
        if (mounted) {
          setState(() {
            _isLanguageLoaded = true;
            _isAppInitialized = true;
          });
        }
      });
    } catch (e) {
      logger.e('언어 변경 적용 중 오류: $e');
      if (mounted) {
        setState(() {
          _isLanguageLoaded = true;
          _isAppInitialized = true;
        });
      }
    }
  }
}
