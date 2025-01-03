import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/common_theme.dart';
import 'package:picnic_lib/ui/style.dart';

ThemeData novelThemeLight = ThemeData.light().copyWith(
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    displayMedium: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    displaySmall: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    headlineMedium: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    headlineSmall: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    titleLarge: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    titleMedium: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    titleSmall: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    bodyLarge: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    bodyMedium: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    bodySmall: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    labelLarge: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
    labelSmall: TextStyle(fontFamily: 'Pretendard', color: Colors.black),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.point500,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.point500,
    selectedIconTheme: IconThemeData(color: Colors.black),
    unselectedIconTheme: IconThemeData(color: Colors.black54),
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.black54,
    selectedLabelStyle: TextStyle(color: Colors.black),
    unselectedLabelStyle: TextStyle(color: Colors.black54),
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
