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

  /// 기기 식별자 가져오기.
  ///
  /// v2 정책: Android 의 OS-level build fingerprint 가 같은 모델+펌웨어
  /// 사용자 사이에 collision 을 일으켜 anti-abuse device cohort 가 FP 를
  /// 다발 → flutter_secure_storage 에 영구 저장된 UUID v4 로 전환.
  /// iOS 는 identifierForVendor 가 이미 vendor-unique 라 안전하지만,
  /// 일관성 + 단일 path 위해 platform 무관 UUID 사용.
  ///
  /// 강제 마이그레이션 (v2):
  ///   1. v2 키 (device_fingerprint_v2_uuid) 우선
  ///   2. legacy 키 (device_fingerprint) 가 있으면 무조건 새 UUID 발급 + 옛 키 제거.
  ///      build-based hash collision 즉시 해소.
  ///      trade-off: 차단된 farm user 도 새 UUID 받아 cohort 1회 흩어짐 (attendance 매일 1회라
  ///      다시 cohort 형성에 1-2일, farm candy 누적 미미).
  ///   3. 둘 다 없으면 신규 UUID v4 생성.
  static Future<String> getDeviceId() async {
    final uuid = await _storage.read(key: _uuidVersionKey);
    if (uuid != null && uuid.isNotEmpty) {
      return uuid;
    }

    final legacy = await _storage.read(key: _fingerprintKey);
    if (legacy != null && legacy.isNotEmpty) {
      // 강제 마이그레이션 — legacy hash 폐기, 신규 UUID.
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
