import 'package:prame_app/constants.dart';
import 'package:flutter/material.dart';

ThemeData themeLight = ThemeData.light().copyWith(
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
    backgroundColor: mainColorLightMode,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: mainColorLightMode,
    selectedIconTheme: IconThemeData(color: Colors.white),
    selectedLabelStyle: TextStyle(color: Colors.white),
    unselectedIconTheme: IconThemeData(color: Colors.white54),
    unselectedLabelStyle: TextStyle(color: Colors.white54),
  ),
  colorScheme: const ColorScheme(
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.black,
    onSecondary: Colors.white,
    background: Colors.white,
    onBackground: Colors.black,
    error: Colors.red,
    onError: Colors.red,
    surface: Colors.white,
    onSurface: Colors.black,
    brightness: Brightness.light,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      padding: MaterialStateProperty.all(const EdgeInsets.all(4)),
    ),
  ),
);

ThemeData themeDark = ThemeData.dark(useMaterial3: true).copyWith(
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    displayMedium: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    displaySmall: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    headlineMedium: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    headlineSmall: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    titleLarge: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    titleMedium: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    titleSmall: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    bodyLarge: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    bodyMedium: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    bodySmall: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    labelLarge: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
    labelSmall: TextStyle(fontFamily: 'Pretendard', color: Colors.white),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: mainColorDarkMode,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: mainColorDarkMode,
    selectedIconTheme: IconThemeData(color: Colors.white),
    selectedLabelStyle: TextStyle(color: Colors.white),
    unselectedIconTheme: IconThemeData(color: Colors.white54),
    unselectedLabelStyle: TextStyle(color: Colors.white54),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      padding: MaterialStateProperty.all(const EdgeInsets.all(4)),
    ),
  ),
  colorScheme: const ColorScheme(
    primary: Colors.white,
    onPrimary: Colors.black,
    secondary: Colors.white,
    onSecondary: Colors.black,
    background: Colors.black,
    onBackground: Colors.white,
    error: Colors.red,
    onError: Colors.red,
    surface: Colors.black,
    onSurface: Colors.white,
    brightness: Brightness.dark,
  ).copyWith(background: Colors.black),
);
