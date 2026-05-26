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

  group('buildDeviceInfoForMatching', () {
    // 2025-02 인시던트 회귀 가드:
    // info.systemFeatures 를 deviceInfo 에 합치면 Samsung 단말의
    // 'com.samsung.android.cloud' 같은 정상 패키지가 'cloud' 키워드에
    // whole-token 매치돼서 594/595 FP 발생함.
    String build({
      String manufacturer = 'samsung',
      String model = 'SM-A125F',
      String brand = 'samsung',
      String fingerprint =
          'samsung/a12nnxx/a12:12/SP1A.210812.016/A125FXXS6CXJ1:user/release-keys',
      String product = 'a12nnxx',
      String device = 'a12',
      String hardware = 'mt6765',
      String host = '21DJ6A01',
      String board = 'a12',
      String bootloader = 'A125FXXS6CXJ1',
      String display = 'SP1A.210812.016.A125FXXS6CXJ1',
      String id = 'SP1A.210812.016',
      String tags = 'release-keys',
      String type = 'user',
      List<String> supported32BitAbis = const ['armeabi-v7a', 'armeabi'],
      List<String> supported64BitAbis = const ['arm64-v8a'],
    }) {
      return VirtualMachineDetector.buildDeviceInfoForMatching(
        manufacturer: manufacturer,
        model: model,
        brand: brand,
        fingerprint: fingerprint,
        product: product,
        device: device,
        hardware: hardware,
        host: host,
        board: board,
        bootloader: bootloader,
        display: display,
        id: id,
        tags: tags,
        type: type,
        supported32BitAbis: supported32BitAbis,
        supported64BitAbis: supported64BitAbis,
      );
    }

    test('lowercased output', () {
      expect(build(), equals(build().toLowerCase()));
    });

    test('includes core build fields', () {
      final out = build();
      expect(out, contains('samsung'));
      expect(out, contains('sm-a125f'));
      expect(out, contains('mt6765'));
      expect(out, contains('a125fxxs6cxj1'));
      expect(out, contains('release-keys'));
    });

    test('includes compound host_product_device and brand_manufacturer_model',
        () {
      final out = build();
      expect(out, contains('21dj6a01_a12nnxx_a12'));
      expect(out, contains('samsung_samsung_sm-a125f'));
    });

    test('includes supported ABIs', () {
      final out = build(
        supported32BitAbis: ['armeabi-v7a', 'armeabi'],
        supported64BitAbis: ['arm64-v8a'],
      );
      expect(out, contains('arm64-v8a'));
      expect(out, contains('armeabi-v7a'));
    });

    test(
      'real Samsung Galaxy A12 input does NOT contain "cloud" '
      '(systemFeatures excluded - regression for 2025-02 FP incident)',
      () {
        final out = build();
        expect(
          VirtualMachineDetector.containsWholeToken(out, 'cloud'),
          isFalse,
          reason:
              'Samsung 정상 system feature (com.samsung.android.cloud) 가 '
              'deviceInfo 에 섞이면 "cloud" 키워드가 FP 매치함. '
              'systemFeatures 를 deviceInfo 합성에서 제외해야 함.',
        );
      },
    );

    test('emulator-indicative fingerprint still matches "emulator" keyword',
        () {
      final out = build(
        manufacturer: 'unknown',
        model: 'Android SDK built for x86_64',
        brand: 'generic',
        fingerprint:
            'generic/sdk_gphone64_x86_64/emulator:13/TE1A.220922.034/9692585:userdebug/test-keys',
        product: 'sdk_gphone64_x86_64',
        device: 'emulator',
        hardware: 'ranchu',
        tags: 'test-keys',
        type: 'userdebug',
      );
      expect(VirtualMachineDetector.containsWholeToken(out, 'emulator'), isTrue);
      expect(VirtualMachineDetector.containsWholeToken(out, 'ranchu'), isTrue);
      expect(VirtualMachineDetector.containsWholeToken(out, 'test-keys'),
          isTrue);
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
