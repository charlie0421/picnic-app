import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/vm_detection_models.dart';

void main() {
  group('VMDetectionConfig', () {
    test('enableBuildCheck defaults to true', () {
      expect(VMDetectionConfig.enableBuildCheck, isTrue);
    });

    test('enableHardwareCheck defaults to true', () {
      expect(VMDetectionConfig.enableHardwareCheck, isTrue);
    });

    test('enableNetworkCheck defaults to false', () {
      expect(VMDetectionConfig.enableNetworkCheck, isFalse);
    });

    test('enableSamsungStrictCheck defaults to false', () {
      expect(VMDetectionConfig.enableSamsungStrictCheck, isFalse);
    });

    test('enableSentryReport defaults to true', () {
      expect(VMDetectionConfig.enableSentryReport, isTrue);
    });

    test('disableInDebugMode defaults to true', () {
      expect(VMDetectionConfig.disableInDebugMode, isTrue);
    });

    test('isVMCheckDisabled returns false by default', () {
      expect(VMDetectionConfig.isVMCheckDisabled, isFalse);
    });
  });

  group('KeywordMatch', () {
    test('constructs with keyword and isMatch=true', () {
      final match = KeywordMatch('emulator', true);

      expect(match.keyword, 'emulator');
      expect(match.isMatch, isTrue);
    });

    test('constructs with keyword and isMatch=false', () {
      final match = KeywordMatch('samsung', false);

      expect(match.keyword, 'samsung');
      expect(match.isMatch, isFalse);
    });
  });

  group('BuildCheckResults', () {
    test('constructs with all required fields', () {
      final vmMatches = [KeywordMatch('generic', true)];
      final bluestacksMatches = [KeywordMatch('bluestacks', false)];
      final hardwareMatches = [KeywordMatch('goldfish', true)];
      final manufacturerMatches = [KeywordMatch('unknown', false)];
      final checkResults = <String, dynamic>{'isVM': true};

      final results = BuildCheckResults(
        deviceInfo: 'Test Device Info',
        vmKeywords: ['generic', 'virtual'],
        bluestacksKeywords: ['bluestacks'],
        hardwareKeywords: ['goldfish'],
        manufacturerKeywords: ['unknown'],
        vmMatches: vmMatches,
        bluestacksMatches: bluestacksMatches,
        hardwareMatches: hardwareMatches,
        manufacturerMatches: manufacturerMatches,
        checkResults: checkResults,
      );

      expect(results.deviceInfo, 'Test Device Info');
      expect(results.vmKeywords, ['generic', 'virtual']);
      expect(results.bluestacksKeywords, ['bluestacks']);
      expect(results.hardwareKeywords, ['goldfish']);
      expect(results.manufacturerKeywords, ['unknown']);
      expect(results.vmMatches, vmMatches);
      expect(results.bluestacksMatches, bluestacksMatches);
      expect(results.hardwareMatches, hardwareMatches);
      expect(results.manufacturerMatches, manufacturerMatches);
      expect(results.checkResults, checkResults);
    });

    test('constructs with empty lists and map', () {
      final results = BuildCheckResults(
        deviceInfo: '',
        vmKeywords: [],
        bluestacksKeywords: [],
        hardwareKeywords: [],
        manufacturerKeywords: [],
        vmMatches: [],
        bluestacksMatches: [],
        hardwareMatches: [],
        manufacturerMatches: [],
        checkResults: {},
      );

      expect(results.deviceInfo, isEmpty);
      expect(results.vmKeywords, isEmpty);
      expect(results.bluestacksKeywords, isEmpty);
      expect(results.hardwareKeywords, isEmpty);
      expect(results.manufacturerKeywords, isEmpty);
      expect(results.vmMatches, isEmpty);
      expect(results.bluestacksMatches, isEmpty);
      expect(results.hardwareMatches, isEmpty);
      expect(results.manufacturerMatches, isEmpty);
      expect(results.checkResults, isEmpty);
    });
  });

  group('HardwareCheckResults', () {
    test('constructs with all required fields', () {
      final checkResults = <String, dynamic>{
        'cpuCheck': true,
        'sensorCheck': false,
      };

      final results = HardwareCheckResults(
        cpuKeywords: ['qemu', 'virtual'],
        hasSensors: true,
        checkResults: checkResults,
      );

      expect(results.cpuKeywords, ['qemu', 'virtual']);
      expect(results.hasSensors, isTrue);
      expect(results.checkResults, checkResults);
    });

    test('constructs with hasSensors=false', () {
      final results = HardwareCheckResults(
        cpuKeywords: [],
        hasSensors: false,
        checkResults: {},
      );

      expect(results.cpuKeywords, isEmpty);
      expect(results.hasSensors, isFalse);
      expect(results.checkResults, isEmpty);
    });
  });
}
