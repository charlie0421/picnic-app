import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:picnic_lib/ui/style.dart';

TabBarThemeData commonTabBarTheme = TabBarThemeData(
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
          EdgeInsets.symmetric(horizontal: 32.0, vertical: 0)),
      backgroundColor: WidgetStateProperty.all(AppColors.primary500),
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
          AppTypo.caption12B,
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

BottomSheetThemeData commonBottomSheetTheme = BottomSheetThemeData(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: const Radius.circular(40),
      topRight: const Radius.circular(40),
    ),
  ),
);

MarkdownStyleSheet commonMarkdownStyleSheet = MarkdownStyleSheet(
  h3: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
  h3Align: WrapAlignment.center,
  h6: getTextStyle(AppTypo.body14M, AppColors.grey900),
  h6Align: WrapAlignment.center,
);

DialogThemeData commonDialogTheme = const DialogThemeData(
  backgroundColor: AppColors.grey00,
);

ElevatedButtonThemeData getElevatedButtonThemeData(
    {Color? backgroundColor,
    Color? borderColor,
    AppTypo? appTypo,
    Color? textColor,
    double? borderRadius,
    double? borderWidth}) {
  // ScreenUtil이 초기화되지 않았을 때를 대비한 안전한 패딩 계산
  final horizontalPadding = 32.0; // 고정 값 사용

  return ElevatedButtonThemeData(
    style: ButtonStyle(
        padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 0)),
        backgroundColor:
            WidgetStateProperty.all(backgroundColor ?? AppColors.primary500),
        foregroundColor: WidgetStateProperty.all(textColor ?? AppColors.grey00),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 20),
            side: BorderSide(
                color: borderColor ?? AppColors.primary500,
                width: borderWidth ?? 1,
                style: BorderStyle.solid),
          ),
        ),
        textStyle: WidgetStateProperty.all(
          getTextStyle(
            appTypo ?? AppTypo.caption12B,
            textColor ?? AppColors.grey00,
          ),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
  );
}
