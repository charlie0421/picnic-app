import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:app_links/app_links.dart';
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
import 'package:picnic_app/screens/login_screen.dart';
import 'package:picnic_app/screens/pic/pic_camera_screen.dart';
import 'package:picnic_app/screens/portal.dart';
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

void logJwtToken(String token) {
  const int chunkSize = 500; // 한 번에 로깅할 토큰의 길이
  int startIndex = 0;

  while (startIndex < token.length) {
    int endIndex = startIndex + chunkSize;
    if (endIndex > token.length) {
      endIndex = token.length;
    }

    logger.i(token.substring(startIndex, endIndex));
    startIndex = endIndex;
  }
}

class _PicnicAppState extends ConsumerState<App> with WidgetsBindingObserver {
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
        logJwtToken(jwtToken);
      }
    });

    final appLinks = AppLinks(); // AppLinks is singleton

    appLinks.uriLinkStream.listen((Uri uri) {
      logger.i('Incoming link: $uri');
      ref.read(userInfoProvider.notifier).getUserProfiles();
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
    if (!isWeb() && isMobile()) {
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
    ScreenUtil.init(
      context,
      designSize: UniversalPlatform.isWeb
          ? const Size(Constants.webWidth, Constants.webHeight)
          : const Size(375, 812),
    );

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
              LoginScreen.routeName: (context) => const LoginScreen(),
              Portal.routeName: (context) => const Portal(),
              '/pic-camera': (context) => const PicCameraScreen(),
            },
            home: FlutterSplashScreen.fadeIn(
                useImmersiveMode: true,
                duration: const Duration(milliseconds: 3000),
                animationDuration: const Duration(milliseconds: 3000),
                childWidget: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Image.asset("assets/splash.png", fit: BoxFit.cover)),
                nextScreen: const Portal())),
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
