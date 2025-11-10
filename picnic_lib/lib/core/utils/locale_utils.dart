import 'package:flutter/material.dart';
import 'package:picnic_lib/services/locale_service.dart';

/// Flutter 로케일 코드를 DB 언어 코드로 변환
/// Flutter: zh_CN, zh_TW, bn_BD → DB: zh, zh-TW, bn
String _normalizeLocaleToDbCode(Locale locale) {
  final languageCode = locale.languageCode.toLowerCase();
  final countryCode = locale.countryCode?.toUpperCase();

  // 중국어 처리: zh_CN -> zh, zh_TW -> zh-TW
  if (languageCode == 'zh') {
    if (countryCode == 'TW') {
      return 'zh-TW';
    }
    return 'zh';
  }

  // 벵골어 처리: bn_BD -> bn
  if (languageCode == 'bn') {
    return 'bn';
  }

  // 기타 언어는 languageCode 그대로 사용
  return languageCode;
}

/// Flutter 언어 코드 문자열을 DB 언어 코드로 변환
/// 예: "zh_CN" -> "zh", "zh_TW" -> "zh-TW", "bn_BD" -> "bn"
/// "zh-cn" -> "zh", "zh-tw" -> "zh-TW" (하이픈 형식도 지원)
String _normalizeLanguageCodeToDbCode(String languageCode) {
  // 언더스코어 또는 하이픈으로 분리
  final parts = languageCode.contains('_')
      ? languageCode.split('_')
      : languageCode.split('-');
  final lang = parts[0].toLowerCase();
  final country = parts.length > 1 ? parts[1].toUpperCase() : null;

  if (lang == 'zh') {
    if (country == 'TW') {
      return 'zh-TW';
    }
    return 'zh';
  }

  if (lang == 'bn') {
    return 'bn';
  }

  return lang;
}

/// JSON에서 현재 로케일에 맞는 텍스트 가져오기
String getLocaleTextFromJson(Map<String, dynamic> json, BuildContext context) {
  if (json.isEmpty) return '';

  final locale = Localizations.localeOf(context);
  final dbLanguageCode = _normalizeLocaleToDbCode(locale);
  
  // LocaleService도 함께 업데이트 (Flutter 형식 유지)
  final flutterLanguageCode = locale.countryCode != null
      ? '${locale.languageCode}_${locale.countryCode}'
      : locale.languageCode;
  LocaleService.instance.updateLanguageCode(flutterLanguageCode);
  
  // DB 언어 코드로 조회 (en fallback)
  return json[dbLanguageCode] ?? json['en'] ?? '';
}

/// JSON에서 특정 로케일에 맞는 텍스트 가져오기
String getLocaleTextFromJsonWithLocale(
  Map<String, dynamic> json,
  String languageCode,
) {
  if (json.isEmpty) return '';

  // Flutter 형식 언어 코드를 DB 형식으로 변환
  final dbLanguageCode = _normalizeLanguageCodeToDbCode(languageCode);
  
  // DB 언어 코드로 조회 (en fallback)
  return json[dbLanguageCode] ?? json['en'] ?? '';
}

/// 다국어 JSON에서 최적의 텍스트를 반환 (현재 로케일 → 폴백 체인 → 기본값)
String getBestLocaleText(
  Map<String, dynamic> json,
  BuildContext context, {
  List<String>? fallbacks,
  String defaultText = 'Artist',
}) {
  if (json.isEmpty) return defaultText;

  String title = getLocaleTextFromJson(json, context).trim();
  if (title.isNotEmpty) return title;

  const defaultFallbacks = [
    'ko',
    'en',
    'ja',
    'id',
    'th',
    'vi',
    'fil',
    'zh',
    'zh-cn',
    'zh-tw',
  ];
  final chain = fallbacks ?? defaultFallbacks;
  for (final lc in chain) {
    title = getLocaleTextFromJsonWithLocale(json, lc).trim();
    if (title.isNotEmpty) return title;
  }
  return defaultText;
}
