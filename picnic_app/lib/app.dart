import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:picnic_app/presentation/screens/portal.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/services/app_badge_service.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_initializer.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/route_manager.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
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
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/providers/global_purchase_provider.dart';
import 'package:picnic_lib/core/services/global_purchase_listener.dart';

import 'package:picnic_lib/presentation/screens/ban_screen.dart';
import 'package:picnic_lib/presentation/screens/network_error_screen.dart';
import 'package:picnic_lib/presentation/widgets/patch_restart_dialog.dart';
import 'package:picnic_lib/presentation/widgets/ad_reward_dialog_host.dart';
import 'package:picnic_lib/supabase_options.dart';
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

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  Widget? initScreen;
  StreamSubscription? _authSubscription;
  StreamSubscription? _appLinksSubscription;
  String? _activeRewardUserId;
  bool _rewardRecoveryReady = false;

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

    // 구매 스트림 구독을 앱 첫 프레임에 세운다. iOS 는 큐 옵저버가 붙는
    // 순간(= 이 read) 미완료 트랜잭션을 재전달하므로 이보다 늦으면 그 이벤트를
    // 놓친다. 스토어 화면은 같은 인스턴스를 빌려 쓰기만 하므로 구독은 프로세스
    // 전체에서 하나다. 미완료 결제 리컨사일은 세션이 필요해서
    // _initializeAppBasics(SDK 준비 후)로 미룬다.
    _initializeGlobalPurchaseListener();

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

  // SDK 초기화 완료 대기 및 시스템 UI 설정
  // 기본 초기화와 환경 설정은 MainInitializer에서 runApp 전에 완료됨
  Future<void> _initializeAppBasics() async {
    // SDK 초기화 완료 대기 (MainInitializer에서 runApp 후 병렬 실행 중)
    logger.i('SDK 초기화 대기 중...');
    await MainInitializer.sdkReady;
    logger.i('SDK 초기화 완료');
    _initializeRewardRecovery();
    // 미완료 결제 리컨사일은 세션이 복원된 뒤에 돌아야 한다 (Supabase 는
    // runApp 이후 Phase 2 에서 초기화된다). 구독 자체는 initState 에서 이미
    // 세워져 있으므로, 그 사이에 도착하는 재전달 이벤트는 유실되지 않는다.
    _sweepUnfinishedPurchases();

    // anti-abuse ip_hash prefetch — fire-and-forget. 실패는 IpHashService 내부에서 swallow.
    // 보호 대상 호출(광고/출석/아티스트요청) 전에 캐시가 채워지면 hint 송신, 안 채워지면
    // 서버가 어쨌든 자체 IP 로 hash 계산하므로 client hint 는 본질적으로 best-effort.
    unawaited(ref.read(ipHashServiceProvider).fetchAndCache());

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
          // 스플래시 대기 없이 바로 앱 초기화 진행
          await AppInitializer.initializeApp(navigatorKey.currentContext!, ref);
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

    Widget currentScreen;
    if (kForceBanScreen) {
      logger.i('임시 강제 - 밴 화면 표시');
      currentScreen = const BanScreen();
    } else if (!_isAppInitialized) {
      // 초기화 중 경량 로컬 스플래시만 표시 (네트워크/패치 체크 없음)
      currentScreen = Image.asset('assets/splash.webp', fit: BoxFit.cover);
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
    // PatchRestartDialogListener는 MaterialApp 내부(home)에 배치해야 Navigator context 사용 가능
    return AppBuilder.buildApp(
      navigatorKey: navigatorKey,
      scaffoldKey: _scaffoldKey,
      routes: routes,
      title: 'PICNIC',
      theme: _getCurrentTheme(ref),
      home: AdRewardDialogHost(
        child: PatchRestartDialogListener(
          child: UpdateDialog(child: currentScreen),
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

  Future<void> _retryConnection() async {
    await AppInitializer.retryConnection(ref);
  }

  void _syncRewardOwner(String? nextUserId) {
    final recovery = ref.read(adRewardRecoveryProvider.notifier);
    if (_activeRewardUserId != nextUserId) {
      recovery.resetForLogout();
      _activeRewardUserId = nextUserId;
    }
    if (nextUserId != null) {
      unawaited(
        recovery
            .recover(nextUserId)
            .catchError((Object error, StackTrace stack) {
          logger.e('광고 보상 복구 실패', error: error, stackTrace: stack);
        }),
      );
    }
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

  void _initializeRewardRecovery() {
    if (_rewardRecoveryReady) return;
    _rewardRecoveryReady = true;
    _syncRewardOwner(supabase.auth.currentUser?.id);
    _authSubscription = supabase.auth.onAuthStateChange.listen((authState) {
      _syncRewardOwner(authState.session?.user.id);
    });
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
        // Sync app badge with unread notifications count
        AppBadgeService.syncBadgeWithUnreadCount();
        if (_rewardRecoveryReady) {
          _syncRewardOwner(supabase.auth.currentUser?.id);
        }
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
                logger.e('resume 미완료 결제 스윕 실패', error: error, stackTrace: stack);
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
