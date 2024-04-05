import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/pages/landing_page.dart';
import 'package:prame_app/providers/app_setting_provider.dart';
import 'package:prame_app/screens/home_screen.dart';
import 'package:prame_app/screens/language_screen.dart';
import 'package:prame_app/ui/style.dart';

class LandingScreen extends ConsumerWidget {
  static const String routeName = '/landing';

  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettingState = ref.watch(appSettingProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, HomeScreen.routeName);
              },
              child: Text(Intl.message('nav_library'),
                  style: getTextStyle(AppTypo.UI16B, AppColors.Gray900)),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, LanguageScreen.routeName);
              },
              child: Text(
                  'Language : ${languageMap[appSettingState.locale.languageCode]}',
                  style: getTextStyle(AppTypo.UI16B, AppColors.Gray900)),
            )
          ],
        ),
      ),
      body: const LandingPage(),
    );
  }
}
