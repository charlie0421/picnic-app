import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/device_fingerprint.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/config_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

          // Sentry에 상세 정보 전송
          await Sentry.captureMessage(
            '가상 머신 감지',
            level: SentryLevel.warning,
            withScope: (scope) async {
              // 기본 디바이스 정보
              scope.setContexts('device_info', {
                'manufacturer': androidInfo.manufacturer,
                'model': androidInfo.model,
                'brand': androidInfo.brand,
                'device': androidInfo.device,
                'product': androidInfo.product,
                'hardware': androidInfo.hardware,
                'fingerprint': androidInfo.fingerprint,
              });

              // 시스템 정보
              scope.setContexts('system_info', {
                'android_version': androidInfo.version.release,
                'sdk_int': androidInfo.version.sdkInt,
                'security_patch': androidInfo.version.securityPatch,
                'board': androidInfo.board,
                'bootloader': androidInfo.bootloader,
                'host': androidInfo.host,
                'id': androidInfo.id,
              });

              // 하드웨어 상세 정보
              scope.setContexts('hardware_info', {
                'supported_abis': androidInfo.supportedAbis,
                'physical_device': androidInfo.isPhysicalDevice,
                'cpu_info': await _readCpuInfo(),
              });

              // 체크 결과
              scope.setContexts('detection_results', {
                'build_check': buildInfo,
                'hardware_check': hardwareCheck,
                'network_check': networkCheck,
              });

              // 네트워크 정보
              scope.setContexts('network_info', {
                'ttl': await _getTTL(),
                'mac_address': await _getMacAddress(),
              });

              // 감지 상세 정보 추가
              scope.setContexts('detection_details', {
                'build_check_details': {
                  'matched_vm_keywords':
                      _detectionDetails['matched_vm_keywords'],
                  'matched_bluestacks_keywords':
                      _detectionDetails['matched_bluestacks_keywords'],
                  'matched_hardware_keywords':
                      _detectionDetails['matched_hardware_keywords'],
                  'matched_manufacturer_keywords':
                      _detectionDetails['matched_manufacturer_keywords'],
                  'empty_manufacturer': _detectionDetails['empty_manufacturer'],
                },
                'hardware_check_details': {
                  'matched_cpu_keywords':
                      _detectionDetails['matched_cpu_keywords'],
                  'has_sensors': _detectionDetails['has_sensors'],
                },
                'network_check_details': {
                  'ttl_value': await _getTTL(),
                  'ttl_range': await ref
                      .read(configServiceProvider)
                      .getConfig('VIRTUAL_TTL_RANGE'),
                  'mac_address': await _getMacAddress(),
                  'suspicious_mac_prefixes': await ref
                      .read(configServiceProvider)
                      .getConfig('VIRTUAL_MAC_KEYWORDS'),
                },
              });

              // 태그 설정
              scope.setTag('device_type', 'virtual_machine');
              scope.setTag('os_version', androidInfo.version.release);
              scope.setTag('device_model',
                  '${androidInfo.manufacturer} ${androidInfo.model}');
            },
          );

          await _banVirtualDevice();

          // 감지 상세 정보 초기화
          _detectionDetails = {};
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
    // 디버그 로그 추가
    logger.d('제조사: ${info.manufacturer}');
    logger.d('모델: ${info.model}');
    logger.d('하드웨어: ${info.hardware}');

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

    // 매칭된 키워드 찾기
    final List<String> matchedVmKeywords =
        vmKeywords.where((keyword) => deviceInfo.contains(keyword)).toList();
    final List<String> matchedBluestacksKeywords = bluestacksKeywords
        .where((keyword) => deviceInfo.contains(keyword))
        .toList();
    final List<String> matchedHardwareKeywords = suspiciousHardwareKeywords
        .where((keyword) => info.hardware.toLowerCase().contains(keyword))
        .toList();
    final List<String> matchedManufacturerKeywords =
        suspiciousManufacturerKeywords
            .where(
                (keyword) => info.manufacturer.toLowerCase().contains(keyword))
            .toList();

    // 결과와 매칭된 키워드 저장
    _detectionDetails = {
      'matched_vm_keywords': matchedVmKeywords,
      'matched_bluestacks_keywords': matchedBluestacksKeywords,
      'matched_hardware_keywords': matchedHardwareKeywords,
      'matched_manufacturer_keywords': matchedManufacturerKeywords,
      'empty_manufacturer': info.manufacturer.isEmpty,
    };

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

      // 매칭된 CPU 키워드 찾기
      final List<String> matchedCpuKeywords = suspiciousCpuKeywords
          .where((keyword) => cpuInfo.toLowerCase().contains(keyword))
          .toList();

      final bool suspiciousCpu = matchedCpuKeywords.isNotEmpty;
      final bool hasSensors = await _checkSensors();

      // 하드웨어 체크 결과 저장
      _detectionDetails.addAll({
        'matched_cpu_keywords': matchedCpuKeywords,
        'cpu_info': cpuInfo,
        'has_sensors': hasSensors,
      });

      return suspiciousCpu || !hasSensors;
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

  // 감지 상세 정보를 저장할 static 변수
  static Map<String, dynamic> _detectionDetails = {};
}
