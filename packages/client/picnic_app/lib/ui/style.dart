import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color Mint500 = Color(0xFF83FBC8);
  static const Color Primary500 = Color(0xFF9374FF);
  static const Color Sub500 = Color(0xFFCDFB5D);
  static const Color Point500 = Color(0xFFFFA9BD);

  static const Color Gray900 = Color(0xFF000000);

  // static const Color Gray800 = Color(0xFF1E2327);
  static const Color Gray700 = Color(0xFF252528);
  static const Color Gray600 = Color(0xFF5D5F66);
  static const Color Gray500 = Color(0xFF878A93);
  static const Color Gray400 = Color(0xFFA6A8AF);
  static const Color Gray300 = Color(0xFFD7D7DC);
  static const Color Gray200 = Color(0xFFEBEBEF);
  static const Color Gray100 = Color(0xFFF7F7F8);
  static const Color Gray00 = Colors.white;
}

enum AppTypo {
  UI24B(24.0, FontWeight.w800, -0.72, 0.06),
  UI20B(20.0, FontWeight.w800, -0.60, 0.07),
  UI18B(18.0, FontWeight.w800, -0.54, 0.09),
  UI16B(16.0, FontWeight.w800, -0.48, 0.09),
  UI14B(14.0, FontWeight.w800, -0.42, 0.10),
  UI13B(13.0, FontWeight.w800, -0.39, 0.12),
  UI12B(12.0, FontWeight.w800, -0.36, 0.12),
  UI11B(11.0, FontWeight.w800, -0.11, 0.13),
  UI10B(10.0, FontWeight.w800, -0.10, 0.16),
  UI9B(9.0, FontWeight.w800, -0.09, 0.17),
  UI24M(24.0, FontWeight.w500, -0.72, 0.06),
  UI20M(20.0, FontWeight.w500, -0.60, 0.07),
  UI18M(18.0, FontWeight.w500, -0.54, 0.09),
  UI16M(16.0, FontWeight.w500, -0.32, 0.09),
  UI14M(14.0, FontWeight.w500, -0.42, 0.10),
  UI13M(13.0, FontWeight.w500, -0.39, 0.12),
  UI12M(12.0, FontWeight.w500, -0.36, 0.12),
  UI11M(11.0, FontWeight.w500, -0.11, 0.13),
  UI10M(10.0, FontWeight.w500, -0.10, 0.16),
  UI9M(9.0, FontWeight.w500, -0.09, 0.17),
  UI24(24.0, FontWeight.w400, -0.72, 0.06),
  UI20(20.0, FontWeight.w400, -0.60, 0.07),
  UI18(18.0, FontWeight.w400, -0.54, 0.09),
  UI16(16.0, FontWeight.w400, -0.48, 0.09),
  UI14(14.0, FontWeight.w400, -0.42, 0.10),
  UI13(13.0, FontWeight.w400, -0.39, 0.12),
  UI12(12.0, FontWeight.w400, -0.12, 0.12),
  UI11(11.0, FontWeight.w400, -0.11, 0.13),
  UI10(10.0, FontWeight.w400, -0.10, 0.12),
  UI9(9.0, FontWeight.w400, -0.09, 0.17);

  final double _size;

  double get size => _size.sp;

  final FontWeight weight;
  final double height;
  final double letterSpacing;

  const AppTypo(
    this._size,
    this.weight,
    this.letterSpacing,
    this.height,
  );
}

TextStyle getTextStyle(BuildContext context, AppTypo typo, [Color? color]) {
  color ??= Theme.of(context).colorScheme.primary;
  return TextStyle(
    color: color,
    fontSize: typo._size,
    fontFamily: 'Pretendard',
    fontWeight: typo.weight,
    letterSpacing: typo.letterSpacing,
    // height: typo.height,
  );
}
