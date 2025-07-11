// picnic_lib/lib/core/utils/i18n.dart
import 'package:flutter/material.dart';

/// JSON에서 현재 로케일에 맞는 텍스트 가져오기
/// BuildContext를 사용하여 현재 로케일을 가져옵니다.
String getLocaleTextFromJson(Map<String, dynamic> json,
    [BuildContext? context]) {
  if (json.isEmpty) return '';

  String locale;
  if (context != null) {
    // BuildContext가 제공된 경우 Localizations.localeOf 사용
    locale = Localizations.localeOf(context).languageCode;
  } else {
    // BuildContext가 없는 경우 시스템 로케일 사용 (하위호환용)
    locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  }

  return json[locale] ?? json['en'] ?? '';
}

/// 특정 언어 코드로 JSON에서 텍스트 가져오기
String getLocaleTextFromJsonWithLocale(
    Map<String, dynamic> json, String languageCode) {
  if (json.isEmpty) return '';

  return json[languageCode] ?? json['en'] ?? '';
}
