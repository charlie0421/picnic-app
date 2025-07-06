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

  void setThemeMode(String modeStr) {
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

  void setArea(String area) {
    globalStorage.saveData('area', area);
    state = state.copyWith(area: area);
  }
}

@freezed
class Setting with _$Setting {
  const Setting._();

  const factory Setting({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(false) bool postAnonymousMode,
    @Default('ko') String language,
    @Default('all') String area,
  }) = _Setting;

  /// 지원되는 언어 목록
  static const List<String> supportedLanguages = [
    'ko', // 한국어
    'en', // 영어
    'ja', // 일본어
    'zh', // 중국어
    'id', // 인도네시아어
  ];

  Future<Setting> load() async {
    final language = await globalStorage.loadData('language', 'ko');
    final area = await globalStorage.loadData('area', 'all');

    // 언어 유효성 검사: 빈 값이거나 지원되지 않는 언어일 경우 'ko'로 설정
    final fixedLanguage = (language == null ||
            language.isEmpty ||
            !supportedLanguages.contains(language))
        ? 'ko'
        : language;
    final fixedArea = area == null || area.isEmpty ? 'all' : area;

    if (fixedLanguage != language) {
      logger.i(
          '언어 설정 수정: $language → $fixedLanguage (지원되는 언어: ${supportedLanguages.join(', ')})');
      await globalStorage.debugSaveLanguage(fixedLanguage);
    }

    return Setting(
      language: fixedLanguage,
      area: fixedArea,
    );
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
