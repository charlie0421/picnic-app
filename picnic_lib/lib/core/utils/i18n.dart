import 'package:intl/intl.dart';

String getLocaleLanguage() {
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
