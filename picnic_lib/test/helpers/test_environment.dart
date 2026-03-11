import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

/// 테스트 환경에서 AppColors를 초기화합니다.
/// Environment._config가 필요한 동적 색상(primary500 등)을 테스트용 기본값으로 설정합니다.
void initTestColors() {
  AppColors.primary500 = const Color(0xFF6200EE);
  AppColors.secondary500 = const Color(0xFF03DAC6);
  AppColors.sub500 = const Color(0xFFBB86FC);
  AppColors.point500 = const Color(0xFFFF0266);
  AppColors.point900 = const Color(0xFFCF6679);
}
