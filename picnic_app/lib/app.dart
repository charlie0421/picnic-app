import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_app/bottom_navigation_menu.dart';
import 'package:picnic_app/presentation/screens/portal.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';
import 'package:picnic_lib/core/services/update_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/l10n_setup.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/force_update_overlay.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/pages/oauth_callback_page.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_protector_provider.dart';
import 'package:picnic_lib/presentation/providers/update_checker.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/screens/ban_screen.dart';
import 'package:picnic_lib/presentation/screens/network_error_screen.dart';
import 'package:picnic_lib/presentation/screens/pic/pic_camera_screen.dart';
import 'package:picnic_lib/presentation/screens/privacy.dart';
import 'package:picnic_lib/presentation/screens/purchase.dart';
import 'package:picnic_lib/presentation/screens/signup/signup_screen.dart';
import 'package:picnic_lib/presentation/screens/terms.dart';
import 'package:picnic_lib/presentation/widgets/optimized_splash_image.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/community_theme.dart';
import 'package:picnic_lib/ui/mypage_theme.dart';
import 'package:picnic_lib/ui/novel_theme.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/vote_theme.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late Future<void> _initializationFuture;
  bool _didInitialize = false;
  Widget? initScreen;
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  int? _androidSdkVersion;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  StreamSubscription? _authSubscription;
  StreamSubscription? _appLinksSubscription;

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
    _initializationFuture = Future.value();

    if (UniversalPlatform.isMobile) {
      _setupAppLinksListener();
      _setupSupabaseAuthListener();
      _checkAndroidVersion();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialize) {
      _didInitialize = true;
      _initializationFuture = _initializeAppWithSplash();
    }
  }

  Future<void> _checkInitialNetwork() async {
    try {
      final networkService = NetworkConnectivityService();

      final isOnline = await networkService.checkOnlineStatus();
      logger.i('Network check: $isOnline');

      setState(() {});
    } catch (e, s) {
      logger.e('Network check error: $e', stackTrace: s);
    }
  }

  Future<void> _retryConnection() async {
// 재시도 중에는 로딩 상태로
    await _checkInitialNetwork();
  }

  Future<void> _checkAndroidVersion() async {
    if (UniversalPlatform.isAndroid) {
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        setState(() {
          _androidSdkVersion = androidInfo.version.sdkInt;
          logger.i('Android SDK Version: $_androidSdkVersion'); // 디버깅용
        });
      } catch (e, s) {
        logger.i('Failed to get Android SDK version: $e',
            stackTrace: s); // 디버깅용
      }
    }
    _initializeSystemUI();
  }

  void _initializeSystemUI() {
    if (kIsWeb) return;

    if (UniversalPlatform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      if (_androidSdkVersion != null && _androidSdkVersion! < 30) {
        // Android 11 미만
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      } else {
        // Android 11 이상
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );
      }
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(appInitializationProvider);
    logger.i('initState: $initState');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenInfoMap = {
        PortalType.vote.name.toString(): voteScreenInfo,
        PortalType.pic.name.toString(): picScreenInfo,
        PortalType.community.name.toString(): communityScreenInfo,
        PortalType.novel.name.toString(): novelScreenInfo,
      };
      ref.read(screenInfosProvider.notifier).setScreenInfoMap(screenInfoMap);
    });

    return MaterialApp(
      home: FutureBuilder(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return initState.isInitialized
                ? _buildNextScreen()
                : const Center(child: CircularProgressIndicator());
          }

          return AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 1500),
            child: OptimizedSplashImage(ref: ref),
          );
        },
      ),
      localizationsDelegates: PicnicLibL10n.localizationsDelegates,
      supportedLocales: PicnicLibL10n.supportedLocales,
    );
  }

  Future<void> _initializeAppWithSplash() async {
    // 최소 스플래시 표시 시간 보장
    await Future.wait([
      _initializeApp(),
      Future.delayed(const Duration(milliseconds: 3000)),
    ]);
  }

  Future<void> _initializeApp() async {
    try {
      logger.i('앱 초기화 시작');

      // 1. 기본 초기화
      await precacheImage(const AssetImage("assets/splash.webp"), context);
      logger.i('스플래시 이미지 프리캐시 완료');

      if (!mounted) return;

      ref.read(appSettingProvider.notifier);
      ref
          .read(globalMediaQueryProvider.notifier)
          .updateMediaQueryData(MediaQuery.of(context));
      logger.i('기본 설정 초기화 완료');

      // 2. 모바일 전용 초기화
      if (UniversalPlatform.isMobile) {
        final networkService = NetworkConnectivityService();
        final hasNetwork = await networkService.checkOnlineStatus();
        logger.i('네트워크 상태 확인: $hasNetwork');

        if (!mounted) return;

        // 네트워크 상태 업데이트
        ref.read(appInitializationProvider.notifier).updateState(
              hasNetwork: hasNetwork,
            );

        if (hasNetwork) {
          try {
            final isBanned = await DeviceManager.isDeviceBanned();
            logger.i('디바이스 밴 상태: $isBanned');

            if (!mounted) return;

            // 밴 상태 업데이트
            ref.read(appInitializationProvider.notifier).updateState(
                  isBanned: isBanned,
                );

            final updateInfo = await checkForUpdates(ref);
            logger.i('업데이트 정보: $updateInfo');

            if (!mounted) return;

            // 업데이트 정보 업데이트
            ref.read(appInitializationProvider.notifier).updateState(
                  updateInfo: updateInfo,
                );

            if (!isBanned &&
                updateInfo?.status == UpdateStatus.updateRequired) {
              await _loadProducts();
              logger.i('제품 정보 로드 완료');
            }
          } catch (e) {
            logger.e('모바일 초기화 중 오류: $e');
          }
        }
      } else {
        await _loadProducts();
        logger.i('제품 정보 로드 완료');
      }

      if (!mounted) return;

      // 최종 초기화 완료 상태 설정
      ref.read(appInitializationProvider.notifier).updateState(
            isInitialized: true,
          );

      logger.i('앱 초기화 완료 - isInitialized: true로 설정됨');
    } catch (e, s) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: s);
      if (mounted) {
        ref.read(appInitializationProvider.notifier).updateState(
              hasNetwork: false,
              isInitialized: true,
            );
        logger.i('에러 발생으로 인한 초기화 완료 처리');
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      await Future.wait([
        ref.read(serverProductsProvider.future),
        ref.read(storeProductsProvider.future),
      ]);
    } catch (e, s) {
      logger.e('Failed to load products', error: e, stackTrace: s);
      // 제품 로드 실패 처리
    }
  }

  void _setupSupabaseAuthListener() {
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        logger.i('jwtToken: ${session.accessToken}');
      }

      if (data.event == AuthChangeEvent.signedIn) {
        await ref.read(userInfoProvider.notifier).getUserProfiles();
      } else if (data.event == AuthChangeEvent.signedOut) {
        logger.i('User signed out');
      }
    });
  }

  void _setupAppLinksListener() {
    final appLinks = AppLinks();
    _appLinksSubscription = appLinks.uriLinkStream.listen((Uri uri) {
      logger.i('Incoming link: $uri');
      if (uri.pathSegments.contains('terms')) {
        initScreen = uri.pathSegments.contains('ko')
            ? const TermsScreen(language: 'ko')
            : const TermsScreen(language: 'en');
      } else if (uri.pathSegments.contains('privacy')) {
        initScreen = uri.pathSegments.contains('ko')
            ? const PrivacyScreen(language: 'ko')
            : const PrivacyScreen(language: 'en');
      } else {
        ref.read(userInfoProvider.notifier).getUserProfiles();
      }
    }, onError: (err) {
      logger.e('Error: $err');
    });
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

  Widget _buildNextScreen() {
    final initState = ref.watch(appInitializationProvider);

    if (!initState.hasNetwork) {
      return MaterialApp(
        home: NetworkErrorScreen(
          onRetry: _retryConnection,
        ),
      );
    }

    if (initState.isBanned) {
      return const MaterialApp(
        home: BanScreen(),
      );
    }

    if (initState.updateInfo?.status == UpdateStatus.updateRequired) {
      return MaterialApp(
        home: ForceUpdateOverlay(
          updateInfo: initState.updateInfo!,
        ),
      );
    }

    return ScreenUtilInit(
      designSize: const Size(393, 892),
      minTextAdapt: true,
      splitScreenMode: true,
      child: OverlaySupport.global(
        child: Consumer(
          builder: (context, ref, child) {
            final appSettingState = ref.watch(appSettingProvider);
            final isScreenProtector = ref.watch(isScreenProtectorProvider);

            _updateScreenProtector(isScreenProtector);

            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Picnic',
              theme: _getCurrentTheme(ref),
              themeMode: appSettingState.themeMode,
              locale: appSettingState.locale,
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
              builder: UniversalPlatform.isWeb
                  ? (context, child) => MediaQuery(
                        data: ref
                            .watch(globalMediaQueryProvider)
                            .copyWith(size: const Size(600, 800)),
                        child: child ?? const SizedBox.shrink(),
                      )
                  : (context, child) => child ?? const SizedBox.shrink(),
              home: UpdateDialog(child: initScreen ?? const Portal()),
            );
          },
        ),
      ),
    );
  }

  void _updateScreenProtector(bool isScreenProtector) {
    if (!kIsWeb) {
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
}
