import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:picnic_lib/core/utils/device_fingerprint_helper.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:uuid/uuid.dart';

class DeviceFingerprint {
  static const _storage = FlutterSecureStorage();
  static const _fingerprintKey = 'device_fingerprint';
  static const _uuidVersionKey = 'device_fingerprint_v2_uuid';
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const _uuidGen = Uuid();

  /// 기기 식별자.
  ///
  /// Android: SSAID(Settings.Secure.ANDROID_ID) 가 유효하면 그 해시를 우선 반환한다.
  ///   - SSAID 는 재설치/업데이트를 견디고(공장초기화만 리셋) 기종/펌웨어에서 파생되지
  ///     않아 collision 이 없다. stored UUID 보다 우선해야 기존 유저도 업그레이드된다.
  ///   - 해시는 저장하지 않는다(결정적이라 재계산해도 동일). SSAID 무효(에뮬레이터 등)면
  ///     기존 UUID 흐름으로 폴백한다.
  /// iOS: 기존 UUID 흐름(Keychain 이 재설치를 견딤).
  static Future<String> getDeviceId() async {
    if (UniversalPlatform.isAndroid) {
      final ssaid = await const AndroidId().getId();
      final norm = DeviceFingerprintHelper.normalizeAndroidId(ssaid);
      if (norm != null) {
        return DeviceFingerprintHelper.hashAndroidId(norm);
      }
      // SSAID 무효 → 아래 UUID 폴백
    }
    return _getOrCreateUuid();
  }

  /// v2 UUID 우선 → legacy 강제 마이그레이션 → fresh UUID.
  /// (Android SSAID 무효 시 폴백, iOS 기본 경로.)
  static Future<String> _getOrCreateUuid() async {
    final uuid = await _storage.read(key: _uuidVersionKey);
    if (uuid != null && uuid.isNotEmpty) {
      return uuid;
    }

    final legacy = await _storage.read(key: _fingerprintKey);
    if (legacy != null && legacy.isNotEmpty) {
      final migrated = _uuidGen.v4();
      await _storage.write(key: _uuidVersionKey, value: migrated);
      await _storage.delete(key: _fingerprintKey);
      return migrated;
    }

    final fresh = _uuidGen.v4();
    await _storage.write(key: _uuidVersionKey, value: fresh);
    return fresh;
  }

  /// 기기 지문 생성 (legacy path, v2 마이그레이션 이후 호출 안 됨).
  /// reset()/verify() 호환을 위해 유지.
  static Future<String> _generateFingerprint() async {
    Map<String, dynamic> deviceData = {};

    if (UniversalPlatform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      deviceData = DeviceFingerprintHelper.buildAndroidDeviceData(
        id: androidInfo.id,
        fingerprint: androidInfo.fingerprint,
        brand: androidInfo.brand,
        device: androidInfo.device,
        hardware: androidInfo.hardware,
        manufacturer: androidInfo.manufacturer,
        model: androidInfo.model,
        product: androidInfo.product,
        bootloader: androidInfo.bootloader,
        display: androidInfo.display,
        host: androidInfo.host,
      );
    } else if (UniversalPlatform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      deviceData = DeviceFingerprintHelper.buildIosDeviceData(
        name: iosInfo.name,
        model: iosInfo.model,
        systemName: iosInfo.systemName,
        systemVersion: iosInfo.systemVersion,
        localizedModel: iosInfo.localizedModel,
        identifierForVendor: iosInfo.identifierForVendor,
        isPhysicalDevice: iosInfo.isPhysicalDevice,
      );
    }

    return DeviceFingerprintHelper.generateHash(deviceData);
  }

  /// 기기 지문 초기화 — legacy 와 v2 키 모두 제거.
  /// SSAID 기반 id 는 저장값이 아니므로 reset 후에도 동일한 값이 반환된다
  /// (기기 신원은 "리셋" 대상이 아님 — 의도된 동작).
  static Future<void> reset() async {
    await _storage.delete(key: _fingerprintKey);
    await _storage.delete(key: _uuidVersionKey);
  }

  /// 기기 지문 검증
  static Future<bool> verify(String fingerprint) async {
    String currentFingerprint = await getDeviceId();
    return fingerprint == currentFingerprint;
  }
}
