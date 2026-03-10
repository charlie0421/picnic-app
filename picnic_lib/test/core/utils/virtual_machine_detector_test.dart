import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/virtual_machine_detector.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';

void main() {
  group('VMDetectionConfig', () {
    test('기본 설정값 확인', () {
      expect(VMDetectionConfig.enableBuildCheck, isTrue);
      expect(VMDetectionConfig.enableHardwareCheck, isTrue);
      expect(VMDetectionConfig.enableNetworkCheck, isFalse);
      expect(VMDetectionConfig.enableSamsungStrictCheck, isFalse);
      expect(VMDetectionConfig.enableSentryReport, isTrue);
      expect(VMDetectionConfig.disableInDebugMode, isTrue);
    });

    test('isVMCheckDisabled - 환경변수 없으면 false', () {
      // 기본 테스트 환경에서는 환경변수가 설정되지 않으므로 false
      expect(VMDetectionConfig.isVMCheckDisabled, isFalse);
    });
  });

  group('KeywordMatch', () {
    test('매칭된 키워드', () {
      final match = KeywordMatch('emulator', true);
      expect(match.keyword, equals('emulator'));
      expect(match.isMatch, isTrue);
    });

    test('매칭되지 않은 키워드', () {
      final match = KeywordMatch('samsung', false);
      expect(match.keyword, equals('samsung'));
      expect(match.isMatch, isFalse);
    });
  });

  group('BuildCheckResults', () {
    test('빈 결과 생성', () {
      final results = BuildCheckResults(
        deviceInfo: 'test device info',
        vmKeywords: ['emulator', 'sdk'],
        bluestacksKeywords: ['bluestacks'],
        hardwareKeywords: ['goldfish'],
        manufacturerKeywords: ['unknown'],
        vmMatches: [],
        bluestacksMatches: [],
        hardwareMatches: [],
        manufacturerMatches: [],
        checkResults: {
          'has_vm_keywords': false,
          'has_bluestacks_keywords': false,
          'suspicious_hardware': false,
          'suspicious_manufacturer': false,
        },
      );
      expect(results.deviceInfo, equals('test device info'));
      expect(results.vmKeywords, hasLength(2));
      expect(results.vmMatches, isEmpty);
      expect(results.checkResults['has_vm_keywords'], isFalse);
    });

    test('매칭 결과가 있는 경우', () {
      final results = BuildCheckResults(
        deviceInfo: 'generic emulator device',
        vmKeywords: ['emulator'],
        bluestacksKeywords: [],
        hardwareKeywords: [],
        manufacturerKeywords: [],
        vmMatches: [KeywordMatch('emulator', true)],
        bluestacksMatches: [],
        hardwareMatches: [],
        manufacturerMatches: [],
        checkResults: {
          'has_vm_keywords': true,
          'has_bluestacks_keywords': false,
          'suspicious_hardware': false,
          'suspicious_manufacturer': false,
        },
      );
      expect(results.vmMatches, hasLength(1));
      expect(results.vmMatches.first.keyword, equals('emulator'));
      expect(results.checkResults['has_vm_keywords'], isTrue);
    });
  });

  group('HardwareCheckResults', () {
    test('정상 기기 결과', () {
      final results = HardwareCheckResults(
        cpuKeywords: ['qemu', 'virtual'],
        hasSensors: true,
        checkResults: {
          'has_sensors': true,
          'suspicious_cpu': false,
        },
      );
      expect(results.hasSensors, isTrue);
      expect(results.cpuKeywords, hasLength(2));
      expect(results.checkResults['suspicious_cpu'], isFalse);
    });

    test('의심스러운 기기 결과', () {
      final results = HardwareCheckResults(
        cpuKeywords: ['qemu'],
        hasSensors: false,
        checkResults: {
          'has_sensors': false,
          'suspicious_cpu': true,
        },
      );
      expect(results.hasSensors, isFalse);
      expect(results.checkResults['suspicious_cpu'], isTrue);
    });
  });

  group('WebPSupportInfo', () {
    test('기본값은 모두 false', () {
      const info = WebPSupportInfo();
      expect(info.webp, isFalse);
      expect(info.animatedWebp, isFalse);
    });

    test('모두 지원하는 경우', () {
      const info = WebPSupportInfo(webp: true, animatedWebp: true);
      expect(info.webp, isTrue);
      expect(info.animatedWebp, isTrue);
    });

    test('기본 WebP만 지원하는 경우', () {
      const info = WebPSupportInfo(webp: true, animatedWebp: false);
      expect(info.webp, isTrue);
      expect(info.animatedWebp, isFalse);
    });
  });
}
