import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/admob_test_device_policy.dart';

void main() {
  group('AdMobTestDevicePolicy.parse', () {
    test('splits a comma-separated value into ids preserving order', () {
      expect(
        AdMobTestDevicePolicy.parse('abc,def,ghi', isDebugMode: true),
        equals(['abc', 'def', 'ghi']),
      );
    });

    test('trims whitespace around each segment', () {
      expect(
        AdMobTestDevicePolicy.parse('  abc , def\t,\nghi  ', isDebugMode: true),
        equals(['abc', 'def', 'ghi']),
      );
    });

    test('drops empty segments (leading, trailing, consecutive commas)', () {
      expect(
        AdMobTestDevicePolicy.parse(',abc,,def, ,ghi,', isDebugMode: true),
        equals(['abc', 'def', 'ghi']),
      );
    });

    test('preserves the case of each id', () {
      expect(
        AdMobTestDevicePolicy.parse('AbC123,def456,GHI789', isDebugMode: true),
        equals(['AbC123', 'def456', 'GHI789']),
      );
    });

    test('keeps duplicates and does not reorder', () {
      expect(
        AdMobTestDevicePolicy.parse('b,a,b', isDebugMode: true),
        equals(['b', 'a', 'b']),
      );
    });

    test('returns null when the raw value is null', () {
      expect(AdMobTestDevicePolicy.parse(null, isDebugMode: true), isNull);
    });

    test('returns null when the raw value is absent (empty string)', () {
      expect(AdMobTestDevicePolicy.parse('', isDebugMode: true), isNull);
    });

    test('returns null when the raw value is blank', () {
      expect(
        AdMobTestDevicePolicy.parse('   \t\n ', isDebugMode: true),
        isNull,
      );
    });

    test('returns null when every segment is empty', () {
      expect(AdMobTestDevicePolicy.parse(', , ,', isDebugMode: true), isNull);
    });

    test('returns null in release mode even when ids are configured', () {
      expect(
        AdMobTestDevicePolicy.parse('abc,def', isDebugMode: false),
        isNull,
      );
    });

    test('returns null in release mode when the raw value is absent', () {
      expect(AdMobTestDevicePolicy.parse('', isDebugMode: false), isNull);
    });
  });

  group('AdMobTestDevicePolicy.testDeviceIds (build-time define)', () {
    const raw = String.fromEnvironment(AdMobTestDevicePolicy.environmentKey);

    test('reads the ADMOB_TEST_DEVICE_IDS define', () {
      expect(AdMobTestDevicePolicy.environmentKey, 'ADMOB_TEST_DEVICE_IDS');
    });

    test(
      'is null when the define is absent (default test run)',
      () {
        expect(AdMobTestDevicePolicy.testDeviceIds, isNull);
      },
      skip: raw.isNotEmpty
          ? 'ADMOB_TEST_DEVICE_IDS is set in this run; covered by wiring test'
          : false,
    );

    test('is the define parsed under kDebugMode', () {
      expect(
        AdMobTestDevicePolicy.testDeviceIds,
        equals(AdMobTestDevicePolicy.parse(raw, isDebugMode: kDebugMode)),
      );
    });
  });
}
