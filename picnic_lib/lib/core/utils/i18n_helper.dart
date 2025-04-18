import 'package:flutter/widgets.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';
import 'package:picnic_lib/generated/app_localizations.dart';

/// OTA 국제화를 위한 헬퍼 함수
/// AppLocalizations에 정의되지 않은 키도 Crowdin에서 직접 가져옴
String t(BuildContext context, String key, [List<dynamic>? args]) {
  try {
    // AppLocalizations에 정의된 getter를 호출 시도
    final appLocalizations = AppLocalizations.of(context);
    final mirror = reflect(appLocalizations);
    final getterResult = mirror.getField(key);
    if (getterResult != null) {
      return getterResult.toString();
    }
  } catch (e) {
    // getter가 존재하지 않거나 오류 발생
  }

  // Crowdin에서 직접 가져오기
  final locale = Localizations.localeOf(context).toString();
  String? text = Crowdin.getText(locale, key);

  // 파라미터 처리
  if (text != null && args != null && args.isNotEmpty) {
    for (int i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', args[i].toString());
    }
  }

  return text ?? key;
}

/// 매개변수가 있는 문자열을 위한 헬퍼 함수
String tp(BuildContext context, String key, Map<String, dynamic> params) {
  final locale = Localizations.localeOf(context).toString();
  String? text = Crowdin.getText(locale, key);

  if (text != null && params.isNotEmpty) {
    params.forEach((key, value) {
      text = text!.replaceAll('{$key}', value.toString());
    });
  }

  return text ?? key;
}
