import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:prame_app/generated/l10n.dart';
import 'package:prame_app/overlays.dart';
import 'package:prame_app/providers/app_setting_provider.dart';
import 'package:prame_app/providers/celeb_list_provider.dart';
import 'package:prame_app/screens/draw_image_screen.dart';
import 'package:prame_app/screens/gallery_detail_screen.dart';
import 'package:prame_app/screens/home_screen.dart';
import 'package:prame_app/screens/landing_screen.dart';
import 'package:prame_app/screens/language_screen.dart';
import 'package:prame_app/screens/my_screen.dart';
import 'package:prame_app/screens/prame_screen.dart';
import 'package:prame_app/ui/theme.dart';
import 'package:prame_app/util.dart';
import 'package:screen_protector/screen_protector.dart';

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
      await ScreenProtector.preventScreenshotOn();
    });
    WidgetsBinding.instance.addObserver(this);
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
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      child: OverlaySupport.global(
        child: MaterialApp(
            title: 'Prame App Demo',
            theme: themeLight,
            darkTheme: themeLight,
            themeMode: appSettingState.themeMode,
            locale: appSettingState.locale,
            routes: {
              LandingScreen.routeName: (context) => const LandingScreen(),
              MyScreen.routeName: (context) => const MyScreen(),
              LanguageScreen.routeName: (context) => const LanguageScreen(),
              PrameScreen.routeName: (context) => const PrameScreen(),
              DrawImageScreen.routeName: (context) => const DrawImageScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == GalleryDetailScreen.routeName) {
                final args = settings.arguments as GalleryDetailScreenArguments;
                return MaterialPageRoute(
                    builder: (context) => GalleryDetailScreen(
                          galleryId: args.galleryId,
                          galleryName: args.galleryName,
                        ));
              }
              if (settings.name == HomeScreen.routeName) {
                final args = settings.arguments as HomeScreenArguments;

                return MaterialPageRoute(
                    builder: (context) => HomeScreen(
                          celebModel: args.celebModel,
                        ));
              }

              return null;
            },
            localizationsDelegates: [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            home: HomeScreen(
              celebModel: asyncCelebListState.value?.items.first,
            )),
      ),
    );
  }
}
