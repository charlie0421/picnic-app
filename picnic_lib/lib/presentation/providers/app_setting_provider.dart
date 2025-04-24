import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/app_setting_provider.freezed.dart';
part '../../generated/providers/app_setting_provider.g.dart';

@riverpod
class AppSetting extends _$AppSetting {
  Setting setting = const Setting(); // 초기 값이 필요하다면 임시로 할당

  AppSetting() {
    loadSettings();
  }

  @override
  Setting build() {
    return setting;
  }

  Future<void> loadSettings() async {
    final loadedSetting = await const Setting().load();
    state = loadedSetting;
  }

  setThemeMode(String modeStr) {
    state = state.copyWith(themeMode: parseThemeMode(modeStr));
    globalStorage.saveData('themeMode', modeStr);
  }

  void setPostAnonymousMode(bool postAnonymousMode) {
    globalStorage.saveData('postAnonymousMode', postAnonymousMode.toString());
    state = state.copyWith(postAnonymousMode: postAnonymousMode);
  }

  void setLanguage(String language) {
    globalStorage.saveData('language', language);
    state = state.copyWith(language: language);
  }
}

@freezed
class Setting with _$Setting {
  const Setting._();

  const factory Setting({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(false) bool postAnonymousMode,
    @Default('en') String language,
  }) = _Setting;

  Future<Setting> load() async {
    var themeModeStr = await globalStorage.loadData('themeMode', 'system');
    var postAnonymousModeStr =
        await globalStorage.loadData('postAnonymousMode', 'false');
    var languageStr = await globalStorage.loadData('language', 'en');

    logger.i(
        'loaded config: themeMode=$themeModeStr, postAnonymousMode=$postAnonymousModeStr, language=$languageStr');

    return copyWith(
        themeMode: parseThemeMode(themeModeStr!),
        postAnonymousMode: postAnonymousModeStr == 'true',
        language: languageStr ?? 'en');
  }
}

ThemeMode parseThemeMode(String modeStr) {
  switch (modeStr) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.system;
  }
}
