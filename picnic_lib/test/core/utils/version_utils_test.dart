import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/version_utils.dart';

void main() {
  group('VersionUtils.parseMajorVersion', () {
    test('parses standard version string', () {
      expect(VersionUtils.parseMajorVersion('26.2'), 26);
    });

    test('parses single number version', () {
      expect(VersionUtils.parseMajorVersion('18'), 18);
    });

    test('parses version with multiple dots', () {
      expect(VersionUtils.parseMajorVersion('15.4.1'), 15);
    });

    test('returns 0 for empty string', () {
      expect(VersionUtils.parseMajorVersion(''), 0);
    });

    test('returns 0 for non-numeric string', () {
      expect(VersionUtils.parseMajorVersion('abc'), 0);
    });

    test('parses version starting with zero', () {
      expect(VersionUtils.parseMajorVersion('0.1'), 0);
    });

    test('parses large major version', () {
      expect(VersionUtils.parseMajorVersion('100.0'), 100);
    });

    test('returns 0 for dot-only string', () {
      expect(VersionUtils.parseMajorVersion('.'), 0);
    });

    test('returns 0 for leading dot', () {
      expect(VersionUtils.parseMajorVersion('.5'), 0);
    });
  });

  group('VersionUtils.isIOSVersionAtLeast26', () {
    test('returns true for version 26', () {
      expect(VersionUtils.isIOSVersionAtLeast26('26.0'), isTrue);
    });

    test('returns true for version above 26', () {
      expect(VersionUtils.isIOSVersionAtLeast26('27.1'), isTrue);
    });

    test('returns false for version 25', () {
      expect(VersionUtils.isIOSVersionAtLeast26('25.9'), isFalse);
    });

    test('returns false for version 18', () {
      expect(VersionUtils.isIOSVersionAtLeast26('18.4'), isFalse);
    });

    test('returns false for empty string', () {
      expect(VersionUtils.isIOSVersionAtLeast26(''), isFalse);
    });

    test('returns true for exactly 26 no minor', () {
      expect(VersionUtils.isIOSVersionAtLeast26('26'), isTrue);
    });
  });

  group('VersionUtils.isIOSVersionAtLeast', () {
    test('returns true when version equals minimum', () {
      expect(VersionUtils.isIOSVersionAtLeast('18.0', 18), isTrue);
    });

    test('returns true when version exceeds minimum', () {
      expect(VersionUtils.isIOSVersionAtLeast('20.1', 18), isTrue);
    });

    test('returns false when version below minimum', () {
      expect(VersionUtils.isIOSVersionAtLeast('17.9', 18), isFalse);
    });

    test('returns false for empty string with any minimum', () {
      expect(VersionUtils.isIOSVersionAtLeast('', 1), isFalse);
    });

    test('returns true for any version when minimum is 0', () {
      expect(VersionUtils.isIOSVersionAtLeast('0.0', 0), isTrue);
    });

    test('returns false for non-numeric with positive minimum', () {
      expect(VersionUtils.isIOSVersionAtLeast('abc', 1), isFalse);
    });
  });
}
