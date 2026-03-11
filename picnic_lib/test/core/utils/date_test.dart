import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/date.dart';

void main() {
  group('convertKoreanTraditionalTime', () {
    test('returns correct emoji for each number', () {
      expect(convertKoreanTraditionalTime('1'), '🐀');
      expect(convertKoreanTraditionalTime('2'), '🐂');
      expect(convertKoreanTraditionalTime('3'), '🐅');
      expect(convertKoreanTraditionalTime('4'), '🐇');
      expect(convertKoreanTraditionalTime('5'), '🐉');
      expect(convertKoreanTraditionalTime('6'), '🐍');
      expect(convertKoreanTraditionalTime('7'), '🐎');
      expect(convertKoreanTraditionalTime('8'), '🐑');
      expect(convertKoreanTraditionalTime('9'), '🐒');
      expect(convertKoreanTraditionalTime('10'), '🐓');
      expect(convertKoreanTraditionalTime('11'), '🐕');
      expect(convertKoreanTraditionalTime('12'), '🐖');
    });

    test('returns empty string for null', () {
      expect(convertKoreanTraditionalTime(null), '');
    });

    test('returns empty string for invalid input', () {
      expect(convertKoreanTraditionalTime('0'), '');
      expect(convertKoreanTraditionalTime('13'), '');
      expect(convertKoreanTraditionalTime('abc'), '');
      expect(convertKoreanTraditionalTime(''), '');
    });
  });

  group('getCurrentTimeZoneIdentifier', () {
    test('returns non-empty string', () {
      final result = getCurrentTimeZoneIdentifier();
      expect(result, isNotEmpty);
    });
  });

  group('getShortTimeZoneIdentifier', () {
    test('returns non-empty string', () {
      final result = getShortTimeZoneIdentifier();
      expect(result, isNotEmpty);
    });

    test('does not contain slash', () {
      final result = getShortTimeZoneIdentifier();
      expect(result.contains('/'), isFalse);
    });
  });

  group('getTimezoneAbbreviation', () {
    test('returns non-empty string', () {
      final result = getTimezoneAbbreviation();
      expect(result, isNotEmpty);
    });

    test('returns short abbreviation', () {
      final result = getTimezoneAbbreviation();
      expect(result.length, lessThanOrEqualTo(10));
    });
  });

  group('formatLocalDateTime', () {
    test('returns empty string for null dateTime', () {
      expect(formatLocalDateTime(null), '');
    });

    test('formats valid dateTime', () {
      final dt = DateTime.utc(2024, 1, 15, 5, 30);
      final result = formatLocalDateTime(dt);
      expect(result, isNotEmpty);
      expect(result, contains('2024'));
    });

    test('formats without timezone', () {
      final dt = DateTime.utc(2024, 6, 1, 12, 0);
      final result = formatLocalDateTime(dt, includeTimezone: false);
      expect(result, isNotEmpty);
      expect(result, contains('2024'));
    });

    test('custom format', () {
      final dt = DateTime.utc(2024, 3, 15, 10, 30);
      final result = formatLocalDateTime(
        dt,
        format: 'yyyy/MM/dd',
        includeTimezone: false,
      );
      expect(result, contains('2024'));
      expect(result, contains('/'));
    });
  });

  group('formatVotePeriod', () {
    test('returns empty string when startAt is null', () {
      expect(formatVotePeriod(null, DateTime.now()), '');
    });

    test('returns empty string when stopAt is null', () {
      expect(formatVotePeriod(DateTime.now(), null), '');
    });

    test('returns empty string when both are null', () {
      expect(formatVotePeriod(null, null), '');
    });

    test('formats valid period', () {
      final start = DateTime.utc(2024, 1, 15, 14, 30);
      final stop = DateTime.utc(2024, 1, 22, 23, 59);
      final result = formatVotePeriod(start, stop);
      expect(result, isNotEmpty);
      expect(result, contains('~'));
    });
  });
}
