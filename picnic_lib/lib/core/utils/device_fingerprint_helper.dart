import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Pure helper utilities for device fingerprint generation.
///
/// All methods are static, pure, and have no side effects,
/// making them easy to unit test independently.
class DeviceFingerprintHelper {
  /// Normalizes device data by sorting entries alphabetically by key.
  ///
  /// Returns a new [Map] with the same entries sorted by key.
  static Map<String, dynamic> sortDeviceData(Map<String, dynamic> data) {
    return Map.fromEntries(
      data.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Generates a SHA-256 hash string from a device data map.
  ///
  /// The data is first sorted by key, then JSON-encoded, then hashed.
  /// Returns a 64-character lowercase hex string.
  static String generateHash(Map<String, dynamic> deviceData) {
    final sortedData = sortDeviceData(deviceData);
    final dataString = json.encode(sortedData);
    final bytes = utf8.encode(dataString);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// 알려진 불량 SSAID 상수 — 일부 구형 단말이 하드코딩 반환하던 값.
  static const String _badAndroidId = '9774d56d682e549c';
  static final RegExp _hexOnly = RegExp(r'^[0-9a-f]+$');

  /// SSAID(Settings.Secure.ANDROID_ID) 를 검증·정규화한다.
  ///
  /// 규칙: trim + 소문자화 → 빈값 / 불량상수 / 비-hex / 8자 미만은 무효(null).
  /// SSAID 는 통상 16자 hex 지만 leading-zero 등으로 짧게 렌더될 수 있어
  /// 상한은 강제하지 않는다(유효값 over-reject 방지).
  static String? normalizeAndroidId(String? ssaid) {
    if (ssaid == null) return null;
    final v = ssaid.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v == _badAndroidId) return null;
    if (v.length < 8) return null;
    if (!_hexOnly.hasMatch(v)) return null;
    return v;
  }

  /// device_hash 네임스페이스 prefix — raw SSAID 역산/타시스템 상관 방지.
  static const String _androidIdNamespace = 'picnic.android_id:';

  /// 정규화된 SSAID 를 네임스페이스와 함께 SHA-256 한 64-hex 문자열 반환.
  /// 입력은 [normalizeAndroidId] 를 통과한 값이어야 한다.
  static String hashAndroidId(String normalizedSsaid) {
    final bytes = utf8.encode('$_androidIdNamespace$normalizedSsaid');
    return sha256.convert(bytes).toString();
  }

  /// Extracts relevant Android device properties into a map.
  ///
  /// Accepts individual property values to remain pure (no dependency
  /// on AndroidDeviceInfo).
  static Map<String, dynamic> buildAndroidDeviceData({
    required String id,
    required String fingerprint,
    required String brand,
    required String device,
    required String hardware,
    required String manufacturer,
    required String model,
    required String product,
    required String bootloader,
    required String display,
    required String host,
  }) {
    return {
      'id': id,
      'androidId': fingerprint,
      'brand': brand,
      'device': device,
      'hardware': hardware,
      'manufacturer': manufacturer,
      'model': model,
      'product': product,
      'bootloader': bootloader,
      'display': display,
      'fingerprint': fingerprint,
      'host': host,
    };
  }

  /// Extracts relevant iOS device properties into a map.
  ///
  /// Accepts individual property values to remain pure (no dependency
  /// on IosDeviceInfo).
  static Map<String, dynamic> buildIosDeviceData({
    required String name,
    required String model,
    required String systemName,
    required String systemVersion,
    required String localizedModel,
    required String? identifierForVendor,
    required bool isPhysicalDevice,
  }) {
    return {
      'name': name,
      'model': model,
      'systemName': systemName,
      'systemVersion': systemVersion,
      'localizedModel': localizedModel,
      'identifierForVendor': identifierForVendor,
      'isPhysicalDevice': isPhysicalDevice,
    };
  }
}
