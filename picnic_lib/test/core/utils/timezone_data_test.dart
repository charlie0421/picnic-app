import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/timezone_data.dart';

void main() {
  group('timezoneAbbreviations', () {
    test('주요 시간대가 포함되어 있음', () {
      expect(timezoneAbbreviations['Asia/Seoul'], equals('KST'));
      expect(timezoneAbbreviations['Asia/Tokyo'], equals('JST'));
      expect(timezoneAbbreviations['America/New_York'], equals('EST'));
      expect(timezoneAbbreviations['America/Los_Angeles'], equals('PST'));
      expect(timezoneAbbreviations['Europe/London'], equals('GMT'));
    });

    test('아시아-태평양 시간대', () {
      expect(timezoneAbbreviations['Asia/Shanghai'], equals('CST'));
      expect(timezoneAbbreviations['Asia/Singapore'], equals('SGT'));
      expect(timezoneAbbreviations['Asia/Bangkok'], equals('ICT'));
    });

    test('유럽 시간대', () {
      expect(timezoneAbbreviations['Europe/Berlin'], equals('CET'));
      expect(timezoneAbbreviations['Europe/Paris'], equals('CET'));
      expect(timezoneAbbreviations['Europe/Moscow'], equals('MSK'));
    });

    test('남미 시간대', () {
      expect(timezoneAbbreviations['America/Sao_Paulo'], equals('BRT'));
      expect(
          timezoneAbbreviations['America/Argentina/Buenos_Aires'], equals('ART'));
    });
  });

  group('getTimeZonesByAbbreviation', () {
    test('KST로 검색하면 Asia/Seoul 반환', () {
      final zones = getTimeZonesByAbbreviation('KST');
      expect(zones, contains('Asia/Seoul'));
    });

    test('CET로 검색하면 여러 유럽 도시 반환', () {
      final zones = getTimeZonesByAbbreviation('CET');
      expect(zones, contains('Europe/Berlin'));
      expect(zones, contains('Europe/Paris'));
      expect(zones.length, greaterThanOrEqualTo(2));
    });

    test('존재하지 않는 약어는 빈 목록 반환', () {
      final zones = getTimeZonesByAbbreviation('INVALID');
      expect(zones, isEmpty);
    });

    test('HST는 여러 위치에서 사용', () {
      final zones = getTimeZonesByAbbreviation('HST');
      expect(zones, isNotEmpty);
    });
  });

  group('getSupportedAbbreviations', () {
    test('중복 없는 정렬된 약어 목록 반환', () {
      final abbrs = getSupportedAbbreviations();
      expect(abbrs, isNotEmpty);
      // 정렬 확인
      for (int i = 1; i < abbrs.length; i++) {
        expect(abbrs[i].compareTo(abbrs[i - 1]), greaterThanOrEqualTo(0));
      }
    });

    test('주요 약어가 포함되어 있음', () {
      final abbrs = getSupportedAbbreviations();
      expect(abbrs, contains('KST'));
      expect(abbrs, contains('JST'));
      expect(abbrs, contains('EST'));
      expect(abbrs, contains('GMT'));
    });

    test('중복이 없음', () {
      final abbrs = getSupportedAbbreviations();
      expect(abbrs.length, equals(abbrs.toSet().length));
    });
  });
}
