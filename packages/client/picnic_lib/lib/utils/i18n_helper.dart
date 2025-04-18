import 'package:flutter/material.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:picnic_lib/generated/app_localizations.dart';

/// i18n 헬퍼 클래스
class I18nHelper {
  /// Crowdin에서 직접 키를 사용하여 번역을 가져오는 함수
  static String t(BuildContext context, String key, {String? fallback}) {
    final locale = Localizations.localeOf(context);
    // Crowdin SDK를 통해 직접 번역 가져오기
    final translation = CrowdinSdk.getString(key, locale.toLanguageTag());

    // 번역이 없거나 비어있는 경우 fallback 사용
    if (translation == null || translation.isEmpty) {
      return fallback ?? key;
    }

    return translation;
  }

  /// 현재 앱에서 사용중인 AppLocalizations 인스턴스 반환
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context)!;
  }

  /// 지원하는 모든 로케일 목록 반환
  static List<Locale> get supportedLocales {
    return AppLocalizations.supportedLocales;
  }

  /// 앱의 현재 로케일 반환
  static Locale getCurrentLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }
}

/// 간편하게 사용할 수 있는 확장 함수
extension I18nContext on BuildContext {
  /// 컨텍스트에서 바로 번역 함수 사용 (예: context.t('key'))
  String t(String key, {String? fallback}) {
    return I18nHelper.t(this, key, fallback: fallback);
  }

  /// 컨텍스트에서 바로 AppLocalizations 접근 (예: context.i18n.someKey)
  AppLocalizations get i18n => AppLocalizations.of(this)!;
}
