import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_platform/universal_platform.dart';

class DeviceFingerprint {
  static const _storage = FlutterSecureStorage();
  static const _fingerprintKey = 'device_fingerprint';
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 기기 식별자 가져오기
  static Future<String> getDeviceId() async {
    // 1. 저장된 지문이 있는지 확인
    String? storedFingerprint = await _storage.read(key: _fingerprintKey);
    if (storedFingerprint != null) {
      return storedFingerprint;
    }

    // 2. 새로운 지문 생성
    String fingerprint = await _generateFingerprint();

    // 3. 생성된 지문 저장
    await _storage.write(key: _fingerprintKey, value: fingerprint);

    return fingerprint;
  }

  /// 기기 지문 생성
  static Future<String> _generateFingerprint() async {
    Map<String, dynamic> deviceData = {};

    if (UniversalPlatform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      deviceData = {
        'id': androidInfo.id,
        'androidId': androidInfo.fingerprint,
        'brand': androidInfo.brand,
        'device': androidInfo.device,
        'hardware': androidInfo.hardware,
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'product': androidInfo.product,
        'bootloader': androidInfo.bootloader,
        'display': androidInfo.display,
        'fingerprint': androidInfo.fingerprint,
        'host': androidInfo.host,
      };
    } else if (UniversalPlatform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      deviceData = {
        'name': iosInfo.name,
        'model': iosInfo.model,
        'systemName': iosInfo.systemName,
        'systemVersion': iosInfo.systemVersion,
        'localizedModel': iosInfo.localizedModel,
        'identifierForVendor': iosInfo.identifierForVendor,
        'isPhysicalDevice': iosInfo.isPhysicalDevice,
      };
    }

    // 데이터를 정렬된 문자열로 변환
    final sortedData = Map.fromEntries(
        deviceData.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

    // SHA-256 해시 생성
    final dataString = json.encode(sortedData);
    final bytes = utf8.encode(dataString);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  /// 기기 지문 초기화
  static Future<void> reset() async {
    await _storage.delete(key: _fingerprintKey);
  }

  /// 기기 지문 검증
  static Future<bool> verify(String fingerprint) async {
    String currentFingerprint = await getDeviceId();
    return fingerprint == currentFingerprint;
  }
}
