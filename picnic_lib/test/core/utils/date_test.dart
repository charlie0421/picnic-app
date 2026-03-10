import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/date.dart';

void main() {
  group('convertKoreanTraditionalTime', () {
    test('1~12까지 올바른 동물 이모지 반환', () {
      expect(convertKoreanTraditionalTime('1'), equals('\u{1F400}')); // 쥐
      expect(convertKoreanTraditionalTime('2'), equals('\u{1F402}')); // 소
      expect(convertKoreanTraditionalTime('3'), equals('\u{1F405}')); // 호랑이
      expect(convertKoreanTraditionalTime('4'), equals('\u{1F407}')); // 토끼
      expect(convertKoreanTraditionalTime('5'), equals('\u{1F409}')); // 용
      expect(convertKoreanTraditionalTime('6'), equals('\u{1F40D}')); // 뱀
      expect(convertKoreanTraditionalTime('7'), equals('\u{1F40E}')); // 말
      expect(convertKoreanTraditionalTime('8'), equals('\u{1F411}')); // 양
      expect(convertKoreanTraditionalTime('9'), equals('\u{1F412}')); // 원숭이
      expect(convertKoreanTraditionalTime('10'), equals('\u{1F413}')); // 닭
      expect(convertKoreanTraditionalTime('11'), equals('\u{1F415}')); // 개
      expect(convertKoreanTraditionalTime('12'), equals('\u{1F416}')); // 돼지
    });

    test('null이면 빈 문자열 반환', () {
      expect(convertKoreanTraditionalTime(null), equals(''));
    });

    test('범위 밖 값이면 빈 문자열 반환', () {
      expect(convertKoreanTraditionalTime('0'), equals(''));
      expect(convertKoreanTraditionalTime('13'), equals(''));
      expect(convertKoreanTraditionalTime('abc'), equals(''));
    });
  });

  group('getTimezoneAbbreviation', () {
    test('시간대 약어를 반환', () {
      final result = getTimezoneAbbreviation();
      // 실행 환경에 따라 다르지만, 빈 문자열이 아닌 유효한 값이어야 함
      expect(result, isNotEmpty);
    });
  });

  group('formatLocalDateTime', () {
    test('null이면 빈 문자열 반환', () {
      expect(formatLocalDateTime(null), equals(''));
    });

    test('유효한 DateTime이면 포맷된 문자열 반환', () {
      final dateTime = DateTime.utc(2025, 1, 15, 5, 30);
      final result = formatLocalDateTime(dateTime);
      // 포맷된 결과에 년도가 포함되어야 함
      expect(result, contains('2025'));
    });

    test('includeTimezone=false이면 시간대 미포함', () {
      final dateTime = DateTime.utc(2025, 6, 15, 12, 0);
      final result = formatLocalDateTime(dateTime, includeTimezone: false);
      final resultWithTz = formatLocalDateTime(dateTime, includeTimezone: true);
      // 시간대 제외 결과가 더 짧아야 함
      expect(result.length, lessThan(resultWithTz.length));
    });

    test('커스텀 포맷 적용', () {
      final dateTime = DateTime.utc(2025, 3, 10, 14, 30);
      final result = formatLocalDateTime(
        dateTime,
        format: 'yyyy-MM-dd',
        includeTimezone: false,
      );
      expect(result, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });

  group('formatVotePeriod', () {
    test('시작/종료 모두 null이면 빈 문자열', () {
      expect(formatVotePeriod(null, null), equals(''));
    });

    test('시작만 null이면 빈 문자열', () {
      expect(formatVotePeriod(null, DateTime.now()), equals(''));
    });

    test('종료만 null이면 빈 문자열', () {
      expect(formatVotePeriod(DateTime.now(), null), equals(''));
    });

    test('유효한 기간이면 ~ 구분자 포함', () {
      final start = DateTime.utc(2025, 1, 1, 0, 0);
      final stop = DateTime.utc(2025, 1, 31, 23, 59);
      final result = formatVotePeriod(start, stop);
      expect(result, contains('~'));
      expect(result, contains('2025'));
    });
  });

  group('getCurrentTimeZoneIdentifier', () {
    test('시간대 이름을 반환', () {
      final result = getCurrentTimeZoneIdentifier();
      expect(result, isNotEmpty);
    });
  });

  group('getShortTimeZoneIdentifier', () {
    test('짧은 시간대 이름을 반환', () {
      final result = getShortTimeZoneIdentifier();
      expect(result, isNotEmpty);
      // / 구분자가 없어야 함 (짧은 형태)
      expect(result.contains('/'), isFalse);
    });
  });
}
