import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';

TabBarTheme commonTabBarTheme = TabBarTheme(
  labelStyle: getTextStyle(
    AppTypo.BODY14M,
    AppColors.Grey900,
  ),
  unselectedLabelStyle: getTextStyle(
    AppTypo.BODY14R,
    AppColors.Grey600,
  ),
  indicatorSize: TabBarIndicatorSize.tab,
);

SwitchThemeData commonSwitchTheme = SwitchThemeData(
  trackColor: WidgetStateProperty.all(AppColors.Primary500),
  trackOutlineWidth: const WidgetStatePropertyAll(0),
  trackOutlineColor: WidgetStateProperty.all(AppColors.Grey00),
);

BottomSheetThemeData commonBottomSheetTheme = const BottomSheetThemeData(
  dragHandleSize: Size(200, 2),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
    ),
  ),
);
