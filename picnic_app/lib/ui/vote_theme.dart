import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  scaffoldBackgroundColor: AppColors.Grey00,
  // bottomNavigationBarTheme: const BottomNavigationBarThemeData(
  //   backgroundColor: voteMainColorLight,
  //   selectedIconTheme: IconThemeData(color: Colors.black),
  //   unselectedIconTheme: IconThemeData(color: Colors.black54),
  //   selectedItemColor: Colors.black,
  //   unselectedItemColor: Colors.black54,
  //   selectedLabelStyle: TextStyle(color: Colors.black),
  //   unselectedLabelStyle: TextStyle(color: Colors.black54),
  // ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
        padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: 32.w, vertical: 0).r),
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
  dialogTheme: commonDialogTheme,
);
