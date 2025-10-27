import 'package:flutter/material.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/logger.dart';

final voteMainColor = AppColors.secondary500;
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
};

const Size webDesignSize = Size(600, 800);
