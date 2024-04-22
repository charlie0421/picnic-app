import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color GP00 = Color(0xFFF3FBF7);
  static const Color GP50 = Color(0xFFDCF3E6);
  static const Color GP100 = Color(0xFFC4EBD6);
  static const Color GP200 = Color(0xFF95DBB6);
  static const Color GP300 = Color(0xFF4FC285);
  static const Color GP400 = Color(0xFF14AE5C);
  static const Color GP500 = Color(0xFF0F8345);
  static const Color GP600 = Color(0xFF0B6033);
  static const Color GP700 = Color(0xFF073D20);
  static const Color GP800 = Color(0xFF0E2F1C);
  static const Color GP900 = Color(0xFF031A0E);

  static const Color Gray900 = Color(0xFF0B0D0F);
  static const Color Gray800 = Color(0xFF1E2327);
  static const Color Gray700 = Color(0xFF2E363C);
  static const Color Gray600 = Color(0xFF444F59);
  static const Color Gray500 = Color(0xFF5B6976);
  static const Color Gray400 = Color(0xFF6B8298);
  static const Color Gray300 = Color(0xFF97AFC4);
  static const Color Gray200 = Color(0xFFB7C7D6);
  static const Color Gray100 = Color(0xFFD7E0E8);
  static const Color Gray50 = Color(0xFFF5F3EE);
  static const Color Gray00 = Colors.white;

  static const Color BS400 = Color(0xFF235BC7);
  static const Color BS300 = Color(0xFF4080FF);
  static const Color BS200 = Color(0xFF70A0FF);
  static const Color BS100 = Color(0xFF8EB4FF);
  static const Color BS50 = Color(0xFFEFF2F6);

  static const Color PS450 = Color(0xFF57417A);
  static const Color PS350 = Color(0xFF654ED9);
  static const Color PS250 = Color(0xFF765CF2);
  static const Color PS150 = Color(0xFF9B88F5);
  static const Color PS100 = Color(0xFF9C89F6);
  static const Color PS50 = Color(0xFFEBE7FD);
  static const Color PS00 = Color(0xFFEBE7FD);

  static const Color OS400 = Color(0xFFF24822);
  static const Color OS300 = Color(0xFFE7963B);
  static const Color OS250 = Color(0xFFECAA60);
  static const Color OS200 = Color(0xFFFBD53A);
  static const Color OS100 = Color(0xFFFCE482);

  static const Color RS400 = Color(0xFFDB004F);
  static const Color RS300 = Color(0xFFFF4085);
  static const Color RS200 = Color(0xFFFF75A7);
  static const Color RS100 = Color(0xFFFF99BD);
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
