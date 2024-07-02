import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/ui/common_theme.dart';
import 'package:picnic_app/ui/style.dart';

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
  appBarTheme: const AppBarTheme(
    backgroundColor: picMainColor,
    foregroundColor: Colors.white,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: picMainColor,
    selectedIconTheme: IconThemeData(color: Colors.black),
    unselectedIconTheme: IconThemeData(color: Colors.black54),
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.black54,
    selectedLabelStyle: TextStyle(color: Colors.black),
    unselectedLabelStyle: TextStyle(color: Colors.black54),
  ),
  scaffoldBackgroundColor: AppColors.Grey00,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 32, vertical: 0).r),
        backgroundColor: WidgetStateProperty.all(AppColors.Mint500),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
                color: AppColors.Primary500,
                width: 1,
                strokeAlign: BorderSide.strokeAlignInside),
          ),
        ),
        textStyle: WidgetStateProperty.all(
          getTextStyle(
            AppTypo.BODY14B,
            AppColors.Primary500,
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
);
