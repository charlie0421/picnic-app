import 'package:flutter/foundation.dart';

/// Pure logic helpers extracted from [DeviceManager] for testability.
///
/// These methods build device info maps from raw data without
/// requiring native plugin calls.
class DeviceManagerHelper {
  /// Build an Android device info map from raw values.
  @visibleForTesting
  static Map<String, dynamic> buildAndroidDeviceInfo({
    required String brand,
    required String manufacturer,
    required String model,
    required String device,
    required String product,
    required int sdkInt,
    required String release,
    String? securityPatch,
    required String hardware,
    required bool isPhysicalDevice,
    required String fingerprint,
  }) {
    return {
      'platform': 'android',
      'brand': brand,
      'manufacturer': manufacturer,
      'model': model,
      'device': device,
      'product': product,
      'version': {
        'sdk': sdkInt,
        'release': release,
        'security_patch': securityPatch,
      },
      'hardware': hardware,
      'is_physical_device': isPhysicalDevice,
      'android_id': fingerprint,
      'fingerprint': fingerprint,
    };
  }

  /// Build an iOS device info map from raw values.
  @visibleForTesting
  static Map<String, dynamic> buildIOSDeviceInfo({
    required String name,
    required String model,
    required String systemName,
    required String systemVersion,
    required String localizedModel,
    String? identifierForVendor,
    required bool isPhysicalDevice,
    required String machine,
    required String release,
  }) {
    return {
      'platform': 'ios',
      'name': name,
      'model': model,
      'system_name': systemName,
      'system_version': systemVersion,
      'localized_model': localizedModel,
      'identifier_for_vendor': identifierForVendor,
      'is_physical_device': isPhysicalDevice,
      'utsname': {
        'machine': machine,
        'release': release,
      },
    };
  }

  /// Build a web browser info map from raw values.
  @visibleForTesting
  static Map<String, dynamic> buildWebDeviceInfo({
    required String browserName,
    String? platformOs,
    String? userAgent,
    String? language,
  }) {
    return {
      'platform': 'web',
      'browser': browserName,
      'platform_os': platformOs,
      'user_agent': userAgent,
      'language': language,
    };
  }

  /// Build the unknown platform fallback map.
  @visibleForTesting
  static Map<String, dynamic> buildUnknownPlatformInfo() {
    return {'platform': 'unknown'};
  }

  /// Build the error fallback map.
  @visibleForTesting
  static Map<String, dynamic> buildErrorInfo(String errorMessage) {
    return {'platform': 'error', 'error': errorMessage};
  }

  /// Build the device registration upsert data.
  @visibleForTesting
  static Map<String, dynamic> buildRegistrationData({
    required String deviceId,
    required String userId,
    required String now,
    required Map<String, dynamic> deviceInfo,
    required String appVersion,
    required String buildNumber,
    String? lastIp,
  }) {
    return {
      'device_id': deviceId,
      'user_id': userId,
      'last_seen': now,
      'created_at': now,
      'device_info': deviceInfo,
      'app_version': appVersion,
      'app_build_number': buildNumber,
      'last_ip': lastIp,
      'last_updated': now,
    };
  }
}
