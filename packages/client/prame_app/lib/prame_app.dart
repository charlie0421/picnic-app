import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:prame_app/generated/l10n.dart';
import 'package:prame_app/overlays.dart';
import 'package:prame_app/providers/app_setting_provider.dart';
import 'package:prame_app/providers/celeb_list_provider.dart';
import 'package:prame_app/providers/navigation_provider.dart';
import 'package:prame_app/screens/portal.dart';
import 'package:prame_app/ui/fan_theme.dart';
import 'package:prame_app/ui/vote_theme.dart';
import 'package:prame_app/util.dart';

class PrameApp extends ConsumerStatefulWidget {
  const PrameApp({super.key});

  @override
  createState() => _PrameAppState();
}

class _PrameAppState extends ConsumerState<PrameApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appSettingProvider.notifier).loadSettings();
      // await ScreenProtector.preventScreenshotOn();
    });
    WidgetsBinding.instance.addObserver(this);
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
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      child: OverlaySupport.global(
        child: MaterialApp(
            title: 'Prame App Demo',
            theme: _getCurrentTheme(),
            darkTheme: fanThemeLight,
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
    } else {
      return fanThemeLight;
    }
  }
}
