import 'package:flutter/material.dart';
import 'package:picnic_lib/services/locale_service.dart';

/// JSON에서 현재 로케일에 맞는 텍스트 가져오기
String getLocaleTextFromJson(Map<String, dynamic> json, BuildContext context) {
  if (json.isEmpty) return '';

  final locale = Localizations.localeOf(context).languageCode;
  // LocaleService도 함께 업데이트
  LocaleService.instance.updateLanguageCode(locale);
  return json[locale] ?? json['en'] ?? '';
}

/// JSON에서 특정 로케일에 맞는 텍스트 가져오기
String getLocaleTextFromJsonWithLocale(
  Map<String, dynamic> json,
  String languageCode,
) {
  if (json.isEmpty) return '';

  return json[languageCode] ?? json['en'] ?? '';
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
