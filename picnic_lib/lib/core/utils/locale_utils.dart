import 'package:flutter/material.dart';

/// JSON에서 현재 로케일에 맞는 텍스트 가져오기
String getLocaleTextFromJson(Map<String, dynamic> json, BuildContext context) {
  if (json.isEmpty) return '';

  final locale = Localizations.localeOf(context).languageCode;
  return json[locale] ?? json['en'] ?? '';
}

/// JSON에서 특정 로케일에 맞는 텍스트 가져오기
String getLocaleTextFromJsonWithLocale(Map<String, dynamic> json, String languageCode) {
  if (json.isEmpty) return '';
  
  return json[languageCode] ?? json['en'] ?? '';
} 