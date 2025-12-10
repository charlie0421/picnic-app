import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:picnic_app/presentation/screens/portal.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_initializer.dart';
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
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/device_debug_info.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_lib/core/constatns/constants.dart';

// 임시: 밴 화면 강제 표시 플래그 (테스트 제거)
const bool kForceBanScreen = false;

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

  // 지원되는 언어 목록은 AppLocalizations.supportedLocales를 단일 소스로 사용

  // 앱의 라우트 맵 - 앱 고유 라우트만 포함 (공통 라우트는 RouteManager에서 관리)9
  final Map<String, WidgetBuilder> _appSpecificRoutes = {
    Portal.routeName: (context) => const Portal(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

    // 기존 코드의 나머지 부분은 유지
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
    } catch (e, stackTrace) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isAppInitialized = false;
        });
      }
      return; // 오류 발생 시 더 이상 진행하지 않음
    }

    // mounted 상태 확인 후 컨텍스트가 필요한 부분 실행
    if (mounted) {
      _initializeAppWithContext();
    } else {
      logger.e('앱 초기화 중 위젯이 dispose됨');
    }

    logger.i('_initializeApp 완료');
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

        // 스크린 정보 맵 생성
        final screenInfoMap = {
          PortalType.vote.name.toString(): voteScreenInfo,
          PortalType.pic.name.toString(): picScreenInfo,
          PortalType.community.name.toString(): communityScreenInfo,
          PortalType.novel.name.toString(): novelScreenInfo,
          PortalType.mypage.name.toString(): mypageScreenInfo,
        };

        // screenInfosProvider에 스크린 정보 설정
        ref.read(screenInfosProvider.notifier).update(screenInfoMap);

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
    if (kForceBanScreen) {
      logger.i('임시 강제 - 밴 화면 표시');
      currentScreen = const BanScreen();
    } else if (!_isAppInitialized) {
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
      // logger.i('정상 상태 - 포털 화면 표시');
      currentScreen = const Portal();
    }

    // 현재 언어 정보 로깅
    // 'zh_CN' / 'zh_TW' 등 언어_국가 코드를 지원
    final currentLocale = parseLocale(appSettingState.language);
    // logger.i('현재 언어: ${currentLocale.languageCode}');

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
      supportedLocales: AppLocalizations.supportedLocales,
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
      case PortalType.goongHap:
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
