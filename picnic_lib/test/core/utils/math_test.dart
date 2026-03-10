import 'package:picnic_lib/core/utils/math.dart';
import 'package:test/test.dart';

void main() {
  group('generateRandomString', () {
    test('길이 0을 전달하면 빈 문자열을 반환한다', () {
      final result = generateRandomString(0);
      expect(result, isEmpty);
      expect(result.length, equals(0));
    });

    test('길이 1을 전달하면 길이 1인 문자열을 반환한다', () {
      final result = generateRandomString(1);
      expect(result.length, equals(1));
    });

    test('길이 10을 전달하면 길이 10인 문자열을 반환한다', () {
      final result = generateRandomString(10);
      expect(result.length, equals(10));
    });

    test('길이 100을 전달하면 길이 100인 문자열을 반환한다', () {
      final result = generateRandomString(100);
      expect(result.length, equals(100));
    });

    test('생성된 문자열은 영숫자(alphanumeric) 문자만 포함한다', () {
      final result = generateRandomString(200);
      final alphanumericPattern = RegExp(r'^[A-Za-z0-9]*$');
      expect(alphanumericPattern.hasMatch(result), isTrue);
    });

    test('두 번 호출하면 (높은 확률로) 서로 다른 문자열을 반환한다', () {
      final result1 = generateRandomString(20);
      final result2 = generateRandomString(20);
      expect(result1, isNot(equals(result2)));
    });
  });
}
