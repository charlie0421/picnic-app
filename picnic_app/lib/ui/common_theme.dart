import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:picnic_app/ui/style.dart';

TabBarTheme commonTabBarTheme = TabBarTheme(
  labelStyle: getTextStyle(
    AppTypo.body14M,
    AppColors.grey900,
  ),
  unselectedLabelStyle: getTextStyle(
    AppTypo.body14R,
    AppColors.grey300,
  ),
  indicatorSize: TabBarIndicatorSize.tab,
  indicatorColor: AppColors.grey900,
);

SwitchThemeData commonSwitchTheme = SwitchThemeData(
  trackColor: WidgetStateProperty.all(AppColors.primary500),
  trackOutlineWidth: const WidgetStatePropertyAll(0),
  trackOutlineColor: WidgetStateProperty.all(AppColors.grey00),
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

MarkdownStyleSheet commonMarkdownStyleSheet = MarkdownStyleSheet(
  h3: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
  h3Align: WrapAlignment.center,
  h6: getTextStyle(AppTypo.body14M, AppColors.grey900),
  h6Align: WrapAlignment.center,
);

DialogTheme commonDialogTheme = const DialogTheme(
  backgroundColor: AppColors.grey00,
);
