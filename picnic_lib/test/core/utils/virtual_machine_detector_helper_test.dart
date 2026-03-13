import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/virtual_machine_detector_helper.dart';

void main() {
  // ===========================================================================
  // sanitizeKeywords
  // ===========================================================================
  group('sanitizeKeywords', () {
    test('returns empty list for null', () {
      expect(VirtualMachineDetectorHelper.sanitizeKeywords(null), isEmpty);
    });

    test('returns empty list for empty string', () {
      expect(VirtualMachineDetectorHelper.sanitizeKeywords(''), isEmpty);
    });

    test('splits comma-separated values', () {
      expect(
        VirtualMachineDetectorHelper.sanitizeKeywords('a,b,c'),
        equals(['a', 'b', 'c']),
      );
    });

    test('filters out empty segments from trailing commas', () {
      expect(
        VirtualMachineDetectorHelper.sanitizeKeywords('a,,b,'),
        equals(['a', 'b']),
      );
    });

    test('handles single keyword without commas', () {
      expect(
        VirtualMachineDetectorHelper.sanitizeKeywords('emulator'),
        equals(['emulator']),
      );
    });
  });

  // ===========================================================================
  // containsWholeToken
  // ===========================================================================
  group('containsWholeToken', () {
    test('returns false for empty keyword', () {
      expect(
        VirtualMachineDetectorHelper.containsWholeToken('some text', ''),
        isFalse,
      );
    });

    test('matches whole word bounded by spaces', () {
      expect(
        VirtualMachineDetectorHelper.containsWholeToken(
          'this is qemu based',
          'qemu',
        ),
        isTrue,
      );
    });

    test('does not match substring inside a larger word', () {
      expect(
        VirtualMachineDetectorHelper.containsWholeToken(
          'myqemuhost',
          'qemu',
        ),
        isFalse,
      );
    });

    test('matches at start of string', () {
      expect(
        VirtualMachineDetectorHelper.containsWholeToken('qemu device', 'qemu'),
        isTrue,
      );
    });

    test('matches at end of string', () {
      expect(
        VirtualMachineDetectorHelper.containsWholeToken(
          'device qemu',
          'qemu',
        ),
        isTrue,
      );
    });

    test('is case-insensitive', () {
      expect(
        VirtualMachineDetectorHelper.containsWholeToken('QEMU device', 'qemu'),
        isTrue,
      );
    });

    test('handles regex special characters in keyword', () {
      expect(
        VirtualMachineDetectorHelper.containsWholeToken(
          'version (1.0)',
          '(1.0)',
        ),
        isTrue,
      );
    });

    test('does not match when keyword is part of underscore-connected word', () {
      expect(
        VirtualMachineDetectorHelper.containsWholeToken(
          'my_qemu_host',
          'qemu',
        ),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // findMatchingKeywords / findContainedKeywords
  // ===========================================================================
  group('findMatchingKeywords', () {
    test('returns only whole-token matches', () {
      final result = VirtualMachineDetectorHelper.findMatchingKeywords(
        'this is qemu and nox device',
        ['qemu', 'nox', 'bluestacks'],
      );
      expect(result, containsAll(['qemu', 'nox']));
      expect(result, isNot(contains('bluestacks')));
    });

    test('returns empty list when nothing matches', () {
      expect(
        VirtualMachineDetectorHelper.findMatchingKeywords(
          'samsung galaxy s24',
          ['qemu', 'virtual'],
        ),
        isEmpty,
      );
    });
  });

  group('findContainedKeywords', () {
    test('finds substring matches case-insensitively', () {
      final result = VirtualMachineDetectorHelper.findContainedKeywords(
        'Goldfish-Hardware',
        ['goldfish', 'ranchu'],
      );
      expect(result, equals(['goldfish']));
    });

    test('returns empty when no substring matches', () {
      expect(
        VirtualMachineDetectorHelper.findContainedKeywords(
          'exynos',
          ['goldfish', 'ranchu'],
        ),
        isEmpty,
      );
    });
  });

  // ===========================================================================
  // evaluateBuildKeywords / isBuildSuspicious
  // ===========================================================================
  group('evaluateBuildKeywords', () {
    test('detects VM keywords', () {
      final result = VirtualMachineDetectorHelper.evaluateBuildKeywords(
        deviceInfoLower: 'generic qemu emulator',
        hardwareLower: 'exynos',
        manufacturerLower: 'samsung',
        vmKeywords: ['qemu', 'genymotion'],
        bluestacksKeywords: ['bluestacks'],
        hardwareKeywords: ['goldfish'],
        manufacturerKeywords: ['unknown'],
      );
      expect(result['has_vm_keywords'], isTrue);
      expect(result['has_bluestacks_keywords'], isFalse);
      expect(result['suspicious_hardware'], isFalse);
      expect(result['suspicious_manufacturer'], isFalse);
    });

    test('detects bluestacks keywords', () {
      final result = VirtualMachineDetectorHelper.evaluateBuildKeywords(
        deviceInfoLower: 'oneplus bluestacks emulator',
        hardwareLower: 'ranchu',
        manufacturerLower: 'bluestacks',
        vmKeywords: ['qemu'],
        bluestacksKeywords: ['bluestacks'],
        hardwareKeywords: ['ranchu'],
        manufacturerKeywords: ['bluestacks'],
      );
      expect(result['has_bluestacks_keywords'], isTrue);
      expect(result['suspicious_hardware'], isTrue);
      expect(result['suspicious_manufacturer'], isTrue);
    });

    test('flags empty hardware as suspicious', () {
      final result = VirtualMachineDetectorHelper.evaluateBuildKeywords(
        deviceInfoLower: 'normal device',
        hardwareLower: '',
        manufacturerLower: 'samsung',
        vmKeywords: [],
        bluestacksKeywords: [],
        hardwareKeywords: [],
        manufacturerKeywords: [],
      );
      expect(result['suspicious_hardware'], isTrue);
    });

    test('returns all false for a clean device', () {
      final result = VirtualMachineDetectorHelper.evaluateBuildKeywords(
        deviceInfoLower: 'samsung sm-s926n galaxy s24 ultra exynos',
        hardwareLower: 'exynos2400',
        manufacturerLower: 'samsung',
        vmKeywords: ['qemu', 'genymotion', 'nox'],
        bluestacksKeywords: ['bluestacks'],
        hardwareKeywords: ['goldfish', 'ranchu'],
        manufacturerKeywords: ['unknown'],
      );
      expect(result.values.every((v) => v == false), isTrue);
    });
  });

  group('isBuildSuspicious', () {
    test('returns true if any flag is true', () {
      expect(
        VirtualMachineDetectorHelper.isBuildSuspicious({
          'has_vm_keywords': false,
          'has_bluestacks_keywords': false,
          'suspicious_hardware': true,
          'suspicious_manufacturer': false,
        }),
        isTrue,
      );
    });

    test('returns false when all flags are false', () {
      expect(
        VirtualMachineDetectorHelper.isBuildSuspicious({
          'has_vm_keywords': false,
          'has_bluestacks_keywords': false,
          'suspicious_hardware': false,
          'suspicious_manufacturer': false,
        }),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // checkSamsungSuspiciousPatterns
  // ===========================================================================
  group('checkSamsungSuspiciousPatterns', () {
    test('returns empty for non-Samsung device', () {
      expect(
        VirtualMachineDetectorHelper.checkSamsungSuspiciousPatterns(
          manufacturerLower: 'google',
          modelLower: 'pixel 8',
          bootloaderLower: 'unknown',
          systemFeatures: [],
        ),
        isEmpty,
      );
    });

    test('returns empty for Samsung non-SM model', () {
      expect(
        VirtualMachineDetectorHelper.checkSamsungSuspiciousPatterns(
          manufacturerLower: 'samsung',
          modelLower: 'galaxy tab',
          bootloaderLower: 'unknown',
          systemFeatures: [],
        ),
        isEmpty,
      );
    });

    test('detects unknown bootloader on Samsung SM device', () {
      final reasons =
          VirtualMachineDetectorHelper.checkSamsungSuspiciousPatterns(
        manufacturerLower: 'samsung',
        modelLower: 'sm-s926n',
        bootloaderLower: 'unknown',
        systemFeatures: [],
      );
      expect(reasons, contains('unknown_bootloader'));
    });

    test('detects missing Knox on Galaxy model', () {
      final reasons =
          VirtualMachineDetectorHelper.checkSamsungSuspiciousPatterns(
        manufacturerLower: 'samsung',
        modelLower: 'sm-galaxy-s24',
        bootloaderLower: 's926nxxu1axf1',
        systemFeatures: ['android.hardware.sensor.accelerometer'],
      );
      expect(reasons, contains('missing_knox'));
    });

    test('does not flag Knox when present', () {
      final reasons =
          VirtualMachineDetectorHelper.checkSamsungSuspiciousPatterns(
        manufacturerLower: 'samsung',
        modelLower: 'sm-galaxy-s24',
        bootloaderLower: 's926nxxu1axf1',
        systemFeatures: ['com.samsung.android.knox'],
      );
      expect(reasons, isNot(contains('missing_knox')));
    });
  });

  // ===========================================================================
  // checkHardware
  // ===========================================================================
  group('checkHardware', () {
    test('returns true when CPU matches a configured keyword', () {
      expect(
        VirtualMachineDetectorHelper.checkHardware(
          cpuInfoLower: 'processor: intel vbox',
          hasSensors: true,
          cpuKeywords: ['vbox'],
        ),
        isTrue,
      );
    });

    test('returns true when CPU contains hypervisor', () {
      expect(
        VirtualMachineDetectorHelper.checkHardware(
          cpuInfoLower: 'flags: hypervisor avx2',
          hasSensors: true,
          cpuKeywords: [],
        ),
        isTrue,
      );
    });

    test('returns true when CPU contains virtual', () {
      expect(
        VirtualMachineDetectorHelper.checkHardware(
          cpuInfoLower: 'model name: virtual processor',
          hasSensors: true,
          cpuKeywords: [],
        ),
        isTrue,
      );
    });

    test('returns true when CPU contains qemu', () {
      expect(
        VirtualMachineDetectorHelper.checkHardware(
          cpuInfoLower: 'hardware: qemu',
          hasSensors: true,
          cpuKeywords: [],
        ),
        isTrue,
      );
    });

    test('returns true when sensors are missing', () {
      expect(
        VirtualMachineDetectorHelper.checkHardware(
          cpuInfoLower: 'processor: arm cortex-a78',
          hasSensors: false,
          cpuKeywords: [],
        ),
        isTrue,
      );
    });

    test('returns false for clean CPU with sensors', () {
      expect(
        VirtualMachineDetectorHelper.checkHardware(
          cpuInfoLower: 'processor: arm cortex-a78\nhardware: exynos2400',
          hasSensors: true,
          cpuKeywords: ['vbox', 'vmware'],
        ),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // countProcessorsFromCpuInfo
  // ===========================================================================
  group('countProcessorsFromCpuInfo', () {
    test('counts processor lines correctly', () {
      const cpuInfo = '''
processor	: 0
model name	: ARM Cortex-A78
processor	: 1
model name	: ARM Cortex-A78
processor	: 2
model name	: ARM Cortex-A55
''';
      expect(
        VirtualMachineDetectorHelper.countProcessorsFromCpuInfo(cpuInfo),
        equals(3),
      );
    });

    test('returns 0 for empty string', () {
      expect(
        VirtualMachineDetectorHelper.countProcessorsFromCpuInfo(''),
        equals(0),
      );
    });

    test('returns 0 when no processor lines exist', () {
      expect(
        VirtualMachineDetectorHelper.countProcessorsFromCpuInfo(
          'model name: ARM\nhardware: exynos\n',
        ),
        equals(0),
      );
    });

    test('handles leading whitespace on processor lines', () {
      const cpuInfo = '  processor\t: 0\n  processor\t: 1\n';
      expect(
        VirtualMachineDetectorHelper.countProcessorsFromCpuInfo(cpuInfo),
        equals(2),
      );
    });
  });

  // ===========================================================================
  // parseTTLFromPingOutput
  // ===========================================================================
  group('parseTTLFromPingOutput', () {
    test('extracts TTL from typical ping output', () {
      const output =
          '64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=3.42 ms';
      expect(
        VirtualMachineDetectorHelper.parseTTLFromPingOutput(output),
        equals(117),
      );
    });

    test('returns null when no TTL present', () {
      expect(
        VirtualMachineDetectorHelper.parseTTLFromPingOutput(
          'Request timed out.',
        ),
        isNull,
      );
    });

    test('returns null for empty string', () {
      expect(
        VirtualMachineDetectorHelper.parseTTLFromPingOutput(''),
        isNull,
      );
    });
  });

  // ===========================================================================
  // checkNetwork
  // ===========================================================================
  group('checkNetwork', () {
    test('detects suspicious TTL in range', () {
      expect(
        VirtualMachineDetectorHelper.checkNetwork(
          ttl: 65,
          macAddress: null,
          ttlRangeConfig: '60,70',
          macKeywordsConfig: null,
        ),
        isTrue,
      );
    });

    test('does not flag TTL outside range', () {
      expect(
        VirtualMachineDetectorHelper.checkNetwork(
          ttl: 117,
          macAddress: null,
          ttlRangeConfig: '60,70',
          macKeywordsConfig: null,
        ),
        isFalse,
      );
    });

    test('does not flag when TTL is null', () {
      expect(
        VirtualMachineDetectorHelper.checkNetwork(
          ttl: null,
          macAddress: null,
          ttlRangeConfig: '60,70',
          macKeywordsConfig: null,
        ),
        isFalse,
      );
    });

    test('does not flag TTL when range config is malformed', () {
      expect(
        VirtualMachineDetectorHelper.checkNetwork(
          ttl: 65,
          macAddress: null,
          ttlRangeConfig: 'abc,xyz',
          macKeywordsConfig: null,
        ),
        isFalse,
      );
    });

    test('does not flag TTL when range has wrong number of parts', () {
      expect(
        VirtualMachineDetectorHelper.checkNetwork(
          ttl: 65,
          macAddress: null,
          ttlRangeConfig: '60',
          macKeywordsConfig: null,
        ),
        isFalse,
      );
    });

    test('detects suspicious MAC address prefix', () {
      expect(
        VirtualMachineDetectorHelper.checkNetwork(
          ttl: null,
          macAddress: '08:00:27:AB:CD:EF',
          ttlRangeConfig: null,
          macKeywordsConfig: '08:00:27,00:50:56',
        ),
        isTrue,
      );
    });

    test('does not flag clean MAC address', () {
      expect(
        VirtualMachineDetectorHelper.checkNetwork(
          ttl: null,
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ttlRangeConfig: null,
          macKeywordsConfig: '08:00:27,00:50:56',
        ),
        isFalse,
      );
    });

    test('does not flag when MAC is null', () {
      expect(
        VirtualMachineDetectorHelper.checkNetwork(
          ttl: null,
          macAddress: null,
          ttlRangeConfig: null,
          macKeywordsConfig: '08:00:27',
        ),
        isFalse,
      );
    });

    test('returns true when both TTL and MAC are suspicious', () {
      expect(
        VirtualMachineDetectorHelper.checkNetwork(
          ttl: 65,
          macAddress: '08:00:27:AB:CD:EF',
          ttlRangeConfig: '60,70',
          macKeywordsConfig: '08:00:27',
        ),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // hasSufficientSensors
  // ===========================================================================
  group('hasSufficientSensors', () {
    test('returns true with all four sensor features', () {
      expect(
        VirtualMachineDetectorHelper.hasSufficientSensors([
          'android.hardware.sensor.accelerometer',
          'android.hardware.sensor.gyroscope',
          'android.hardware.sensor.compass',
          'android.hardware.touchscreen',
        ]),
        isTrue,
      );
    });

    test('returns true with exactly 2 sensor features (default threshold)', () {
      expect(
        VirtualMachineDetectorHelper.hasSufficientSensors([
          'android.hardware.sensor.accelerometer',
          'android.hardware.touchscreen',
        ]),
        isTrue,
      );
    });

    test('returns false with fewer than threshold', () {
      expect(
        VirtualMachineDetectorHelper.hasSufficientSensors([
          'android.hardware.sensor.accelerometer',
        ]),
        isFalse,
      );
    });

    test('returns false for empty list', () {
      expect(
        VirtualMachineDetectorHelper.hasSufficientSensors([]),
        isFalse,
      );
    });

    test('respects custom threshold', () {
      expect(
        VirtualMachineDetectorHelper.hasSufficientSensors(
          [
            'android.hardware.sensor.accelerometer',
            'android.hardware.sensor.gyroscope',
            'android.hardware.sensor.compass',
          ],
          threshold: 3,
        ),
        isTrue,
      );
    });

    test('ignores non-sensor features', () {
      expect(
        VirtualMachineDetectorHelper.hasSufficientSensors([
          'android.hardware.camera',
          'android.hardware.bluetooth',
          'android.hardware.wifi',
        ]),
        isFalse,
      );
    });
  });

  // ===========================================================================
  // isVirtualMachine (overall scoring)
  // ===========================================================================
  group('isVirtualMachine', () {
    test('returns true when build is suspicious', () {
      expect(
        VirtualMachineDetectorHelper.isVirtualMachine(
          buildSuspicious: true,
          hardwareSuspicious: false,
          networkSuspicious: false,
        ),
        isTrue,
      );
    });

    test('returns true when hardware is suspicious', () {
      expect(
        VirtualMachineDetectorHelper.isVirtualMachine(
          buildSuspicious: false,
          hardwareSuspicious: true,
          networkSuspicious: false,
        ),
        isTrue,
      );
    });

    test('returns true when network is suspicious', () {
      expect(
        VirtualMachineDetectorHelper.isVirtualMachine(
          buildSuspicious: false,
          hardwareSuspicious: false,
          networkSuspicious: true,
        ),
        isTrue,
      );
    });

    test('returns false when nothing is suspicious', () {
      expect(
        VirtualMachineDetectorHelper.isVirtualMachine(
          buildSuspicious: false,
          hardwareSuspicious: false,
          networkSuspicious: false,
        ),
        isFalse,
      );
    });

    test('ignores build when disabled', () {
      expect(
        VirtualMachineDetectorHelper.isVirtualMachine(
          buildSuspicious: true,
          hardwareSuspicious: false,
          networkSuspicious: false,
          buildCheckEnabled: false,
        ),
        isFalse,
      );
    });

    test('ignores hardware when disabled', () {
      expect(
        VirtualMachineDetectorHelper.isVirtualMachine(
          buildSuspicious: false,
          hardwareSuspicious: true,
          networkSuspicious: false,
          hardwareCheckEnabled: false,
        ),
        isFalse,
      );
    });

    test('ignores network when disabled', () {
      expect(
        VirtualMachineDetectorHelper.isVirtualMachine(
          buildSuspicious: false,
          hardwareSuspicious: false,
          networkSuspicious: true,
          networkCheckEnabled: false,
        ),
        isFalse,
      );
    });

    test('returns false when all checks are disabled', () {
      expect(
        VirtualMachineDetectorHelper.isVirtualMachine(
          buildSuspicious: true,
          hardwareSuspicious: true,
          networkSuspicious: true,
          buildCheckEnabled: false,
          hardwareCheckEnabled: false,
          networkCheckEnabled: false,
        ),
        isFalse,
      );
    });
  });
}
