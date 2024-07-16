import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/overlays.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
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
import 'package:picnic_app/util.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:universal_platform/universal_platform.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  createState() => _PicnicAppState();
}

class _PicnicAppState extends ConsumerState<App> with WidgetsBindingObserver {
  Widget? initScreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appSettingProvider.notifier).loadSettings();
      await ScreenProtector.preventScreenshotOn();
    });
    WidgetsBinding.instance.addObserver(this);

    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        final jwtToken = session.accessToken;
        logger.d(jwtToken);
      }
    });

    final appLinks = AppLinks(); // AppLinks is singleton

    appLinks.uriLinkStream.listen((Uri uri) {
      logger.i('Incoming link: $uri');

      if (uri.pathSegments.contains('terms')) {
        logger.i('Terms link');

        uri.pathSegments.contains('ko')
            ? initScreen = const TermsScreen(language: 'ko')
            : initScreen = const TermsScreen(language: 'en');
      } else if (uri.pathSegments.contains('privacy')) {
        logger.i('Privacy link');
        uri.pathSegments.contains('ko')
            ? initScreen = const PrivacyScreen(language: 'ko')
            : initScreen = const PrivacyScreen(language: 'en');
      } else {
        ref.read(userInfoProvider.notifier).getUserProfiles();
      }
    }, onError: (err) {
      // Handle error
      print('Error: $err');
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
          (BuildContext context, t) {
            return Container(
              color: blackScreenColor,
            );
          },
          duration: Duration.zero,
        );
      } else if (state == AppLifecycleState.resumed) {
        clearBlackScreenOverlay();
      }
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSettingState = ref.watch(appSettingProvider);

    ScreenUtil.init(context,
        designSize: kIsWeb ? webDesignSize : const Size(393, 892));

    return ScreenUtilInit(
      child: OverlaySupport.global(
        child: MaterialApp(
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
              Portal.routeName: (context) => const Portal(),
              SignUpScreen.routeName: (context) => const SignUpScreen(),
              '/pic-camera': (context) => const PicCameraScreen(),
              TermsScreen.routeName: (context) => const TermsScreen(),
              PrivacyScreen.routeName: (context) => const PrivacyScreen(),
            },
            home: UniversalPlatform.isWeb
                ? initScreen ?? const Portal()
                : FlutterSplashScreen.fadeIn(
                    useImmersiveMode: true,
                    duration: const Duration(milliseconds: 3000),
                    animationDuration: const Duration(milliseconds: 3000),
                    childWidget: SizedBox(
                        width: getPlatformScreenSize(context).width,
                        height: getPlatformScreenSize(context).height,
                        child: Image.asset("assets/splash.png",
                            fit: BoxFit.cover)),
                    nextScreen: initScreen ?? const Portal())),
      ),
    );
  }

  _getCurrentTheme() {
    final currentPortal = ref.watch(navigationInfoProvider);

    if (currentPortal.portalType == PortalType.vote) {
      return voteThemeLight;
    } else if (currentPortal.portalType == PortalType.pic) {
      return picThemeLight;
    } else if (currentPortal.portalType == PortalType.community) {
      return communityThemeLight;
    } else if (currentPortal.portalType == PortalType.novel) {
      return novelThemeLight;
    } else if (currentPortal.portalType == PortalType.mypage) {
      return mypageThemeLight;
    } else {
      return picThemeLight;
    }
  }
}
