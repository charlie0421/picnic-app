import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'package:picnic_app/overlays.dart';
import 'package:picnic_app/providers/ad_providers.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/product_provider.dart';
import 'package:picnic_app/providers/screen_protector_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/screens/pic/pic_camera_screen.dart';
import 'package:picnic_app/screens/portal.dart';
import 'package:picnic_app/screens/privacy.dart';
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
  createState() => _PicnicAppState();
}

class _PicnicAppState extends ConsumerState<App> with WidgetsBindingObserver {
  Widget? initScreen;
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(updateCheckerProvider.notifier).checkForUpdate();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appSettingProvider.notifier).loadSettings();
      ref.read(rewardedAdsProvider.notifier).loadAd(0);
      ref.read(rewardedAdsProvider.notifier).loadAd(1);
    });
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() {
      ref.read(serverProductsProvider);
      ref.read(storeProductsProvider);
    });

    supabase.auth.onAuthStateChange.listen((data) async {
      FirebaseCrashlytics.instance.log('Auth state changed: ${data.event}');
      logger.i('Auth state changed: ${data.event}');
      logger.i('User: ${data.session}');
      final session = data.session;
      if (session != null) {
        logger.d('jwtToken: ${session.accessToken}');
      }

      if (data.event == AuthChangeEvent.signedIn) {
        logger.e('User signed in');
        await ref.read(userInfoProvider.notifier).getUserProfiles();
        ref.read(userInfoProvider.notifier).subscribeToUserProfiles();
      } else if (data.event == AuthChangeEvent.signedOut) {
        logger.e('User signed out');
        ref.read(userInfoProvider.notifier).state = AsyncValue.data(null);
        ref.read(userInfoProvider.notifier).unsubscribeFromUserProfiles();
      }
    });

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
    ScreenProtector.preventScreenshotOff();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (isMobile()) {
      if (state == AppLifecycleState.inactive) {
        blackScreenOverlaySupport ??= showOverlay(
            (context, t) => Container(color: blackScreenColor),
            duration: Duration.zero);
      } else if (state == AppLifecycleState.resumed) {
        clearBlackScreenOverlay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSettingState = ref.watch(appSettingProvider);

    final isScreenProtector = ref.watch(isScreenProtectorProvider);
    logger.e('screenProtectorState: $isScreenProtector');
    if (isScreenProtector) {
      ScreenProtector.preventScreenshotOn();
    } else {
      ScreenProtector.preventScreenshotOff();
    }
    ScreenUtil.init(context,
        designSize: kIsWeb ? webDesignSize : const Size(393, 892));

    return ScreenUtilInit(
      child: OverlaySupport.global(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Picnic',
          theme: _getCurrentTheme(),
          themeMode: appSettingState.themeMode,
          locale: appSettingState.locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          routes: {
            Portal.routeName: (context) => Portal(),
            SignUpScreen.routeName: (context) => const SignUpScreen(),
            '/pic-camera': (context) => const PicCameraScreen(),
            TermsScreen.routeName: (context) => const TermsScreen(),
            PrivacyScreen.routeName: (context) => const PrivacyScreen(),
          },
          navigatorObservers: [observer],
          builder: (context, child) =>
              UpdateDialog(child: child ?? const SizedBox.shrink()),
          home: UniversalPlatform.isWeb
              ? initScreen ?? Portal()
              : FlutterSplashScreen.fadeIn(
                  useImmersiveMode: true,
                  duration: const Duration(milliseconds: 3000),
                  animationDuration: const Duration(milliseconds: 3000),
                  childWidget: SizedBox(
                    width: getPlatformScreenSize(context).width,
                    height: getPlatformScreenSize(context).height,
                    child: Image.asset("assets/splash.png", fit: BoxFit.cover),
                  ),
                  nextScreen: initScreen ?? Portal(),
                ),
        ),
      ),
    );
  }

  ThemeData _getCurrentTheme() {
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
