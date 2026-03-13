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
    final ianaName = getIanaTimeZoneName();
    final offset = DateTime.now().timeZoneOffset;

    return DateHelpers.resolveTimezoneAbbreviation(
      timeZoneName,
      ianaName,
      offset,
    );
  } catch (e) {
    logger.e('시간대 약어 가져오기 실패', error: e);
    return formatUtcOffset();
  }
}

/// IANA 시간대 이름을 가져오는 시도
@visibleForTesting
String? getIanaTimeZoneName() {
  try {
    final timeZoneName = DateTime.now().timeZoneName;
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    return DateHelpers.resolveIanaTimeZoneName(timeZoneName, offsetHours);
  } catch (e) {
    return null;
  }
}

/// UTC 오프셋을 포맷팅합니다.
/// 예: 'GMT+9', 'GMT-5', 'GMT+5:30'
@visibleForTesting
String formatUtcOffset() {
  return DateHelpers.formatUtcOffsetFromDuration(DateTime.now().timeZoneOffset);
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

/// 테스트 가능한 순수 헬퍼 메서드 모음
class DateHelpers {
  DateHelpers._();

  /// Duration으로부터 UTC 오프셋 문자열을 생성합니다.
  /// 예: 'GMT+9', 'GMT-5', 'GMT+5:30'
  static String formatUtcOffsetFromDuration(Duration offset) {
    final hours = offset.inHours.abs();
    final minutes = offset.inMinutes.abs() % 60;
    final sign = offset.isNegative ? '-' : '+';

    if (minutes == 0) {
      return 'GMT$sign$hours';
    } else {
      return 'GMT$sign$hours:${minutes.toString().padLeft(2, '0')}';
    }
  }

  /// 시간대 이름, IANA 이름, 오프셋으로부터 시간대 약어를 결정합니다.
  static String resolveTimezoneAbbreviation(
    String timeZoneName,
    String? ianaName,
    Duration timeZoneOffset,
  ) {
    // 1. 시스템이 반환한 이름이 이미 약어 형태면 그대로 사용
    if (timeZoneName.length <= 5 && !timeZoneName.contains('/')) {
      if (!timeZoneName.contains('GMT') || timeZoneName == 'GMT') {
        return timeZoneName;
      }
    }

    // 2. IANA 시간대 이름으로 데이터베이스에서 약어 찾기
    if (ianaName != null && timezoneAbbreviations.containsKey(ianaName)) {
      return timezoneAbbreviations[ianaName]!;
    }

    // 3. UTC 오프셋으로 폴백
    return formatUtcOffsetFromDuration(timeZoneOffset);
  }

  /// 시간대 이름과 오프셋 시간으로 IANA 시간대 이름을 추론합니다.
  static String? resolveIanaTimeZoneName(
    String timeZoneName,
    int offsetHours,
  ) {
    // IANA 형식인 경우 그대로 반환
    if (timeZoneName.contains('/')) {
      return timeZoneName;
    }

    // 오프셋 기반으로 가능한 시간대 추론
    switch (offsetHours) {
      case 9:
        return 'Asia/Seoul';
      case 8:
        return 'Asia/Shanghai';
      case 7:
        return 'Asia/Bangkok';
      case -5:
        return 'America/New_York';
      case -8:
        return 'America/Los_Angeles';
      case 0:
        return 'Europe/London';
      case 1:
        return 'Europe/Berlin';
      default:
        return null;
    }
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
