import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/generated/l10n.dart';

import 'package:picnic_app/presentation/screens/portal.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_initializer.dart';
import 'package:picnic_lib/core/utils/language_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/route_manager.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/force_update_overlay.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_protector_provider.dart';
import 'package:picnic_lib/presentation/screens/ban_screen.dart';
import 'package:picnic_lib/presentation/screens/network_error_screen.dart';
import 'package:picnic_lib/presentation/widgets/splash_image.dart';
import 'package:picnic_lib/ui/community_theme.dart';
import 'package:picnic_lib/ui/mypage_theme.dart';
import 'package:picnic_lib/ui/novel_theme.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/vote_theme.dart';
import 'package:picnic_lib/core/config/environment.dart';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/device_debug_info.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  Widget? initScreen;
  StreamSubscription? _authSubscription;
  StreamSubscription? _appLinksSubscription;

  // 앱이 이미 초기화되었는지 여부를 추적하는 플래그
  bool _isAppInitialized = false;

  // 스캐폴드 메신저 키
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  // 지원되는 언어 목록
  static const List<Locale> _supportedLocales = [
    Locale('ko'), // 한국어 (기본값)
    Locale('en'), // 영어
    Locale('ja'), // 일본어
    Locale('zh'), // 중국어
    Locale('id'), // 인도네시아어
  ];

  // 앱의 라우트 맵 - 앱 고유 라우트만 포함 (공통 라우트는 RouteManager에서 관리)
  final Map<String, WidgetBuilder> _appSpecificRoutes = {
    Portal.routeName: (context) => const Portal(),
  };

  @override
  void initState() {
    super.initState();
    logger.i('App initState 호출됨');

    // AppLifecycleInitializer를 사용하여 앱 초기화 및 리스너 설정
    AppLifecycleInitializer.setupAppInitializers(ref, context);

    // 라우트 설정
    AppLifecycleInitializer.setupAppRoutes(ref, _appSpecificRoutes);

    // 디버그 모드에서 디바이스 정보 로깅
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DeviceDebugInfo.logDeviceInfo();
        DeviceDebugInfo.logSafeAreaInfo(context);
        DeviceDebugInfo.isGalaxyS25Like(context);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppInitializer.initializeAppWithSplash(context, ref);
    });

    // 기존 코드의 나머지 부분은 유지
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    logger.i('_initializeApp 시작');

    // 앱이 이미 초기화되었다면 바로 반환
    if (_isAppInitialized) {
      logger.i('앱이 이미 초기화됨. 초기화 과정 스킵');
      return;
    }

    try {
      // 컨텍스트 없이 실행 가능한 초기화 부분
      await _initializeAppBasics();

      // mounted 상태 확인
      if (!mounted) {
        logger.e('앱 초기화 중 위젯이 dispose됨');
        return;
      }

      // 컨텍스트가 필요한 부분 동기적으로 실행
      _initializeAppWithContext();

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

  // 컨텍스트가 필요 없는 초기화 작업
  Future<void> _initializeAppBasics() async {
    // 기본 초기화
    logger.i('기본 초기화 시작');
    await AppInitializer.initializeBasics();
    logger.i('기본 초기화 완료');

    // 환경 초기화
    logger.i('환경 초기화 시작');
    await AppInitializer.initializeEnvironment(Environment.currentEnvironment);
    logger.i('환경 초기화 완료');

    // 시스템 UI 초기화
    logger.i('시스템 UI 초기화 시작');
    await AppInitializer.initializeSystemUI();
    logger.i('시스템 UI 초기화 완료');

    // 언어 및 국제화 초기화
    await _initializeLanguage();
    logger.i('언어 및 국제화 초기화 완료');
  }

  // 컨텍스트가 필요한 초기화 작업 (동기적으로 실행)
  void _initializeAppWithContext() {
    // 앱 초기화 (필요한 경우 Future.microtask로 래핑)
    Future.microtask(() async {
      try {
        logger.i('앱 초기화 시작 (with context)');

        // ignore: use_build_context_synchronously
        // 이 경고를 무시하는 이유: Future.microtask 내부에서 사용되는 context는
        // 하위 위젯 빌드 없이 초기화 목적으로만 사용되며, mounted 체크를 통해 안전하게 관리됨
        if (mounted) {
          // 일반 앱 초기화 진행 (패치 체크는 SplashImage에서 담당)
          await AppInitializer.initializeAppWithSplash(context, ref);
        }

        logger.i('앱 초기화 완료 (with context)');

        if (!mounted) return;

        // 최종 언어가 제대로 설정되었는지 확인
        final currentLanguage = ref.read(appSettingProvider).language;
        logger.i('앱 초기화 완료 후 최종 언어 확인: $currentLanguage');

        setState(() {
          _isAppInitialized = true;
          logger.i('_isAppInitialized 상태를 true로 변경, 앱 UI 리빌드 트리거');
        });
      } catch (e) {
        logger.e('컨텍스트 초기화 중 오류 발생', error: e);
        if (mounted) {
          setState(() {
            _isAppInitialized = false;
          });
        }
      }
    });
  }

  // 언어 초기화를 위한 별도 메서드 (간소화)
  Future<void> _initializeLanguage() async {
    logger.i('언어 초기화 시작 (picnic_app)');

    // LanguageInitializer가 모든 로직(설정 로드, 에러 핸들링, fallback)을 처리
    final (success, language) =
        await LanguageInitializer.initializeLanguage(ref, S.load);

    logger.i('언어 초기화 완료: 성공=$success, 언어=$language');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(globalMediaQueryProvider);

    final appInitState = ref.watch(appInitializationProvider);
    final appSettingState = ref.watch(appSettingProvider);

    // 화면 보호기 상태 감지 및 처리 (PIC 메뉴에서만 활성화)
    final isScreenProtector = ref.watch(isScreenProtectorProvider);

    // PIC 메뉴별 캡처 방지 설정 업데이트
    AppBuilder.updateScreenProtector(isScreenProtector);

    Widget currentScreen;
    if (!_isAppInitialized) {
      logger.i('앱이 초기화되지 않음 - 스플래시 화면 표시 (패치 체크 포함)');
      // 패치 체크 기능이 활성화된 SplashImage 사용
      currentScreen = const SplashImage(enablePatchCheck: true);
    } else if (!appInitState.hasNetwork) {
      logger.i('네트워크 오류 - 네트워크 오류 화면 표시');
      currentScreen = NetworkErrorScreen(onRetry: _retryConnection);
    } else if (appInitState.isBanned) {
      logger.i('밴 상태 - 밴 화면 표시');
      currentScreen = const BanScreen();
    } else if (appInitState.updateInfo?.status == UpdateStatus.updateRequired) {
      logger.i('업데이트 필요 - 업데이트 화면 표시');
      currentScreen = ForceUpdateOverlay(updateInfo: appInitState.updateInfo!);
    } else {
      logger.i('정상 상태 - 포털 화면 표시');
      currentScreen = const Portal();
    }

    // 현재 언어 정보 로깅
    final currentLocale = Locale(appSettingState.language);
    logger.i('현재 언어: ${currentLocale.languageCode}');

    // 라우트 처리
    final routes = RouteManager.mergeRoutes(_appSpecificRoutes);

    // AppBuilder를 사용하여 앱 UI 구성
    return AppBuilder.buildApp(
      navigatorKey: navigatorKey,
      scaffoldKey: _scaffoldKey,
      routes: routes,
      title: 'PICNIC',
      theme: _getCurrentTheme(ref),
      home: UpdateDialog(child: currentScreen),
      localizationsDelegates: [
        // picnic_lib의 ARB 파일 기반 번역 (gen-l10n으로 생성)
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: _supportedLocales,
      locale: currentLocale,
      enableScreenProtector: isScreenProtector,
    );
  }

  Future<void> _retryConnection() async {
    await AppInitializer.retryConnection(ref);
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
    WidgetsBinding.instance.removeObserver(this);

    // 앱 리스너 정리
    AppLifecycleInitializer.disposeAppListeners(
      _authSubscription,
      _appLinksSubscription,
    );

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.i('앱 생명주기 상태 변경: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아올 때
        logger.i('앱이 포그라운드로 복귀');
        break;
      case AppLifecycleState.inactive:
        // 앱이 비활성화될 때
        logger.i('앱이 비활성화됨');
        break;
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 전환될 때
        logger.i('앱이 백그라운드로 전환됨');
        break;
      case AppLifecycleState.detached:
        // 앱이 분리될 때
        logger.i('앱이 분리됨');
        break;
      default:
        break;
    }
  }
}
