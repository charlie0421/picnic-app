import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

class _FakeLocalStorage implements LocalStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> saveData(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> loadData(String key, dynamic defaultValue) async {
    return _store[key] ?? defaultValue?.toString();
  }

  @override
  Future<void> removeData(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clearStorage() async {
    _store.clear();
  }

  String? operator [](String key) => _store[key];
}

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

  group('Setting.load()', () {
    late _FakeLocalStorage fakeStorage;
    late LocalStorage originalStorage;

    setUp(() {
      fakeStorage = _FakeLocalStorage();
      originalStorage = globalStorage;
      globalStorage = fakeStorage;
    });

    tearDown(() {
      globalStorage = originalStorage;
    });

    test('loads default values when storage is empty', () async {
      final setting = await const Setting().load();
      expect(setting.language, 'ko');
      expect(setting.area, 'all');
    });

    test('loads saved language and area', () async {
      await fakeStorage.saveData('language', 'en');
      await fakeStorage.saveData('area', 'kpop');
      final setting = await const Setting().load();
      expect(setting.language, 'en');
      expect(setting.area, 'kpop');
    });

    test('migrates zh to zh_CN', () async {
      await fakeStorage.saveData('language', 'zh');
      final setting = await const Setting().load();
      expect(setting.language, 'zh_CN');
    });

    test('migrates bn to bn_BD', () async {
      await fakeStorage.saveData('language', 'bn');
      final setting = await const Setting().load();
      expect(setting.language, 'bn_BD');
    });

    test('falls back to ko for unsupported language', () async {
      await fakeStorage.saveData('language', 'xyz_unsupported');
      final setting = await const Setting().load();
      expect(setting.language, 'ko');
    });

    test('falls back to ko for empty language', () async {
      await fakeStorage.saveData('language', '');
      final setting = await const Setting().load();
      expect(setting.language, 'ko');
    });

    test('falls back to all for empty area', () async {
      await fakeStorage.saveData('area', '');
      final setting = await const Setting().load();
      expect(setting.area, 'all');
    });

    test('saves corrected language back to storage', () async {
      await fakeStorage.saveData('language', 'xyz_unsupported');
      await const Setting().load();
      // After load, the corrected language should be saved back
      expect(fakeStorage['language'], 'ko');
    });

    test('loads ja language correctly', () async {
      await fakeStorage.saveData('language', 'ja');
      final setting = await const Setting().load();
      expect(setting.language, 'ja');
    });

    test('loads zh_TW correctly', () async {
      await fakeStorage.saveData('language', 'zh_TW');
      final setting = await const Setting().load();
      expect(setting.language, 'zh_TW');
    });
  });

  group('LocalStorageLanguageExtension', () {
    late _FakeLocalStorage fakeStorage;
    late LocalStorage originalStorage;

    setUp(() {
      fakeStorage = _FakeLocalStorage();
      originalStorage = globalStorage;
      globalStorage = fakeStorage;
    });

    tearDown(() {
      globalStorage = originalStorage;
    });

    test('debugSaveLanguage saves and can retrieve language', () async {
      await fakeStorage.debugSaveLanguage('en');
      expect(fakeStorage['language'], 'en');
    });

    test('debugSaveLanguage overwrites previous value', () async {
      await fakeStorage.debugSaveLanguage('ko');
      await fakeStorage.debugSaveLanguage('ja');
      expect(fakeStorage['language'], 'ja');
    });
  });

  group('AppSetting provider', () {
    late _FakeLocalStorage fakeStorage;
    late LocalStorage originalStorage;
    late ProviderContainer container;

    setUp(() {
      fakeStorage = _FakeLocalStorage();
      originalStorage = globalStorage;
      globalStorage = fakeStorage;
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      globalStorage = originalStorage;
    });

    test('initial build returns default Setting', () {
      final state = container.read(appSettingProvider);
      expect(state.themeMode, ThemeMode.system);
      expect(state.postAnonymousMode, isFalse);
      expect(state.language, 'ko');
      expect(state.area, 'all');
    });

    test('setThemeMode updates state and saves to storage', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setThemeMode('dark');

      final state = container.read(appSettingProvider);
      expect(state.themeMode, ThemeMode.dark);
      expect(fakeStorage['themeMode'], 'dark');
    });

    test('setThemeMode to light', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setThemeMode('light');

      final state = container.read(appSettingProvider);
      expect(state.themeMode, ThemeMode.light);
      expect(fakeStorage['themeMode'], 'light');
    });

    test('setThemeMode to system', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setThemeMode('system');

      final state = container.read(appSettingProvider);
      expect(state.themeMode, ThemeMode.system);
      expect(fakeStorage['themeMode'], 'system');
    });

    test('setThemeMode with unknown defaults to system', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setThemeMode('unknown_mode');

      final state = container.read(appSettingProvider);
      expect(state.themeMode, ThemeMode.system);
    });

    test('setPostAnonymousMode to true', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setPostAnonymousMode(true);

      final state = container.read(appSettingProvider);
      expect(state.postAnonymousMode, isTrue);
      expect(fakeStorage['postAnonymousMode'], 'true');
    });

    test('setPostAnonymousMode to false', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setPostAnonymousMode(true);
      notifier.setPostAnonymousMode(false);

      final state = container.read(appSettingProvider);
      expect(state.postAnonymousMode, isFalse);
      expect(fakeStorage['postAnonymousMode'], 'false');
    });

    test('setLanguage updates state and saves to storage', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setLanguage('en');

      final state = container.read(appSettingProvider);
      expect(state.language, 'en');
      expect(fakeStorage['language'], 'en');
    });

    test('setLanguage to ja', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setLanguage('ja');

      final state = container.read(appSettingProvider);
      expect(state.language, 'ja');
      expect(fakeStorage['language'], 'ja');
    });

    test('setArea updates state and saves to storage', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setArea('kpop');

      final state = container.read(appSettingProvider);
      expect(state.area, 'kpop');
      expect(fakeStorage['area'], 'kpop');
    });

    test('setArea to different values', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setArea('jpop');

      expect(container.read(appSettingProvider).area, 'jpop');

      notifier.setArea('all');
      expect(container.read(appSettingProvider).area, 'all');
    });

    test('multiple settings can be changed independently', () async {
      final notifier = container.read(appSettingProvider.notifier);
      notifier.setThemeMode('dark');
      notifier.setLanguage('en');
      notifier.setArea('kpop');
      notifier.setPostAnonymousMode(true);

      final state = container.read(appSettingProvider);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.language, 'en');
      expect(state.area, 'kpop');
      expect(state.postAnonymousMode, isTrue);
    });
  });

  group('constants parseLocale', () {
    test('parses simple locale code', () {
      final locale = parseLocale('ko');
      expect(locale.languageCode, 'ko');
    });

    test('parses locale with country code', () {
      final locale = parseLocale('zh_CN');
      expect(locale.languageCode, 'zh');
      expect(locale.countryCode, 'CN');
    });

    test('parses zh_TW', () {
      final locale = parseLocale('zh_TW');
      expect(locale.languageCode, 'zh');
      expect(locale.countryCode, 'TW');
    });

    test('parses bn_BD', () {
      final locale = parseLocale('bn_BD');
      expect(locale.languageCode, 'bn');
      expect(locale.countryCode, 'BD');
    });

    test('parses en without underscore', () {
      final locale = parseLocale('en');
      expect(locale.languageCode, 'en');
    });
  });
}
