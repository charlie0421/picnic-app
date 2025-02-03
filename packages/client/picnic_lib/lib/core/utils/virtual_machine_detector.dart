import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/device_fingerprint.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/config_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

class VirtualMachineDetector {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 가상 머신 감지 및 초기화
  static Future<bool> detect(WidgetRef ref) async {
    if (!_isMobile()) return false;

    // 디버그 모드에서는 가상 머신 체크 건너뛰기
    if (kDebugMode) {
      // logger.i('디버그 모드: 가상 머신 체크 건너뛰기');
      return false;
    }

    try {
      logger.i('가상 머신 검사 시작...');

      if (UniversalPlatform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        // 1. Build 값 체크
        final buildInfo = await _checkBuildValues(androidInfo, ref);

        // 2. 하드웨어 기반 체크
        final hardwareCheck = await _checkHardware(ref);

        // 3. 네트워크 환경 체크
        final networkCheck = await _checkNetworkEnvironment(ref);

        final isEmulator = buildInfo || hardwareCheck || networkCheck;

        if (isEmulator) {
          logger.w('가상 머신 감지됨 (상세 정보):');
          logger.w('Build 체크: $buildInfo');
          logger.w('하드웨어 체크: $hardwareCheck');
          logger.w('네트워크 체크: $networkCheck');
          await _banVirtualDevice();
        }

        return isEmulator;
      }

      if (UniversalPlatform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        if (!iosInfo.isPhysicalDevice) {
          logger.w('iOS 가상 디바이스 감지됨');
          await _banVirtualDevice();
          return true;
        }
        return false;
      }

      return false;
    } catch (e, s) {
      logger.e('가상 머신 검사 중 오류 발생:', error: e, stackTrace: s);
      return false;
    }
  }

  static bool _isMobile() {
    return UniversalPlatform.isAndroid || UniversalPlatform.isIOS;
  }

  static Future<bool> _checkBuildValues(
      AndroidDeviceInfo info, WidgetRef ref) async {
    final String deviceInfo = '''
      ${info.manufacturer}
      ${info.model}
      ${info.brand}
      ${info.fingerprint}
      ${info.product}
      ${info.device}
      ${info.hardware}
      ${info.host}
      ${info.board}
      ${info.bootloader}
      ${info.display}
      ${info.id}
    '''
        .toLowerCase();

    final configService = ref.read(configServiceProvider);

    // 일반 가상 머신 키워드
    final List<String> vmKeywords =
        (await configService.getConfig('VIRTUAL_KEYWORDS'))?.split(',') ?? [];

    // 블루스택스 특정 키워드
    final List<String> bluestacksKeywords =
        (await configService.getConfig('VIRTUAL_BLUESTACK_KEWORDS'))
                ?.split(',') ??
            [];

    final List<String> suspiciousHardwareKeywords =
        (await configService.getConfig('VIRTUAL_HARDWARE_KEYWORDS'))
                ?.split(',') ??
            [];
    // 추가 하드웨어 체크
    final bool suspiciousHardware = suspiciousHardwareKeywords
        .any((keyword) => info.hardware.toLowerCase().contains(keyword));

    // 추가 제조사 체크
    final List<String> suspiciousManufacturerKeywords =
        (await configService.getConfig('VIRTUAL_MANUFACTURER_KEYWORDS'))
                ?.split(',') ??
            [];

    final bool suspiciousManufacturer = suspiciousManufacturerKeywords.any(
            (keyword) => info.manufacturer.toLowerCase().contains(keyword)) ||
        info.manufacturer.isEmpty;

    final bool hasVmKeywords =
        vmKeywords.any((keyword) => deviceInfo.contains(keyword));
    final bool hasBluestacksKeywords =
        bluestacksKeywords.any((keyword) => deviceInfo.contains(keyword));

    return hasVmKeywords ||
        hasBluestacksKeywords ||
        suspiciousHardware ||
        suspiciousManufacturer;
  }

  static Future<bool> _checkHardware(WidgetRef ref) async {
    try {
      final String cpuInfo = await _readCpuInfo();
      final configService = ref.read(configServiceProvider);
      final suspiciousCpuKeywords =
          (await configService.getConfig('VIRTUAL_CPU_KEYWORD'))?.split(',') ??
              [];
      final bool suspiciousCpu = suspiciousCpuKeywords
          .any((keyword) => cpuInfo.toLowerCase().contains(keyword));
      if (suspiciousCpu) return true;

      final bool hasSensors = await _checkSensors();
      if (!hasSensors) return true;

      return false;
    } catch (e) {
      logger.e('하드웨어 체크 중 오류:', error: e);
      return false;
    }
  }

  static Future<bool> _checkNetworkEnvironment(WidgetRef ref) async {
    try {
      final int? ttl = await _getTTL();
      final configService = ref.read(configServiceProvider);
      final suspiciousTtlKeywords =
          (await configService.getConfig('VIRTUAL_TTL_RANGE'))?.split(',') ??
              [];
      final bool suspiciousTtl = suspiciousTtlKeywords.length == 2 &&
          ttl != null &&
          ttl >= int.parse(suspiciousTtlKeywords[0]) &&
          ttl <= int.parse(suspiciousTtlKeywords[1]);
      if (suspiciousTtl) return true;

      final String? macAddress = await _getMacAddress();
      final suspiciousMacAddressKeywords =
          (await configService.getConfig('VIRTUAL_MAC_KEYWORDS'))?.split(',') ??
              [];
      final bool suspiciousMacAddress = suspiciousMacAddressKeywords.any(
          (keyword) => macAddress != null && macAddress.startsWith(keyword));
      if (suspiciousMacAddress) return true;

      return false;
    } catch (e) {
      logger.e('네트워크 환경 체크 중 오류:', error: e);
      return false;
    }
  }

  static Future<String> _readCpuInfo() async {
    try {
      final file = File('/proc/cpuinfo');
      return await file.readAsString();
    } catch (e) {
      return '';
    }
  }

  static Future<bool> _checkSensors() async {
    return true; // 실제 구현 필요
  }

  static Future<int?> _getTTL() async {
    try {
      final result = await Process.run('ping', ['-c', '1', '8.8.8.8']);
      final output = result.stdout.toString();
      final ttlMatch = RegExp(r'ttl=(\d+)').firstMatch(output);
      return ttlMatch != null ? int.parse(ttlMatch.group(1)!) : null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> _getMacAddress() async {
    try {
      final networkInterfaces = await NetworkInterface.list();
      return networkInterfaces.first.addresses.first.address;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _banVirtualDevice() async {
    try {
      final deviceId = await DeviceFingerprint.getDeviceId();
      await _supabase.from('device_bans').upsert({
        'device_id': deviceId,
        'reason': 'Virtual device detected',
        'created_at': DateTime.now().toIso8601String(),
      });
      logger.i('가상 디바이스 차단 정보 저장됨: $deviceId');
    } catch (e, s) {
      logger.e('가상 디바이스 차단 중 오류 발생:', error: e, stackTrace: s);
    }
  }
}
