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
    Map<String, dynamic> json, String languageCode) {
  if (json.isEmpty) return '';

  return json[languageCode] ?? json['en'] ?? '';
}
