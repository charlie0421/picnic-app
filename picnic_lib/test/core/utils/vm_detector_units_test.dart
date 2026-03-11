import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/virtual_machine_detector.dart';

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

    test('환경변수 기반 비활성화 확인', () {
      // 기본 환경에서는 환경변수가 없으므로 false
      // (실제 환경변수 설정 시 테스트는 CI에서)
      expect(VMDetectionConfig.isVMCheckDisabled, isFalse);
    });
  });

  group('KeywordMatch', () {
    test('매칭된 키워드', () {
      final match = KeywordMatch('emulator', true);
      expect(match.keyword, equals('emulator'));
      expect(match.isMatch, isTrue);
    });

    test('매칭 안 된 키워드', () {
      final match = KeywordMatch('bluestacks', false);
      expect(match.keyword, equals('bluestacks'));
      expect(match.isMatch, isFalse);
    });
  });

  group('BuildCheckResults', () {
    test('생성 및 필드 접근', () {
      final results = BuildCheckResults(
        deviceInfo: 'samsung galaxy s24',
        vmKeywords: ['emulator', 'virtual'],
        bluestacksKeywords: ['bluestacks'],
        hardwareKeywords: ['goldfish'],
        manufacturerKeywords: ['genymotion'],
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
      expect(results.deviceInfo, contains('samsung'));
      expect(results.vmKeywords.length, equals(2));
      expect(results.checkResults['has_vm_keywords'], isFalse);
    });
  });

  group('HardwareCheckResults', () {
    test('생성 및 필드 접근', () {
      final results = HardwareCheckResults(
        cpuKeywords: ['qemu', 'virtual'],
        hasSensors: true,
        checkResults: {
          'suspicious_cpu': false,
          'has_sensors': true,
        },
      );
      expect(results.cpuKeywords.length, equals(2));
      expect(results.hasSensors, isTrue);
      expect(results.checkResults['suspicious_cpu'], isFalse);
    });
  });
}
