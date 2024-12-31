import 'dart:async';

import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:app_links/app_links.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_app/dialogs/force_update_overlay.dart';
import 'package:picnic_app/dialogs/update_dialog.dart';
import 'package:picnic_app/enums.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/optimized_splash_image.dart';
import 'package:picnic_app/pages/oauth_callback_page.dart';
import 'package:picnic_app/providers/app_initialization_provider.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/global_media_query.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/product_provider.dart';
import 'package:picnic_app/providers/screen_protector_provider.dart';
import 'package:picnic_app/providers/update_checker.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/screens/ban_screen.dart';
import 'package:picnic_app/screens/network_error_screen.dart';
import 'package:picnic_app/screens/pic/pic_camera_screen.dart';
import 'package:picnic_app/screens/portal.dart';
import 'package:picnic_app/screens/privacy.dart';
import 'package:picnic_app/screens/purchase.dart';
import 'package:picnic_app/screens/signup/signup_screen.dart';
import 'package:picnic_app/screens/terms.dart';
import 'package:picnic_app/services/device_manager.dart';
import 'package:picnic_app/services/network_connectivity_service.dart';
import 'package:picnic_app/services/update_service.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/community_theme.dart';
import 'package:picnic_app/ui/mypage_theme.dart';
import 'package:picnic_app/ui/novel_theme.dart';
import 'package:picnic_app/ui/pic_theme.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/ui/vote_theme.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
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

    if (UniversalPlatform.isMobile) {
      _setupAppLinksListener();
      _setupSupabaseAuthListener();
      _checkAndroidVersion();
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
    return MaterialApp(
      home: FlutterSplashScreen.fadeIn(
        useImmersiveMode: true,
        duration: const Duration(milliseconds: 3000),
        animationDuration: const Duration(milliseconds: 1500),
        onInit: _initializeApp,
        childWidget: OptimizedSplashImage(ref: ref),
        nextScreen: initState.isInitialized
            ? _buildNextScreen()
            : const SizedBox.shrink(),
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
    );
  }

  void _initializeApp() async {
    try {
      logger.i('앱 초기화 시작');

      await precacheImage(const AssetImage("assets/splash.webp"), context);
      await Future.delayed(
          const Duration(milliseconds: 2000)); // 최소 스플래시 표시 시간 보장
      ref.read(appSettingProvider.notifier);
      ref
          .read(globalMediaQueryProvider.notifier)
          .updateMediaQueryData(MediaQuery.of(context));

      if (UniversalPlatform.isMobile) {
        final networkService = NetworkConnectivityService();
        final hasNetwork = await networkService.checkOnlineStatus();
        logger.i('Network check: $hasNetwork');

        ref.read(appInitializationProvider.notifier).updateState(
              hasNetwork: hasNetwork,
            );

        if (hasNetwork) {
          final isBanned = await DeviceManager.isDeviceBanned();
          logger.i('Device banned: $isBanned');

          ref.read(appInitializationProvider.notifier).updateState(
                isBanned: isBanned,
              );

          final updateInfo = await checkForUpdates(ref);

          logger.i('Update info: $updateInfo');
          ref
              .read(appInitializationProvider.notifier)
              .updateState(updateInfo: updateInfo);

          if (!isBanned && updateInfo?.status == UpdateStatus.updateRequired) {
            await _loadProducts();
          }
        }
      } else {
        await _loadProducts();
      }

      if (!mounted) return;

      ref.read(appInitializationProvider.notifier).updateState(
            isInitialized: true,
          );
    } catch (e, s) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: s);
      if (mounted) {
        ref.read(appInitializationProvider.notifier).updateState(
              hasNetwork: false,
              isInitialized: true,
            );
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
      return MaterialApp(
        home: const BanScreen(),
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
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
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
