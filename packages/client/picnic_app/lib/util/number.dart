import 'package:intl/intl.dart';

String formatCount(int number, String labelName) {
  final String viewString = Intl.getCurrentLocale() == 'ko'
      ? '${formatViewCountNumberKo(number)} ${Intl.message(labelName)}'
      : '${formatViewCountNumberEn(number)} ${Intl.message(labelName)}';
  return viewString;
}

String formatViewCountNumberKo(int number) {
  if (number >= 100000000) {
    return '${(number / 100000000).toStringAsFixed(1)}억';
  } else if (number >= 10000) {
    return '${(number / 10000).toStringAsFixed(1)}만';
  } else {
    return NumberFormat(number < 1000 ? '###' : '#,###').format(number);
  }
}

String formatViewCountNumberEn(int number) {
  if (number >= 1000000000) {
    return '${(number / 1000000000).toStringAsFixed(1)}B';
  } else if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else {
    return NumberFormat(number < 1000 ? '###' : '#,###').format(number);
  }
}

String formatNumberWithComma<T>(T number) {
  final numberFormat = NumberFormat("#,###");
  return T == String
      ? numberFormat.format(int.parse(number as String))
      : numberFormat.format(number);
}
