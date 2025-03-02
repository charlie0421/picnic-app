import 'package:flutter/material.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/ui/common_theme.dart';
import 'package:picnic_lib/ui/style.dart';

ThemeData communityThemeLight = ThemeData.light().copyWith(
  appBarTheme: AppBarTheme(
    backgroundColor: communityMainColor,
    foregroundColor: Colors.white,
  ),
  bottomAppBarTheme: const BottomAppBarTheme(
    color: Colors.transparent,
  ),
  scaffoldBackgroundColor: AppColors.grey00,
  elevatedButtonTheme: getElevatedButtonThemeData(
      borderColor: AppColors.sub500, textColor: AppColors.grey00),
  tabBarTheme: commonTabBarTheme as TabBarThemeData,
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
  dialogTheme: commonDialogTheme as DialogThemeData,
);
