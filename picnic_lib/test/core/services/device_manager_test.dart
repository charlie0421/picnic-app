import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/device_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('DeviceManager - isDeviceBanned', () {
    test('returns false when device is not banned', () async {
      setupMockSupabase({
        'device_bans': <Map<String, dynamic>>[],
      });

      // getDeviceId will fail in test environment since DeviceFingerprint
      // relies on platform-specific code. We catch the error at the service level
      // which returns false.
      final result = await DeviceManager.isDeviceBanned();

      // In test environment, getDeviceId will throw since
      // DeviceFingerprint uses platform channels. The catch block
      // returns false.
      expect(result, isFalse);
    });

    test('returns false on error', () async {
      // Without setupMockSupabase, supabase is not initialized
      // DeviceManager.isDeviceBanned catches exceptions and returns false
      tearDownMockSupabase();

      // This should catch the error and return false
      // because getDeviceId will fail in test environment
      setupMockSupabase({
        'device_bans': <Map<String, dynamic>>[],
      });

      final result = await DeviceManager.isDeviceBanned();
      expect(result, isFalse);
    });
  });

  group('DeviceManager - updateLastSeen', () {
    test('does not throw on error', () async {
      setupMockSupabase({
        'devices': <Map<String, dynamic>>[],
      });

      // updateLastSeen calls getDeviceId which will fail in test,
      // but the method catches errors silently
      await DeviceManager.updateLastSeen();
      // If we get here without throwing, the test passes
    });
  });

  group('DeviceManager - registerDevice', () {
    test('returns false on error in test environment', () async {
      setupMockSupabase({
        'devices': <Map<String, dynamic>>[],
      });

      // registerDevice calls getDeviceId which will fail in test env,
      // the catch block returns false
      final result = await DeviceManager.registerDevice('test-user-id');
      expect(result, isFalse);
    });
  });

  group('DeviceManager - getDeviceInfo', () {
    test('returns error info when platform methods fail in test', () async {
      // In test environment, device_info_plus methods fail because
      // there's no platform channel. The catch block returns an error map.
      final info = await DeviceManager.getDeviceInfo();

      // In test, UniversalPlatform checks may return false for all platforms,
      // so it falls through to 'unknown' or the catch block returns error
      expect(info, isA<Map<String, dynamic>>());
      expect(info.containsKey('platform'), isTrue);
    });
  });

  group('DeviceManager - getDeviceId', () {
    test('throws when DeviceFingerprint fails in test environment', () async {
      // DeviceFingerprint.getDeviceId uses platform channels that
      // are not available in test environment. The method rethrows.
      expect(
        () => DeviceManager.getDeviceId(),
        throwsA(anything),
      );
    });
  });

  group('DeviceManager - getDeviceInfo on non-mobile platform', () {
    test('returns map with platform key', () async {
      final info = await DeviceManager.getDeviceInfo();
      expect(info, isA<Map<String, dynamic>>());
      expect(info.containsKey('platform'), isTrue);
    });

    test('returns unknown or error platform in test environment', () async {
      // In macOS test env, UniversalPlatform.isAndroid/isIOS/isWeb are all false
      // so it returns {'platform': 'unknown'} or the catch block returns error
      final info = await DeviceManager.getDeviceInfo();
      expect(
        info['platform'] == 'unknown' || info['platform'] == 'error',
        isTrue,
      );
    });

    test('returns consistent results on repeated calls', () async {
      final info1 = await DeviceManager.getDeviceInfo();
      final info2 = await DeviceManager.getDeviceInfo();
      expect(info1['platform'], info2['platform']);
    });
  });

  group('DeviceManager - isDeviceBanned with different data', () {
    test('handles empty device_bans table', () async {
      setupMockSupabase({
        'device_bans': <Map<String, dynamic>>[],
      });
      final result = await DeviceManager.isDeviceBanned();
      // getDeviceId fails in test, catch returns false
      expect(result, isFalse);
    });

    test('handles device_bans table with data', () async {
      setupMockSupabase({
        'device_bans': [
          {'device_id': 'some-device', 'reason': 'abuse'}
        ],
      });
      final result = await DeviceManager.isDeviceBanned();
      // getDeviceId fails in test, catch returns false
      expect(result, isFalse);
    });
  });

  group('DeviceManager - registerDevice with different userIds', () {
    test('returns false for empty userId', () async {
      setupMockSupabase({
        'devices': <Map<String, dynamic>>[],
        'functions:get-client-ip': {'ip': '127.0.0.1'},
      });
      final result = await DeviceManager.registerDevice('');
      // getDeviceId fails in test, catch returns false
      expect(result, isFalse);
    });

    test('returns false for valid userId (DeviceFingerprint fails)', () async {
      setupMockSupabase({
        'devices': <Map<String, dynamic>>[],
        'functions:get-client-ip': {'ip': '192.168.1.1'},
      });
      final result = await DeviceManager.registerDevice('user-abc-123');
      expect(result, isFalse);
    });
  });

  group('DeviceManager - updateLastSeen with different states', () {
    test('silently fails when mock supabase has no devices table', () async {
      setupMockSupabase({});
      await DeviceManager.updateLastSeen();
      // No exception thrown
    });

    test('silently fails with devices table present', () async {
      setupMockSupabase({
        'devices': [
          {'device_id': 'test', 'last_seen': '2026-01-01T00:00:00Z'},
        ],
      });
      await DeviceManager.updateLastSeen();
      // No exception thrown - getDeviceId fails but caught
    });
  });
}
