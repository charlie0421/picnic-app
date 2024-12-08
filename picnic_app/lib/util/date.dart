import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/util/logger.dart';

String formatTimeAgo(BuildContext context, DateTime timestamp) {
  final now = DateTime.now().toUtc();
  final difference = now.difference(timestamp);

  if (difference.inDays >= 1) {
    return Intl.message('label_time_ago_day',
        args: [difference.inDays.toString()]);
  } else if (difference.inHours >= 1) {
    return Intl.message('label_time_ago_hour',
        args: [difference.inHours.toString()]);
  } else if (difference.inMinutes >= 1) {
    return Intl.message('label_time_ago_minute',
        args: [difference.inMinutes.toString()]);
  } else {
    return S.of(context).label_time_ago_right_now;
  }
}

String formatCurrentTime() {
  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd HH:mm:ss', Intl.getCurrentLocale());
  return formatter.format(now);
}

String formatDateTimeYYYYMMDD(DateTime dateTime) {
  var formatter = DateFormat('yyyy.MM.dd', Intl.getCurrentLocale());
  return formatter.format(dateTime);
}

String formatDateTimeYYYYMMDDHHM(DateTime dateTime) {
  var formatter = DateFormat('yyyy.MM.dd HH:mm', Intl.getCurrentLocale());
  return formatter.format(dateTime);
}

String getCurrentTimeZoneIdentifier() {
  try {
    return DateTime.now().timeZoneName;
  } catch (e, s) {
    // 오류 발생 시 시스템 시간대 이름 또는 UTC 반환
    logger.e('error', error: e, stackTrace: s);
    return DateTime.now().timeZoneName;
  }
}

String getShortTimeZoneIdentifier() {
  String fullIdentifier = getCurrentTimeZoneIdentifier();
  List<String> parts = fullIdentifier.split('/');
  return parts.last; // 예: 'London', 'Seoul' 등
}

String convertKoreanTraditionalTime(String? time) {
  switch (time) {
    case '1':
      return '🐀';
    case '2':
      return '🐂';
    case '3':
      return '🐅';
    case '4':
      return '🐇';
    case '5':
      return '🐉';
    case '6':
      return '🐍';
    case '7':
      return '🐎';
    case '8':
      return '🐑';
    case '9':
      return '🐒';
    case '10':
      return '🐓';
    case '11':
      return '🐕';
    case '12':
      return '🐖';
    default:
      return '';
  }
}
