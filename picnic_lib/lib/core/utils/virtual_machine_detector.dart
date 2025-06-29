import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/config_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

// 가상머신 체크 설정 (오탐 방지용)
class VMDetectionConfig {
  // 개별 체크 비활성화 옵션
  static const bool enableBuildCheck = true;
  static const bool enableHardwareCheck = true;
  static const bool enableNetworkCheck = false; // 네트워크 체크는 오탐이 많아서 비활성화
  static const bool enableSamsungStrictCheck = false; // 삼성 기기 엄격 체크 비활성화
  static const bool enableSentryReport = true;

  // 디버그 모드 설정
  static const bool disableInDebugMode = true; // 디버그 모드에서 완전 비활성화

  // 환경변수로 전체 가상머신 체크 비활성화
  static bool get isVMCheckDisabled {
    const envDisabled = String.fromEnvironment('DISABLE_VM_CHECK');
    const envNoCheck = String.fromEnvironment('NO_VM_CHECK');
    const envSkipCheck = String.fromEnvironment('SKIP_VM_CHECK');

    return envDisabled == 'true' ||
        envNoCheck == 'true' ||
        envSkipCheck == 'true';
  }
}

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

  /// 가상 머신 감지 및 초기화
  static Future<bool> detect(WidgetRef ref) async {
    if (!_isMobile()) return false;

    // 환경변수로 전체 가상머신 체크 비활성화
    if (VMDetectionConfig.isVMCheckDisabled) {
      logger.i('환경변수에 의해 가상머신 체크가 비활성화됨');
      return false;
    }

    // 디버그 모드에서는 가상 머신 체크 건너뛰기
    if (kDebugMode && VMDetectionConfig.disableInDebugMode) {
      logger.d('디버그 모드: 가상 머신 체크 건너뛰기');
      return false;
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
        // final processorCount = await _getCpuCores();

        // 개별 체크 수행 (설정에 따라 활성화/비활성화)
        final buildInfo = VMDetectionConfig.enableBuildCheck
            ? await _checkBuildValues(androidInfo, configs.sublist(0, 4))
            : false;
        final hardwareCheck = VMDetectionConfig.enableHardwareCheck
            ? _checkHardwareWithInfo(cpuInfo, hasSensors, configs[4])
            : false;
        final networkCheck = VMDetectionConfig.enableNetworkCheck
            ? _checkNetworkWithInfo(ttl, macAddress, configs.sublist(5))
            : false;

        final isEmulator = buildInfo || hardwareCheck || networkCheck;

        // 체크 결과 로깅
        logger.i('''
가상머신 체크 결과:
- Build 체크: ${VMDetectionConfig.enableBuildCheck ? buildInfo : '비활성화'}
- Hardware 체크: ${VMDetectionConfig.enableHardwareCheck ? hardwareCheck : '비활성화'}  
- Network 체크: ${VMDetectionConfig.enableNetworkCheck ? networkCheck : '비활성화'}
- 최종 결과: $isEmulator
        ''');

        if (isEmulator) {
          // 감지 결과 요약 로깅
          logger.w(
            '''가상 머신 감지됨
            {
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
            }
            ''',
          );

          // 상세 감지 정보 로깅
          if (buildInfo) {
            final results =
                await _getBuildCheckResults(androidInfo, configs.sublist(0, 4));
            logger.w(
              '''Build 체크 상세 정보
              {
                'detection_details': {
                  'matched_keywords': {
                    'vm': ${results.vmMatches.map((e) => e.keyword).toList()},
                    'bluestacks': ${results.bluestacksMatches.map((e) => e.keyword).toList()},
                    'hardware':
                        ${results.hardwareMatches.map((e) => e.keyword).toList()},
                    'manufacturer':
                        ${results.manufacturerMatches.map((e) => e.keyword).toList()},
                  },
                  'manufacturer_empty':
                      ${results.checkResults['suspicious_manufacturer']},
                },
              }''',
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

          // Sentry에 상세 정보 전송 (설정에 따라)
          if (VMDetectionConfig.enableSentryReport) {
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
          }
        } else {
          logger.i('가상 머신 검사 결과: 정상 기기');

          // 정상 기기의 경우에도 분석 결과 로깅
          final buildResults =
              await _getBuildCheckResults(androidInfo, configs.sublist(0, 4));
          final hardwareResults = await _getHardwareCheckResults(configs);
          final networkResults =
              await _getNetworkCheckResults(configs.sublist(5));

          final deviceInfo = '''
정상 기기 상세 정보:
- 제조사: ${androidInfo.manufacturer}
- 모델: ${androidInfo.model}
- 하드웨어: ${androidInfo.hardware}
- 안드로이드 버전: ${androidInfo.version.release}
- SDK: ${androidInfo.version.sdkInt}
- 물리적 기기 여부: ${androidInfo.isPhysicalDevice}

빌드 체크 결과:
- 기기 정보: ${buildResults.deviceInfo}
- VM 키워드 매칭: ${buildResults.vmMatches.map((e) => e.keyword).toList()}
- Bluestacks 키워드 매칭: ${buildResults.bluestacksMatches.map((e) => e.keyword).toList()}
- 하드웨어 키워드 매칭: ${buildResults.hardwareMatches.map((e) => e.keyword).toList()}
- 제조사 키워드 매칭: ${buildResults.manufacturerMatches.map((e) => e.keyword).toList()}

하드웨어 체크 결과:
- CPU 정보: ${hardwareResults.checkResults['cpu_info_full']}
- 센서 존재 여부: ${hardwareResults.hasSensors}
- 지원 ABI: ${hardwareResults.checkResults['supported_abis']}

네트워크 체크 결과:
- TTL: ${networkResults['ttl_value']}
- MAC 주소: ${networkResults['mac_address']}
''';

          logger.d(deviceInfo);
        }

        return isEmulator;
      }

      if (UniversalPlatform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        if (!iosInfo.isPhysicalDevice) {
          logger.w('iOS 가상 디바이스 감지됨');
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
      ${info.tags}
      ${info.type}
      ${info.supported32BitAbis.join(' ')}
      ${info.supported64BitAbis.join(' ')}
      ${info.systemFeatures.join(' ')}
      ${info.host}_${info.product}_${info.device}
      ${info.brand}_${info.manufacturer}_${info.model}
    '''
        .toLowerCase();

    // 기본 정보 로깅
    logger.d('''
디바이스 기본 정보:
- manufacturer: ${info.manufacturer}
- model: ${info.model}
- brand: ${info.brand}
- product: ${info.product}
- device: ${info.device}
- hardware: ${info.hardware}
''');

    // 시스템 정보 로깅
    logger.d('''
디바이스 시스템 정보:
- host: ${info.host}
- fingerprint: ${info.fingerprint}
- board: ${info.board}
- bootloader: ${info.bootloader}
- display: ${info.display}
- id: ${info.id}
''');

    // 추가 정보 로깅
    logger.d('''
디바이스 추가 정보:
- tags: ${info.tags}
- type: ${info.type}
- isPhysicalDevice: ${info.isPhysicalDevice}
- 32bit ABIs: ${info.supported32BitAbis.join(', ')}
- 64bit ABIs: ${info.supported64BitAbis.join(', ')}
''');

    // 버전 정보 로깅
    logger.d('''
디바이스 버전 정보:
- release: ${info.version.release}
- sdkInt: ${info.version.sdkInt}
- codename: ${info.version.codename}
- incremental: ${info.version.incremental}
''');

    // 시스템 기능 로깅
    logger.d('''
시스템 기능 (처음 10개):
${info.systemFeatures.take(10).map((f) => '- $f').join('\n')}
''');

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

    final suspiciousHardware = info.hardware.isEmpty ||
        hardwareKeywords
            .any((keyword) => info.hardware.toLowerCase().contains(keyword));

    // 삼성 기기 관련 의심스러운 패턴 체크 (설정에 따라 활성화)
    if (VMDetectionConfig.enableSamsungStrictCheck &&
        info.manufacturer.toLowerCase() == 'samsung' &&
        info.model.toLowerCase().startsWith('sm-')) {
      final suspiciousReasons = <String>[];

      // 더 관대한 체크로 변경 (오탐 방지)
      if (info.bootloader.toLowerCase() == 'unknown') {
        suspiciousReasons.add('알 수 없는 부트로더');
      }

      // Knox 체크는 삼성 특정 모델에서만 적용
      if (info.model.toLowerCase().contains('galaxy') &&
          !info.systemFeatures.any((f) => f.contains('knox'))) {
        suspiciousReasons.add('Knox 보안 기능 누락');
      }

      if (suspiciousReasons.isNotEmpty) {
        logger.w('''
삼성 기기 의심 패턴 감지 (엄격 모드):
- 제조사: ${info.manufacturer}
- 모델: ${info.model}
- 의심 이유: ${suspiciousReasons.join(', ')}
        ''');
      }
    }

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
        'suspicious_hardware': hardwareMatches.isNotEmpty || suspiciousHardware,
        'suspicious_manufacturer': manufacturerMatches.isNotEmpty
      },
    );
  }

  static bool _checkHardwareWithInfo(
    String cpuInfo,
    bool hasSensors,
    String? cpuKeywordsConfig,
  ) {
    final cpuKeywords = _sanitizeKeywords(cpuKeywordsConfig);

    // CPU 정보에서 의심스러운 패턴 체크
    final suspiciousCpu = cpuKeywords.any(
          (keyword) => cpuInfo.toLowerCase().contains(keyword),
        ) ||
        cpuInfo.toLowerCase().contains('hypervisor') ||
        cpuInfo.toLowerCase().contains('virtual') ||
        cpuInfo.toLowerCase().contains('qemu');

    return suspiciousCpu || !hasSensors;
  }

  static Future<int?> _getCpuCores() async {
    try {
      final file = File('/proc/cpuinfo');
      final cpuInfo = await file.readAsString();

      // processor 라인을 찾아서 개수를 세는 방식
      final processorCount = cpuInfo
          .split('\n')
          .where((line) => line.trim().toLowerCase().startsWith('processor'))
          .length;

      if (processorCount == 0) {
        // processor 라인이 없는 경우, CPU 코어 수를 직접 가져오기
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.supportedAbis.length;
      }

      return processorCount;
    } catch (e) {
      logger.e('CPU 코어 수 가져오기 실패:', error: e);
      return null;
    }
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
    try {
      // 실제 센서 체크 구현 (간단 버전)
      final androidInfo = await _deviceInfo.androidInfo;

      // 물리적 기기 여부를 우선 체크
      if (!androidInfo.isPhysicalDevice) {
        return false; // 에뮬레이터로 확실히 감지됨
      }

      // systemFeatures에서 센서 관련 기능 체크
      final sensorFeatures = [
        'android.hardware.sensor.accelerometer',
        'android.hardware.sensor.gyroscope',
        'android.hardware.sensor.compass',
        'android.hardware.touchscreen',
      ];

      final existingSensors = sensorFeatures
          .where((feature) => androidInfo.systemFeatures.contains(feature))
          .length;

      // 센서가 2개 이상 있으면 정상 기기로 판단
      return existingSensors >= 2;
    } catch (e) {
      logger.e('센서 체크 중 오류:', error: e);
      return true; // 오류 시 정상 기기로 처리 (오탐 방지)
    }
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
      if (!UniversalPlatform.isAndroid) return null;

      // /sys/class/net/{interface}/address 파일에서 MAC 주소 읽기
      for (var interface in ['wlan0', 'eth0']) {
        final file = File('/sys/class/net/$interface/address');
        if (await file.exists()) {
          final mac = (await file.readAsString()).trim().toUpperCase();
          if (mac.isNotEmpty && mac != '00:00:00:00:00:00') {
            logger.d('MAC 주소 찾음: $interface -> $mac');
            return mac;
          }
        }
      }

      logger.d('유효한 MAC 주소를 찾을 수 없음');
      return null;
    } catch (e) {
      logger.e('MAC 주소 가져오기 실패: ${e.toString()}');
      return null;
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
    try {
      final buildCheckResults =
          await _getBuildCheckResults(androidInfo, configs);
      final processorCount = await _getCpuCores();

      logger.i('Sentry 리포트 전송 시작...');

      await Sentry.captureMessage(
        '⚠️ 가상 머신 감지 ⚠️',
        level: SentryLevel.warning,
        withScope: (scope) {
          scope.setContexts('detection_report', {
            'summary': {
              'detection_type': [
                if (buildInfo) '빌드 정보 체크',
                if (hardwareCheck) '하드웨어 체크',
                if (networkCheck) '네트워크 체크',
              ].join(', '),
              'device_info': {
                'manufacturer': androidInfo.manufacturer,
                'model': androidInfo.model,
                'hardware': androidInfo.hardware,
                'board': androidInfo.board,
                'bootloader': androidInfo.bootloader,
                'fingerprint': androidInfo.fingerprint,
                'host': androidInfo.host,
                'is_physical_device': androidInfo.isPhysicalDevice,
                'processor_count': processorCount,
              },
            },
            'detection_details': {
              'build': buildInfo
                  ? {
                      'suspicious_reasons': [
                        if (buildCheckResults.vmMatches.isNotEmpty)
                          '가상 머신 키워드 발견: ${buildCheckResults.vmMatches.map((e) => e.keyword).join(", ")}',
                        if (buildCheckResults.bluestacksMatches.isNotEmpty)
                          '블루스택스 키워드 발견: ${buildCheckResults.bluestacksMatches.map((e) => e.keyword).join(", ")}',
                        if (buildCheckResults.hardwareMatches.isNotEmpty)
                          '의심스러운 하드웨어: ${buildCheckResults.hardwareMatches.map((e) => e.keyword).join(", ")}',
                        if (buildCheckResults.manufacturerMatches.isNotEmpty)
                          '의심스러운 제조사: ${buildCheckResults.manufacturerMatches.map((e) => e.keyword).join(", ")}',
                        if (buildCheckResults
                                .checkResults['suspicious_manufacturer'] ==
                            true)
                          '제조사 정보 불일치',
                      ],
                    }
                  : '감지되지 않음',
              'hardware': hardwareCheck
                  ? {
                      'suspicious_reasons': [
                        if (!hasSensors) '센서 없음',
                        if (cpuInfo.contains('hypervisor') ||
                            cpuInfo.contains('virtual'))
                          '가상화 관련 CPU 정보 발견',
                        '전체 CPU 정보: $cpuInfo',
                      ],
                    }
                  : '감지되지 않음',
              'network': networkCheck
                  ? {
                      'suspicious_reasons': [
                        if (ttl != null) 'TTL 값 의심: $ttl',
                        if (macAddress != null) 'MAC 주소 의심: $macAddress',
                      ],
                    }
                  : '감지되지 않음',
            },
          });
        },
      );

      logger.i('Sentry 리포트 전송 완료');
    } catch (e, s) {
      logger.e('Sentry 리포트 전송 실패:', error: e, stackTrace: s);
    }
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
