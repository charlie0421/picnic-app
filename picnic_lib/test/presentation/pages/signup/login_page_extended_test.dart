import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

/// Extended tests for LoginPage production code coverage.
///
/// Tests additional production code paths not covered in the main test.
void main() {
  group('languageMap detailed checks', () {
    test('has 12 entries', () {
      expect(languageMap.length, 12);
    });

    test('contains all 12 expected language codes', () {
      expect(languageMap.containsKey('ko'), isTrue);
      expect(languageMap.containsKey('en'), isTrue);
      expect(languageMap.containsKey('es'), isTrue);
      expect(languageMap.containsKey('ja'), isTrue);
      expect(languageMap.containsKey('zh_CN'), isTrue);
      expect(languageMap.containsKey('zh_TW'), isTrue);
      expect(languageMap.containsKey('id'), isTrue);
      expect(languageMap.containsKey('bn_BD'), isTrue);
      expect(languageMap.containsKey('fil'), isTrue);
      expect(languageMap.containsKey('th'), isTrue);
      expect(languageMap.containsKey('vi'), isTrue);
      expect(languageMap.containsKey('my'), isTrue);
    });

    test('Spanish label is correct', () {
      expect(languageMap['es'], equals('Espa\u00f1ol'));
    });

    test('Chinese Simplified label is correct', () {
      expect(languageMap['zh_CN'], equals('简体中文'));
    });

    test('Chinese Traditional label is correct', () {
      expect(languageMap['zh_TW'], equals('繁體中文'));
    });

    test('Indonesian label is correct', () {
      expect(languageMap['id'], equals('Bahasa Indonesia'));
    });

    test('Bengali label is correct', () {
      expect(languageMap['bn_BD'], equals('বাংলা'));
    });

    test('Filipino label is correct', () {
      expect(languageMap['fil'], equals('Filipino'));
    });

    test('Thai label is correct', () {
      expect(languageMap['th'], equals('ไทย'));
    });

    test('Vietnamese label is correct', () {
      expect(languageMap['vi'], equals('Tiếng Việt'));
    });

    test('Myanmar label is correct', () {
      expect(languageMap['my'], equals('မြန်မာ'));
    });
  });

  group('PicnicAuthExceptions factory methods', () {
    test('canceled exception code is "canceled"', () {
      final ex = PicnicAuthExceptions.canceled();
      expect(ex.code, 'canceled');
    });

    test('network exception code is "network_error"', () {
      final ex = PicnicAuthExceptions.network();
      expect(ex.code, 'network_error');
    });

    test('storageError exception code is "storage_error"', () {
      final ex = PicnicAuthExceptions.storageError();
      expect(ex.code, 'storage_error');
    });

    test('invalidToken exception code is "invalid_token"', () {
      final ex = PicnicAuthExceptions.invalidToken();
      expect(ex.code, 'invalid_token');
    });

    test('unsupportedProvider includes provider name in message', () {
      final ex = PicnicAuthExceptions.unsupportedProvider('twitter');
      expect(ex.message, contains('twitter'));
    });

    test('unknown exception toString includes code', () {
      final ex = PicnicAuthExceptions.unknown();
      expect(ex.toString(), contains('unknown'));
    });
  });

  group('Setting model detailed tests', () {
    test('default Setting has expected values', () {
      const setting = Setting();
      expect(setting.themeMode, ThemeMode.system);
      expect(setting.language, 'ko');
      expect(setting.postAnonymousMode, isFalse);
      expect(setting.area, 'all');
    });

    test('Setting copyWith language', () {
      const setting = Setting();
      final updated = setting.copyWith(language: 'en');
      expect(updated.language, 'en');
      expect(updated.themeMode, ThemeMode.system);
    });

    test('Setting copyWith themeMode', () {
      const setting = Setting();
      final updated = setting.copyWith(themeMode: ThemeMode.dark);
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.language, 'ko');
    });

    test('Setting copyWith all fields', () {
      const setting = Setting();
      final updated = setting.copyWith(
        language: 'ja',
        themeMode: ThemeMode.light,
        postAnonymousMode: true,
        area: 'tokyo',
      );
      expect(updated.language, 'ja');
      expect(updated.themeMode, ThemeMode.light);
      expect(updated.postAnonymousMode, isTrue);
      expect(updated.area, 'tokyo');
    });

    test('Setting supportedLanguages contains common languages', () {
      final languages = Setting.supportedLanguages;
      expect(languages, contains('ko'));
      expect(languages, contains('en'));
      expect(languages, contains('ja'));
    });

    test('Setting supportedLanguages does not contain bare zh or bn', () {
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

    test('defaults to system for unknown strings', () {
      expect(parseThemeMode(''), ThemeMode.system);
      expect(parseThemeMode('auto'), ThemeMode.system);
      expect(parseThemeMode('DARK'), ThemeMode.system);
    });
  });

  group('parseLocale from production code', () {
    test('parses simple language codes', () {
      expect(parseLocale('en').languageCode, 'en');
      expect(parseLocale('ko').languageCode, 'ko');
      expect(parseLocale('ja').languageCode, 'ja');
    });

    test('parses compound locale codes', () {
      final zhCN = parseLocale('zh_CN');
      expect(zhCN.languageCode, 'zh');
      expect(zhCN.countryCode, 'CN');

      final zhTW = parseLocale('zh_TW');
      expect(zhTW.languageCode, 'zh');
      expect(zhTW.countryCode, 'TW');

      final bnBD = parseLocale('bn_BD');
      expect(bnBD.languageCode, 'bn');
      expect(bnBD.countryCode, 'BD');
    });
  });

  group('Platform utility functions from production code', () {
    test('isIOS returns false in test', () {
      expect(ui.isIOS(), isFalse);
    });

    test('isAndroid returns false in test', () {
      expect(ui.isAndroid(), isFalse);
    });

    test('isMobile returns false in test', () {
      expect(ui.isMobile(), isFalse);
    });

    test('isMacOS returns a boolean', () {
      expect(ui.isMacOS(), isA<bool>());
    });

    test('isWindows returns a boolean', () {
      expect(ui.isWindows(), isA<bool>());
    });

    test('isLinux returns a boolean', () {
      expect(ui.isLinux(), isA<bool>());
    });

    test('isDesktop returns a boolean', () {
      expect(ui.isDesktop(), isA<bool>());
    });
  });

  group('LoginPage class', () {
    test('routeName is /login', () {
      expect(LoginPage.routeName, '/login');
    });

    test('can be const-constructed', () {
      const page = LoginPage();
      expect(page, isA<LoginPage>());
    });
  });

  group('LastProvider class', () {
    test('can be const-constructed', () {
      const widget = LastProvider();
      expect(widget, isA<StatelessWidget>());
    });
  });

  group('Constants: webDesignSize', () {
    test('webDesignSize dimensions are correct', () {
      expect(webDesignSize.width, 600);
      expect(webDesignSize.height, 800);
    });
  });

  group('countryMap from production code', () {
    test('countryMap has same size as languageMap', () {
      expect(countryMap.length, languageMap.length);
    });

    test('Korean maps to KR', () {
      expect(countryMap['ko'], 'KR');
    });

    test('English maps to US', () {
      expect(countryMap['en'], 'US');
    });

    test('Japanese maps to JP', () {
      expect(countryMap['ja'], 'JP');
    });
  });

  group('NavBarConstants from production code', () {
    test('bottomNavHeight is 52', () {
      expect(NavBarConstants.bottomNavHeight, 52.0);
    });

    test('bottomNavOuterMargin is 16', () {
      expect(NavBarConstants.bottomNavOuterMargin, 16.0);
    });
  });
}
