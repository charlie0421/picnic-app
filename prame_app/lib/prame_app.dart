import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:prame_app/generated/l10n.dart';
import 'package:prame_app/providers/app_setting_provider.dart';
import 'package:prame_app/screens/home_screen.dart';
import 'package:prame_app/screens/landing_screen.dart';
import 'package:prame_app/screens/language_screen.dart';
import 'package:prame_app/screens/my_screen.dart';
import 'package:prame_app/screens/prame_screen.dart';
import 'package:prame_app/ui/theme.dart';

import 'constants.dart';

class PrameApp extends ConsumerStatefulWidget {
  const PrameApp({super.key});

  @override
  createState() => _PrameAppState();
}

class _PrameAppState extends ConsumerState<PrameApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appSettingProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appSettingState = ref.watch(appSettingProvider);
    logger.i('appSettingState.locale: ${appSettingState.locale}');
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      child: MaterialApp(
          title: 'Prame App Demo',
          theme: themeLight,
          darkTheme: themeLight,
          themeMode: appSettingState.themeMode,
          locale: appSettingState.locale,
          routes: {
            LandingScreen.routeName: (context) => const LandingScreen(),
            HomeScreen.routeName: (context) => const HomeScreen(),
            MyScreen.routeName: (context) => const MyScreen(),
            LanguageScreen.routeName: (context) => const LanguageScreen(),
            PrameScreen.routeName: (context) => const PrameScreen(),
          },
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: const LandingScreen()),
    );
  }
}
