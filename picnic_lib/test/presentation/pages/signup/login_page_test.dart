import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

/// Tests for LoginPage production code.
///
/// Widget rendering is blocked by platform channel dependencies
/// (FlutterSecureStorage, AuthService, ScreenProtector, card_swiper).
/// We test all importable production code: constants, models, utility
/// functions, and widget constructors.
void main() {
  group('LoginPage widget', () {
    test('LoginPage has correct routeName', () {
      expect(LoginPage.routeName, equals('/login'));
    });

    test('LoginPage can be constructed', () {
      const page = LoginPage();
      expect(page, isA<LoginPage>());
    });

    test('LoginPage with key can be constructed', () {
      const page = LoginPage(key: ValueKey('login'));
      expect(page, isA<LoginPage>());
      expect(page.key, equals(const ValueKey('login')));
    });
  });

  group('LastProvider widget', () {
    test('LastProvider can be constructed', () {
      const widget = LastProvider();
      expect(widget, isA<LastProvider>());
    });

    test('LastProvider with key can be constructed', () {
      const widget = LastProvider(key: ValueKey('last'));
      expect(widget, isA<LastProvider>());
      expect(widget.key, equals(const ValueKey('last')));
    });
  });

  group('languageMap constant from production code', () {
    test('contains all expected language codes', () {
      expect(languageMap.containsKey('ko'), isTrue);
      expect(languageMap.containsKey('en'), isTrue);
      expect(languageMap.containsKey('ja'), isTrue);
      expect(languageMap.containsKey('zh_CN'), isTrue);
    });

    test('has correct Korean label', () {
      expect(languageMap['ko'], equals('한국어'));
    });

    test('has correct English label', () {
      expect(languageMap['en'], equals('English'));
    });

    test('has correct Japanese label', () {
      expect(languageMap['ja'], equals('日本語'));
    });

    test('all entries have non-empty values', () {
      for (final entry in languageMap.entries) {
        expect(entry.value.isNotEmpty, isTrue,
            reason: '${entry.key} should have a non-empty value');
      }
    });

    test('entries list preserves order', () {
      final entries = languageMap.entries.toList();
      expect(entries.first.key, 'ko');
      expect(entries.length, languageMap.length);
    });
  });

  group('countryMap constant from production code', () {
    test('all languageMap keys are in countryMap', () {
      for (final key in languageMap.keys) {
        expect(countryMap.containsKey(key), isTrue,
            reason: 'countryMap should contain "$key"');
      }
    });

    test('country codes are valid 2-letter ISO codes', () {
      for (final entry in countryMap.entries) {
        expect(entry.value.length, equals(2),
            reason: 'Country code for "${entry.key}" should be 2 letters');
        expect(entry.value, equals(entry.value.toUpperCase()),
            reason: 'Country code for "${entry.key}" should be uppercase');
      }
    });
  });

  group('parseLocale from production code', () {
    test('parses simple language code', () {
      final locale = parseLocale('ko');
      expect(locale.languageCode, equals('ko'));
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

    test('all languageMap keys produce valid locales', () {
      for (final code in languageMap.keys) {
        final locale = parseLocale(code);
        expect(locale.languageCode.isNotEmpty, isTrue,
            reason: 'parseLocale("$code") should produce valid locale');
      }
    });
  });

  group('PicnicAuthException from production code', () {
    test('PicnicAuthException stores code and message', () {
      final ex = PicnicAuthException('test_code', 'test message');
      expect(ex.code, equals('test_code'));
      expect(ex.message, equals('test message'));
    });

    test('PicnicAuthException stores originalError', () {
      final original = Exception('original');
      final ex = PicnicAuthException('code', 'msg', originalError: original);
      expect(ex.originalError, equals(original));
    });

    test('PicnicAuthException toString', () {
      final ex = PicnicAuthException('canceled', 'User canceled');
      expect(ex.toString(), contains('canceled'));
      expect(ex.toString(), contains('User canceled'));
    });

    test('PicnicAuthException implements Exception', () {
      final ex = PicnicAuthException('code', 'msg');
      expect(ex, isA<Exception>());
    });
  });

  group('PicnicAuthExceptions factory methods', () {
    test('canceled() creates correct exception', () {
      final ex = PicnicAuthExceptions.canceled();
      expect(ex.code, equals('canceled'));
      expect(ex.message, isNotEmpty);
    });

    test('invalidToken() creates correct exception', () {
      final ex = PicnicAuthExceptions.invalidToken();
      expect(ex.code, equals('invalid_token'));
      expect(ex.message, isNotEmpty);
    });

    test('network() creates correct exception', () {
      final ex = PicnicAuthExceptions.network();
      expect(ex.code, equals('network_error'));
      expect(ex.message, isNotEmpty);
    });

    test('storageError() creates correct exception', () {
      final ex = PicnicAuthExceptions.storageError();
      expect(ex.code, equals('storage_error'));
      expect(ex.message, isNotEmpty);
    });

    test('unsupportedProvider() creates correct exception', () {
      final ex = PicnicAuthExceptions.unsupportedProvider('facebook');
      expect(ex.code, equals('unsupported_provider'));
      expect(ex.message, contains('facebook'));
    });

    test('unknown() creates correct exception', () {
      final ex = PicnicAuthExceptions.unknown();
      expect(ex.code, equals('unknown'));
      expect(ex.message, isNotEmpty);
    });

    test('unknown() with originalError', () {
      final original = Exception('underlying error');
      final ex = PicnicAuthExceptions.unknown(originalError: original);
      expect(ex.originalError, equals(original));
    });

    test('deviceBanned() creates AuthException', () {
      final ex = PicnicAuthExceptions.deviceBanned();
      expect(ex.statusCode, equals('DEVICE_BANNED'));
      expect(ex.message, contains('banned'));
    });
  });

  group('isIOS() from production code', () {
    test('returns false in test environment', () {
      expect(ui.isIOS(), isFalse);
    });
  });

  group('isAndroid() from production code', () {
    test('returns false in test environment', () {
      expect(ui.isAndroid(), isFalse);
    });
  });

  group('isMobile() from production code', () {
    test('returns false in test environment', () {
      expect(ui.isMobile(), isFalse);
    });
  });

  group('isDesktop() from production code', () {
    test('returns a boolean in test environment', () {
      expect(ui.isDesktop(), isA<bool>());
    });
  });

  group('Constants from production code', () {
    test('webWidth has expected value', () {
      expect(Constants.webWidth, equals(375));
    });

    test('webHeight has expected value', () {
      expect(Constants.webHeight, equals(812));
    });

    test('snackBarDuration has expected value', () {
      expect(Constants.snackBarDuration, equals(const Duration(seconds: 5)));
    });

    test('webDesignSize has expected dimensions', () {
      expect(webDesignSize.width, equals(600));
      expect(webDesignSize.height, equals(800));
    });
  });

  group('NavBarConstants from production code', () {
    test('bottomNavHeight has expected value', () {
      expect(NavBarConstants.bottomNavHeight, equals(52.0));
    });

    test('bottomNavOuterMargin has expected value', () {
      expect(NavBarConstants.bottomNavOuterMargin, equals(16.0));
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

    test('Setting copyWith postAnonymousMode', () {
      const setting = Setting();
      final updated = setting.copyWith(postAnonymousMode: true);
      expect(updated.postAnonymousMode, isTrue);
    });

    test('Setting copyWith area', () {
      const setting = Setting();
      final updated = setting.copyWith(area: 'seoul');
      expect(updated.area, 'seoul');
    });

    test('Setting supportedLanguages returns non-empty list', () {
      final languages = Setting.supportedLanguages;
      expect(languages.isNotEmpty, isTrue);
      expect(languages, contains('ko'));
      expect(languages, contains('en'));
    });

    test('Setting supportedLanguages excludes bare zh and bn', () {
      final languages = Setting.supportedLanguages;
      expect(languages.contains('zh'), isFalse);
      expect(languages.contains('bn'), isFalse);
    });
  });

  group('parseThemeMode from production code', () {
    test('parses light', () {
      expect(parseThemeMode('light'), ThemeMode.light);
    });

    test('parses dark', () {
      expect(parseThemeMode('dark'), ThemeMode.dark);
    });

    test('parses system', () {
      expect(parseThemeMode('system'), ThemeMode.system);
    });

    test('unknown defaults to system', () {
      expect(parseThemeMode('unknown'), ThemeMode.system);
    });

    test('empty string defaults to system', () {
      expect(parseThemeMode(''), ThemeMode.system);
    });
  });

  group('webDesignSize from production code', () {
    test('webDesignSize is correct', () {
      expect(webDesignSize, equals(const Size(600, 800)));
    });
  });
}
