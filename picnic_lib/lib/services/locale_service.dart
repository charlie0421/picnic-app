import 'package:flutter/material.dart';

/// 전역 로케일 상태를 관리하는 서비스
class LocaleService {
  static LocaleService? _instance;
  static LocaleService get instance => _instance ??= LocaleService._();

  LocaleService._();

  String _currentLanguageCode = 'ko'; // 기본값

  /// 현재 언어 코드 반환
  String get currentLanguageCode => _currentLanguageCode;

  /// 언어 코드 업데이트
  void updateLanguageCode(String languageCode) {
    _currentLanguageCode = languageCode;
  }

  /// BuildContext에서 언어 코드를 추출하여 업데이트
  void updateFromContext(BuildContext context) {
    final locale = Localizations.localeOf(context);
    _currentLanguageCode = locale.languageCode;
  }
}
