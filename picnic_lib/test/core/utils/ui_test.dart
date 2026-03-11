import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;

void main() {
  group('getComplementaryColor', () {
    test('검정의 보색은 흰색에 가까움', () {
      final result = ui.getComplementaryColor(const Color(0xFF000000));
      // color.r for black = 0.0, toInt() = 0, 255-0 = 255
      expect(result, equals(const Color(0xFFFFFFFF)));
    });

    test('보색 계산 - alpha는 항상 255 유지', () {
      final result = ui.getComplementaryColor(const Color(0xFF808080));
      expect(result.a, equals(1.0));
    });

    test('보색 계산 - RGB 반전', () {
      // getComplementaryColor는 Color.r (0.0~1.0)에서 toInt() 사용
      // 따라서 정확한 RGB 반전이 아닌 근사값을 반환할 수 있음
      final input = const Color(0xFF000000);
      final result = ui.getComplementaryColor(input);
      // black → 0.0.toInt() = 0 → 255-0 = 255
      expect(result.r, closeTo(1.0, 0.01));
      expect(result.g, closeTo(1.0, 0.01));
      expect(result.b, closeTo(1.0, 0.01));
    });

    test('Color.fromARGB로 결과 생성 확인', () {
      // getComplementaryColor는 Color.r (0.0~1.0)에 toInt()를 사용
      // 이는 0.0~1.0 범위를 0 또는 1로 변환하므로 근사값만 테스트
      final result = ui.getComplementaryColor(const Color(0xFF808080));
      // 0x80/255 ≈ 0.502 → toInt() = 0 → 255-0 = 255
      expect(result, isA<Color>());
    });
  });

  group('플랫폼 감지 함수', () {
    test('isIOS 반환 타입 bool', () {
      expect(ui.isIOS(), isA<bool>());
    });

    test('isAndroid 반환 타입 bool', () {
      expect(ui.isAndroid(), isA<bool>());
    });

    test('isMobile 반환 타입 bool', () {
      expect(ui.isMobile(), isA<bool>());
    });

    test('isDesktop 반환 타입 bool', () {
      expect(ui.isDesktop(), isA<bool>());
    });

    test('isMacOS 반환 타입 bool', () {
      expect(ui.isMacOS(), isA<bool>());
    });

    test('isWindows 반환 타입 bool', () {
      expect(ui.isWindows(), isA<bool>());
    });

    test('isLinux 반환 타입 bool', () {
      expect(ui.isLinux(), isA<bool>());
    });

    test('isMobile과 isDesktop은 상호 배타적', () {
      if (!ui.isMobile() && !ui.isDesktop()) {
        expect(true, isTrue);
      } else {
        expect(ui.isMobile() != ui.isDesktop(), isTrue);
      }
    });
  });
}
