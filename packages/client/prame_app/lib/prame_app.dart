import 'package:prame_app/constants.dart';
import 'package:prame_app/providers/app_setting_provider.dart';
import 'package:prame_app/screens/home_screen.dart';
import 'package:prame_app/screens/landing_screen.dart';
import 'package:prame_app/screens/my_screen.dart';
import 'package:prame_app/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrameApp extends ConsumerWidget {
  const PrameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ThemeMode themeMode = ref.watch(themeProvider);
    return MaterialApp(
        title: 'Prame App Demo',
        theme: themeLight,
        darkTheme: themeDark,
        themeMode: themeMode,
        routes: {
          LandingScreen.routeName: (context) => const LandingScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          MyScreen.routeName: (context) => const MyScreen(),
        },
        home: LandingScreen());
  }
}
