import 'package:flutter/material.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/logger.dart';

final voteMainColor = AppColors.secondary500;
final goongHapMainColor = AppColors.primary500;
final picMainColor = AppColors.primary500;
final communityMainColor = AppColors.sub500;
final novelMainColor = AppColors.point500;

class Constants {
  Constants._();

  static double webWidth = 375;
  static double webHeight = 812;
  static Duration snackBarDuration = const Duration(seconds: 5);
}

/// 하단 내비게이션 관련 상수
class NavBarConstants {
  NavBarConstants._();

  /// 하단 내비게이션 바의 고정 높이
  static const double bottomNavHeight = 52.0;

  /// 하단 내비게이션 아이콘의 공통 표시 크기
  static const double bottomNavIconSize = 24.0;

  /// 내비 외곽 하단 마진 (콘텐츠 패딩 계산에도 사용)
  static const double bottomNavOuterMargin = 16.0;
}

LocalStorage globalStorage = LocalStorage();

// LocalStorage 언어 설정 관련 확장 메서드
extension LocalStorageLanguageExtension on LocalStorage {
  Future<void> debugSaveLanguage(String language) async {
    logger.i('언어 설정 저장: $language');
    await saveData('language', language);
    final savedValue = await loadData('language', null);
    logger.i('저장된 언어 확인: $savedValue');
  }
}

/// 언어 코드 문자열을 Locale로 변환 (예: 'zh_CN' -> Locale('zh','CN'))
Locale parseLocale(String code) {
  if (code.contains('_')) {
    final parts = code.split('_');
    final lang = parts[0];
    final country = parts.length > 1 ? parts[1] : '';
    if (country.isNotEmpty) {
      return Locale.fromSubtags(languageCode: lang, countryCode: country);
    }
    return Locale(lang);
  }
  return Locale(code);
}

Map<String, String> countryMap = {
  'en': 'US',
  'es': 'ES',
  'ko': 'KR',
  'ja': 'JP',
  'zh_CN': 'CN',
  'zh_TW': 'TW',
  'id': 'ID',
  'bn_BD': 'BD',
  'fil': 'PH',
  'th': 'TH',
  'vi': 'VN',
  'my': 'MM',
};

Map<String, String> languageMap = {
  'ko': '한국어',
  'en': 'English',
  'es': 'Español',
  'ja': '日本語',
  'zh_CN': '简体中文',
  'zh_TW': '繁體中文',
  'id': 'Bahasa Indonesia',
  'bn_BD': 'বাংলা',
  'fil': 'Filipino',
  'th': 'ไทย',
  'vi': 'Tiếng Việt',
  'my': 'မြန်မာ',
};

/// 지역 코드가 없는 언어 코드를 앱이 실제로 사용하는 지역 변형으로 정규화한다.
///
/// `AppLocalizations.supportedLocales` 는 ARB 파일에서 생성되므로 지역 없는
/// `zh` / `bn` 을 포함하지만, 앱은 이 둘을 단독으로 취급하지 않는다
/// (`languageMap` / `countryMap` / `Setting.supportedLanguages` 모두 12개).
/// 저장된 값에 대해 [Setting.load] 가 수행하는 마이그레이션과 동일한 규칙이며,
/// 이 함수가 그 규칙의 단일 출처다.
///
/// 매핑이 없는 코드는 그대로 돌려준다.
String canonicalLanguageCode(String code) {
  switch (code) {
    case 'zh':
      return 'zh_CN';
    case 'bn':
      return 'bn_BD';
    default:
      return code;
  }
}

/// 언어 코드의 표시 이름을 반환한다. 어떤 입력에도 예외를 던지지 않는다.
///
/// [languageMap] 은 손으로 관리되는 반면 `Setting.supportedLanguages` 는
/// `AppLocalizations.supportedLocales` 에서 파생되어 자동으로 늘어난다.
/// 라벨이 없는 코드는 코드 자체를 보여주는 최후 폴백으로 처리하고,
/// 실제로 그런 코드가 생기지 않는지는 테스트로 고정한다
/// (`login_page_language_label_test.dart`).
String languageLabel(String code) =>
    languageMap[canonicalLanguageCode(code)] ?? code;

const Size webDesignSize = Size(600, 800);
