import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/services/locale_service.dart';

void main() {
  group('getLocaleTextFromJson', () {
    test('returns text for current locale', () {
      LocaleService.instance.updateLanguageCode('ko');
      final result = getLocaleTextFromJson({'ko': '한국어', 'en': 'English'});
      expect(result, '한국어');
    });

    test('falls back to en', () {
      LocaleService.instance.updateLanguageCode('fr');
      final result = getLocaleTextFromJson({'ko': '한국어', 'en': 'English'});
      expect(result, 'English');
      LocaleService.instance.updateLanguageCode('ko');
    });

    test('returns empty for empty map', () {
      expect(getLocaleTextFromJson({}), '');
    });

    test('returns empty when no matching locale and no en', () {
      LocaleService.instance.updateLanguageCode('fr');
      final result = getLocaleTextFromJson({'ko': '한국어'});
      expect(result, '');
      LocaleService.instance.updateLanguageCode('ko');
    });
  });

  group('getLocaleTextFromJsonWithLocale', () {
    test('returns text for specified locale', () {
      final result =
          getLocaleTextFromJsonWithLocale({'ko': '한국어', 'en': 'English'}, 'ko');
      expect(result, '한국어');
    });

    test('falls back to en', () {
      final result =
          getLocaleTextFromJsonWithLocale({'ko': '한국어', 'en': 'English'}, 'ja');
      expect(result, 'English');
    });

    test('returns empty for empty map', () {
      expect(getLocaleTextFromJsonWithLocale({}, 'ko'), '');
    });
  });
}
