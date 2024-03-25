import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/generated/l10n.dart';
import 'package:prame_app/providers/app_setting_provider.dart';
import 'package:prame_app/screens/home_screen.dart';
import 'package:prame_app/screens/landing_screen.dart';
import 'package:prame_app/screens/language_screen.dart';
import 'package:prame_app/screens/my_screen.dart';
import 'package:prame_app/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrameApp extends ConsumerWidget {
  const PrameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ThemeMode themeMode = ref.watch(themeProvider);
    Locale locale = ref.watch(localeProvider);
    return MaterialApp(
        title: 'Prame App Demo',
        theme: themeLight,
        darkTheme: themeDark,
        themeMode: themeMode,
        locale: locale,
        routes: {
          LandingScreen.routeName: (context) => const LandingScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          MyScreen.routeName: (context) => const MyScreen(),
          LanguageScreen.routeName: (context) => const LanguageScreen(),
        },
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: LandingScreen());
  }
}
