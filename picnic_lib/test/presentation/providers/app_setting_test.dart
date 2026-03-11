import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

void main() {
  group('Setting', () {
    test('default values', () {
      const setting = Setting();
      expect(setting.themeMode, ThemeMode.system);
      expect(setting.postAnonymousMode, isFalse);
      expect(setting.language, 'ko');
      expect(setting.area, 'all');
    });

    test('copyWith all fields', () {
      const setting = Setting();
      final updated = setting.copyWith(
        themeMode: ThemeMode.dark,
        postAnonymousMode: true,
        language: 'en',
        area: 'kpop',
      );
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.postAnonymousMode, isTrue);
      expect(updated.language, 'en');
      expect(updated.area, 'kpop');
    });

    test('copyWith preserves unchanged values', () {
      const setting = Setting(language: 'ja', area: 'musical');
      final updated = setting.copyWith(postAnonymousMode: true);
      expect(updated.language, 'ja');
      expect(updated.area, 'musical');
      expect(updated.postAnonymousMode, isTrue);
      expect(updated.themeMode, ThemeMode.system);
    });

    test('supportedLanguages is non-empty', () {
      final languages = Setting.supportedLanguages;
      expect(languages, isNotEmpty);
      expect(languages, contains('ko'));
      expect(languages, contains('en'));
    });

    test('supportedLanguages excludes bare zh and bn', () {
      final languages = Setting.supportedLanguages;
      expect(languages, isNot(contains('zh')));
      expect(languages, isNot(contains('bn')));
    });

    test('supportedLanguages includes zh_CN and zh_TW', () {
      final languages = Setting.supportedLanguages;
      expect(languages, contains('zh_CN'));
      expect(languages, contains('zh_TW'));
    });
  });

  group('parseThemeMode', () {
    test('light', () {
      expect(parseThemeMode('light'), ThemeMode.light);
    });

    test('dark', () {
      expect(parseThemeMode('dark'), ThemeMode.dark);
    });

    test('system', () {
      expect(parseThemeMode('system'), ThemeMode.system);
    });

    test('unknown defaults to system', () {
      expect(parseThemeMode('unknown'), ThemeMode.system);
      expect(parseThemeMode(''), ThemeMode.system);
    });
  });
}
