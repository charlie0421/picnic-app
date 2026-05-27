import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/device_manager_helper.dart';

void main() {
  group('DeviceManagerHelper.buildAndroidDeviceInfo', () {
    test('builds correct Android device info map', () {
      final result = DeviceManagerHelper.buildAndroidDeviceInfo(
        brand: 'Samsung',
        manufacturer: 'samsung',
        model: 'SM-G991B',
        device: 'o1s',
        product: 'o1sxxx',
        sdkInt: 33,
        release: '13',
        securityPatch: '2023-10-01',
        hardware: 'exynos2100',
        isPhysicalDevice: true,
        fingerprint: 'samsung/o1s/o1s:13/TP1A.220624.014',
      );

      expect(result['platform'], 'android');
      expect(result['brand'], 'Samsung');
      expect(result['manufacturer'], 'samsung');
      expect(result['model'], 'SM-G991B');
      expect(result['device'], 'o1s');
      expect(result['product'], 'o1sxxx');
      expect(result['hardware'], 'exynos2100');
      expect(result['is_physical_device'], true);
      expect(result['android_id'], contains('samsung'));
      expect(result['fingerprint'], contains('samsung'));

      final version = result['version'] as Map<String, dynamic>;
      expect(version['sdk'], 33);
      expect(version['release'], '13');
      expect(version['security_patch'], '2023-10-01');
    });

    test('handles null security patch', () {
      final result = DeviceManagerHelper.buildAndroidDeviceInfo(
        brand: 'Google',
        manufacturer: 'Google',
        model: 'Pixel 7',
        device: 'panther',
        product: 'panther',
        sdkInt: 34,
        release: '14',
        securityPatch: null,
        hardware: 'tensor',
        isPhysicalDevice: true,
        fingerprint: 'google/panther/panther:14',
      );

      final version = result['version'] as Map<String, dynamic>;
      expect(version['security_patch'], isNull);
    });

    test('handles emulator values', () {
      final result = DeviceManagerHelper.buildAndroidDeviceInfo(
        brand: 'google',
        manufacturer: 'Google',
        model: 'sdk_gphone64_arm64',
        device: 'emulator64_arm64',
        product: 'sdk_gphone64_arm64',
        sdkInt: 34,
        release: '14',
        securityPatch: null,
        hardware: 'ranchu',
        isPhysicalDevice: false,
        fingerprint: 'google/sdk_gphone64_arm64',
      );

      expect(result['platform'], 'android');
      expect(result['is_physical_device'], false);
      expect(result['hardware'], 'ranchu');
    });
  });

  group('DeviceManagerHelper.buildIOSDeviceInfo', () {
    test('builds correct iOS device info map', () {
      final result = DeviceManagerHelper.buildIOSDeviceInfo(
        name: 'iPhone',
        model: 'iPhone',
        systemName: 'iOS',
        systemVersion: '17.0',
        localizedModel: 'iPhone',
        identifierForVendor: 'ABC-123-DEF',
        isPhysicalDevice: true,
        machine: 'iPhone15,2',
        release: '23.0.0',
      );

      expect(result['platform'], 'ios');
      expect(result['name'], 'iPhone');
      expect(result['model'], 'iPhone');
      expect(result['system_name'], 'iOS');
      expect(result['system_version'], '17.0');
      expect(result['localized_model'], 'iPhone');
      expect(result['identifier_for_vendor'], 'ABC-123-DEF');
      expect(result['is_physical_device'], true);

      final utsname = result['utsname'] as Map<String, dynamic>;
      expect(utsname['machine'], 'iPhone15,2');
      expect(utsname['release'], '23.0.0');
    });

    test('handles null identifierForVendor', () {
      final result = DeviceManagerHelper.buildIOSDeviceInfo(
        name: 'iPhone Simulator',
        model: 'iPhone',
        systemName: 'iOS',
        systemVersion: '17.0',
        localizedModel: 'iPhone',
        identifierForVendor: null,
        isPhysicalDevice: false,
        machine: 'x86_64',
        release: '23.0.0',
      );

      expect(result['identifier_for_vendor'], isNull);
      expect(result['is_physical_device'], false);
    });
  });

  group('DeviceManagerHelper.buildWebDeviceInfo', () {
    test('builds correct web device info map', () {
      final result = DeviceManagerHelper.buildWebDeviceInfo(
        browserName: 'chrome',
        platformOs: 'MacIntel',
        userAgent: 'Mozilla/5.0 Chrome/120.0',
        language: 'ko',
      );

      expect(result['platform'], 'web');
      expect(result['browser'], 'chrome');
      expect(result['platform_os'], 'MacIntel');
      expect(result['user_agent'], contains('Chrome'));
      expect(result['language'], 'ko');
    });

    test('handles null optional fields', () {
      final result = DeviceManagerHelper.buildWebDeviceInfo(
        browserName: 'safari',
        platformOs: null,
        userAgent: null,
        language: null,
      );

      expect(result['platform'], 'web');
      expect(result['browser'], 'safari');
      expect(result['platform_os'], isNull);
      expect(result['user_agent'], isNull);
      expect(result['language'], isNull);
    });
  });

  group('DeviceManagerHelper.buildUnknownPlatformInfo', () {
    test('returns unknown platform map', () {
      final result = DeviceManagerHelper.buildUnknownPlatformInfo();
      expect(result, {'platform': 'unknown'});
      expect(result.length, 1);
    });
  });

  group('DeviceManagerHelper.buildErrorInfo', () {
    test('returns error map with message', () {
      final result = DeviceManagerHelper.buildErrorInfo('Something went wrong');
      expect(result['platform'], 'error');
      expect(result['error'], 'Something went wrong');
    });

    test('handles empty error message', () {
      final result = DeviceManagerHelper.buildErrorInfo('');
      expect(result['platform'], 'error');
      expect(result['error'], '');
    });
  });

  group('DeviceManagerHelper.buildRegistrationData', () {
    test('builds correct registration data', () {
      final deviceInfo = {'platform': 'android', 'model': 'Pixel'};
      final result = DeviceManagerHelper.buildRegistrationData(
        deviceId: 'device-123',
        userId: 'user-456',
        now: '2025-01-15T10:30:00Z',
        deviceInfo: deviceInfo,
        appVersion: '2.5.0',
        buildNumber: '100',
        lastIp: '192.168.1.1',
      );

      expect(result['device_id'], 'device-123');
      expect(result['user_id'], 'user-456');
      expect(result['last_seen'], '2025-01-15T10:30:00Z');
      expect(result['created_at'], '2025-01-15T10:30:00Z');
      expect(result['device_info'], deviceInfo);
      expect(result['app_version'], '2.5.0');
      expect(result['app_build_number'], '100');
      expect(result['last_ip'], '192.168.1.1');
      expect(result['last_updated'], '2025-01-15T10:30:00Z');
    });

    test('handles null IP address', () {
      final result = DeviceManagerHelper.buildRegistrationData(
        deviceId: 'device-789',
        userId: 'user-abc',
        now: '2025-06-01T00:00:00Z',
        deviceInfo: {'platform': 'ios'},
        appVersion: '1.0.0',
        buildNumber: '1',
        lastIp: null,
      );

      expect(result['last_ip'], isNull);
      expect(result['device_id'], 'device-789');
    });

    test('last_updated uses the same now value', () {
      const now = '2025-03-13T12:00:00Z';
      final result = DeviceManagerHelper.buildRegistrationData(
        deviceId: 'd',
        userId: 'u',
        now: now,
        deviceInfo: {},
        appVersion: '1.0',
        buildNumber: '1',
      );

      expect(result['last_seen'], now);
      expect(result['created_at'], now);
      expect(result['last_updated'], now);
    });
  });

  group('DeviceManagerHelper.determinePlatformType', () {
    test('returns android when isAndroid is true', () {
      final result = DeviceManagerHelper.determinePlatformType(
        isAndroid: true,
        isIOS: false,
        isWeb: false,
      );
      expect(result, 'android');
    });

    test('returns ios when isIOS is true', () {
      final result = DeviceManagerHelper.determinePlatformType(
        isAndroid: false,
        isIOS: true,
        isWeb: false,
      );
      expect(result, 'ios');
    });

    test('returns web when isWeb is true', () {
      final result = DeviceManagerHelper.determinePlatformType(
        isAndroid: false,
        isIOS: false,
        isWeb: true,
      );
      expect(result, 'web');
    });

    test('returns unknown when no platform is true', () {
      final result = DeviceManagerHelper.determinePlatformType(
        isAndroid: false,
        isIOS: false,
        isWeb: false,
      );
      expect(result, 'unknown');
    });

    test('android takes priority when multiple flags are true', () {
      final result = DeviceManagerHelper.determinePlatformType(
        isAndroid: true,
        isIOS: true,
        isWeb: true,
      );
      expect(result, 'android');
    });

    test('ios takes priority over web', () {
      final result = DeviceManagerHelper.determinePlatformType(
        isAndroid: false,
        isIOS: true,
        isWeb: true,
      );
      expect(result, 'ios');
    });
  });

  group('DeviceManagerHelper.isBannedFromResult', () {
    test('null 결과 → ban 아님', () {
      final result = DeviceManagerHelper.isBannedFromResult(null);
      expect(result, isFalse);
    });

    test('unbanned_at 가 null 인 active ban row → ban 임', () {
      final result = DeviceManagerHelper.isBannedFromResult(
        {'device_id': 'abc', 'reason': 'abuse', 'unbanned_at': null},
      );
      expect(result, isTrue);
    });

    test('unbanned_at 가 채워진 row (soft unban) → ban 아님 — soft unban 인식', () {
      final result = DeviceManagerHelper.isBannedFromResult({
        'device_id': 'abc',
        'reason': 'abuse',
        'unbanned_at': '2026-05-26T09:03:57.857821+00:00',
      });
      expect(result, isFalse);
    });

    test('unbanned_at 키 없는 empty / 옛 row → ban 으로 처리 (보수적)', () {
      // 기본 schema 에서는 항상 unbanned_at 컬럼 존재. 누락은 예상치 못한 케이스.
      // null/missing 동등 처리: row 가 있으면 ban (보수적).
      final result = DeviceManagerHelper.isBannedFromResult({
        'device_id': 'abc',
      });
      expect(result, isTrue);
    });
  });

  group('DeviceManagerHelper.buildLastSeenUpdate', () {
    test('builds update map with last_seen key', () {
      final result = DeviceManagerHelper.buildLastSeenUpdate(
        '2026-03-13T10:00:00Z',
      );
      expect(result, {'last_seen': '2026-03-13T10:00:00Z'});
    });

    test('contains only one key', () {
      final result = DeviceManagerHelper.buildLastSeenUpdate(
        '2026-01-01T00:00:00Z',
      );
      expect(result.length, 1);
      expect(result.containsKey('last_seen'), isTrue);
    });

    test('handles empty string timestamp', () {
      final result = DeviceManagerHelper.buildLastSeenUpdate('');
      expect(result['last_seen'], '');
    });
  });

  group('DeviceManagerHelper.parseIpFromResponse', () {
    test('parses IP from valid response map', () {
      final result = DeviceManagerHelper.parseIpFromResponse(
        {'ip': '192.168.1.1'},
      );
      expect(result, '192.168.1.1');
    });

    test('returns null when ip key is missing', () {
      final result = DeviceManagerHelper.parseIpFromResponse(
        {'address': '10.0.0.1'},
      );
      expect(result, isNull);
    });

    test('returns null when response is null', () {
      final result = DeviceManagerHelper.parseIpFromResponse(null);
      expect(result, isNull);
    });

    test('returns null when response is not a Map', () {
      final result = DeviceManagerHelper.parseIpFromResponse('not a map');
      expect(result, isNull);
    });

    test('returns null when response is a list', () {
      final result = DeviceManagerHelper.parseIpFromResponse([1, 2, 3]);
      expect(result, isNull);
    });

    test('returns null when ip value is null in map', () {
      final result = DeviceManagerHelper.parseIpFromResponse({'ip': null});
      expect(result, isNull);
    });

    test('parses IPv6 address', () {
      final result = DeviceManagerHelper.parseIpFromResponse(
        {'ip': '::1'},
      );
      expect(result, '::1');
    });

    test('handles map with extra fields', () {
      final result = DeviceManagerHelper.parseIpFromResponse(
        {'ip': '10.0.0.1', 'country': 'KR', 'region': 'Seoul'},
      );
      expect(result, '10.0.0.1');
    });
  });
}
