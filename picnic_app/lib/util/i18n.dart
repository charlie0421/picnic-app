import 'package:intl/intl.dart';

String getLocaleTextFromJson(Map<String, dynamic> json) {
  String locale = Intl.getCurrentLocale().split('_').first;

  if (json.isEmpty) {
    return '';
  }

  if (json.containsKey(locale)) {
    return json[locale];
  }
  return json['en'];
}
