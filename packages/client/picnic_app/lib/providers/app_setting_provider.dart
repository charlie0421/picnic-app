import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_setting_provider.freezed.dart';
part 'app_setting_provider.g.dart';

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
    logger.d('로드된 설정 (loadSettings): ${loadedSetting.toString()}');
    state = loadedSetting;
    logger.d('업데이트된 상태 (loadSettings): ${state.toString()}');
  }

  setThemeMode(String modeStr) {
    state = state.copyWith(themeMode: parseThemeMode(modeStr));
    globalStorage.saveData('themeMode', modeStr);
  }

  setLocale(Locale locale) {
    Intl.defaultLocale = locale.languageCode;
    globalStorage.saveData(
        'locale', '${locale.languageCode}_${locale.countryCode}');
    state = state.copyWith(locale: locale);
  }

  void setPostAnonymousMode(bool postAnonymousMode) {
    logger.d('setPostAnonymousMode 호출: $postAnonymousMode');
    globalStorage.saveData('postAnonymousMode', postAnonymousMode.toString());
    state = state.copyWith(postAnonymousMode: postAnonymousMode);
    logger.d('업데이트된 상태 (setPostAnonymousMode): ${state.toString()}');
  }
}

@freezed
class Setting with _$Setting {
  const Setting._();

  const factory Setting({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(Locale("ko", "KR")) Locale locale,
    @Default(false) bool postAnonymousMode,
  }) = _Setting;

  Future<Setting> load() async {
    var themeModeStr = await globalStorage.loadData('themeMode', 'system');
    var localeStr = await globalStorage.loadData('locale', 'ko_KR');
    var postAnonymousModeStr =
        await globalStorage.loadData('postAnonymousMode', 'false');

    logger.d(
        '로드된 설정: themeMode=$themeModeStr, locale=$localeStr, postAnonymousMode=$postAnonymousModeStr');
    return copyWith(
        themeMode: parseThemeMode(themeModeStr!),
        locale: parseLocale(localeStr!),
        postAnonymousMode: postAnonymousModeStr == 'true');
  }
}

Locale parseLocale(String localeStr) {
  final parts = localeStr.split('_');
  return Locale(parts[0], parts[1]);
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
