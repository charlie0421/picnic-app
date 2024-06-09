import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/ui/common_theme.dart';
import 'package:picnic_app/ui/style.dart';

ThemeData communityThemeLight = ThemeData.light().copyWith(
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
    backgroundColor: communityMainColor,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: communityMainColor,
    selectedIconTheme: IconThemeData(color: Colors.black),
    unselectedIconTheme: IconThemeData(color: Colors.black54),
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.black54,
    selectedLabelStyle: TextStyle(color: Colors.black),
    unselectedLabelStyle: TextStyle(color: Colors.black54),
  ),
  scaffoldBackgroundColor: AppColors.Gray00,
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
  bottomSheetTheme: const BottomSheetThemeData(
    showDragHandle: true,
    dragHandleColor: communityMainColor,
    dragHandleSize: Size(200, 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
    ),
  ),
);
