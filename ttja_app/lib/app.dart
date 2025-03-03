import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
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
import 'package:ttja_app/bottom_navigation_menu.dart';
import 'package:ttja_app/presenstation/screens/portal.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';

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
    _initializationFuture = Future.value();

    // Supabase 인증 리스너는 웹과 모바일 모두에서 필요함
    AppInitializer.setupSupabaseAuthListener(ref);
    
    // Branch 리스너는 모바일에서만 필요
    if (UniversalPlatform.isMobile && !kIsWeb) {
      AppInitializer.setupBranchListener(ref);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialize) {
      _didInitialize = true;
      _initializationFuture = _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    if (UniversalPlatform.isMobile && !kIsWeb) {
      await AppInitializer.initializeSystemUI();
    }
    await AppInitializer.initializeAppWithSplash(context, ref);
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
        future: Future.wait([
          _initializationFuture,
          // 최소 3초 대기
          Future.delayed(const Duration(seconds: 3)),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              initState.isInitialized) {
            return _buildNextScreen();
          } else {
            return AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 1500),
              child: const SplashImage(),
            );
          }
        },
      ),
      localizationsDelegates: PicnicLibL10n.localizationsDelegates,
      supportedLocales: PicnicLibL10n.supportedLocales,
    );
  }

  Future<void> _retryConnection() async {
    await AppInitializer.retryConnection(ref);
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
      if (!kIsWeb) {
        return MaterialApp(
          home: ForceUpdateOverlay(
            updateInfo: initState.updateInfo!,
          ),
        );
      }
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
              title: 'TTJA',
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
