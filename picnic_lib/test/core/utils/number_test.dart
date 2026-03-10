import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/number.dart';

void main() {
  group('formatViewCountNumberKo', () {
    test('1억 이상이면 억 단위로 표시', () {
      expect(formatViewCountNumberKo(100000000), equals('1.0억'));
      expect(formatViewCountNumberKo(250000000), equals('2.5억'));
      expect(formatViewCountNumberKo(1500000000), equals('15.0억'));
    });

    test('1만 이상이면 만 단위로 표시', () {
      expect(formatViewCountNumberKo(10000), equals('1.0만'));
      expect(formatViewCountNumberKo(50000), equals('5.0만'));
      expect(formatViewCountNumberKo(123456), equals('12.3만'));
    });

    test('1000 이상이면 콤마 포맷', () {
      expect(formatViewCountNumberKo(1000), equals('1,000'));
      expect(formatViewCountNumberKo(9999), equals('9,999'));
    });

    test('1000 미만이면 콤마 없이 표시', () {
      expect(formatViewCountNumberKo(0), equals('0'));
      expect(formatViewCountNumberKo(1), equals('1'));
      expect(formatViewCountNumberKo(999), equals('999'));
    });
  });

  group('formatViewCountNumberEn', () {
    test('10억 이상이면 B 단위로 표시', () {
      expect(formatViewCountNumberEn(1000000000), equals('1.0B'));
      expect(formatViewCountNumberEn(2500000000), equals('2.5B'));
    });

    test('100만 이상이면 M 단위로 표시', () {
      expect(formatViewCountNumberEn(1000000), equals('1.0M'));
      expect(formatViewCountNumberEn(5500000), equals('5.5M'));
    });

    test('1000 이상이면 콤마 포맷', () {
      expect(formatViewCountNumberEn(1000), equals('1,000'));
      expect(formatViewCountNumberEn(999999), equals('999,999'));
    });

    test('1000 미만이면 콤마 없이 표시', () {
      expect(formatViewCountNumberEn(0), equals('0'));
      expect(formatViewCountNumberEn(42), equals('42'));
      expect(formatViewCountNumberEn(999), equals('999'));
    });
  });

  group('formatNumberWithComma', () {
    test('정수를 콤마 포맷으로 변환', () {
      expect(formatNumberWithComma(1000), equals('1,000'));
      expect(formatNumberWithComma(1234567), equals('1,234,567'));
    });

    test('문자열 숫자도 변환', () {
      expect(formatNumberWithComma<String>('1000'), equals('1,000'));
      expect(formatNumberWithComma<String>('9876543'), equals('9,876,543'));
    });

    test('1000 미만 숫자', () {
      expect(formatNumberWithComma(0), equals('0'));
      expect(formatNumberWithComma(999), equals('999'));
    });
  });
}
