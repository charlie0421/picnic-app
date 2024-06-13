import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color Mint500 = Color(0xFF83FBC8);
  static const Color Primary500 = Color(0xFF9374FF);
  static const Color Sub500 = Color(0xFFCDFB5D);
  static const Color Point500 = Color(0xFFFFA9BD);
  static const Color Point900 = Color(0xFFEB4A71);

  static const Color StatusError = Color(0xFFFF4242);

  static const Color Grey900 = Color(0xFF000000);

  static const Color Grey800 = Color(0xFF252528);
  static const Color Grey700 = Color(0xFF252528);
  static const Color Grey600 = Color(0xFF5D5F66);
  static const Color Grey500 = Color(0xFF878A93);
  static const Color Grey400 = Color(0xFFA6A8AF);
  static const Color Grey300 = Color(0xFFD7D7DC);
  static const Color Grey200 = Color(0xFFEBEBEF);
  static const Color Grey100 = Color(0xFFF7F7F8);
  static const Color Grey00 = Colors.white;
}

enum AppTypo {
  TITLE18B(18.0, FontWeight.w700, 1.5, 0),
  TITLE18SB(18.0, FontWeight.w600, 1.5, 0),
  TITLE18M(18.0, FontWeight.w500, 1.5, 0),
  BODY16B(16.0, FontWeight.w700, 1.5, 0),
  BODY16M(16.0, FontWeight.w500, 1.5, 0),
  BODY16R(16.0, FontWeight.w400, 1.5, 0),
  BODY14B(14.0, FontWeight.w700, 1.5, 0),
  BODY14M(14.0, FontWeight.w500, 1.5, 0),
  BODY14R(14.0, FontWeight.w400, 1.5, 0),
  CAPTION12B(12.0, FontWeight.w700, 1.5, 0),
  CAPTION12M(12.0, FontWeight.w500, 1.5, 0),
  CAPTION12R(12.0, FontWeight.w400, 1.5, 0),
  CAPTION10SB(10.0, FontWeight.w600, 1.5, 0);

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
