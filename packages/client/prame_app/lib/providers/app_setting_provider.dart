import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_setting_provider.g.dart';

@riverpod
class AppSetting extends _$AppSetting {
  Setting setting = Setting(); // 초기 값이 필요하다면 임시로 할당

  @override
  Setting build() {
    return setting;
  }

  Future<void> loadSettings() async {
    setting = await Setting.load();
    state =
        state.copyWith(themeMode: setting.themeMode, locale: setting.locale);
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
}

class Setting {
  ThemeMode themeMode = ThemeMode.system;
  Locale locale = const Locale('ko_KR');

  Setting();

  static Future<Setting> load() async {
    var themeModeStr = await globalStorage.loadData('themeMode', 'system');
    var localeStr = await globalStorage.loadData('locale', 'ko_KR');
    return Setting()
      ..themeMode = parseThemeMode(themeModeStr!)
      ..locale = parseLocale(localeStr!);
  }

  Setting copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return Setting()
      ..themeMode = themeMode ?? this.themeMode
      ..locale = locale ?? this.locale;
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
