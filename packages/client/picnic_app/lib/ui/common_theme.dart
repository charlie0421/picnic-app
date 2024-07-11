import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:picnic_app/ui/style.dart';

TabBarTheme commonTabBarTheme = TabBarTheme(
  labelStyle: getTextStyle(
    AppTypo.BODY14M,
    AppColors.Grey900,
  ),
  unselectedLabelStyle: getTextStyle(
    AppTypo.BODY14R,
    AppColors.Grey300,
  ),
  indicatorSize: TabBarIndicatorSize.tab,
  indicatorColor: AppColors.Grey900,
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

MarkdownStyleSheet commonMarkdownStyleSheet = MarkdownStyleSheet(
  h3: getTextStyle(AppTypo.CAPTION10SB, AppColors.Primary500),
  h3Align: WrapAlignment.center,
  h6: getTextStyle(AppTypo.BODY14M, AppColors.Grey900),
  h6Align: WrapAlignment.center,
);

DialogTheme commonDialogTheme = const DialogTheme(
  backgroundColor: AppColors.Grey00,
);
