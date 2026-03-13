import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/services/device_manager_helper.dart';
import 'package:picnic_lib/core/utils/device_fingerprint.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:universal_platform/universal_platform.dart';

class DeviceManager {
  static final _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    return _getDeviceInfo();
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (UniversalPlatform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return DeviceManagerHelper.buildAndroidDeviceInfo(
          brand: androidInfo.brand,
          manufacturer: androidInfo.manufacturer,
          model: androidInfo.model,
          device: androidInfo.device,
          product: androidInfo.product,
          sdkInt: androidInfo.version.sdkInt,
          release: androidInfo.version.release,
          securityPatch: androidInfo.version.securityPatch,
          hardware: androidInfo.hardware,
          isPhysicalDevice: androidInfo.isPhysicalDevice,
          fingerprint: androidInfo.fingerprint,
        );
      }

      if (UniversalPlatform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return DeviceManagerHelper.buildIOSDeviceInfo(
          name: iosInfo.name,
          model: iosInfo.model,
          systemName: iosInfo.systemName,
          systemVersion: iosInfo.systemVersion,
          localizedModel: iosInfo.localizedModel,
          identifierForVendor: iosInfo.identifierForVendor,
          isPhysicalDevice: iosInfo.isPhysicalDevice,
          machine: iosInfo.utsname.machine,
          release: iosInfo.utsname.release,
        );
      }

      if (UniversalPlatform.isWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return DeviceManagerHelper.buildWebDeviceInfo(
          browserName: webInfo.browserName.name,
          platformOs: webInfo.platform,
          userAgent: webInfo.userAgent,
          language: webInfo.language,
        );
      }

      return DeviceManagerHelper.buildUnknownPlatformInfo();
    } catch (e, s) {
      logger.e('Error getting device info', error: e, stackTrace: s);
      return DeviceManagerHelper.buildErrorInfo(e.toString());
    }
  }

  static Future<String> getDeviceId() async {
    try {
      final deviceId = await DeviceFingerprint.getDeviceId();
      return deviceId;
    } catch (e, s) {
      logger.e('Error getting device ID', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 디바이스 차단 상태 확인
  static Future<bool> isDeviceBanned() async {
    try {
      final deviceId = await DeviceFingerprint.getDeviceId();
      logger.d('Checking device ban status for $deviceId');
      final result = await supabase
          .from('device_bans')
          .select()
          .eq('device_id', deviceId)
          .maybeSingle();
      return DeviceManagerHelper.isBannedFromResult(result);
    } catch (e, s) {
      logger.e('Error checking device ban status', error: e, stackTrace: s);
      return false;
    }
  }

  static Future<void> updateLastSeen() async {
    try {
      final deviceId = await getDeviceId();
      final now = DateTime.now().toIso8601String();

      await supabase
          .from('devices')
          .update(DeviceManagerHelper.buildLastSeenUpdate(now))
          .eq('device_id', deviceId);
    } catch (e, s) {
      logger.e('Error updating last seen', error: e, stackTrace: s);
    }
  }

  /// 디바이스 등록 또는 업데이트
  static Future<bool> registerDevice(String userId) async {
    try {
      final deviceId = await getDeviceId();
      final deviceInfo = await _getDeviceInfo();
      final now = DateTime.now().toIso8601String();
      final packageInfo = await PackageInfo.fromPlatform();

      final registrationData = DeviceManagerHelper.buildRegistrationData(
        deviceId: deviceId,
        userId: userId,
        now: now,
        deviceInfo: deviceInfo,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        lastIp: await _getIpAddress(),
      );

      await supabase.from('devices').upsert(
        registrationData,
        onConflict: 'device_id',
      );

      return true;
    } catch (e, s) {
      logger.e('Error registering device', error: e, stackTrace: s);
      return false;
    }
  }

  static Future<String?> _getIpAddress() async {
    try {
      final response = await supabase.functions.invoke('get-client-ip');
      return DeviceManagerHelper.parseIpFromResponse(response.data);
    } catch (e, s) {
      logger.e('Error getting IP address', error: e, stackTrace: s);
      return null;
    }
  }
}
