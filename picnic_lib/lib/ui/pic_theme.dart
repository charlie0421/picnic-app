import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/common_theme.dart';
import 'package:picnic_lib/ui/style.dart';

ThemeData picThemeLight = ThemeData.light().copyWith(
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
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary500,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.primary500,
    selectedIconTheme: const IconThemeData(color: Colors.black),
    unselectedIconTheme: const IconThemeData(color: Colors.black54),
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.black54,
    selectedLabelStyle: const TextStyle(color: Colors.black),
    unselectedLabelStyle: const TextStyle(color: Colors.black54),
  ),
  scaffoldBackgroundColor: AppColors.grey00,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
        padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: 32.w, vertical: 0)),
        backgroundColor: WidgetStateProperty.all(AppColors.secondary500),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: AppColors.primary500,
                width: 1,
                strokeAlign: BorderSide.strokeAlignInside),
          ),
        ),
        textStyle: WidgetStateProperty.all(
          getTextStyle(
            AppTypo.body14B,
            AppColors.primary500,
          ),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
