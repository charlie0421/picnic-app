import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';

TabBarTheme commonTabBarTheme = TabBarTheme(
  labelStyle: getTextStyle(
    AppTypo.BODY14M,
    AppColors.Gray900,
  ),
  unselectedLabelStyle: getTextStyle(
    AppTypo.BODY14R,
    AppColors.Gray600,
  ),
  indicatorSize: TabBarIndicatorSize.tab,
);
