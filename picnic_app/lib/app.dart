import 'dart:developer' as developer;

import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/update_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/pages/oauth_callback_page.dart';
import 'package:picnic_app/providers/ad_providers.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/product_provider.dart';
import 'package:picnic_app/providers/screen_protector_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/screens/pic/pic_camera_screen.dart';
import 'package:picnic_app/screens/portal.dart';
import 'package:picnic_app/screens/privacy.dart';
import 'package:picnic_app/screens/purchase.dart';
import 'package:picnic_app/screens/signup/signup_screen.dart';
import 'package:picnic_app/screens/terms.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/community_theme.dart';
import 'package:picnic_app/ui/mypage_theme.dart';
import 'package:picnic_app/ui/novel_theme.dart';
import 'package:picnic_app/ui/pic_theme.dart';
import 'package:picnic_app/ui/vote_theme.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/update_checker.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(updateCheckerProvider.notifier).checkForUpdate();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appSettingProvider.notifier).loadSettings();

      if (!kIsWeb) {
        ref.read(rewardedAdsProvider.notifier).loadAd(0);
        ref.read(rewardedAdsProvider.notifier).loadAd(1);
      }
    });

    if (!kIsWeb) {
      Future.microtask(() {
        ref.read(serverProductsProvider);
        ref.read(storeProductsProvider);
      });
    }

    _setupSupabaseAuthListener();
    _setupAppLinksListener();
  }

  void _setupSupabaseAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) async {
      logger.i('Auth state changed: ${data.event}');
      logger.i('User: ${data.session}');
      final session = data.session;
      if (session != null) {
        developer.log('jwtToken: ${session.accessToken}');
      }

      if (data.event == AuthChangeEvent.signedIn) {
        logger.i('User signed in');
        await ref.read(userInfoProvider.notifier).getUserProfiles();
        ref.read(userInfoProvider.notifier).subscribeToUserProfiles();
      } else if (data.event == AuthChangeEvent.signedOut) {
        logger.e('User signed out');
        ref.read(userInfoProvider.notifier).unsubscribeFromUserProfiles();
      }
    });
  }

  void _setupAppLinksListener() {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((Uri uri) {
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
    if (!kIsWeb) {
      ScreenProtector.preventScreenshotOff();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

            Widget app = MaterialApp(
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

                // 정의되지 않은 라우트에 대한 처리
                return MaterialPageRoute(builder: (_) => const Portal());
              },
              navigatorObservers: [observer],
              builder: (context, child) {
                // Apply custom scaling to the entire app
                return _ScaleAwareBuilder(
                  builder: (context, child) => UpdateDialog(
                    child: child ?? const SizedBox.shrink(),
                  ),
                  child: child!,
                );
              },
              home: _buildHomeScreen(),
            );

            if (kIsWeb) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: app,
                ),
              );
            } else {
              return app;
            }
          },
        ),
      ),
    );
  }

  void _updateScreenProtector(bool isScreenProtector) {
    if (!kIsWeb) {
      if (isScreenProtector) {
        ScreenProtector.preventScreenshotOn();
      } else {
        ScreenProtector.preventScreenshotOff();
      }
    }
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      Portal.routeName: (context) => const Portal(),
      SignUpScreen.routeName: (context) => const SignUpScreen(),
      '/pic-camera': (context) => const PicCameraScreen(),
      TermsScreen.routeName: (context) => const TermsScreen(),
      PrivacyScreen.routeName: (context) => const PrivacyScreen(),
      PurchaseScreen.routeName: (context) => const PurchaseScreen(),
    };
  }

  Widget _buildHomeScreen() {
    if (UniversalPlatform.isWeb) {
      return initScreen ?? const Portal();
    } else {
      return FlutterSplashScreen.fadeIn(
        useImmersiveMode: true,
        duration: const Duration(milliseconds: 3000),
        animationDuration: const Duration(milliseconds: 3000),
        childWidget: SizedBox(
          width: getPlatformScreenSize(context).width,
          height: getPlatformScreenSize(context).height,
          child: Image.asset("assets/splash.png", fit: BoxFit.cover),
        ),
        nextScreen: initScreen ?? const Portal(),
      );
    }
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
      default:
        return picThemeLight;
    }
  }
}

class _ScaleAwareBuilder extends StatelessWidget {
  final Widget child;
  final Widget Function(BuildContext, Widget?) builder;

  const _ScaleAwareBuilder({
    required this.child,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web, use a custom scaling factor
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: const Size(600, 800),
          // textScaleFactor: 600 / 393, // Adjust text scale for web
        ),
        child: builder(context, child),
      );
    } else {
      // For mobile, use the original MediaQuery
      return builder(context, child);
    }
  }
}
