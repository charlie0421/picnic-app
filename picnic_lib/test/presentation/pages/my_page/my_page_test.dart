import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

/// Tests for MyPage production code.
///
/// Widget rendering is blocked by platform dependencies (RouteAwareStateMixin,
/// google_mobile_ads, flutter_phoenix, cached_network_image).
/// We test all importable production code: widget constructor, constants,
/// data models, and utility functions.
void main() {
  group('MyPage widget', () {
    test('can be const-constructed', () {
      const page = MyPage();
      expect(page, isA<MyPage>());
    });

    test('has correct pageName', () {
      const page = MyPage();
      expect(page.pageName, equals('page_title_mypage'));
    });

    test('with key can be constructed', () {
      const page = MyPage(key: ValueKey('mypage'));
      expect(page.key, equals(const ValueKey('mypage')));
    });
  });

  group('languageMap from production code', () {
    test('contains expected languages', () {
      expect(languageMap.containsKey('ko'), isTrue);
      expect(languageMap.containsKey('en'), isTrue);
      expect(languageMap.containsKey('ja'), isTrue);
      expect(languageMap.containsKey('zh_CN'), isTrue);
      expect(languageMap.containsKey('zh_TW'), isTrue);
      expect(languageMap.containsKey('es'), isTrue);
      expect(languageMap.containsKey('id'), isTrue);
      expect(languageMap.containsKey('th'), isTrue);
      expect(languageMap.containsKey('vi'), isTrue);
      expect(languageMap.containsKey('fil'), isTrue);
      expect(languageMap.containsKey('my'), isTrue);
      expect(languageMap.containsKey('bn_BD'), isTrue);
    });

    test('has 12 entries', () {
      expect(languageMap.length, 12);
    });

    test('Korean is first entry', () {
      expect(languageMap.keys.first, 'ko');
    });

    test('all entries have non-empty labels', () {
      for (final entry in languageMap.entries) {
        expect(entry.key.isNotEmpty, isTrue);
        expect(entry.value.isNotEmpty, isTrue);
      }
    });

    test('language display lookup works', () {
      expect(languageMap['ko'], equals('한국어'));
      expect(languageMap['en'], equals('English'));
      expect(languageMap['ja'], equals('日本語'));
    });

    test('falls back to key for unknown language', () {
      const currentLanguage = 'xx';
      final displayLabel = languageMap[currentLanguage] ?? currentLanguage;
      expect(displayLabel, equals('xx'));
    });
  });

  group('countryMap from production code', () {
    test('all languageMap keys are in countryMap', () {
      for (final key in languageMap.keys) {
        expect(countryMap.containsKey(key), isTrue,
            reason: 'countryMap should contain "$key"');
      }
    });

    test('country codes are valid 2-letter uppercase ISO codes', () {
      for (final entry in countryMap.entries) {
        expect(entry.value.length, equals(2),
            reason: 'Country code for "${entry.key}" should be 2 letters');
        expect(entry.value, equals(entry.value.toUpperCase()),
            reason: 'Country code for "${entry.key}" should be uppercase');
      }
    });

    test('has 12 entries matching languageMap', () {
      expect(countryMap.length, equals(12));
    });
  });

  group('parseLocale from production code', () {
    test('parses simple language code', () {
      final locale = parseLocale('ko');
      expect(locale.languageCode, equals('ko'));
      expect(locale.countryCode, isNull);
    });

    test('parses language with country code', () {
      final locale = parseLocale('zh_CN');
      expect(locale.languageCode, equals('zh'));
      expect(locale.countryCode, equals('CN'));
    });

    test('parses zh_TW correctly', () {
      final locale = parseLocale('zh_TW');
      expect(locale.languageCode, equals('zh'));
      expect(locale.countryCode, equals('TW'));
    });

    test('parses bn_BD correctly', () {
      final locale = parseLocale('bn_BD');
      expect(locale.languageCode, equals('bn'));
      expect(locale.countryCode, equals('BD'));
    });

    test('parses English code', () {
      final locale = parseLocale('en');
      expect(locale.languageCode, equals('en'));
    });

    test('parses Japanese code', () {
      final locale = parseLocale('ja');
      expect(locale.languageCode, equals('ja'));
    });

    test('all languageMap keys produce valid locales', () {
      for (final code in languageMap.keys) {
        final locale = parseLocale(code);
        expect(locale.languageCode.isNotEmpty, isTrue,
            reason: 'parseLocale("$code") should produce valid locale');
      }
    });
  });

  group('Setting model from production code', () {
    test('default Setting has expected values', () {
      const setting = Setting();
      expect(setting.themeMode, ThemeMode.system);
      expect(setting.language, 'ko');
      expect(setting.postAnonymousMode, isFalse);
      expect(setting.area, 'all');
    });

    test('copyWith language', () {
      const setting = Setting();
      final updated = setting.copyWith(language: 'en');
      expect(updated.language, 'en');
      expect(updated.themeMode, ThemeMode.system);
    });

    test('copyWith themeMode', () {
      const setting = Setting();
      final updated = setting.copyWith(themeMode: ThemeMode.dark);
      expect(updated.themeMode, ThemeMode.dark);
    });

    test('copyWith area', () {
      const setting = Setting();
      final updated = setting.copyWith(area: 'tokyo');
      expect(updated.area, 'tokyo');
    });

    test('supportedLanguages returns non-empty list', () {
      final languages = Setting.supportedLanguages;
      expect(languages.isNotEmpty, isTrue);
      expect(languages, contains('ko'));
    });

    test('supportedLanguages excludes bare zh and bn', () {
      final languages = Setting.supportedLanguages;
      expect(languages.contains('zh'), isFalse);
      expect(languages.contains('bn'), isFalse);
    });
  });

  group('parseThemeMode from production code', () {
    test('parses all valid modes', () {
      expect(parseThemeMode('light'), ThemeMode.light);
      expect(parseThemeMode('dark'), ThemeMode.dark);
      expect(parseThemeMode('system'), ThemeMode.system);
    });

    test('unknown defaults to system', () {
      expect(parseThemeMode(''), ThemeMode.system);
      expect(parseThemeMode('auto'), ThemeMode.system);
    });
  });

  group('PicnicAuthExceptions from production code', () {
    test('canceled()', () {
      final ex = PicnicAuthExceptions.canceled();
      expect(ex.code, 'canceled');
    });

    test('network()', () {
      final ex = PicnicAuthExceptions.network();
      expect(ex.code, 'network_error');
    });

    test('storageError()', () {
      final ex = PicnicAuthExceptions.storageError();
      expect(ex.code, 'storage_error');
    });

    test('unknown()', () {
      final ex = PicnicAuthExceptions.unknown();
      expect(ex.code, 'unknown');
    });
  });

  group('Constants from production code', () {
    test('Constants.webWidth', () {
      expect(Constants.webWidth, 375);
    });

    test('Constants.webHeight', () {
      expect(Constants.webHeight, 812);
    });

    test('NavBarConstants.bottomNavHeight', () {
      expect(NavBarConstants.bottomNavHeight, 52.0);
    });

    test('NavBarConstants.bottomNavOuterMargin', () {
      expect(NavBarConstants.bottomNavOuterMargin, 16.0);
    });

    test('webDesignSize', () {
      expect(webDesignSize, const Size(600, 800));
    });
  });
}
