import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:picnic_app/presentation/screens/portal.dart';
import 'package:picnic_app/presentation/splash/responsive_splash.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/services/app_badge_service.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/core/services/branch_link_service.dart';
import 'package:picnic_lib/core/services/ad_reward_lifecycle.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/route_manager.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/force_update_overlay.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/providers/anti_abuse_providers.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/global_purchase_provider.dart';
import 'package:picnic_lib/core/services/global_purchase_listener.dart';

import 'package:picnic_lib/presentation/screens/ban_screen.dart';
import 'package:picnic_lib/presentation/screens/initialization_error_screen.dart';
import 'package:picnic_lib/presentation/screens/network_error_screen.dart';
import 'package:picnic_lib/presentation/widgets/patch_restart_dialog.dart';
import 'package:picnic_lib/presentation/widgets/ad_reward_dialog_host.dart';
import 'package:picnic_lib/ui/community_theme.dart';
import 'package:picnic_lib/ui/mypage_theme.dart';
import 'package:picnic_lib/ui/novel_theme.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/vote_theme.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/utils/device_debug_info.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_lib/core/constatns/constants.dart';

// 임시: 밴 화면 강제 표시 플래그 (테스트 제거)
const bool kForceBanScreen = false;

typedef PicnicAppStartupAttempt = Future<void> Function({required bool retry});

enum _InitializationRetryTarget { startup, connection }

class App extends ConsumerStatefulWidget {
  const App({
    super.key,
    this.startupAttempt,
    this.portalBuilder,
  });

  /// Narrow seam for exercising the real App startup state machine.
  final PicnicAppStartupAttempt? startupAttempt;
  final WidgetBuilder? portalBuilder;

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  Widget? initScreen;
  StreamSubscription? _appLinksSubscription;
  AdRewardLifecycle? _rewardLifecycle;
  final RetryableStartupStages _startupStages = RetryableStartupStages();
  final StartupConnectionChecks<UpdateInfo> _connectionChecks =
      StartupConnectionChecks<UpdateInfo>();
  Future<void>? _initializationInFlight;
  Future<void>? _connectionRetryInFlight;
  Object? _initializationError;
  _InitializationRetryTarget _retryTarget = _InitializationRetryTarget.startup;
  int _initializationGeneration = 0;
  int _branchReadinessGeneration = 0;

  /// The process-lifetime owner of purchase delivery.
  ///
  /// Held here because `_AppState` is the longest-lived thing in the tree and
  /// already the `WidgetsBindingObserver` the resume sweep needs. Reading the
  /// provider in [initState] is what makes the `purchaseStream` subscription
  /// exist from the first frame; before this, the only subscription was created
  /// by the store screen, so a purchase that completed while no store was
  /// mounted (app killed mid-purchase, Ask to Buy approved later, purchase made
  /// on another device) reached nobody and had to be recovered by asking the
  /// user to open the store.
  GlobalPurchaseListener? _purchaseListener;

  // 앱이 이미 초기화되었는지 여부를 추적하는 플래그
  bool _isAppInitialized = false;
  late final int _branchHandlerOwner;

  // 스캐폴드 메신저 키 - SnackbarUtil과 공유하여 전역 토스트 표시 지원
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      SnackbarUtil.scaffoldMessengerKey;

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
    _branchHandlerOwner = BranchLinkService.instance.attachHandler(
      (url) => AppInitializer.handleDeepLink(ref, url),
    );

    // 구매 스트림 구독을 앱 첫 프레임에 세운다. iOS 는 큐 옵저버가 붙는
    // 순간(= 이 read) 미완료 트랜잭션을 재전달하므로 이보다 늦으면 그 이벤트를
    // 놓친다. 스토어 화면은 같은 인스턴스를 빌려 쓰기만 하므로 구독은 프로세스
    // 전체에서 하나다. 미완료 결제 리컨사일은 세션이 필요해서
    // _initializeAppBasics(SDK 준비 후)로 미룬다.
    if (widget.startupAttempt == null) {
      _initializeGlobalPurchaseListener();
    }

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
        logger.e(
          '앱 초기화 중 오류 발생',
          error: error,
          stackTrace: stackTrace,
        );
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
    final injectedAttempt = widget.startupAttempt;
    if (injectedAttempt != null) {
      await injectedAttempt(retry: retry);
      return;
    }

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

    await _startupStages.run('picnic-reward-lifecycle', () async {
      final rewardLifecycle = ref.read(adRewardLifecycleProvider);
      rewardLifecycle.start();
      _rewardLifecycle = rewardLifecycle;
    });
    if (!mounted) return;

    // The stream subscription exists from initState. Reconciliation waits for
    // the recovered auth session and is launched only once after SDK success.
    await _startupStages.run('picnic-purchase-reconciliation-launch', () async {
      _sweepUnfinishedPurchases();
    });
    if (!mounted) return;

    await _startupStages.run('picnic-ip-hash-prefetch-launch', () async {
      unawaited(ref.read(ipHashServiceProvider).fetchAndCache());
    });
    if (!mounted) return;

    await _startupStages.run(
      'picnic-system-ui',
      AppInitializer.initializeSystemUI,
    );
    if (!mounted) return;

    // Let AppBuilder install the navigator before context-dependent startup.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final initializationContext = navigatorKey.currentContext;
    if (initializationContext == null) {
      throw StateError('Navigator context is unavailable during startup');
    }
    if (!initializationContext.mounted) return;

    await AppInitializer.initializeApp(
      initializationContext,
      ref,
      startupStages: _startupStages,
      connectionChecks: _connectionChecks,
      isActive: () => mounted,
    );
    if (!mounted) return;

    await _startupStages.run('picnic-screen-infos', () async {
      final screenInfoMap = {
        PortalType.vote.name: voteScreenInfo,
        PortalType.pic.name: picScreenInfo,
        PortalType.community.name: communityScreenInfo,
        PortalType.novel.name: novelScreenInfo,
        PortalType.mypage.name: mypageScreenInfo,
      };
      ref.read(screenInfosProvider.notifier).update(screenInfoMap);
    });

    final currentLanguage = ref.read(appSettingProvider).language;
    logger.i('앱 초기화 완료 후 최종 언어 확인: $currentLanguage');
  }

  void _retryInitialization() {
    unawaited(_initializeApp(retry: true));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(globalMediaQueryProvider);

    final appInitState = ref.watch(appInitializationProvider);
    final appSettingState = ref.watch(appSettingProvider);

    Widget currentScreen;
    var isPortalReady = false;
    if (kForceBanScreen) {
      logger.i('임시 강제 - 밴 화면 표시');
      currentScreen = const BanScreen();
    } else if (_initializationError != null) {
      currentScreen = InitializationErrorScreen(
        onRetry: _retryTarget == _InitializationRetryTarget.connection
            ? () => unawaited(_retryConnection())
            : _retryInitialization,
      );
    } else if (!_isAppInitialized) {
      // 초기화 중 경량 로컬 스플래시만 표시 (네트워크/패치 체크 없음)
      currentScreen = const ResponsiveSplash();
    } else if (!appInitState.hasNetwork) {
      logger.i('네트워크 오류 - 네트워크 오류 화면 표시');
      currentScreen = NetworkErrorScreen(
        onRetry: () => unawaited(_retryConnection()),
      );
    } else if (appInitState.isBanned) {
      logger.i('밴 상태 - 밴 화면 표시');
      currentScreen = const BanScreen();
    } else if (appInitState.updateInfo?.status == UpdateStatus.updateRequired) {
      logger.i('업데이트 필요 - 업데이트 화면 표시');
      currentScreen = ForceUpdateOverlay(updateInfo: appInitState.updateInfo!);
    } else {
      // logger.i('정상 상태 - 포털 화면 표시');
      isPortalReady = true;
      currentScreen = widget.portalBuilder?.call(context) ?? const Portal();
    }

    // 현재 언어 정보 로깅
    // 'zh_CN' / 'zh_TW' 등 언어_국가 코드를 지원
    final currentLocale = parseLocale(appSettingState.language);
    // logger.i('현재 언어: ${currentLocale.languageCode}');

    // 라우트 처리
    final routes = RouteManager.mergeRoutes(_appSpecificRoutes);
    final branchGeneration = ++_branchReadinessGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || branchGeneration != _branchReadinessGeneration) return;
      BranchLinkService.instance.setHandlerReady(
        _branchHandlerOwner,
        isPortalReady && navigatorKey.currentContext != null,
      );
    });

    // AppBuilder를 사용하여 앱 UI 구성
    // PatchRestartDialogListener는 MaterialApp 내부(home)에 배치해야 Navigator context 사용 가능
    return AppBuilder.buildApp(
      navigatorKey: navigatorKey,
      scaffoldKey: _scaffoldKey,
      routes: routes,
      title: 'PICNIC',
      theme: _getCurrentTheme(ref),
      home: widget.startupAttempt != null
          ? currentScreen
          : AdRewardDialogHost(
              child: PatchRestartDialogListener(
                child: UpdateDialog(
                  enabled: isPortalReady,
                  child: currentScreen,
                ),
              ),
            ),
      localizationsDelegates: [
        // picnic_lib의 ARB 파일 기반 번역 (gen-l10n으로 생성)
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: currentLocale,
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
        logger.e(
          '네트워크 복구 검사 중 오류 발생',
          error: error,
          stackTrace: stackTrace,
        );
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

  void _initializeGlobalPurchaseListener() {
    if (_purchaseListener != null) return;
    try {
      _purchaseListener = ref.read(globalPurchaseListenerProvider);
    } catch (e, stackTrace) {
      // 스토어 플러그인 초기화 실패로 앱 자체가 뜨지 못하게 하지는 않는다.
      // 이 경우 예전과 같은 상태(스토어 화면이 열릴 때 복구)로 떨어진다.
      logger.e('전역 구매 리스너 초기화 실패', error: e, stackTrace: stackTrace);
    }
  }

  void _sweepUnfinishedPurchases() {
    final purchases = _purchaseListener;
    if (purchases == null) return;
    unawaited(
      purchases.sweepOnColdStart().then(
        (report) => logger.i('콜드 스타트 미완료 결제 스윕: $report'),
        onError: (Object error, StackTrace stack) {
          logger.e('콜드 스타트 미완료 결제 스윕 실패', error: error, stackTrace: stack);
        },
      ),
    );
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
    _rewardLifecycle?.dispose();
    _branchReadinessGeneration++;
    BranchLinkService.instance.detachHandler(_branchHandlerOwner);
    unawaited(PushTokenService.dispose());

    // 앱 리스너 정리
    AppLifecycleInitializer.disposeAppListeners(null, _appLinksSubscription);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.i('앱 생명주기 상태 변경: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아올 때
        logger.i('앱이 포그라운드로 복귀');
        // Sync app badge with unread notifications count
        AppBadgeService.syncBadgeWithUnreadCount();
        unawaited(PushTokenService.resume());
        // 미완료 결제 리컨사일. 콜드 스타트에서는 스토어가 스스로 재전달하지만
        // resume 에는 그런 것이 없다 - Ask to Buy 승인이나 포그라운드에서
        // 실패한 정산이 다음 실행까지 갇혀 있던 자리다. 리스너가 자체
        // 레이트리밋을 걸므로(최소 5분 간격, 스토어 화면이 열려 있으면 생략)
        // 앱 전환을 반복해도 재검증 폭풍이 되지 않는다.
        final purchases = _purchaseListener;
        if (purchases != null) {
          unawaited(
            purchases.sweepOnResume().then(
              (report) => logger.i('resume 미완료 결제 스윕: $report'),
              onError: (Object error, StackTrace stack) {
                logger.e(
                  'resume 미완료 결제 스윕 실패',
                  error: error,
                  stackTrace: stack,
                );
              },
            ),
          );
        }
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
