import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/timezone_data.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';

String formatTimeAgo(BuildContext context, DateTime timestamp) {
  final now = DateTime.now().toUtc();
  final difference = now.difference(timestamp);

  if (difference.inDays >= 1) {
    return AppLocalizations.of(context).label_time_ago_day(difference.inDays);
  } else if (difference.inHours >= 1) {
    return AppLocalizations.of(context).label_time_ago_hour(difference.inHours);
  } else if (difference.inMinutes >= 1) {
    return AppLocalizations.of(
      context,
    ).label_time_ago_minute(difference.inMinutes);
  } else {
    return AppLocalizations.of(context).label_time_ago_right_now;
  }
}

String formatCurrentTime() {
  var now = DateTime.now();
  var formatter = DateFormat(
    'yyyy-MM-dd HH:mm:ss',
    Localizations.localeOf(navigatorKey.currentContext!).languageCode,
  );
  return formatter.format(now);
}

String formatDateTimeYYYYMMDD(DateTime dateTime) {
  var formatter = DateFormat(
    'yyyy.MM.dd',
    Localizations.localeOf(navigatorKey.currentContext!).languageCode,
  );
  return formatter.format(dateTime);
}

String formatDateTimeYYYYMMDDHHM(DateTime dateTime) {
  var formatter = DateFormat(
    'yyyy.MM.dd HH:mm',
    Localizations.localeOf(navigatorKey.currentContext!).languageCode,
  );
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

/// 현재 기기의 시간대 약어를 반환합니다.
/// 예: 'KST', 'JST', 'PST', 'GMT+9'
/// 웹(picnic-web)과 동일한 구현을 유지합니다.
String getTimezoneAbbreviation() {
  try {
    final timeZoneName = DateTime.now().timeZoneName;

    // 1. 시스템이 반환한 이름이 이미 약어 형태면 그대로 사용
    // (예: iOS에서 'KST', 'JST' 등을 직접 반환하는 경우)
    if (timeZoneName.length <= 5 && !timeZoneName.contains('/')) {
      // GMT+X 형식이 아닌 실제 약어면 그대로 반환
      if (!timeZoneName.contains('GMT') || timeZoneName == 'GMT') {
        return timeZoneName;
      }
    }

    // 2. IANA 시간대 이름으로 데이터베이스에서 약어 찾기
    final ianaName = _getIanaTimeZoneName();
    if (ianaName != null && timezoneAbbreviations.containsKey(ianaName)) {
      return timezoneAbbreviations[ianaName]!;
    }

    // 3. UTC 오프셋으로 폴백
    return _formatUtcOffset();
  } catch (e) {
    logger.e('시간대 약어 가져오기 실패', error: e);
    return _formatUtcOffset();
  }
}

/// IANA 시간대 이름을 가져오는 시도
String? _getIanaTimeZoneName() {
  try {
    // DateTime.now().timeZoneName이 IANA 형식인 경우 (일부 플랫폼)
    final timeZoneName = DateTime.now().timeZoneName;
    if (timeZoneName.contains('/')) {
      return timeZoneName;
    }

    // 오프셋 기반으로 가능한 시간대 추론
    final offset = DateTime.now().timeZoneOffset;
    final offsetHours = offset.inHours;

    // 일반적인 시간대 매핑 (오프셋 기반)
    switch (offsetHours) {
      case 9:
        return 'Asia/Seoul'; // KST (한국, 일본)
      case 8:
        return 'Asia/Shanghai'; // CST (중국)
      case 7:
        return 'Asia/Bangkok'; // ICT (태국, 베트남)
      case -5:
        return 'America/New_York'; // EST
      case -8:
        return 'America/Los_Angeles'; // PST
      case 0:
        return 'Europe/London'; // GMT
      case 1:
        return 'Europe/Berlin'; // CET
      default:
        return null;
    }
  } catch (e) {
    return null;
  }
}

/// UTC 오프셋을 포맷팅합니다.
/// 예: 'GMT+9', 'GMT-5', 'GMT+5:30'
String _formatUtcOffset() {
  final offset = DateTime.now().timeZoneOffset;
  final hours = offset.inHours.abs();
  final minutes = offset.inMinutes.abs() % 60;
  final sign = offset.isNegative ? '-' : '+';

  if (minutes == 0) {
    return 'GMT$sign$hours';
  } else {
    return 'GMT$sign$hours:${minutes.toString().padLeft(2, '0')}';
  }
}

/// DB의 UTC DateTime을 현지 시간으로 변환하고 시간대 약어를 포함하여 포맷팅합니다.
/// 웹(picnic-web)의 formatLocalDateTime과 동일한 기능입니다.
///
/// 예: '2024.01.15 14:30 KST'
String formatLocalDateTime(
  DateTime? dateTime, {
  String format = 'yyyy.MM.dd HH:mm',
  bool includeTimezone = true,
}) {
  if (dateTime == null) return '';

  try {
    final localDateTime = dateTime.toLocal();
    final formatter = DateFormat(format);
    final formatted = formatter.format(localDateTime);

    if (includeTimezone) {
      final tzAbbr = getTimezoneAbbreviation();
      return '$formatted $tzAbbr';
    }

    return formatted;
  } catch (e) {
    logger.e('날짜 포맷팅 실패', error: e);
    return '';
  }
}

/// 투표 기간을 포맷팅합니다.
/// 웹(picnic-web)의 formatVotePeriodWithTimeZone과 동일한 기능입니다.
///
/// 예: '2024.01.15 14:30 ~ 2024.01.22 23:59 KST'
String formatVotePeriod(
  DateTime? startAt,
  DateTime? stopAt, {
  String format = 'yyyy.MM.dd HH:mm',
}) {
  if (startAt == null || stopAt == null) return '';

  try {
    final startFormatted = formatLocalDateTime(
      startAt,
      format: format,
      includeTimezone: false,
    );
    final stopFormatted = formatLocalDateTime(
      stopAt,
      format: format,
      includeTimezone: true,
    );

    return '$startFormatted ~ $stopFormatted';
  } catch (e) {
    logger.e('투표 기간 포맷팅 실패', error: e);
    return '';
  }
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
