import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Pure helper utilities for device fingerprint generation.
///
/// All methods are static, pure, and have no side effects,
/// making them easy to unit test independently.
@visibleForTesting
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
