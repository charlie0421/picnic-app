import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/overlays.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/screens/portal.dart';
import 'package:picnic_app/ui/community_theme.dart';
import 'package:picnic_app/ui/pic_theme.dart';
import 'package:picnic_app/ui/novel_theme.dart';
import 'package:picnic_app/ui/vote_theme.dart';
import 'package:picnic_app/util.dart';

class PicnicApp extends ConsumerStatefulWidget {
  const PicnicApp({super.key});

  @override
  createState() => _PicnicAppState();
}

class _PicnicAppState extends ConsumerState<PicnicApp>
    with WidgetsBindingObserver {
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appSettingProvider.notifier).loadSettings();
      // await ScreenProtector.preventScreenshotOn();
    });
    WidgetsBinding.instance.addObserver(this);
    // final _appLinks = AppLinks(); // AppLinks is singleton
    //
    // _sub = _appLinks.uriLinkStream.listen((Uri uri) {
    //   logger.i('Incoming link: $uri');
    // }, onError: (err) {
    //   Handle error
    // print('Error: $err');
    // });
  }

  @override
  void dispose() {
    // ScreenProtector.preventScreenshotOff();

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
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      child: OverlaySupport.global(
        child: MaterialApp(
            title: 'Picnic App',
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
            home: const Portal()),
      ),
    );
  }

  _getCurrentTheme() {
    final currentPortal = ref.watch(navigationInfoProvider);

    if (currentPortal.portalString == 'vote') {
      return voteThemeLight;
    } else if (currentPortal.portalString == 'pic') {
      return picThemeLight;
    } else if (currentPortal.portalString == 'community') {
      return communityThemeLight;
    } else if (currentPortal.portalString == 'novel') {
      return novelThemeLight;
    } else {
      return picThemeLight;
    }
  }
}
