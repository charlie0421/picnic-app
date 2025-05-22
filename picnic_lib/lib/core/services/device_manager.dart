import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/core/utils/device_fingerprint.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:universal_platform/universal_platform.dart';

class DeviceManager {
  static final _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (UniversalPlatform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'device': androidInfo.device,
          'product': androidInfo.product,
          'version': {
            'sdk': androidInfo.version.sdkInt,
            'release': androidInfo.version.release,
            'security_patch': androidInfo.version.securityPatch,
          },
          'hardware': androidInfo.hardware,
          'is_physical_device': androidInfo.isPhysicalDevice,
          'android_id': androidInfo.fingerprint,
          'fingerprint': androidInfo.fingerprint,
        };
      }

      if (UniversalPlatform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
          'localized_model': iosInfo.localizedModel,
          'identifier_for_vendor': iosInfo.identifierForVendor,
          'is_physical_device': iosInfo.isPhysicalDevice,
          'utsname': {
            'machine': iosInfo.utsname.machine,
            'release': iosInfo.utsname.release,
          }
        };
      }

      if (UniversalPlatform.isWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return {
          'platform': 'web',
          'browser': webInfo.browserName.name,
          'platform_os': webInfo.platform,
          'user_agent': webInfo.userAgent,
          'language': webInfo.language,
        };
      }

      return {'platform': 'unknown'};
    } catch (e, s) {
      logger.e('Error getting device info', error: e, stackTrace: s);
      return {'platform': 'error', 'error': e.toString()};
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
      return result != null;
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
          .update({'last_seen': now}).eq('device_id', deviceId);
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

      await supabase.from('devices').upsert({
        'device_id': deviceId,
        'user_id': userId,
        'last_seen': now,
        'created_at': now,
        'device_info': deviceInfo,
        'app_version': packageInfo.version, // 앱 버전 정보 추가
        'app_build_number': packageInfo.buildNumber, // 빌드 번호 추가
        'last_ip': await _getIpAddress(), // IP 주소 추가 (선택사항)
        'last_updated': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id');

      return true;
    } catch (e, s) {
      logger.e('Error registering device', error: e, stackTrace: s);
      return false;
    }
  }

  static Future<String?> _getIpAddress() async {
    try {
      final response = await supabase.functions.invoke('get-client-ip');
      return response.data['ip'] as String?;
    } catch (e, s) {
      logger.e('Error getting IP address', error: e, stackTrace: s);
      return null;
    }
  }
}
