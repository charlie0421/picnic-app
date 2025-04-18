// picnic_lib/lib/core/utils/i18n.dart
import 'package:flutter/widgets.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/locale_provider.dart';

// 주의: Crowdin은 로케일 문자열을 ko_KR 형식으로 필요로 함
String _formatLocale(Locale locale) {
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
    return '${locale.languageCode}_${locale.countryCode}';
  }
  return locale.languageCode;
}

ProviderContainer? _container;

void setProviderContainer(ProviderContainer container) {
  _container = container;
}

String t(String key, [List<String>? args]) {
  // 1. 가능하면 localeProvider에서 로케일 가져오기 (우선순위 1)
  Locale? currentLocale;

  if (_container != null) {
    try {
      currentLocale = _container!.read(localeStateProvider);
    } catch (e) {
      // Provider를 찾을 수 없는 경우 무시
    }
  }

  // 2. navigatorKey로 로케일 가져오기 (우선순위 2)
  String localeStr;
  if (currentLocale != null) {
    localeStr = _formatLocale(currentLocale);
  } else if (navigatorKey.currentContext != null) {
    Locale contextLocale = Localizations.localeOf(navigatorKey.currentContext!);
    localeStr = _formatLocale(contextLocale);
  } else {
    // 3. 기본값 사용 (우선순위 3)
    localeStr = 'ko_KR';
  }

  // Crowdin에서 번역 가져오기
  String? translatedText = Crowdin.getText(localeStr, key);

  // 번역이 없으면 영어로 시도
  if (translatedText == null || translatedText.isEmpty) {
    translatedText = Crowdin.getText('en', key);
  }

  // 영어도 없으면 한국어로 시도
  if (translatedText == null || translatedText.isEmpty) {
    translatedText = Crowdin.getText('ko_KR', key);
  }

  // 최종적으로 키 반환
  String finalText = translatedText ?? key;

  // 인자가 있으면 플레이스홀더 교체
  if (args != null) {
    for (int i = 0; i < args.length; i++) {
      finalText = finalText.replaceAll('{$i}', args[i]);
    }
  }

  return finalText;
}

String getLocaleLanguage() {
  // localeProvider가 있으면 사용
  if (_container != null) {
    try {
      final locale = _container!.read(localeStateProvider);
      return locale.languageCode;
    } catch (e) {
      // Provider를 찾을 수 없는 경우 무시
    }
  }
  return Intl.getCurrentLocale().split('_').first;
}

String getLocaleTextFromJson(Map<String, dynamic> json) {
  String locale = getLocaleLanguage();

  if (json.isEmpty) {
    return '';
  }

  if (json.containsKey(locale)) {
    return json[locale];
  }
  return json['en'];
}
