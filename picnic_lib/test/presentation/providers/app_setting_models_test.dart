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

    test('copyWith updates single field', () {
      const setting = Setting();
      final updated = setting.copyWith(language: 'en');
      expect(updated.language, 'en');
      expect(updated.themeMode, ThemeMode.system);
      expect(updated.area, 'all');
    });

    test('copyWith updates multiple fields', () {
      const setting = Setting();
      final updated = setting.copyWith(
        themeMode: ThemeMode.dark,
        language: 'ja',
        area: 'kr',
        postAnonymousMode: true,
      );
      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.language, 'ja');
      expect(updated.area, 'kr');
      expect(updated.postAnonymousMode, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      const setting = Setting(
        themeMode: ThemeMode.light,
        language: 'en',
        area: 'us',
        postAnonymousMode: true,
      );
      final updated = setting.copyWith(area: 'kr');
      expect(updated.themeMode, ThemeMode.light);
      expect(updated.language, 'en');
      expect(updated.postAnonymousMode, isTrue);
    });

    test('supportedLanguages returns non-empty list', () {
      final languages = Setting.supportedLanguages;
      expect(languages, isNotEmpty);
      expect(languages, contains('ko'));
      expect(languages, contains('en'));
      // zh and bn should be excluded (replaced by zh_CN, bn_BD)
      expect(languages.where((l) => l == 'zh'), isEmpty);
      expect(languages.where((l) => l == 'bn'), isEmpty);
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

    test('unknown defaults to ThemeMode.system', () {
      expect(parseThemeMode('invalid'), ThemeMode.system);
      expect(parseThemeMode(''), ThemeMode.system);
    });
  });
}
