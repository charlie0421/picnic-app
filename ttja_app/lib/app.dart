import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/services/app_badge_service.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/language_initializer.dart';
import 'package:picnic_lib/core/utils/route_manager.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/force_update_overlay.dart';
import 'package:picnic_lib/presentation/providers/anti_abuse_providers.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/screens/ban_screen.dart';
import 'package:picnic_lib/presentation/screens/initialization_error_screen.dart';
import 'package:picnic_lib/presentation/screens/network_error_screen.dart';

import 'package:picnic_lib/ui/community_theme.dart';
import 'package:picnic_lib/ui/mypage_theme.dart';
import 'package:picnic_lib/ui/novel_theme.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/vote_theme.dart';
import 'package:ttja_app/presenstation/screens/portal.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';

enum _InitializationRetryTarget { startup, connection }

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  // 스캐폴드 메신저 키 - SnackbarUtil과 공유하여 전역 토스트 표시 지원
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      SnackbarUtil.scaffoldMessengerKey;

  bool _isAppInitialized = false;
  final RetryableStartupStages _startupStages = RetryableStartupStages();
  final StartupConnectionChecks<UpdateInfo> _connectionChecks =
      StartupConnectionChecks<UpdateInfo>();
  Future<void>? _initializationInFlight;
  Future<void>? _connectionRetryInFlight;
  Object? _initializationError;
  _InitializationRetryTarget _retryTarget = _InitializationRetryTarget.startup;
  int _initializationGeneration = 0;
  Widget? initScreen;
  StreamSubscription? _authSubscription;
  StreamSubscription? _appLinksSubscription;

  // 지원되는 언어 목록은 AppLocalizations.supportedLocales를 단일 소스로 사용

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

    // 앱 라우트 설정
    AppLifecycleInitializer.setupAppRoutes(ref, _appSpecificRoutes);

    // 초기화 로직을 initState()에서 수행 - 별도 Future로 선언하지 않고 즉시 실행
    _initializeApp();
  }

  Future<void> _initializeApp({bool retry = false}) {
    if (_isAppInitialized) return Future<void>.value();

    final inFlight = _initializationInFlight;
    if (inFlight != null) return inFlight;

    final generation = ++_initializationGeneration;
    if (retry && mounted) {
      setState(() {
        _initializationError = null;
        _retryTarget = _InitializationRetryTarget.startup;
      });
    }

    late final Future<void> attempt;
    attempt = () async {
      try {
        logger.i('_initializeApp 시작 (retry=$retry)');
        await _runInitializationAttempt(retry: retry);
        if (!_isCurrentInitialization(generation)) return;

        setState(() {
          _isAppInitialized = true;
          _initializationError = null;
        });
        logger.i('_initializeApp 완료');
      } catch (error, stackTrace) {
        logger.e('앱 초기화 중 오류 발생', error: error, stackTrace: stackTrace);
        if (!_isCurrentInitialization(generation)) return;

        setState(() {
          _isAppInitialized = false;
          _initializationError = error;
          _retryTarget = _InitializationRetryTarget.startup;
        });
      } finally {
        if (identical(_initializationInFlight, attempt)) {
          _initializationInFlight = null;
        }
      }
    }();
    _initializationInFlight = attempt;
    return attempt;
  }

  bool _isCurrentInitialization(int generation) =>
      mounted && generation == _initializationGeneration;

  Future<void> _runInitializationAttempt({required bool retry}) async {
    logger.i('SDK 초기화 대기 중...');
    final readiness = retry
        ? await MainInitializer.retrySdkInitialization()
        : await MainInitializer.sdkReady;
    if (!readiness.isReady) {
      Error.throwWithStackTrace(
        readiness.error ?? StateError('SDK initialization failed'),
        readiness.stackTrace ?? StackTrace.current,
      );
    }
    if (!mounted) return;
    logger.i('SDK 초기화 완료');

    await _startupStages.run('ttja-ip-hash-prefetch-launch', () async {
      unawaited(ref.read(ipHashServiceProvider).fetchAndCache());
    });

    if (UniversalPlatform.isMobile && !kIsWeb) {
      await _startupStages.run(
        'ttja-system-ui',
        AppInitializer.initializeSystemUI,
      );
    }
    if (!mounted) return;

    await _startupStages.run('ttja-language', _initializeLanguage);
    if (!mounted) return;
    if (!context.mounted) return;

    await AppInitializer.initializeApp(
      context,
      ref,
      startupStages: _startupStages,
      connectionChecks: _connectionChecks,
      isActive: () => mounted,
    );
    if (!mounted) return;

    await _startupStages.run('ttja-app-initialized-marker', () async {
      AppLifecycleInitializer.markAppInitialized(ref);
    });
  }

  void _retryInitialization() {
    unawaited(_initializeApp(retry: true));
  }

  // 언어 초기화를 위한 별도 메서드 (간소화)
  Future<void> _initializeLanguage() async {
    logger.i('언어 초기화 시작 (ttja_app)');

    // LanguageInitializer가 모든 로직(설정 로드, 에러 핸들링, fallback)을 처리
    final (success, language) = await LanguageInitializer.initializeLanguage(
      ref,
      AppLocalizations.delegate.load,
    );

    logger.i('언어 초기화 완료: 성공=$success, 언어=$language');
  }

  @override
  Widget build(BuildContext context) {
    // 앱 설정 관련 상태 구독
    final appSettingState = ref.watch(appSettingProvider);
    final appInitState = ref.watch(appInitializationProvider);
    // 내비게이션 관련 프로바이더 구독
    ref.watch(navigationInfoProvider);
    ref.watch(globalMediaQueryProvider);

    Widget homeWidget;
    if (_initializationError != null) {
      homeWidget = InitializationErrorScreen(
        onRetry: _retryTarget == _InitializationRetryTarget.connection
            ? () => unawaited(_retryConnection())
            : _retryInitialization,
      );
    } else if (!_isAppInitialized) {
      homeWidget = Image.asset('assets/splash.webp', fit: BoxFit.cover);
    } else if (!appInitState.hasNetwork) {
      homeWidget = NetworkErrorScreen(
        onRetry: () => unawaited(_retryConnection()),
      );
    } else if (appInitState.isBanned) {
      homeWidget = const BanScreen();
    } else if (appInitState.updateInfo?.status == UpdateStatus.updateRequired) {
      homeWidget = ForceUpdateOverlay(updateInfo: appInitState.updateInfo!);
    } else {
      homeWidget = const Portal();
    }

    // 라우트 처리
    final routes = RouteManager.mergeRoutes(_appSpecificRoutes);

    // AppBuilder를 사용하여 앱 UI 구성
    return AppBuilder.buildApp(
      navigatorKey: navigatorKey,
      scaffoldKey: _scaffoldKey,
      routes: routes,
      title: 'TTJA',
      theme: _getCurrentTheme(ref),
      home: UpdateDialog(child: homeWidget),
      localizationsDelegates: [
        // picnic_lib의 ARB 파일 기반 번역 (gen-l10n으로 생성)
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(appSettingState.language),
    );
  }

  Future<void> _retryConnection() {
    final inFlight = _connectionRetryInFlight;
    if (inFlight != null) return inFlight;

    final generation = _initializationGeneration;
    if (mounted) {
      setState(() {
        _initializationError = null;
        _retryTarget = _InitializationRetryTarget.connection;
      });
    }

    late final Future<void> attempt;
    attempt = () async {
      try {
        await AppInitializer.retryConnection(
          ref,
          connectionChecks: _connectionChecks,
          isActive: () => mounted,
        );
      } catch (error, stackTrace) {
        logger.e('네트워크 복구 검사 중 오류 발생', error: error, stackTrace: stackTrace);
        if (!_isCurrentInitialization(generation)) return;
        setState(() {
          _initializationError = error;
          _retryTarget = _InitializationRetryTarget.connection;
        });
      } finally {
        if (identical(_connectionRetryInFlight, attempt)) {
          _connectionRetryInFlight = null;
        }
      }
    }();
    _connectionRetryInFlight = attempt;
    return attempt;
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
    _initializationGeneration++;
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
        // 앱이 포그라운드로 돌아올 때 필요한 작업
        // Sync app badge with unread notifications count
        AppBadgeService.syncBadgeWithUnreadCount();
        break;
      case AppLifecycleState.inactive:
        // 앱이 비활성화될 때 필요한 작업
        break;
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 전환될 때 필요한 작업
        break;
      case AppLifecycleState.detached:
        // 앱이 분리될 때 필요한 작업
        break;
      default:
        break;
    }
  }

  // 언어 변경 적용 - 번역을 즉시 로드하고 UI를 업데이트하는 강화된 메서드
}
