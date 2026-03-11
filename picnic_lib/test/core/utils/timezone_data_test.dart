import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/timezone_data.dart';

void main() {
  group('timezoneAbbreviations', () {
    test('contains Asia/Seoul as KST', () {
      expect(timezoneAbbreviations['Asia/Seoul'], 'KST');
    });

    test('contains Asia/Tokyo as JST', () {
      expect(timezoneAbbreviations['Asia/Tokyo'], 'JST');
    });

    test('contains America/New_York as EST', () {
      expect(timezoneAbbreviations['America/New_York'], 'EST');
    });

    test('contains Europe/London as GMT', () {
      expect(timezoneAbbreviations['Europe/London'], 'GMT');
    });

    test('has all expected entries', () {
      expect(timezoneAbbreviations.length, greaterThanOrEqualTo(40));
    });
  });

  group('getTimeZonesByAbbreviation', () {
    test('returns zones for KST', () {
      final zones = getTimeZonesByAbbreviation('KST');
      expect(zones, contains('Asia/Seoul'));
    });

    test('returns zones for CET', () {
      final zones = getTimeZonesByAbbreviation('CET');
      expect(zones, contains('Europe/Berlin'));
      expect(zones, contains('Europe/Paris'));
      expect(zones.length, greaterThanOrEqualTo(4));
    });

    test('returns empty for unknown abbreviation', () {
      final zones = getTimeZonesByAbbreviation('UNKNOWN');
      expect(zones, isEmpty);
    });

    test('returns zones for EST', () {
      final zones = getTimeZonesByAbbreviation('EST');
      expect(zones, contains('America/New_York'));
      expect(zones, contains('America/Toronto'));
    });
  });

  group('getSupportedAbbreviations', () {
    test('returns sorted unique abbreviations', () {
      final abbreviations = getSupportedAbbreviations();
      expect(abbreviations, isNotEmpty);
      expect(abbreviations, contains('KST'));
      expect(abbreviations, contains('JST'));
      expect(abbreviations, contains('EST'));
      expect(abbreviations, contains('GMT'));
    });

    test('is sorted', () {
      final abbreviations = getSupportedAbbreviations();
      for (int i = 1; i < abbreviations.length; i++) {
        expect(abbreviations[i].compareTo(abbreviations[i - 1]),
            greaterThanOrEqualTo(0));
      }
    });

    test('contains no duplicates', () {
      final abbreviations = getSupportedAbbreviations();
      expect(abbreviations.length, abbreviations.toSet().length);
    });
  });
}
