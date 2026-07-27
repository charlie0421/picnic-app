import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/common_theme.dart';
import 'package:picnic_lib/ui/style.dart';

ThemeData mypageThemeLight = ThemeData.light().copyWith(
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    displayMedium: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    displaySmall: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    headlineMedium: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    headlineSmall: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    titleLarge: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    titleMedium: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    titleSmall: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    bodyLarge: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    bodyMedium: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    bodySmall: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    labelLarge: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
    labelSmall: TextStyle(fontFamily: 'Pretendard', package: 'picnic_lib', color: Colors.black),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.grey00,
  ),
  scaffoldBackgroundColor: AppColors.grey00,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
    ),
  ),
  tabBarTheme: commonTabBarTheme,
  switchTheme: commonSwitchTheme,
  colorScheme: const ColorScheme(
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.black,
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.red,
    surface: Colors.white,
    onSurface: Colors.black,
    brightness: Brightness.light,
  ),
  bottomSheetTheme: commonBottomSheetTheme,
  dialogTheme: commonDialogTheme,
);
