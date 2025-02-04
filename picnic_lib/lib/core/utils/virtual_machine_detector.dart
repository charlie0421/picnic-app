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

// 클래스들을 파일 상단으로 이동
class KeywordMatch {
  final String keyword;
  final bool isMatch;

  KeywordMatch(this.keyword, this.isMatch);
}

class BuildCheckResults {
  final String deviceInfo;
  final List<String> vmKeywords;
  final List<String> bluestacksKeywords;
  final List<String> hardwareKeywords;
  final List<String> manufacturerKeywords;
  final List<KeywordMatch> vmMatches;
  final List<KeywordMatch> bluestacksMatches;
  final List<KeywordMatch> hardwareMatches;
  final List<KeywordMatch> manufacturerMatches;
  final Map<String, dynamic> checkResults;

  BuildCheckResults({
    required this.deviceInfo,
    required this.vmKeywords,
    required this.bluestacksKeywords,
    required this.hardwareKeywords,
    required this.manufacturerKeywords,
    required this.vmMatches,
    required this.bluestacksMatches,
    required this.hardwareMatches,
    required this.manufacturerMatches,
    required this.checkResults,
  });
}

class HardwareCheckResults {
  final List<String> cpuKeywords;
  final bool hasSensors;
  final Map<String, dynamic> checkResults;

  HardwareCheckResults({
    required this.cpuKeywords,
    required this.hasSensors,
    required this.checkResults,
  });
}

class VirtualMachineDetector {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 가상 머신 감지 및 초기화
  static Future<bool> detect(WidgetRef ref) async {
    if (!_isMobile()) return false;

    // 디버그 모드에서는 가상 머신 체크 건너뛰기
    if (kDebugMode) {
      logger.d('디버그 모드: 가상 머신 체크 건너뛰기');
      // return false;
    }

    try {
      logger.i('가상 머신 검사 시작...');

      if (UniversalPlatform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final configService = ref.read(configServiceProvider);

        // 모든 설정값 한 번에 가져오기
        final configs = await Future.wait([
          configService.getConfig('VIRTUAL_KEYWORDS'),
          configService.getConfig('VIRTUAL_BLUESTACK_KEWORDS'),
          configService.getConfig('VIRTUAL_HARDWARE_KEYWORDS'),
          configService.getConfig('VIRTUAL_MANUFACTURER_KEYWORDS'),
          configService.getConfig('VIRTUAL_CPU_KEYWORD'),
          configService.getConfig('VIRTUAL_TTL_RANGE'),
          configService.getConfig('VIRTUAL_MAC_KEYWORDS'),
        ]);

        // 자주 사용되는 값들 미리 가져오기
        final cpuInfo = await _readCpuInfo();
        final ttl = await _getTTL();
        final macAddress = await _getMacAddress();
        final hasSensors = await _checkSensors();

        // 체크 수행
        final buildInfo =
            await _checkBuildValues(androidInfo, configs.sublist(0, 4));
        final hardwareCheck =
            _checkHardwareWithInfo(cpuInfo, hasSensors, configs[4]);
        final networkCheck =
            _checkNetworkWithInfo(ttl, macAddress, configs.sublist(5));

        final isEmulator = buildInfo || hardwareCheck || networkCheck;

        if (isEmulator) {
          // 감지 결과 요약 로깅
          logger.w(
            '가상 머신 감지됨',
            error: {
              'detection_summary': {
                'detection_type': [
                  if (buildInfo) 'Build 체크 ✅',
                  if (hardwareCheck) 'Hardware 체크 ✅',
                  if (networkCheck) 'Network 체크 ✅',
                ].join(', '),
                'device_info': {
                  'manufacturer': androidInfo.manufacturer,
                  'model': androidInfo.model,
                  'hardware': androidInfo.hardware,
                  'android_version': androidInfo.version.release,
                  'sdk': androidInfo.version.sdkInt,
                },
              },
            },
          );

          // 상세 감지 정보 로깅
          if (buildInfo) {
            final results =
                await _getBuildCheckResults(androidInfo, configs.sublist(0, 4));
            logger.w(
              'Build 체크 상세 정보',
              error: {
                'detection_details': {
                  'matched_keywords': {
                    'vm': results.vmMatches.map((e) => e.keyword).toList(),
                    'bluestacks': results.bluestacksMatches
                        .map((e) => e.keyword)
                        .toList(),
                    'hardware':
                        results.hardwareMatches.map((e) => e.keyword).toList(),
                    'manufacturer': results.manufacturerMatches
                        .map((e) => e.keyword)
                        .toList(),
                  },
                  'manufacturer_empty':
                      results.checkResults['suspicious_manufacturer'],
                },
              },
            );
          }

          if (hardwareCheck) {
            final results = await _getHardwareCheckResults(configs);
            logger.w('Hardware 체크 상세 정보', error: {
              'detection_details': {
                'cpu_info': cpuInfo,
                'cpu_keywords': results.cpuKeywords,
                'has_sensors': hasSensors,
                'is_physical_device': androidInfo.isPhysicalDevice,
              },
            });
          }

          if (networkCheck) {
            logger.w('Network 체크 상세 정보', error: {
              'detection_details': {
                'ttl': {
                  'value': ttl,
                  'range': configs[5],
                },
                'mac': {
                  'address': macAddress,
                  'matched_keywords': _sanitizeKeywords(configs[6])
                      .where(
                          (keyword) => macAddress?.startsWith(keyword) ?? false)
                      .toList(),
                },
              },
            });
          }

          // Sentry에 상세 정보 전송
          await _sendSentryReport(
            androidInfo: androidInfo,
            configs: configs,
            cpuInfo: cpuInfo,
            ttl: ttl,
            macAddress: macAddress,
            hasSensors: hasSensors,
            buildInfo: buildInfo,
            hardwareCheck: hardwareCheck,
            networkCheck: networkCheck,
          );

          await _banVirtualDevice();
        } else {
          logger.i('가상 머신 검사 결과: 정상 기기');
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
    AndroidDeviceInfo info,
    List<String?> configs,
  ) async {
    try {
      final buildCheckResults = await _getBuildCheckResults(info, configs);

      return buildCheckResults.checkResults['has_vm_keywords'] == true ||
          buildCheckResults.checkResults['has_bluestacks_keywords'] == true ||
          buildCheckResults.checkResults['suspicious_hardware'] == true ||
          buildCheckResults.checkResults['suspicious_manufacturer'] == true;
    } catch (e) {
      logger.e('Build 체크 중 오류:', error: e);
      return false;
    }
  }

  static List<String> _sanitizeKeywords(String? config) {
    if (config == null || config.isEmpty) return [];
    return config.split(',').where((k) => k.isNotEmpty).toList();
  }

  static Future<BuildCheckResults> _getBuildCheckResults(
      AndroidDeviceInfo info, List<String?> configs) async {
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

    final vmKeywords = _sanitizeKeywords(configs[0]);
    final bluestacksKeywords = _sanitizeKeywords(configs[1]);
    final hardwareKeywords = _sanitizeKeywords(configs[2]);
    final manufacturerKeywords = _sanitizeKeywords(configs[3]);

    // 매칭된 키워드 찾기
    final vmMatches = vmKeywords
        .map((keyword) => KeywordMatch(keyword, deviceInfo.contains(keyword)))
        .where((match) => match.isMatch)
        .toList();

    final bluestacksMatches = bluestacksKeywords
        .map((keyword) => KeywordMatch(keyword, deviceInfo.contains(keyword)))
        .where((match) => match.isMatch)
        .toList();

    final hardwareMatches = hardwareKeywords
        .map((keyword) => KeywordMatch(
            keyword, info.hardware.toLowerCase().contains(keyword)))
        .where((match) => match.isMatch)
        .toList();

    final manufacturerMatches = manufacturerKeywords
        .map((keyword) => KeywordMatch(
            keyword, info.manufacturer.toLowerCase().contains(keyword)))
        .where((match) => match.isMatch)
        .toList();

    // 디버그 로그
    logger.d({
      'manufacturer': info.manufacturer,
      'model': info.model,
      'hardware': info.hardware,
      'matched_vm_keywords': vmMatches.map((e) => e.keyword).toList(),
      'matched_bluestacks_keywords':
          bluestacksMatches.map((e) => e.keyword).toList(),
      'matched_hardware_keywords':
          hardwareMatches.map((e) => e.keyword).toList(),
      'matched_manufacturer_keywords':
          manufacturerMatches.map((e) => e.keyword).toList(),
    });

    return BuildCheckResults(
      deviceInfo: deviceInfo,
      vmKeywords: vmKeywords,
      bluestacksKeywords: bluestacksKeywords,
      hardwareKeywords: hardwareKeywords,
      manufacturerKeywords: manufacturerKeywords,
      vmMatches: vmMatches,
      bluestacksMatches: bluestacksMatches,
      hardwareMatches: hardwareMatches,
      manufacturerMatches: manufacturerMatches,
      checkResults: {
        'has_vm_keywords': vmMatches.isNotEmpty,
        'has_bluestacks_keywords': bluestacksMatches.isNotEmpty,
        'suspicious_hardware': hardwareMatches.isNotEmpty,
        'suspicious_manufacturer':
            manufacturerMatches.isNotEmpty || info.manufacturer.isEmpty,
      },
    );
  }

  static bool _checkHardwareWithInfo(
    String cpuInfo,
    bool hasSensors,
    String? cpuKeywordsConfig,
  ) {
    final cpuKeywords = _sanitizeKeywords(cpuKeywordsConfig);
    final suspiciousCpu = cpuKeywords.any(
      (keyword) => cpuInfo.toLowerCase().contains(keyword),
    );
    return suspiciousCpu || !hasSensors;
  }

  static bool _checkNetworkWithInfo(
    int? ttl,
    String? macAddress,
    List<String?> configs,
  ) {
    final ttlRange = _sanitizeKeywords(configs[0]);
    final macKeywords = _sanitizeKeywords(configs[1]);

    final suspiciousTtl = ttlRange.length == 2 &&
        ttl != null &&
        int.tryParse(ttlRange[0]) != null &&
        int.tryParse(ttlRange[1]) != null &&
        ttl >= int.parse(ttlRange[0]) &&
        ttl <= int.parse(ttlRange[1]);

    final suspiciousMac = macAddress != null &&
        macKeywords.any(
            (keyword) => keyword.isNotEmpty && macAddress.startsWith(keyword));

    return suspiciousTtl || suspiciousMac;
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

  // Sentry 리포트 전송을 위한 별도 메서드
  static Future<void> _sendSentryReport({
    required AndroidDeviceInfo androidInfo,
    required List<String?> configs,
    required String cpuInfo,
    required int? ttl,
    required String? macAddress,
    required bool hasSensors,
    required bool buildInfo,
    required bool hardwareCheck,
    required bool networkCheck,
  }) async {
    final buildCheckResults = await _getBuildCheckResults(androidInfo, configs);
    final hardwareCheckResults = await _getHardwareCheckResults(configs);

    await Sentry.captureMessage(
      '가상 머신 감지 ⚠️',
      level: SentryLevel.warning,
      withScope: (scope) async {
        scope.setContexts('detection_report', {
          'summary': {
            'detection_conditions': {
              'build_check': buildInfo ? '✅ 감지됨' : '❌ 정상',
              'hardware_check': hardwareCheck ? '✅ 감지됨' : '❌ 정상',
              'network_check': networkCheck ? '✅ 감지됨' : '❌ 정상',
            },
            'device': {
              'manufacturer_model':
                  '${androidInfo.manufacturer} ${androidInfo.model}',
              'android_version': androidInfo.version.release,
              'sdk_level': androidInfo.version.sdkInt,
              'hardware': androidInfo.hardware,
              'fingerprint': androidInfo.fingerprint,
            },
          },
          'detection_details': {
            'build': buildInfo
                ? {
                    'matched_keywords': {
                      'vm': buildCheckResults.vmMatches
                          .map((e) => e.keyword)
                          .toList(),
                      'bluestacks': buildCheckResults.bluestacksMatches
                          .map((e) => e.keyword)
                          .toList(),
                      'hardware': buildCheckResults.hardwareMatches
                          .map((e) => e.keyword)
                          .toList(),
                      'manufacturer': buildCheckResults.manufacturerMatches
                          .map((e) => e.keyword)
                          .toList(),
                    },
                    'manufacturer_empty': buildCheckResults
                        .checkResults['suspicious_manufacturer'],
                  }
                : '감지되지 않음',
            'hardware': hardwareCheck
                ? {
                    'cpu_info': cpuInfo,
                    'matched_cpu_keywords': hardwareCheckResults.cpuKeywords,
                    'has_sensors': hasSensors,
                    'is_physical_device': androidInfo.isPhysicalDevice,
                  }
                : '감지되지 않음',
            'network': networkCheck
                ? {
                    'ttl_value': ttl,
                    'ttl_range': configs[5],
                    'mac_address': macAddress,
                    'mac_keywords_matched': _sanitizeKeywords(configs[6])
                        .where((keyword) =>
                            macAddress?.startsWith(keyword) ?? false)
                        .toList(),
                  }
                : '감지되지 않음',
          },
          'configuration': {
            'keywords': {
              'vm': buildCheckResults.vmKeywords,
              'bluestacks': buildCheckResults.bluestacksKeywords,
              'hardware': buildCheckResults.hardwareKeywords,
              'manufacturer': buildCheckResults.manufacturerKeywords,
              'cpu': hardwareCheckResults.cpuKeywords,
            },
          },
          'raw_device_info': buildCheckResults.deviceInfo,
        });

        scope.setTag(
            'detection_type',
            [
              if (buildInfo) 'build',
              if (hardwareCheck) 'hardware',
              if (networkCheck) 'network'
            ].join('+'));
        scope.setTag(
            'device_model', '${androidInfo.manufacturer} ${androidInfo.model}');
        scope.setTag('os_version', androidInfo.version.release);
      },
    );
  }

  static Future<HardwareCheckResults> _getHardwareCheckResults(
      List<String?> configs) async {
    final cpuKeywordsConfig = configs[4];
    final cpuInfo = await _readCpuInfo();
    final hasSensors = await _checkSensors();

    final cpuKeywords = _sanitizeKeywords(cpuKeywordsConfig);
    final suspiciousCpu = cpuKeywords.any(
      (keyword) => cpuInfo.toLowerCase().contains(keyword),
    );

    return HardwareCheckResults(
      cpuKeywords: cpuKeywords,
      hasSensors: hasSensors,
      checkResults: {
        'cpu_info_full': cpuInfo,
        'has_sensors': hasSensors,
        'suspicious_cpu': suspiciousCpu,
        'supported_abis': (await _deviceInfo.androidInfo).supportedAbis,
        'is_physical_device': (await _deviceInfo.androidInfo).isPhysicalDevice,
      },
    );
  }

  static Future<Map<String, dynamic>> _getNetworkCheckResults(
      List<String?> configs) async {
    final ttl = await _getTTL();
    final macAddress = await _getMacAddress();

    return {
      'ttl_value': ttl,
      'mac_address': macAddress,
      'ttl_range': configs[0],
      'mac_keywords': configs[1],
    };
  }
}
