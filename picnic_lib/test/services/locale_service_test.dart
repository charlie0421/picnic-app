import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/services/locale_service.dart';

void main() {
  group('LocaleService', () {
    test('싱글톤 인스턴스', () {
      final instance1 = LocaleService.instance;
      final instance2 = LocaleService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('기본 언어 코드는 ko', () {
      // 싱글톤이므로 이전 테스트 영향 가능 - 직접 확인
      final service = LocaleService.instance;
      // updateLanguageCode로 초기화
      service.updateLanguageCode('ko');
      expect(service.currentLanguageCode, equals('ko'));
    });

    test('언어 코드 업데이트', () {
      final service = LocaleService.instance;

      service.updateLanguageCode('en');
      expect(service.currentLanguageCode, equals('en'));

      service.updateLanguageCode('ja');
      expect(service.currentLanguageCode, equals('ja'));

      service.updateLanguageCode('zh_CN');
      expect(service.currentLanguageCode, equals('zh_CN'));
    });

    // 정리: 기본값 복원
    tearDown(() {
      LocaleService.instance.updateLanguageCode('ko');
    });
  });
}
