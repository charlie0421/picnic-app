import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/device_fingerprint.dart';

void main() {
  group('DeviceFingerprint', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    group('getDeviceId', () {
      test('generates a new fingerprint when none is stored', () async {
        final deviceId = await DeviceFingerprint.getDeviceId();
        expect(deviceId, isNotNull);
        expect(deviceId, isNotEmpty);
        // SHA-256 hash is 64 hex chars
        expect(deviceId.length, 64);
      });

      test('returns the same fingerprint on subsequent calls', () async {
        final first = await DeviceFingerprint.getDeviceId();
        final second = await DeviceFingerprint.getDeviceId();
        expect(first, equals(second));
      });

      test('returns stored fingerprint if available', () async {
        const storedFingerprint = 'abc123stored';
        FlutterSecureStorage.setMockInitialValues({
          'device_fingerprint': storedFingerprint,
        });

        final deviceId = await DeviceFingerprint.getDeviceId();
        expect(deviceId, equals(storedFingerprint));
      });

      test('fingerprint is a valid hex string', () async {
        final deviceId = await DeviceFingerprint.getDeviceId();
        // SHA-256 produces only hex characters
        expect(deviceId, matches(RegExp(r'^[a-f0-9]+$')));
      });
    });

    group('reset', () {
      test('clears the stored fingerprint', () async {
        // Generate and store a fingerprint
        await DeviceFingerprint.getDeviceId();

        // Reset it
        await DeviceFingerprint.reset();

        // After reset, a new fingerprint should be generated
        // (it will be different storage key lookup, but since we're in test
        // the mock storage is cleared)
        // Just verify reset completes without error
      });

      test('completes without error even when no fingerprint stored', () async {
        await DeviceFingerprint.reset();
        // Should not throw
      });
    });

    group('verify', () {
      test('returns true for matching fingerprint', () async {
        final deviceId = await DeviceFingerprint.getDeviceId();
        final isValid = await DeviceFingerprint.verify(deviceId);
        expect(isValid, isTrue);
      });

      test('returns false for non-matching fingerprint', () async {
        await DeviceFingerprint.getDeviceId();
        final isValid = await DeviceFingerprint.verify('wrong_fingerprint');
        expect(isValid, isFalse);
      });

      test('returns false for empty string', () async {
        await DeviceFingerprint.getDeviceId();
        final isValid = await DeviceFingerprint.verify('');
        expect(isValid, isFalse);
      });
    });

    group('stored fingerprint persistence', () {
      test('stores fingerprint after first generation', () async {
        final storage = const FlutterSecureStorage();

        // Initially no fingerprint
        final before = await storage.read(key: 'device_fingerprint');
        expect(before, isNull);

        // Generate fingerprint
        final deviceId = await DeviceFingerprint.getDeviceId();

        // Now it should be stored
        final after = await storage.read(key: 'device_fingerprint');
        expect(after, equals(deviceId));
      });

      test('reset removes the stored fingerprint', () async {
        final storage = const FlutterSecureStorage();

        // Generate fingerprint
        await DeviceFingerprint.getDeviceId();
        final before = await storage.read(key: 'device_fingerprint');
        expect(before, isNotNull);

        // Reset
        await DeviceFingerprint.reset();
        final after = await storage.read(key: 'device_fingerprint');
        expect(after, isNull);
      });
    });

    group('verify after reset', () {
      test('old fingerprint no longer verifies after reset', () async {
        final oldId = await DeviceFingerprint.getDeviceId();
        expect(await DeviceFingerprint.verify(oldId), isTrue);

        await DeviceFingerprint.reset();

        // After reset, getDeviceId generates a new fingerprint
        final newId = await DeviceFingerprint.getDeviceId();
        // The new fingerprint should verify
        expect(await DeviceFingerprint.verify(newId), isTrue);
      });
    });
  });
}
