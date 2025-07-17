// picnic_lib/lib/core/utils/i18n.dart
import 'package:flutter/material.dart';
import 'package:picnic_lib/services/locale_service.dart';

/// JSON에서 현재 로케일에 맞는 텍스트 가져오기
/// BuildContext를 사용하여 현재 로케일을 가져옵니다.
String getLocaleTextFromJson(Map<String, dynamic> json,
    [BuildContext? context]) {
  if (json.isEmpty) return '';

  String locale;
  if (context != null) {
    // BuildContext가 제공된 경우 Localizations.localeOf 사용하고 서비스도 업데이트
    locale = Localizations.localeOf(context).languageCode;
    LocaleService.instance.updateFromContext(context);
  } else {
    // BuildContext가 없는 경우 LocaleService에서 현재 언어 가져오기
    locale = LocaleService.instance.currentLanguageCode;
  }

  return json[locale] ?? json['en'] ?? '';
}

/// 특정 언어 코드로 JSON에서 텍스트 가져오기
String getLocaleTextFromJsonWithLocale(
    Map<String, dynamic> json, String languageCode) {
  if (json.isEmpty) return '';

  return json[languageCode] ?? json['en'] ?? '';
}
