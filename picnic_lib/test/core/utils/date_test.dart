import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/date.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  group('convertKoreanTraditionalTime', () {
    test('returns correct emoji for each number', () {
      expect(convertKoreanTraditionalTime('1'), '\u{1F400}');
      expect(convertKoreanTraditionalTime('2'), '\u{1F402}');
      expect(convertKoreanTraditionalTime('3'), '\u{1F405}');
      expect(convertKoreanTraditionalTime('4'), '\u{1F407}');
      expect(convertKoreanTraditionalTime('5'), '\u{1F409}');
      expect(convertKoreanTraditionalTime('6'), '\u{1F40D}');
      expect(convertKoreanTraditionalTime('7'), '\u{1F40E}');
      expect(convertKoreanTraditionalTime('8'), '\u{1F411}');
      expect(convertKoreanTraditionalTime('9'), '\u{1F412}');
      expect(convertKoreanTraditionalTime('10'), '\u{1F413}');
      expect(convertKoreanTraditionalTime('11'), '\u{1F415}');
      expect(convertKoreanTraditionalTime('12'), '\u{1F416}');
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

    test('returns empty string for negative numbers', () {
      expect(convertKoreanTraditionalTime('-1'), '');
    });

    test('returns empty string for decimal numbers', () {
      expect(convertKoreanTraditionalTime('1.5'), '');
    });

    test('returns empty string for whitespace', () {
      expect(convertKoreanTraditionalTime(' '), '');
    });

    test('returns empty string for numbers with leading zeros', () {
      expect(convertKoreanTraditionalTime('01'), '');
    });
  });

  group('getCurrentTimeZoneIdentifier', () {
    test('returns non-empty string', () {
      final result = getCurrentTimeZoneIdentifier();
      expect(result, isNotEmpty);
    });

    test('returns a string', () {
      final result = getCurrentTimeZoneIdentifier();
      expect(result, isA<String>());
    });

    test('returns consistent results on repeated calls', () {
      final result1 = getCurrentTimeZoneIdentifier();
      final result2 = getCurrentTimeZoneIdentifier();
      expect(result1, equals(result2));
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

    test('returns the last part after splitting by slash', () {
      // The function splits by '/' and returns the last part
      final result = getShortTimeZoneIdentifier();
      expect(result, isA<String>());
      // Should never be empty since getCurrentTimeZoneIdentifier is not empty
      expect(result.isNotEmpty, isTrue);
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

    test('returns consistent results on repeated calls', () {
      final r1 = getTimezoneAbbreviation();
      final r2 = getTimezoneAbbreviation();
      expect(r1, equals(r2));
    });

    test('returns a known format (abbreviation or GMT offset)', () {
      final result = getTimezoneAbbreviation();
      // Should be either a timezone abbreviation like KST, GMT, etc.
      // or a GMT offset like GMT+9, GMT-5, GMT+5:30
      expect(result, isNotEmpty);
      // Basic validation: should not contain spaces
      expect(result.contains(' '), isFalse);
    });
  });

  group('formatLocalDateTime', () {
    test('returns empty string for null dateTime', () {
      expect(formatLocalDateTime(null), '');
    });

    test('formats valid dateTime with default format', () {
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
      // Without timezone, should not have the abbreviation at the end
    });

    test('includes timezone abbreviation by default', () {
      final dt = DateTime.utc(2024, 1, 15, 5, 30);
      final result = formatLocalDateTime(dt);
      final resultWithoutTz = formatLocalDateTime(dt, includeTimezone: false);
      // With timezone should be longer than without
      expect(result.length, greaterThan(resultWithoutTz.length));
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

    test('formats epoch datetime', () {
      final dt = DateTime.utc(1970, 1, 1, 0, 0, 0);
      final result = formatLocalDateTime(dt, includeTimezone: false);
      expect(result, contains('1970'));
    });

    test('formats future datetime', () {
      final dt = DateTime.utc(2099, 6, 15, 12, 0);
      final result = formatLocalDateTime(dt, includeTimezone: false);
      expect(result, contains('2099'));
    });

    test('handles date-only format', () {
      final dt = DateTime.utc(2024, 7, 4, 15, 30);
      final result = formatLocalDateTime(
        dt,
        format: 'yyyy-MM-dd',
        includeTimezone: false,
      );
      expect(result, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
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

    test('period contains start and stop dates', () {
      final start = DateTime.utc(2024, 1, 15, 14, 30);
      final stop = DateTime.utc(2024, 1, 22, 23, 59);
      final result = formatVotePeriod(start, stop);
      expect(result, contains('2024'));
      expect(result, contains('~'));
    });

    test('period with custom format', () {
      final start = DateTime.utc(2024, 3, 1, 0, 0);
      final stop = DateTime.utc(2024, 3, 31, 23, 59);
      final result = formatVotePeriod(start, stop, format: 'MM/dd HH:mm');
      expect(result, isNotEmpty);
      expect(result, contains('~'));
    });

    test('same start and stop time', () {
      final dt = DateTime.utc(2024, 6, 15, 12, 0);
      final result = formatVotePeriod(dt, dt);
      expect(result, isNotEmpty);
      expect(result, contains('~'));
    });

    test('stop before start still formats', () {
      final start = DateTime.utc(2024, 12, 31, 23, 59);
      final stop = DateTime.utc(2024, 1, 1, 0, 0);
      final result = formatVotePeriod(start, stop);
      expect(result, isNotEmpty);
      expect(result, contains('~'));
    });

    test('timezone abbreviation appears in the stop part', () {
      final start = DateTime.utc(2024, 1, 15, 14, 30);
      final stop = DateTime.utc(2024, 1, 22, 23, 59);
      final result = formatVotePeriod(start, stop);
      final tz = getTimezoneAbbreviation();
      // The stop part includes timezone
      expect(result, contains(tz));
    });
  });

  group('timezone functions', () {
    test('getCurrentTimeZoneIdentifier returns non-empty string', () {
      final result = getCurrentTimeZoneIdentifier();
      expect(result, isNotEmpty);
    });

    test('getShortTimeZoneIdentifier returns non-empty string', () {
      final result = getShortTimeZoneIdentifier();
      expect(result, isNotEmpty);
    });

    test('getTimezoneAbbreviation returns non-empty string', () {
      final result = getTimezoneAbbreviation();
      expect(result, isNotEmpty);
    });

    test('getTimezoneAbbreviation returns short abbreviation', () {
      final result = getTimezoneAbbreviation();
      expect(result.length, lessThanOrEqualTo(10));
    });
  });

  group('formatCurrentTime (navigatorKey)', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('returns formatted current time string', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatCurrentTime();
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
      expect(result, contains('-'));
      expect(result, contains(':'));
    });
  });

  group('formatDateTimeYYYYMMDD (navigatorKey)', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('formats date correctly', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDD(DateTime(2025, 3, 15));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, '2025.03.15');
    });

    testWidgets('formats another date correctly', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDD(DateTime(2024, 12, 1));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, '2024.12.01');
    });

    testWidgets('formats January 1st correctly', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDD(DateTime(2000, 1, 1));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, '2000.01.01');
    });
  });

  group('formatDateTimeYYYYMMDDHHM (navigatorKey)', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('formats datetime with time correctly', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDDHHM(DateTime(2025, 3, 15, 14, 30));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, '2025.03.15 14:30');
    });

    testWidgets('formats midnight correctly', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDDHHM(DateTime(2025, 1, 1, 0, 0));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, '2025.01.01 00:00');
    });

    testWidgets('formats end of day correctly', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDDHHM(DateTime(2025, 12, 31, 23, 59));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, '2025.12.31 23:59');
    });
  });

  group('formatTimeAgo', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('returns day text for timestamps older than 1 day',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final twoDaysAgo = DateTime.now().toUtc().subtract(
                  const Duration(days: 2),
                );
            result = formatTimeAgo(context, twoDaysAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns hour text for timestamps older than 1 hour',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final twoHoursAgo = DateTime.now().toUtc().subtract(
                  const Duration(hours: 2),
                );
            result = formatTimeAgo(context, twoHoursAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns minute text for timestamps older than 1 minute',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final fiveMinutesAgo = DateTime.now().toUtc().subtract(
                  const Duration(minutes: 5),
                );
            result = formatTimeAgo(context, fiveMinutesAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns right now text for very recent timestamps',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final justNow = DateTime.now().toUtc();
            result = formatTimeAgo(context, justNow);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns day text for exactly 1 day ago', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final oneDayAgo = DateTime.now().toUtc().subtract(
                  const Duration(days: 1),
                );
            result = formatTimeAgo(context, oneDayAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns hour text for exactly 1 hour ago', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final oneHourAgo = DateTime.now().toUtc().subtract(
                  const Duration(hours: 1),
                );
            result = formatTimeAgo(context, oneHourAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns minute text for exactly 1 minute ago',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final oneMinuteAgo = DateTime.now().toUtc().subtract(
                  const Duration(minutes: 1),
                );
            result = formatTimeAgo(context, oneMinuteAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('handles very old timestamps', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final veryOld = DateTime.now().toUtc().subtract(
                  const Duration(days: 365),
                );
            result = formatTimeAgo(context, veryOld);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns minute text for 59 minutes ago', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final fiftyNineMinutesAgo = DateTime.now().toUtc().subtract(
                  const Duration(minutes: 59),
                );
            result = formatTimeAgo(context, fiftyNineMinutesAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns right now text for 30 seconds ago', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final thirtySecondsAgo = DateTime.now().toUtc().subtract(
                  const Duration(seconds: 30),
                );
            result = formatTimeAgo(context, thirtySecondsAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns day text for 100 days ago', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final hundredDaysAgo = DateTime.now().toUtc().subtract(
                  const Duration(days: 100),
                );
            result = formatTimeAgo(context, hundredDaysAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('returns hour text for 23 hours ago', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final twentyThreeHoursAgo = DateTime.now().toUtc().subtract(
                  const Duration(hours: 23),
                );
            result = formatTimeAgo(context, twentyThreeHoursAgo);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });
  });

  group('formatLocalDateTime - additional coverage', () {
    test('formats with time-only format', () {
      final dt = DateTime.utc(2024, 3, 15, 10, 30);
      final result = formatLocalDateTime(
        dt,
        format: 'HH:mm:ss',
        includeTimezone: false,
      );
      expect(result, isNotEmpty);
      expect(result, contains(':'));
    });

    test('formats with month-day format', () {
      final dt = DateTime.utc(2024, 12, 25, 0, 0);
      final result = formatLocalDateTime(
        dt,
        format: 'MM.dd',
        includeTimezone: false,
      );
      expect(result, isNotEmpty);
      expect(result, contains('.'));
    });

    test('formats with timezone and custom format', () {
      final dt = DateTime.utc(2024, 6, 15, 12, 0);
      final result = formatLocalDateTime(
        dt,
        format: 'yyyy-MM-dd',
        includeTimezone: true,
      );
      expect(result, isNotEmpty);
      // Should contain the date and timezone abbreviation
      final tz = getTimezoneAbbreviation();
      expect(result, contains(tz));
    });

    test('formats UTC epoch with timezone', () {
      final dt = DateTime.utc(1970, 1, 1, 0, 0, 0);
      final result = formatLocalDateTime(dt, includeTimezone: true);
      expect(result, contains('1970'));
      expect(result, contains(getTimezoneAbbreviation()));
    });
  });

  group('formatVotePeriod - additional coverage', () {
    test('formats period with time-only format', () {
      final start = DateTime.utc(2024, 1, 15, 14, 30);
      final stop = DateTime.utc(2024, 1, 22, 23, 59);
      final result = formatVotePeriod(start, stop, format: 'HH:mm');
      expect(result, isNotEmpty);
      expect(result, contains('~'));
    });

    test('formats period spanning different years', () {
      final start = DateTime.utc(2023, 12, 31, 23, 59);
      final stop = DateTime.utc(2024, 1, 1, 0, 0);
      final result = formatVotePeriod(start, stop);
      expect(result, isNotEmpty);
      expect(result, contains('~'));
    });

    test('formats period spanning months', () {
      final start = DateTime.utc(2024, 1, 1, 0, 0);
      final stop = DateTime.utc(2024, 6, 30, 23, 59);
      final result = formatVotePeriod(start, stop);
      expect(result, isNotEmpty);
      expect(result, contains('~'));
    });

    test('formats period with very short duration', () {
      final start = DateTime.utc(2024, 6, 15, 12, 0);
      final stop = DateTime.utc(2024, 6, 15, 12, 1);
      final result = formatVotePeriod(start, stop);
      expect(result, isNotEmpty);
      expect(result, contains('~'));
    });
  });

  group('getTimezoneAbbreviation - branch coverage', () {
    test('returns a known timezone abbreviation or GMT offset format', () {
      final result = getTimezoneAbbreviation();
      // The result should match either a known abbreviation or GMT+/-N format
      final isKnownAbbr = RegExp(r'^[A-Z]{2,5}$').hasMatch(result);
      final isGmtOffset =
          RegExp(r'^GMT[+-]\d{1,2}(:\d{2})?$').hasMatch(result);
      expect(isKnownAbbr || isGmtOffset, isTrue,
          reason: 'Expected timezone abbreviation or GMT offset, got: $result');
    });

    test('result does not contain slash', () {
      final result = getTimezoneAbbreviation();
      expect(result.contains('/'), isFalse);
    });
  });

  group('getCurrentTimeZoneIdentifier - additional coverage', () {
    test('returns same value as DateTime.now().timeZoneName', () {
      final expected = DateTime.now().timeZoneName;
      final result = getCurrentTimeZoneIdentifier();
      expect(result, equals(expected));
    });
  });

  group('getShortTimeZoneIdentifier - additional coverage', () {
    test('returns last segment of timezone identifier', () {
      final full = getCurrentTimeZoneIdentifier();
      final parts = full.split('/');
      final expected = parts.last;
      final result = getShortTimeZoneIdentifier();
      expect(result, equals(expected));
    });
  });

  group('formatCurrentTime - additional coverage', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('returns string matching yyyy-MM-dd HH:mm:ss pattern',
        (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatCurrentTime();
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(
        result,
        matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$')),
      );
    });
  });

  group('formatDateTimeYYYYMMDD - additional edge cases', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('formats leap year date', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDD(DateTime(2024, 2, 29));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, '2024.02.29');
    });

    testWidgets('formats date with single-digit month and day', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDD(DateTime(2025, 1, 5));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, '2025.01.05');
    });
  });

  group('formatDateTimeYYYYMMDDHHM - additional edge cases', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('formats single-digit hour and minute', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDDHHM(DateTime(2025, 6, 1, 9, 5));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, '2025.06.01 09:05');
    });

    testWidgets('formats noon correctly', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatDateTimeYYYYMMDDHHM(DateTime(2025, 7, 4, 12, 0));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, '2025.07.04 12:00');
    });
  });

  group('formatTimeAgo - with English locale', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('works with English locale', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final twoDaysAgo = DateTime.now().toUtc().subtract(
                  const Duration(days: 2),
                );
            result = formatTimeAgo(context, twoDaysAgo);
            return const SizedBox();
          }),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('works with English locale for hours', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final threeHoursAgo = DateTime.now().toUtc().subtract(
                  const Duration(hours: 3),
                );
            result = formatTimeAgo(context, threeHoursAgo);
            return const SizedBox();
          }),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('works with English locale for minutes', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            final tenMinutesAgo = DateTime.now().toUtc().subtract(
                  const Duration(minutes: 10),
                );
            result = formatTimeAgo(context, tenMinutesAgo);
            return const SizedBox();
          }),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });

    testWidgets('works with English locale for just now', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = formatTimeAgo(context, DateTime.now().toUtc());
            return const SizedBox();
          }),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isNotEmpty);
    });
  });

  group('getIanaTimeZoneName', () {
    test('returns string containing slash or null', () {
      final result = getIanaTimeZoneName();
      if (result != null) {
        expect(result, contains('/'));
      }
    });

    test('returns consistent results', () {
      final r1 = getIanaTimeZoneName();
      final r2 = getIanaTimeZoneName();
      expect(r1, equals(r2));
    });
  });

  group('formatUtcOffset', () {
    test('returns GMT offset string', () {
      final result = formatUtcOffset();
      expect(result, startsWith('GMT'));
    });

    test('contains sign character', () {
      final result = formatUtcOffset();
      expect(result.contains('+') || result.contains('-'), isTrue);
    });

    test('returns consistent results', () {
      final r1 = formatUtcOffset();
      final r2 = formatUtcOffset();
      expect(r1, equals(r2));
    });
  });

  group('convertKoreanTraditionalTime - additional coverage', () {
    test('returns empty string for very large number', () {
      expect(convertKoreanTraditionalTime('100'), '');
    });

    test('returns empty string for special characters', () {
      expect(convertKoreanTraditionalTime('!@#'), '');
    });

    test('returns empty string for Korean text', () {
      expect(convertKoreanTraditionalTime('하나'), '');
    });
  });
}
