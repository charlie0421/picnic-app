import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/device_fingerprint_helper.dart';

void main() {
  group('DeviceFingerprintHelper', () {
    group('sortDeviceData', () {
      test('sorts map entries alphabetically by key', () {
        final unsorted = {'zebra': 1, 'apple': 2, 'mango': 3};
        final sorted = DeviceFingerprintHelper.sortDeviceData(unsorted);

        expect(sorted.keys.toList(), ['apple', 'mango', 'zebra']);
        expect(sorted['apple'], 2);
        expect(sorted['mango'], 3);
        expect(sorted['zebra'], 1);
      });

      test('returns empty map for empty input', () {
        final sorted = DeviceFingerprintHelper.sortDeviceData({});
        expect(sorted, isEmpty);
      });

      test('handles single-entry map', () {
        final sorted = DeviceFingerprintHelper.sortDeviceData({'only': 'one'});
        expect(sorted.keys.toList(), ['only']);
        expect(sorted['only'], 'one');
      });

      test('handles already sorted map', () {
        final alreadySorted = {'a': 1, 'b': 2, 'c': 3};
        final sorted = DeviceFingerprintHelper.sortDeviceData(alreadySorted);
        expect(sorted.keys.toList(), ['a', 'b', 'c']);
      });

      test('preserves values of different types', () {
        final data = {
          'bool_val': true,
          'int_val': 42,
          'string_val': 'hello',
          'null_val': null,
          'double_val': 3.14,
        };
        final sorted = DeviceFingerprintHelper.sortDeviceData(data);

        expect(sorted['bool_val'], true);
        expect(sorted['int_val'], 42);
        expect(sorted['string_val'], 'hello');
        expect(sorted['null_val'], isNull);
        expect(sorted['double_val'], 3.14);
      });
    });

    group('generateHash', () {
      test('returns a 64-character hex string', () {
        final hash = DeviceFingerprintHelper.generateHash({'key': 'value'});
        expect(hash.length, 64);
        expect(hash, matches(RegExp(r'^[a-f0-9]{64}$')));
      });

      test('produces consistent hash for same input', () {
        final data = {'model': 'iPhone', 'os': 'iOS'};
        final hash1 = DeviceFingerprintHelper.generateHash(data);
        final hash2 = DeviceFingerprintHelper.generateHash(data);
        expect(hash1, equals(hash2));
      });

      test('produces same hash regardless of input key order', () {
        final data1 = {'b': 'second', 'a': 'first'};
        final data2 = {'a': 'first', 'b': 'second'};
        final hash1 = DeviceFingerprintHelper.generateHash(data1);
        final hash2 = DeviceFingerprintHelper.generateHash(data2);
        expect(hash1, equals(hash2));
      });

      test('produces different hash for different data', () {
        final hash1 =
            DeviceFingerprintHelper.generateHash({'device': 'iPhone'});
        final hash2 =
            DeviceFingerprintHelper.generateHash({'device': 'Pixel'});
        expect(hash1, isNot(equals(hash2)));
      });

      test('produces correct SHA-256 for known input', () {
        final data = {'key': 'value'};
        final sorted = DeviceFingerprintHelper.sortDeviceData(data);
        final expectedHash =
            sha256.convert(utf8.encode(json.encode(sorted))).toString();

        final hash = DeviceFingerprintHelper.generateHash(data);
        expect(hash, equals(expectedHash));
      });

      test('handles empty map', () {
        final hash = DeviceFingerprintHelper.generateHash({});
        expect(hash.length, 64);
        expect(hash, matches(RegExp(r'^[a-f0-9]{64}$')));
        // SHA-256 of "{}"
        final expected =
            sha256.convert(utf8.encode(json.encode({}))).toString();
        expect(hash, equals(expected));
      });

      test('handles map with null values', () {
        final hash = DeviceFingerprintHelper.generateHash(
            {'id': null, 'name': 'test'});
        expect(hash.length, 64);
      });
    });

    group('buildAndroidDeviceData', () {
      test('returns map with all expected keys', () {
        final data = DeviceFingerprintHelper.buildAndroidDeviceData(
          id: 'test_id',
          fingerprint: 'test_fingerprint',
          brand: 'Google',
          device: 'pixel',
          hardware: 'qcom',
          manufacturer: 'Google',
          model: 'Pixel 7',
          product: 'panther',
          bootloader: 'slider',
          display: 'TP1A.220624.014',
          host: 'abfarm',
        );

        expect(data, containsPair('id', 'test_id'));
        expect(data, containsPair('androidId', 'test_fingerprint'));
        expect(data, containsPair('brand', 'Google'));
        expect(data, containsPair('device', 'pixel'));
        expect(data, containsPair('hardware', 'qcom'));
        expect(data, containsPair('manufacturer', 'Google'));
        expect(data, containsPair('model', 'Pixel 7'));
        expect(data, containsPair('product', 'panther'));
        expect(data, containsPair('bootloader', 'slider'));
        expect(data, containsPair('display', 'TP1A.220624.014'));
        expect(data, containsPair('fingerprint', 'test_fingerprint'));
        expect(data, containsPair('host', 'abfarm'));
      });

      test('contains exactly 12 entries', () {
        final data = DeviceFingerprintHelper.buildAndroidDeviceData(
          id: 'id',
          fingerprint: 'fp',
          brand: 'b',
          device: 'd',
          hardware: 'h',
          manufacturer: 'm',
          model: 'mo',
          product: 'p',
          bootloader: 'bl',
          display: 'di',
          host: 'ho',
        );
        expect(data.length, 12);
      });

      test('sets androidId and fingerprint both from fingerprint param', () {
        final data = DeviceFingerprintHelper.buildAndroidDeviceData(
          id: 'id',
          fingerprint: 'shared_value',
          brand: 'b',
          device: 'd',
          hardware: 'h',
          manufacturer: 'm',
          model: 'mo',
          product: 'p',
          bootloader: 'bl',
          display: 'di',
          host: 'ho',
        );
        expect(data['androidId'], equals('shared_value'));
        expect(data['fingerprint'], equals('shared_value'));
      });
    });

    group('buildIosDeviceData', () {
      test('returns map with all expected keys', () {
        final data = DeviceFingerprintHelper.buildIosDeviceData(
          name: 'iPhone',
          model: 'iPhone14,2',
          systemName: 'iOS',
          systemVersion: '16.0',
          localizedModel: 'iPhone',
          identifierForVendor: 'ABC-123',
          isPhysicalDevice: true,
        );

        expect(data, containsPair('name', 'iPhone'));
        expect(data, containsPair('model', 'iPhone14,2'));
        expect(data, containsPair('systemName', 'iOS'));
        expect(data, containsPair('systemVersion', '16.0'));
        expect(data, containsPair('localizedModel', 'iPhone'));
        expect(data, containsPair('identifierForVendor', 'ABC-123'));
        expect(data, containsPair('isPhysicalDevice', true));
      });

      test('contains exactly 7 entries', () {
        final data = DeviceFingerprintHelper.buildIosDeviceData(
          name: 'n',
          model: 'm',
          systemName: 'sn',
          systemVersion: 'sv',
          localizedModel: 'lm',
          identifierForVendor: 'iv',
          isPhysicalDevice: false,
        );
        expect(data.length, 7);
      });

      test('handles null identifierForVendor', () {
        final data = DeviceFingerprintHelper.buildIosDeviceData(
          name: 'iPhone',
          model: 'iPhone14,2',
          systemName: 'iOS',
          systemVersion: '16.0',
          localizedModel: 'iPhone',
          identifierForVendor: null,
          isPhysicalDevice: true,
        );
        expect(data['identifierForVendor'], isNull);
      });

      test('handles isPhysicalDevice false (simulator)', () {
        final data = DeviceFingerprintHelper.buildIosDeviceData(
          name: 'iPhone Simulator',
          model: 'iPhone',
          systemName: 'iOS',
          systemVersion: '16.0',
          localizedModel: 'iPhone',
          identifierForVendor: null,
          isPhysicalDevice: false,
        );
        expect(data['isPhysicalDevice'], false);
      });
    });

    group('end-to-end: build data then hash', () {
      test('Android device data produces consistent hash', () {
        final data = DeviceFingerprintHelper.buildAndroidDeviceData(
          id: 'test_id',
          fingerprint: 'test_fp',
          brand: 'Samsung',
          device: 'starqltechn',
          hardware: 'qcom',
          manufacturer: 'samsung',
          model: 'SM-G9600',
          product: 'starqltezh',
          bootloader: 'G9600ZHS7DUA1',
          display: 'RP1A.200720.012',
          host: 'SWDD6808',
        );

        final hash1 = DeviceFingerprintHelper.generateHash(data);
        final hash2 = DeviceFingerprintHelper.generateHash(data);
        expect(hash1, equals(hash2));
        expect(hash1.length, 64);
      });

      test('iOS device data produces consistent hash', () {
        final data = DeviceFingerprintHelper.buildIosDeviceData(
          name: 'Charlie iPhone',
          model: 'iPhone',
          systemName: 'iOS',
          systemVersion: '17.0',
          localizedModel: 'iPhone',
          identifierForVendor: 'E621E1F8-C36C-495A-93FC-0C247A3E6E5F',
          isPhysicalDevice: true,
        );

        final hash1 = DeviceFingerprintHelper.generateHash(data);
        final hash2 = DeviceFingerprintHelper.generateHash(data);
        expect(hash1, equals(hash2));
        expect(hash1.length, 64);
      });

      test('different devices produce different hashes', () {
        final androidData = DeviceFingerprintHelper.buildAndroidDeviceData(
          id: 'id1',
          fingerprint: 'fp1',
          brand: 'Google',
          device: 'pixel',
          hardware: 'qcom',
          manufacturer: 'Google',
          model: 'Pixel 7',
          product: 'panther',
          bootloader: 'slider',
          display: 'TP1A',
          host: 'abfarm',
        );

        final iosData = DeviceFingerprintHelper.buildIosDeviceData(
          name: 'iPhone',
          model: 'iPhone14,2',
          systemName: 'iOS',
          systemVersion: '16.0',
          localizedModel: 'iPhone',
          identifierForVendor: 'ABC-123',
          isPhysicalDevice: true,
        );

        final androidHash = DeviceFingerprintHelper.generateHash(androidData);
        final iosHash = DeviceFingerprintHelper.generateHash(iosData);
        expect(androidHash, isNot(equals(iosHash)));
      });
    });
  });
}
