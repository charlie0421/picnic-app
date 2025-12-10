import 'package:flutter/material.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    // user_profiles.language 업데이트는 language_initializer.dart의 changeLanguage에서 처리
  }

  void setArea(String area) {
    globalStorage.saveData('area', area);
    state = state.copyWith(area: area);
  }
}

class Setting {
  final ThemeMode themeMode;
  final bool postAnonymousMode;
  final String language;
  final String area;

  const Setting({
    this.themeMode = ThemeMode.system,
    this.postAnonymousMode = false,
    this.language = 'ko',
    this.area = 'all',
  });

  Setting copyWith({
    ThemeMode? themeMode,
    bool? postAnonymousMode,
    String? language,
    String? area,
  }) {
    return Setting(
      themeMode: themeMode ?? this.themeMode,
      postAnonymousMode: postAnonymousMode ?? this.postAnonymousMode,
      language: language ?? this.language,
      area: area ?? this.area,
    );
  }

  /// 지원되는 언어 목록 (AppLocalizations.supportedLocales 기반, 단일 소스)
  /// zh 지역 분기(zh_CN/zh_TW)를 포함하기 위해 countryCode를 결합한 코드 사용
  static List<String> get supportedLanguages => AppLocalizations
      .supportedLocales
      .map(
        (locale) => (locale.countryCode == null || locale.countryCode!.isEmpty)
            ? locale.languageCode
            : '${locale.languageCode}_${locale.countryCode}',
      )
      .where((code) => code != 'zh' && code != 'bn')
      .toList();

  Future<Setting> load() async {
    final language = await globalStorage.loadData('language', 'ko');
    final area = await globalStorage.loadData('area', 'all');

    // 언어 유효성 검사: 빈 값이거나 지원되지 않는 언어일 경우 'ko'로 설정
    // 마이그레이션: 과거에 저장된 'zh'는 기본적으로 'zh_CN'으로 전환
    String normalizedLanguage = language ?? 'ko';
    if (normalizedLanguage == 'zh') {
      normalizedLanguage = 'zh_CN';
    }
    if (normalizedLanguage == 'bn') {
      normalizedLanguage = 'bn_BD';
    }

    final fixedLanguage =
        (normalizedLanguage.isEmpty ||
            !supportedLanguages.contains(normalizedLanguage))
        ? 'ko'
        : normalizedLanguage;
    final fixedArea = area == null || area.isEmpty ? 'all' : area;

    if (fixedLanguage != language) {
      logger.i(
        '언어 설정 수정: $language → $fixedLanguage (지원되는 언어: ${supportedLanguages.join(', ')})',
      );
      await globalStorage.debugSaveLanguage(fixedLanguage);
    }

    return Setting(language: fixedLanguage, area: fixedArea);
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
