import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/virtual_machine_detector.dart';

void main() {
  group('VMDetectionConfig', () {
    test('all constant values', () {
      expect(VMDetectionConfig.enableBuildCheck, isTrue);
      expect(VMDetectionConfig.enableHardwareCheck, isTrue);
      expect(VMDetectionConfig.enableNetworkCheck, isFalse);
      expect(VMDetectionConfig.enableSamsungStrictCheck, isFalse);
      expect(VMDetectionConfig.enableSentryReport, isTrue);
      expect(VMDetectionConfig.disableInDebugMode, isTrue);
    });

    test('isVMCheckDisabled is false by default', () {
      expect(VMDetectionConfig.isVMCheckDisabled, isFalse);
    });

    test('isVMCheckDisabled is consistent across calls', () {
      final first = VMDetectionConfig.isVMCheckDisabled;
      final second = VMDetectionConfig.isVMCheckDisabled;
      expect(first, equals(second));
    });
  });

  group('KeywordMatch', () {
    test('matched keyword', () {
      final match = KeywordMatch('emulator', true);
      expect(match.keyword, 'emulator');
      expect(match.isMatch, isTrue);
    });

    test('unmatched keyword', () {
      final match = KeywordMatch('samsung', false);
      expect(match.keyword, 'samsung');
      expect(match.isMatch, isFalse);
    });

    test('empty keyword', () {
      final match = KeywordMatch('', false);
      expect(match.keyword, '');
      expect(match.isMatch, isFalse);
    });

    test('special characters in keyword', () {
      final match = KeywordMatch('sdk_gphone64', true);
      expect(match.keyword, 'sdk_gphone64');
      expect(match.isMatch, isTrue);
    });

    test('unicode keyword', () {
      final match = KeywordMatch('에뮬레이터', true);
      expect(match.keyword, '에뮬레이터');
    });
  });

  group('BuildCheckResults', () {
    test('empty results', () {
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
        checkResults: {
          'has_vm_keywords': false,
          'has_bluestacks_keywords': false,
          'suspicious_hardware': false,
          'suspicious_manufacturer': false,
        },
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
      expect(results.checkResults['has_vm_keywords'], isFalse);
      expect(results.checkResults['has_bluestacks_keywords'], isFalse);
      expect(results.checkResults['suspicious_hardware'], isFalse);
      expect(results.checkResults['suspicious_manufacturer'], isFalse);
    });

    test('stores keyword lists', () {
      final results = BuildCheckResults(
        deviceInfo: 'samsung galaxy s24 ultra',
        vmKeywords: ['emulator', 'virtual', 'sdk'],
        bluestacksKeywords: ['bluestacks', 'bst', 'hd-player'],
        hardwareKeywords: ['goldfish', 'ranchu', 'cutf'],
        manufacturerKeywords: ['genymotion', 'tencent', 'nox'],
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
      expect(results.vmKeywords, hasLength(3));
      expect(results.bluestacksKeywords, hasLength(3));
      expect(results.hardwareKeywords, hasLength(3));
      expect(results.manufacturerKeywords, hasLength(3));
    });
  });

  group('HardwareCheckResults', () {
    test('normal device - has sensors', () {
      final results = HardwareCheckResults(
        cpuKeywords: ['qemu', 'virtual', 'hypervisor'],
        hasSensors: true,
        checkResults: {
          'cpu_info_full': 'Qualcomm Snapdragon 8 Gen 3',
          'has_sensors': true,
          'suspicious_cpu': false,
          'supported_abis': ['arm64-v8a', 'armeabi-v7a'],
          'is_physical_device': true,
        },
      );
      expect(results.hasSensors, isTrue);
      expect(results.cpuKeywords, hasLength(3));
      expect(results.checkResults['suspicious_cpu'], isFalse);
      expect(results.checkResults['is_physical_device'], isTrue);
      expect(results.checkResults['cpu_info_full'], contains('Qualcomm'));
    });

    test('emulator device - no sensors', () {
      final results = HardwareCheckResults(
        cpuKeywords: ['qemu'],
        hasSensors: false,
        checkResults: {
          'cpu_info_full': 'QEMU Virtual CPU version 2.5+',
          'has_sensors': false,
          'suspicious_cpu': true,
          'supported_abis': ['x86_64', 'x86'],
          'is_physical_device': false,
        },
      );
      expect(results.hasSensors, isFalse);
      expect(results.checkResults['suspicious_cpu'], isTrue);
      expect(results.checkResults['is_physical_device'], isFalse);
    });

    test('empty CPU keywords', () {
      final results = HardwareCheckResults(
        cpuKeywords: [],
        hasSensors: true,
        checkResults: {},
      );
      expect(results.cpuKeywords, isEmpty);
      expect(results.checkResults, isEmpty);
    });

    test('many CPU keywords', () {
      final results = HardwareCheckResults(
        cpuKeywords: ['qemu', 'virtual', 'hypervisor', 'kvm', 'bochs'],
        hasSensors: true,
        checkResults: {
          'cpu_info_full': 'Intel(R) Core(TM) i7',
          'has_sensors': true,
          'suspicious_cpu': false,
        },
      );
      expect(results.cpuKeywords, hasLength(5));
      expect(results.cpuKeywords, contains('qemu'));
      expect(results.cpuKeywords, contains('hypervisor'));
      expect(results.cpuKeywords, contains('kvm'));
      expect(results.cpuKeywords, contains('bochs'));
    });
  });

  group('VirtualMachineDetector.sanitizeKeywords', () {
    test('null config returns empty list', () {
      expect(VirtualMachineDetector.sanitizeKeywords(null), isEmpty);
    });

    test('empty config returns empty list', () {
      expect(VirtualMachineDetector.sanitizeKeywords(''), isEmpty);
    });

    test('single keyword', () {
      expect(
        VirtualMachineDetector.sanitizeKeywords('emulator'),
        equals(['emulator']),
      );
    });

    test('multiple keywords', () {
      expect(
        VirtualMachineDetector.sanitizeKeywords('emulator,sdk,generic'),
        equals(['emulator', 'sdk', 'generic']),
      );
    });

    test('trailing comma - filters empty string', () {
      expect(
        VirtualMachineDetector.sanitizeKeywords('emulator,sdk,'),
        equals(['emulator', 'sdk']),
      );
    });

    test('leading comma - filters empty string', () {
      expect(
        VirtualMachineDetector.sanitizeKeywords(',emulator,sdk'),
        equals(['emulator', 'sdk']),
      );
    });

    test('multiple commas - filters empty strings', () {
      expect(
        VirtualMachineDetector.sanitizeKeywords('a,,b,,,c'),
        equals(['a', 'b', 'c']),
      );
    });
  });

  group('VirtualMachineDetector.containsWholeToken', () {
    test('empty keyword returns false', () {
      expect(
        VirtualMachineDetector.containsWholeToken('some text', ''),
        isFalse,
      );
    });

    test('exact match as whole token', () {
      expect(
        VirtualMachineDetector.containsWholeToken('emulator', 'emulator'),
        isTrue,
      );
    });

    test('match at start of string', () {
      expect(
        VirtualMachineDetector.containsWholeToken(
            'emulator device', 'emulator'),
        isTrue,
      );
    });

    test('match at end of string', () {
      expect(
        VirtualMachineDetector.containsWholeToken('my emulator', 'emulator'),
        isTrue,
      );
    });

    test('match in middle of string', () {
      expect(
        VirtualMachineDetector.containsWholeToken(
            'this emulator here', 'emulator'),
        isTrue,
      );
    });

    test('partial match - not a whole token', () {
      expect(
        VirtualMachineDetector.containsWholeToken('sdk_gphone64', 'sdk'),
        isFalse,
      );
    });

    test('case insensitive match', () {
      expect(
        VirtualMachineDetector.containsWholeToken('EMULATOR', 'emulator'),
        isTrue,
      );
      expect(
        VirtualMachineDetector.containsWholeToken('Emulator', 'emulator'),
        isTrue,
      );
    });

    test('keyword with special regex characters', () {
      expect(
        VirtualMachineDetector.containsWholeToken('version 2.5', '2.5'),
        isTrue,
      );
    });

    test('no match returns false', () {
      expect(
        VirtualMachineDetector.containsWholeToken(
            'samsung galaxy', 'emulator'),
        isFalse,
      );
    });

    test('partial word does not match', () {
      expect(
        VirtualMachineDetector.containsWholeToken('emulator device', 'emu'),
        isFalse,
      );
    });

    test('match separated by special characters', () {
      expect(
        VirtualMachineDetector.containsWholeToken(
            'type:emulator:mode', 'emulator'),
        isTrue,
      );
    });

    test('match separated by spaces', () {
      expect(
        VirtualMachineDetector.containsWholeToken(
            'this is emulator based', 'emulator'),
        isTrue,
      );
    });

    test('match at beginning with hyphen', () {
      expect(
        VirtualMachineDetector.containsWholeToken(
            '-emulator stuff', 'emulator'),
        isTrue,
      );
    });
  });

  group('VirtualMachineDetector.checkHardwareWithInfo', () {
    test('normal device - not suspicious', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'Qualcomm Snapdragon 8 Gen 3',
          true,
          'goldfish,ranchu',
        ),
        isFalse,
      );
    });

    test('no sensors makes suspicious', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'Qualcomm Snapdragon 8 Gen 3',
          false,
          '',
        ),
        isTrue,
      );
    });

    test('qemu in CPU info makes suspicious', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'QEMU Virtual CPU version 2.5+',
          true,
          '',
        ),
        isTrue,
      );
    });

    test('hypervisor in CPU info makes suspicious', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'Intel with Hypervisor enabled',
          true,
          '',
        ),
        isTrue,
      );
    });

    test('virtual in CPU info makes suspicious', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'Virtual Machine CPU',
          true,
          '',
        ),
        isTrue,
      );
    });

    test('keyword match in CPU info makes suspicious', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'CPU: goldfish processor',
          true,
          'goldfish,ranchu',
        ),
        isTrue,
      );
    });

    test('null cpuKeywordsConfig with clean CPU', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'ARM Cortex-A78',
          true,
          null,
        ),
        isFalse,
      );
    });

    test('empty cpuKeywordsConfig with clean CPU and sensors', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'ARM Cortex-A78',
          true,
          '',
        ),
        isFalse,
      );
    });

    test('both suspicious CPU and no sensors', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'QEMU Virtual CPU',
          false,
          'qemu',
        ),
        isTrue,
      );
    });
  });

  group('VirtualMachineDetector.checkNetworkWithInfo', () {
    test('no suspicious network', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            64, 'AA:BB:CC:DD:EE:FF', ['1,5', '00:50:56']),
        isFalse,
      );
    });

    test('TTL in suspicious range', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(3, null, ['1,5', '']),
        isTrue,
      );
    });

    test('TTL exactly at lower bound', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(1, null, ['1,5', '']),
        isTrue,
      );
    });

    test('TTL exactly at upper bound', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(5, null, ['1,5', '']),
        isTrue,
      );
    });

    test('TTL outside range', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(64, null, ['1,5', '']),
        isFalse,
      );
    });

    test('null TTL', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(null, null, ['1,5', '']),
        isFalse,
      );
    });

    test('suspicious MAC address', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            null, '00:50:56:AA:BB:CC', ['', '00:50:56']),
        isTrue,
      );
    });

    test('MAC address not matching', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            null, 'AA:BB:CC:DD:EE:FF', ['', '00:50:56']),
        isFalse,
      );
    });

    test('null MAC address', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            null, null, ['', '00:50:56']),
        isFalse,
      );
    });

    test('invalid TTL range format', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(3, null, ['invalid', '']),
        isFalse,
      );
    });

    test('single TTL range value (not 2)', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(3, null, ['5', '']),
        isFalse,
      );
    });

    test('three TTL range values', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(3, null, ['1,3,5', '']),
        isFalse,
      );
    });

    test('both TTL and MAC suspicious', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            3, '00:50:56:AA:BB:CC', ['1,5', '00:50:56']),
        isTrue,
      );
    });

    test('empty configs', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(3, 'AA:BB', [null, null]),
        isFalse,
      );
    });

    test('multiple MAC keywords', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            null, '08:00:27:AA:BB:CC', ['', '00:50:56,08:00:27']),
        isTrue,
      );
    });

    test('MAC keyword but empty string does not match', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            null, 'AA:BB:CC', ['', ',']),
        isFalse,
      );
    });
  });

  group('VirtualMachineDetector.parseTTLFromPingOutput', () {
    test('extracts TTL from ping output', () {
      const output =
          'PING 8.8.8.8 (8.8.8.8): 56 data bytes\n64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=10.123 ms';
      expect(VirtualMachineDetector.parseTTLFromPingOutput(output), equals(117));
    });

    test('no TTL in output returns null', () {
      const output = 'Request timeout for icmp_seq 0';
      expect(VirtualMachineDetector.parseTTLFromPingOutput(output), isNull);
    });

    test('TTL value 1', () {
      expect(
        VirtualMachineDetector.parseTTLFromPingOutput('ttl=1'),
        equals(1),
      );
    });

    test('TTL value 255', () {
      expect(
        VirtualMachineDetector.parseTTLFromPingOutput('ttl=255'),
        equals(255),
      );
    });

    test('empty output returns null', () {
      expect(VirtualMachineDetector.parseTTLFromPingOutput(''), isNull);
    });

    test('TTL in typical Linux ping output', () {
      const output =
          '64 bytes from 8.8.8.8: icmp_seq=1 ttl=64 time=0.045 ms';
      expect(VirtualMachineDetector.parseTTLFromPingOutput(output), equals(64));
    });
  });

  group('VirtualMachineDetector.countProcessorsFromCpuInfo', () {
    test('single processor', () {
      const cpuInfo = '''processor\t: 0
vendor_id\t: GenuineIntel
model name\t: Intel(R) Core(TM) i7
''';
      expect(
        VirtualMachineDetector.countProcessorsFromCpuInfo(cpuInfo),
        equals(1),
      );
    });

    test('multiple processors', () {
      const cpuInfo = '''processor\t: 0
vendor_id\t: GenuineIntel

processor\t: 1
vendor_id\t: GenuineIntel

processor\t: 2
vendor_id\t: GenuineIntel

processor\t: 3
vendor_id\t: GenuineIntel
''';
      expect(
        VirtualMachineDetector.countProcessorsFromCpuInfo(cpuInfo),
        equals(4),
      );
    });

    test('empty cpuinfo returns 0', () {
      expect(
        VirtualMachineDetector.countProcessorsFromCpuInfo(''),
        equals(0),
      );
    });

    test('no processor lines returns 0', () {
      const cpuInfo = '''vendor_id\t: GenuineIntel
model name\t: Intel(R) Core(TM) i7
''';
      expect(
        VirtualMachineDetector.countProcessorsFromCpuInfo(cpuInfo),
        equals(0),
      );
    });

    test('case insensitive processor matching', () {
      const cpuInfo = '''Processor\t: 0
vendor_id\t: GenuineIntel

PROCESSOR\t: 1
vendor_id\t: GenuineIntel
''';
      expect(
        VirtualMachineDetector.countProcessorsFromCpuInfo(cpuInfo),
        equals(2),
      );
    });
  });

  group('build check determination logic', () {
    bool isBuildSuspicious(Map<String, dynamic> checkResults) {
      return checkResults['has_vm_keywords'] == true ||
          checkResults['has_bluestacks_keywords'] == true ||
          checkResults['suspicious_hardware'] == true ||
          checkResults['suspicious_manufacturer'] == true;
    }

    test('all false - not suspicious', () {
      expect(
        isBuildSuspicious({
          'has_vm_keywords': false,
          'has_bluestacks_keywords': false,
          'suspicious_hardware': false,
          'suspicious_manufacturer': false,
        }),
        isFalse,
      );
    });

    test('only vm keywords - suspicious', () {
      expect(
        isBuildSuspicious({
          'has_vm_keywords': true,
          'has_bluestacks_keywords': false,
          'suspicious_hardware': false,
          'suspicious_manufacturer': false,
        }),
        isTrue,
      );
    });

    test('only bluestacks - suspicious', () {
      expect(
        isBuildSuspicious({
          'has_vm_keywords': false,
          'has_bluestacks_keywords': true,
          'suspicious_hardware': false,
          'suspicious_manufacturer': false,
        }),
        isTrue,
      );
    });

    test('only hardware - suspicious', () {
      expect(
        isBuildSuspicious({
          'has_vm_keywords': false,
          'has_bluestacks_keywords': false,
          'suspicious_hardware': true,
          'suspicious_manufacturer': false,
        }),
        isTrue,
      );
    });

    test('only manufacturer - suspicious', () {
      expect(
        isBuildSuspicious({
          'has_vm_keywords': false,
          'has_bluestacks_keywords': false,
          'suspicious_hardware': false,
          'suspicious_manufacturer': true,
        }),
        isTrue,
      );
    });

    test('all true - suspicious', () {
      expect(
        isBuildSuspicious({
          'has_vm_keywords': true,
          'has_bluestacks_keywords': true,
          'suspicious_hardware': true,
          'suspicious_manufacturer': true,
        }),
        isTrue,
      );
    });
  });

  group('overall detection logic', () {
    bool isEmulator(bool buildInfo, bool hardwareCheck, bool networkCheck) {
      return buildInfo || hardwareCheck || networkCheck;
    }

    test('all false - not emulator', () {
      expect(isEmulator(false, false, false), isFalse);
    });

    test('only build - emulator', () {
      expect(isEmulator(true, false, false), isTrue);
    });

    test('only hardware - emulator', () {
      expect(isEmulator(false, true, false), isTrue);
    });

    test('only network - emulator', () {
      expect(isEmulator(false, false, true), isTrue);
    });

    test('all true - emulator', () {
      expect(isEmulator(true, true, true), isTrue);
    });
  });

  group('VirtualMachineDetector class', () {
    test('class exists', () {
      expect(VirtualMachineDetector, isNotNull);
    });
  });

  group('VirtualMachineDetector.checkHardwareWithInfo - additional branches', () {
    test('cpuKeywords config match takes priority over built-in keywords', () {
      // Only cpuKeywordsConfig match, no built-in keyword match, has sensors
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'CPU: ranchu processor rev 1',
          true,
          'ranchu,goldfish',
        ),
        isTrue,
      );
    });

    test('case insensitive match for Hypervisor', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'CPU has HYPERVISOR flag',
          true,
          '',
        ),
        isTrue,
      );
    });

    test('case insensitive match for VIRTUAL', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'VIRTUAL MACHINE CPU',
          true,
          '',
        ),
        isTrue,
      );
    });

    test('case insensitive match for QEMU', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'running on QEMU platform',
          true,
          '',
        ),
        isTrue,
      );
    });

    test('cpuInfo with mixed case keywords still detected', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'HyPerViSoR detected',
          true,
          null,
        ),
        isTrue,
      );
    });

    test('multiple cpuKeywords in config, only second matches', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'CPU: ranchu processor',
          true,
          'goldfish,ranchu,cutf',
        ),
        isTrue,
      );
    });

    test('no sensors alone is suspicious even with clean CPU and null config', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'ARM Cortex-A78 real device',
          false,
          null,
        ),
        isTrue,
      );
    });

    test('cpuInfo contains keyword substring but also has sensors', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'processor with virtual extensions',
          true,
          '',
        ),
        isTrue, // 'virtual' is a built-in keyword
      );
    });

    test('empty cpuInfo with sensors is not suspicious', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          '',
          true,
          '',
        ),
        isFalse,
      );
    });

    test('empty cpuInfo without sensors is suspicious', () {
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          '',
          false,
          '',
        ),
        isTrue,
      );
    });
  });

  group('VirtualMachineDetector.checkNetworkWithInfo - additional branches', () {
    test('TTL range with non-numeric first value', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(3, null, ['abc,5', '']),
        isFalse,
      );
    });

    test('TTL range with non-numeric second value', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(3, null, ['1,xyz', '']),
        isFalse,
      );
    });

    test('TTL just below lower bound', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(0, null, ['1,5', '']),
        isFalse,
      );
    });

    test('TTL just above upper bound', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(6, null, ['1,5', '']),
        isFalse,
      );
    });

    test('MAC address matching first of multiple keywords', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            null, '00:50:56:XX:YY:ZZ', ['', '00:50:56,08:00:27']),
        isTrue,
      );
    });

    test('MAC address does not match any keyword', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            null, 'AA:BB:CC:DD:EE:FF', ['', '00:50:56,08:00:27']),
        isFalse,
      );
    });

    test('null MAC with valid TTL range but TTL outside', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(128, null, ['1,5', '00:50:56']),
        isFalse,
      );
    });

    test('empty TTL range config', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(3, null, ['', '']),
        isFalse,
      );
    });

    test('null TTL range config', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(3, null, [null, null]),
        isFalse,
      );
    });

    test('both configs null with valid TTL and MAC', () {
      expect(
        VirtualMachineDetector.checkNetworkWithInfo(
            3, '00:50:56:AA', [null, null]),
        isFalse,
      );
    });
  });

  group('VirtualMachineDetector.sanitizeKeywords - additional edge cases', () {
    test('whitespace-only keyword is preserved', () {
      // ' ' is not empty, so it should be kept
      expect(
        VirtualMachineDetector.sanitizeKeywords(' '),
        equals([' ']),
      );
    });

    test('keywords with spaces', () {
      expect(
        VirtualMachineDetector.sanitizeKeywords('hello world,foo bar'),
        equals(['hello world', 'foo bar']),
      );
    });

    test('only commas returns empty', () {
      expect(
        VirtualMachineDetector.sanitizeKeywords(',,,'),
        isEmpty,
      );
    });
  });

  group('VirtualMachineDetector.containsWholeToken - additional edge cases', () {
    test('keyword with underscore not matched as part of word', () {
      expect(
        VirtualMachineDetector.containsWholeToken('sdk_gphone64_arm64', 'sdk'),
        isFalse,
      );
    });

    test('keyword separated by dot', () {
      expect(
        VirtualMachineDetector.containsWholeToken('com.emulator.test', 'emulator'),
        isTrue,
      );
    });

    test('keyword with numbers at boundaries', () {
      expect(
        VirtualMachineDetector.containsWholeToken('test123emulator456', 'emulator'),
        isFalse, // digits are word chars
      );
    });

    test('keyword is entire string', () {
      expect(
        VirtualMachineDetector.containsWholeToken('qemu', 'qemu'),
        isTrue,
      );
    });

    test('keyword with parentheses', () {
      expect(
        VirtualMachineDetector.containsWholeToken('(emulator)', 'emulator'),
        isTrue,
      );
    });

    test('keyword with brackets', () {
      expect(
        VirtualMachineDetector.containsWholeToken('[emulator]', 'emulator'),
        isTrue,
      );
    });
  });

  group('VirtualMachineDetector.parseTTLFromPingOutput - additional cases', () {
    test('multiple ttl values returns first', () {
      const output = 'ttl=64 ttl=128';
      expect(VirtualMachineDetector.parseTTLFromPingOutput(output), equals(64));
    });

    test('ttl= with no digits returns null', () {
      const output = 'ttl=abc';
      expect(VirtualMachineDetector.parseTTLFromPingOutput(output), isNull);
    });

    test('TTL in Windows-style ping output', () {
      const output = 'Reply from 8.8.8.8: bytes=32 time=10ms TTL=128';
      // Regex is case sensitive, only matches lowercase ttl
      expect(VirtualMachineDetector.parseTTLFromPingOutput(output), isNull);
    });
  });

  group('VirtualMachineDetector.countProcessorsFromCpuInfo - additional cases', () {
    test('processor line with leading whitespace', () {
      const cpuInfo = '  processor\t: 0\n';
      expect(
        VirtualMachineDetector.countProcessorsFromCpuInfo(cpuInfo),
        equals(1), // trim() removes leading whitespace
      );
    });

    test('processor line without tab separator', () {
      const cpuInfo = 'processor : 0\n';
      expect(
        VirtualMachineDetector.countProcessorsFromCpuInfo(cpuInfo),
        equals(1),
      );
    });

    test('line containing processor but not starting with it', () {
      const cpuInfo = 'my processor is fast\n';
      expect(
        VirtualMachineDetector.countProcessorsFromCpuInfo(cpuInfo),
        equals(0),
      );
    });

    test('eight processors', () {
      final cpuInfo = List.generate(8, (i) => 'processor\t: $i\n').join('\n');
      expect(
        VirtualMachineDetector.countProcessorsFromCpuInfo(cpuInfo),
        equals(8),
      );
    });
  });

  group('emulator scenario tests', () {
    test('normal Samsung device - not detected', () {
      // Build check: no keyword matches
      expect(
        VirtualMachineDetector.containsWholeToken(
          'samsung sm-s926n galaxy s24 ultra exynos2400',
          'emulator',
        ),
        isFalse,
      );
      // Hardware check: real CPU with sensors
      expect(
        VirtualMachineDetector.checkHardwareWithInfo(
          'Qualcomm Snapdragon 8 Gen 3',
          true,
          'qemu,virtual',
        ),
        isFalse,
      );
    });

    test('Nox Player emulator detected via keywords', () {
      expect(
        VirtualMachineDetector.containsWholeToken(
          'nox nox_app_player vbox86p goldfish',
          'nox',
        ),
        isTrue,
      );
    });

    test('Google Pixel emulator detected via emulator keyword', () {
      expect(
        VirtualMachineDetector.containsWholeToken(
          'google sdk_gphone64_arm64 emulator ranchu',
          'emulator',
        ),
        isTrue,
      );
    });

    test('keyword filtering pattern', () {
      final keywords = ['emulator', 'sdk', 'samsung', 'goldfish'];
      final deviceInfo = 'samsung galaxy s24';

      final matches = keywords
          .where((keyword) =>
              deviceInfo.toLowerCase().contains(keyword.toLowerCase()))
          .toList();

      expect(matches, hasLength(1));
      expect(matches.first, 'samsung');
    });

    test('compound checkResults pass/fail', () {
      final normalResults = {
        'has_vm_keywords': false,
        'has_bluestacks_keywords': false,
        'suspicious_hardware': false,
        'suspicious_manufacturer': false,
      };
      final isNormalEmulator = normalResults.values.any((v) => v == true);
      expect(isNormalEmulator, isFalse);

      final suspiciousResults = {
        'has_vm_keywords': false,
        'has_bluestacks_keywords': false,
        'suspicious_hardware': true,
        'suspicious_manufacturer': false,
      };
      final isSuspiciousEmulator =
          suspiciousResults.values.any((v) => v == true);
      expect(isSuspiciousEmulator, isTrue);
    });
  });
}
