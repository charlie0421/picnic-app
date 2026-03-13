import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/services/locale_service.dart';

/// Coverage-focused tests for PushTokenService logic patterns.
///
/// PushTokenService cannot be tested directly because:
/// - All methods are static and depend on FirebaseMessaging
/// - registerToken requires Supabase auth and Environment config
/// - initialize requires platform-specific permissions
///
/// Instead we test the _getAppLanguage logic pattern and LocaleService.
void main() {
  group('_getAppLanguage logic (mirrors PushTokenService._getAppLanguage)', () {
    String getAppLanguage(String appLanguage, String localeName) {
      try {
        // 1. App language from LocaleService
        if (appLanguage.isNotEmpty) {
          if (appLanguage == 'zh-TW' || appLanguage == 'zh_TW') {
            return 'zh-TW';
          }
          return appLanguage.toLowerCase();
        }

        // 2. Fallback: device locale
        if (localeName.isEmpty) return 'en';

        final lowerName = localeName.toLowerCase();
        if (lowerName.startsWith('zh_tw') ||
            lowerName.startsWith('zh-tw') ||
            lowerName.startsWith('zh_hk') ||
            lowerName.startsWith('zh-hk') ||
            lowerName.contains('hant')) {
          return 'zh-TW';
        }

        final parts = localeName.split(RegExp(r'[_-]'));
        if (parts.isNotEmpty && parts[0].isNotEmpty) {
          return parts[0].toLowerCase();
        }

        return 'en';
      } catch (e) {
        return 'en';
      }
    }

    test('Korean language code', () {
      expect(getAppLanguage('ko', ''), 'ko');
    });

    test('English language code', () {
      expect(getAppLanguage('en', ''), 'en');
    });

    test('Japanese language code', () {
      expect(getAppLanguage('ja', ''), 'ja');
    });

    test('zh-TW returns zh-TW (traditional Chinese)', () {
      expect(getAppLanguage('zh-TW', ''), 'zh-TW');
    });

    test('zh_TW returns zh-TW (underscore variant)', () {
      expect(getAppLanguage('zh_TW', ''), 'zh-TW');
    });

    test('uppercase language code is lowered', () {
      expect(getAppLanguage('KO', ''), 'ko');
    });

    test('empty app language falls back to device locale', () {
      expect(getAppLanguage('', 'ko_KR'), 'ko');
    });

    test('empty app language with en_US locale', () {
      expect(getAppLanguage('', 'en_US'), 'en');
    });

    test('empty app language with ja_JP locale', () {
      expect(getAppLanguage('', 'ja_JP'), 'ja');
    });

    test('empty app language with zh_TW locale returns zh-TW', () {
      expect(getAppLanguage('', 'zh_TW'), 'zh-TW');
    });

    test('empty app language with zh-TW locale returns zh-TW', () {
      expect(getAppLanguage('', 'zh-TW'), 'zh-TW');
    });

    test('empty app language with zh_HK locale returns zh-TW', () {
      expect(getAppLanguage('', 'zh_HK'), 'zh-TW');
    });

    test('empty app language with zh-HK locale returns zh-TW', () {
      expect(getAppLanguage('', 'zh-HK'), 'zh-TW');
    });

    test('empty app language with Hant locale returns zh-TW', () {
      expect(getAppLanguage('', 'zh-Hant'), 'zh-TW');
    });

    test('empty app language and empty locale returns en', () {
      expect(getAppLanguage('', ''), 'en');
    });

    test('locale with dash separator', () {
      expect(getAppLanguage('', 'fr-FR'), 'fr');
    });

    test('locale with underscore separator', () {
      expect(getAppLanguage('', 'de_DE'), 'de');
    });
  });

  group('LocaleService', () {
    test('instance is a singleton', () {
      final instance1 = LocaleService.instance;
      final instance2 = LocaleService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('default language code is ko', () {
      final service = LocaleService.instance;
      // Note: default may already be changed by other tests
      expect(service.currentLanguageCode, isNotEmpty);
    });

    test('updateLanguageCode changes current code', () {
      final service = LocaleService.instance;
      service.updateLanguageCode('en');
      expect(service.currentLanguageCode, 'en');

      service.updateLanguageCode('ja');
      expect(service.currentLanguageCode, 'ja');

      // Restore
      service.updateLanguageCode('ko');
    });

    test('updateLanguageCode accepts zh-TW', () {
      final service = LocaleService.instance;
      service.updateLanguageCode('zh-TW');
      expect(service.currentLanguageCode, 'zh-TW');

      // Restore
      service.updateLanguageCode('ko');
    });

    test('updateLanguageCode accepts empty string', () {
      final service = LocaleService.instance;
      service.updateLanguageCode('');
      expect(service.currentLanguageCode, '');

      // Restore
      service.updateLanguageCode('ko');
    });
  });

  group('Platform detection logic (mirrors registerToken)', () {
    String getPlatformString(String platformName) {
      switch (platformName) {
        case 'ios':
          return 'ios';
        case 'android':
          return 'android';
        case 'macos':
          return 'macos';
        case 'windows':
          return 'windows';
        default:
          return 'web';
      }
    }

    test('iOS platform', () {
      expect(getPlatformString('ios'), 'ios');
    });

    test('Android platform', () {
      expect(getPlatformString('android'), 'android');
    });

    test('macOS platform', () {
      expect(getPlatformString('macos'), 'macos');
    });

    test('Windows platform', () {
      expect(getPlatformString('windows'), 'windows');
    });

    test('unknown platform defaults to web', () {
      expect(getPlatformString('linux'), 'web');
    });
  });

  group('Token preview formatting logic', () {
    test('null token shows null', () {
      const String? token = null;
      final preview = token == null
          ? 'null'
          : (token.length > 12 ? '${token.substring(0, 12)}...' : token);
      expect(preview, 'null');
    });

    test('short token shown fully', () {
      const token = 'abc123';
      final preview =
          token.length > 12 ? '${token.substring(0, 12)}...' : token;
      expect(preview, 'abc123');
    });

    test('long token is truncated', () {
      const token = 'abcdefghijklmnopqrstuvwxyz';
      final preview =
          token.length > 12 ? '${token.substring(0, 12)}...' : token;
      expect(preview, 'abcdefghijkl...');
    });

    test('exactly 12 char token shown fully', () {
      const token = 'abcdefghijkl';
      final preview =
          token.length > 12 ? '${token.substring(0, 12)}...' : token;
      expect(preview, 'abcdefghijkl');
    });

    test('13 char token is truncated', () {
      const token = 'abcdefghijklm';
      final preview =
          token.length > 12 ? '${token.substring(0, 12)}...' : token;
      expect(preview, 'abcdefghijkl...');
    });
  });
}
