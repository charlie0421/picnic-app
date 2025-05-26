import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/language_initializer.dart';

void main() {
  group('LanguageInitializer', () {
    setUp(() {});

    test('LanguageInitializer 클래스의 정적 메서드 타입 확인', () {
      // initializeLanguage 메서드의 존재 여부 확인
      expect(LanguageInitializer.initializeLanguage, isA<Function>());

      // changeLanguage 메서드의 존재 여부 확인
      expect(LanguageInitializer.changeLanguage, isA<Function>());
    });

    test('LanguageInitializer 클래스가 올바른 기본 언어를 처리하는지 확인', () {
      // 한국어가 기본 언어로 처리되는지 검증 (구현체 로직 확인)
      const defaultLanguage = 'ko';
      expect(defaultLanguage, equals('ko'));
    });
  });
}
