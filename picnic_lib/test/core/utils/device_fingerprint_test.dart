import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/device_fingerprint.dart';

const _uuidRegex = r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

void main() {
  group('DeviceFingerprint', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    group('getDeviceId — v2 (UUID)', () {
      test('신규 설치 시 UUID v4 생성', () async {
        final deviceId = await DeviceFingerprint.getDeviceId();
        expect(deviceId, isNotNull);
        expect(deviceId, isNotEmpty);
        expect(deviceId, matches(RegExp(_uuidRegex)));
      });

      test('재호출 시 동일 UUID 반환 (persistence)', () async {
        final first = await DeviceFingerprint.getDeviceId();
        final second = await DeviceFingerprint.getDeviceId();
        expect(first, equals(second));
      });

      test('v2 키 저장 확인', () async {
        await DeviceFingerprint.getDeviceId();
        const storage = FlutterSecureStorage();
        final stored = await storage.read(key: 'device_fingerprint_v2_uuid');
        expect(stored, isNotNull);
        expect(stored, matches(RegExp(_uuidRegex)));
      });
    });

    group('getDeviceId — v1 legacy fallback', () {
      test('legacy 키만 있으면 그 값 반환 (점진 마이그레이션)', () async {
        const legacyHash =
            'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
        FlutterSecureStorage.setMockInitialValues({
          'device_fingerprint': legacyHash,
        });

        final deviceId = await DeviceFingerprint.getDeviceId();
        expect(deviceId, equals(legacyHash));
      });

      test('v2 + legacy 둘 다 있으면 v2 우선', () async {
        FlutterSecureStorage.setMockInitialValues({
          'device_fingerprint': 'legacy_value',
          'device_fingerprint_v2_uuid': '11111111-2222-4333-a444-555555555555',
        });

        final deviceId = await DeviceFingerprint.getDeviceId();
        expect(deviceId, equals('11111111-2222-4333-a444-555555555555'));
      });
    });

    group('reset', () {
      test('v2 와 legacy 키 둘 다 제거', () async {
        FlutterSecureStorage.setMockInitialValues({
          'device_fingerprint': 'legacy_value',
          'device_fingerprint_v2_uuid': '11111111-2222-4333-a444-555555555555',
        });
        const storage = FlutterSecureStorage();

        await DeviceFingerprint.reset();

        expect(await storage.read(key: 'device_fingerprint'), isNull);
        expect(await storage.read(key: 'device_fingerprint_v2_uuid'), isNull);
      });

      test('저장된 값 없을 때 reset 도 정상 완료', () async {
        await DeviceFingerprint.reset();
      });
    });

    group('verify', () {
      test('현재 deviceId 와 같으면 true', () async {
        final deviceId = await DeviceFingerprint.getDeviceId();
        final isValid = await DeviceFingerprint.verify(deviceId);
        expect(isValid, isTrue);
      });

      test('다른 값이면 false', () async {
        await DeviceFingerprint.getDeviceId();
        final isValid = await DeviceFingerprint.verify('wrong_value');
        expect(isValid, isFalse);
      });

      test('빈 문자열이면 false', () async {
        await DeviceFingerprint.getDeviceId();
        final isValid = await DeviceFingerprint.verify('');
        expect(isValid, isFalse);
      });
    });

    group('reset → getDeviceId 재생성', () {
      test('reset 후 새 UUID 발급', () async {
        final oldId = await DeviceFingerprint.getDeviceId();
        await DeviceFingerprint.reset();

        final newId = await DeviceFingerprint.getDeviceId();
        expect(newId, isNotEmpty);
        expect(newId, matches(RegExp(_uuidRegex)));
        expect(newId, isNot(equals(oldId)));
      });
    });
  });
}
