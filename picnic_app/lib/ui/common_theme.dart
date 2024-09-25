import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

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

ElevatedButtonThemeData commonElevatedButtonThemeData = ElevatedButtonThemeData(
  style: ButtonStyle(
      padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 32.cw, vertical: 0)),
      backgroundColor: WidgetStateProperty.all(AppColors.primary500),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
              color: AppColors.primary500,
              width: 1,
              strokeAlign: BorderSide.strokeAlignInside),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        getTextStyle(
          AppTypo.body14B,
          AppColors.grey00,
        ),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
