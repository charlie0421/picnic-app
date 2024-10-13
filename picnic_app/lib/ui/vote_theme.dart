import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/ui/common_theme.dart';
import 'package:picnic_app/ui/style.dart';

ThemeData voteThemeLight = ThemeData.light().copyWith(
  appBarTheme: const AppBarTheme(
    backgroundColor: voteMainColor,
    foregroundColor: Colors.white,
  ),
  bottomAppBarTheme: const BottomAppBarTheme(
    color: Colors.transparent,
  ),
  scaffoldBackgroundColor: AppColors.grey00,
  elevatedButtonTheme: getElevatedButtonThemeData(
      borderColor: AppColors.sub500, textColor: AppColors.grey00),
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
