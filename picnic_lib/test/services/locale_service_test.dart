import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/services/locale_service.dart';

void main() {
  group('LocaleService', () {
    test('instance is singleton', () {
      final a = LocaleService.instance;
      final b = LocaleService.instance;
      expect(identical(a, b), isTrue);
    });

    test('default language code is ko', () {
      expect(LocaleService.instance.currentLanguageCode, isNotEmpty);
    });

    test('updateLanguageCode changes language', () {
      LocaleService.instance.updateLanguageCode('en');
      expect(LocaleService.instance.currentLanguageCode, 'en');
      // Reset
      LocaleService.instance.updateLanguageCode('ko');
    });

    test('updateLanguageCode to ja', () {
      LocaleService.instance.updateLanguageCode('ja');
      expect(LocaleService.instance.currentLanguageCode, 'ja');
      LocaleService.instance.updateLanguageCode('ko');
    });
  });
}
