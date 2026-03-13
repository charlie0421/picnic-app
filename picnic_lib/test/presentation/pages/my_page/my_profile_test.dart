import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

/// Tests for MyProfilePage production code.
///
/// Widget rendering is blocked by platform dependencies (ImagePicker,
/// ImageCropper, OverlayLoadingProgress, FlutterSecureStorage, Supabase).
/// We test all importable production code: widget constructor, data models,
/// constants, and utility functions.
void main() {
  group('MyProfilePage widget', () {
    test('can be const-constructed', () {
      const page = MyProfilePage();
      expect(page, isA<MyProfilePage>());
    });

    test('has correct pageName', () {
      const page = MyProfilePage();
      expect(page.pageName, equals('page_title_myprofile'));
    });

    test('with key can be constructed', () {
      const page = MyProfilePage(key: ValueKey('profile'));
      expect(page.key, equals(const ValueKey('profile')));
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
      expect(updated.postAnonymousMode, isFalse);
      expect(updated.area, 'all');
    });

    test('copyWith themeMode', () {
      const setting = Setting();
      final updated = setting.copyWith(themeMode: ThemeMode.dark);
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.language, 'ko');
    });

    test('copyWith postAnonymousMode', () {
      const setting = Setting();
      final updated = setting.copyWith(postAnonymousMode: true);
      expect(updated.postAnonymousMode, isTrue);
    });

    test('copyWith area', () {
      const setting = Setting();
      final updated = setting.copyWith(area: 'seoul');
      expect(updated.area, 'seoul');
    });

    test('copyWith all fields', () {
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

    test('supportedLanguages is non-empty', () {
      final languages = Setting.supportedLanguages;
      expect(languages.isNotEmpty, isTrue);
      expect(languages, contains('ko'));
      expect(languages, contains('en'));
    });

    test('supportedLanguages does not contain bare zh or bn', () {
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
      expect(parseThemeMode(''), ThemeMode.system);
      expect(parseThemeMode('auto'), ThemeMode.system);
      expect(parseThemeMode('DARK'), ThemeMode.system);
    });
  });

  group('languageMap from production code', () {
    test('contains expected languages', () {
      expect(languageMap.containsKey('ko'), isTrue);
      expect(languageMap.containsKey('en'), isTrue);
      expect(languageMap.containsKey('ja'), isTrue);
    });

    test('all entries have non-empty labels', () {
      for (final entry in languageMap.entries) {
        expect(entry.value.isNotEmpty, isTrue);
      }
    });

    test('has 12 entries', () {
      expect(languageMap.length, 12);
    });
  });

  group('countryMap from production code', () {
    test('all languageMap keys are in countryMap', () {
      for (final key in languageMap.keys) {
        expect(countryMap.containsKey(key), isTrue,
            reason: 'countryMap should contain "$key"');
      }
    });

    test('country codes are 2-letter uppercase', () {
      for (final entry in countryMap.entries) {
        expect(entry.value.length, equals(2));
        expect(entry.value, equals(entry.value.toUpperCase()));
      }
    });
  });

  group('parseLocale from production code', () {
    test('parses simple codes', () {
      expect(parseLocale('ko').languageCode, 'ko');
      expect(parseLocale('en').languageCode, 'en');
    });

    test('parses compound codes', () {
      final locale = parseLocale('zh_CN');
      expect(locale.languageCode, 'zh');
      expect(locale.countryCode, 'CN');
    });

    test('all languageMap keys produce valid locales', () {
      for (final code in languageMap.keys) {
        final locale = parseLocale(code);
        expect(locale.languageCode.isNotEmpty, isTrue);
      }
    });
  });

  group('PicnicAuthException from production code', () {
    test('stores code and message', () {
      final ex = PicnicAuthException('code', 'message');
      expect(ex.code, 'code');
      expect(ex.message, 'message');
    });

    test('toString contains code and message', () {
      final ex = PicnicAuthException('test', 'test msg');
      expect(ex.toString(), contains('test'));
      expect(ex.toString(), contains('test msg'));
    });

    test('implements Exception', () {
      expect(PicnicAuthException('c', 'm'), isA<Exception>());
    });
  });

  group('PicnicAuthExceptions factory methods', () {
    test('canceled()', () {
      final ex = PicnicAuthExceptions.canceled();
      expect(ex.code, 'canceled');
    });

    test('invalidToken()', () {
      final ex = PicnicAuthExceptions.invalidToken();
      expect(ex.code, 'invalid_token');
    });

    test('network()', () {
      final ex = PicnicAuthExceptions.network();
      expect(ex.code, 'network_error');
    });

    test('storageError()', () {
      final ex = PicnicAuthExceptions.storageError();
      expect(ex.code, 'storage_error');
    });

    test('unsupportedProvider()', () {
      final ex = PicnicAuthExceptions.unsupportedProvider('test');
      expect(ex.code, 'unsupported_provider');
      expect(ex.message, contains('test'));
    });

    test('unknown()', () {
      final ex = PicnicAuthExceptions.unknown();
      expect(ex.code, 'unknown');
    });

    test('unknown with originalError', () {
      final orig = Exception('orig');
      final ex = PicnicAuthExceptions.unknown(originalError: orig);
      expect(ex.originalError, orig);
    });

    test('deviceBanned()', () {
      final ex = PicnicAuthExceptions.deviceBanned();
      expect(ex.statusCode, 'DEVICE_BANNED');
    });
  });

  group('Constants from production code', () {
    test('webWidth', () {
      expect(Constants.webWidth, 375);
    });

    test('webHeight', () {
      expect(Constants.webHeight, 812);
    });

    test('snackBarDuration', () {
      expect(Constants.snackBarDuration, const Duration(seconds: 5));
    });

    test('webDesignSize', () {
      expect(webDesignSize, const Size(600, 800));
    });
  });

  group('NavBarConstants from production code', () {
    test('bottomNavHeight', () {
      expect(NavBarConstants.bottomNavHeight, 52.0);
    });

    test('bottomNavOuterMargin', () {
      expect(NavBarConstants.bottomNavOuterMargin, 16.0);
    });
  });
}
