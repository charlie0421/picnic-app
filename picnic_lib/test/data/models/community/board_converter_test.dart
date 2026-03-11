import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';

void main() {
  group('DescriptionConverter', () {
    const converter = DescriptionConverter();

    test('Map<String, dynamic> 입력 시 그대로 반환', () {
      final input = {'ko': '설명', 'en': 'description'};
      expect(converter.fromJson(input), equals(input));
    });

    test('String 입력 시 그대로 반환', () {
      expect(converter.fromJson('텍스트 설명'), equals('텍스트 설명'));
    });

    test('다른 타입 입력 시 ArgumentError', () {
      expect(() => converter.fromJson(123), throwsArgumentError);
    });

    test('toJson - Map 입력 시 그대로 반환', () {
      final input = {'ko': '설명'};
      expect(converter.toJson(input), equals(input));
    });

    test('toJson - String 입력 시 그대로 반환', () {
      expect(converter.toJson('설명'), equals('설명'));
    });

    test('toJson - 다른 타입 입력 시 ArgumentError', () {
      expect(() => converter.toJson(123), throwsArgumentError);
    });
  });
}
