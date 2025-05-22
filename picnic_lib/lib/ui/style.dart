import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/config/environment.dart';

class AppColors {
  static Color primary500 = Environment.primaryColor;
  static Color secondary500 = Environment.secondaryColor;
  static Color sub500 = Environment.subColor;
  static Color point500 = Environment.pointColor;
  static Color point900 = Environment.point900Color;

  static const Color statusError = Color(0xFFFF4242);

  static const Color grey900 = Color(0xFF000000);

  static const Color grey800 = Color(0xFF252528);
  static const Color grey700 = Color(0xFF252528);
  static const Color grey600 = Color(0xFF5D5F66);
  static const Color grey500 = Color(0xFF878A93);
  static const Color grey400 = Color(0xFFA6A8AF);
  static const Color grey300 = Color(0xFFD7D7DC);
  static const Color grey200 = Color(0xFFEBEBEF);
  static const Color grey100 = Color(0xFFF7F7F8);
  static const Color grey00 = Colors.white;

  static const Color transparent = Colors.transparent;
}

enum AppTypo {
  title18B(18.0, FontWeight.w700, 1.5, 0),
  title18SB(18.0, FontWeight.w600, 1.5, 0),
  title18M(18.0, FontWeight.w500, 1.5, 0),
  body16B(16.0, FontWeight.w700, 1.5, 0),
  body16M(16.0, FontWeight.w500, 1.5, 0),
  body16R(16.0, FontWeight.w400, 1.5, 0),
  body14B(14.0, FontWeight.w700, 1.5, 0),
  body14M(14.0, FontWeight.w500, 1.5, 0),
  body14R(14.0, FontWeight.w400, 1.5, 0),
  caption12B(12.0, FontWeight.w700, 1.5, 0),
  caption12M(12.0, FontWeight.w500, 1.5, 0),
  caption12R(12.0, FontWeight.w400, 1.5, 0),
  caption10SB(10.0, FontWeight.w600, 1.5, 0);

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

TextStyle getTextStyle(AppTypo typo, [Color? color]) {
  return TextStyle(
    color: color,
    fontSize: typo._size,
    fontFamily: 'Pretendard',
    fontWeight: typo.weight,
    letterSpacing: typo.letterSpacing,
    // height: typo.height,
  );
}
