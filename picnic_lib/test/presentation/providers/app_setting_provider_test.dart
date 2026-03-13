import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

void main() {
  group('Setting', () {
    test('default values', () {
      const setting = Setting();
      expect(setting.themeMode, ThemeMode.system);
      expect(setting.postAnonymousMode, false);
      expect(setting.language, 'ko');
      expect(setting.area, 'all');
    });

    test('custom values', () {
      const setting = Setting(
        themeMode: ThemeMode.dark,
        postAnonymousMode: true,
        language: 'en',
        area: 'kr',
      );
      expect(setting.themeMode, ThemeMode.dark);
      expect(setting.postAnonymousMode, true);
      expect(setting.language, 'en');
      expect(setting.area, 'kr');
    });

    test('copyWith all fields', () {
      const original = Setting();
      final copied = original.copyWith(
        themeMode: ThemeMode.light,
        postAnonymousMode: true,
        language: 'ja',
        area: 'jp',
      );
      expect(copied.themeMode, ThemeMode.light);
      expect(copied.postAnonymousMode, true);
      expect(copied.language, 'ja');
      expect(copied.area, 'jp');
    });

    test('copyWith preserves unmodified fields', () {
      const original = Setting(
        themeMode: ThemeMode.dark,
        language: 'en',
      );
      final copied = original.copyWith(area: 'us');
      expect(copied.themeMode, ThemeMode.dark);
      expect(copied.language, 'en');
      expect(copied.postAnonymousMode, false);
      expect(copied.area, 'us');
    });

    test('copyWith with no args returns equivalent', () {
      const original = Setting(language: 'ja');
      final copied = original.copyWith();
      expect(copied.language, 'ja');
      expect(copied.themeMode, ThemeMode.system);
    });

    test('supportedLanguages is not empty', () {
      expect(Setting.supportedLanguages, isNotEmpty);
    });

    test('supportedLanguages contains ko', () {
      expect(Setting.supportedLanguages, contains('ko'));
    });

    test('supportedLanguages contains en', () {
      expect(Setting.supportedLanguages, contains('en'));
    });

    test('supportedLanguages does not contain plain zh', () {
      // zh is filtered out in favor of zh_CN/zh_TW
      expect(Setting.supportedLanguages, isNot(contains('zh')));
    });

    test('supportedLanguages does not contain plain bn', () {
      expect(Setting.supportedLanguages, isNot(contains('bn')));
    });
  });

  group('parseThemeMode', () {
    test('light returns ThemeMode.light', () {
      expect(parseThemeMode('light'), ThemeMode.light);
    });

    test('dark returns ThemeMode.dark', () {
      expect(parseThemeMode('dark'), ThemeMode.dark);
    });

    test('system returns ThemeMode.system', () {
      expect(parseThemeMode('system'), ThemeMode.system);
    });

    test('empty string returns ThemeMode.system', () {
      expect(parseThemeMode(''), ThemeMode.system);
    });

    test('unknown string returns ThemeMode.system', () {
      expect(parseThemeMode('unknown'), ThemeMode.system);
    });

    test('LIGHT (uppercase) returns ThemeMode.system (case sensitive)', () {
      expect(parseThemeMode('LIGHT'), ThemeMode.system);
    });

    test('null-like returns system', () {
      expect(parseThemeMode('null'), ThemeMode.system);
    });
  });
}
