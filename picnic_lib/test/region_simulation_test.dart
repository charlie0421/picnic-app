import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/region_detection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Region Simulation Tests', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should simulate China region in debug mode', () async {
      // This test only works in debug mode
      if (!kDebugMode) {
        return;
      }

      // Simulate China
      await RegionDetectionService.simulateChina();

      // Detect region
      final regionInfo = await RegionDetectionService.detectRegion();

      expect(regionInfo.countryCode, 'CN');
      expect(regionInfo.region, UserRegion.china);
      expect(regionInfo.countryName, 'Debug: CN');
    });

    test('should simulate other region in debug mode', () async {
      // This test only works in debug mode
      if (!kDebugMode) {
        return;
      }

      // Simulate US
      await RegionDetectionService.simulateOtherRegion('US');

      // Detect region
      final regionInfo = await RegionDetectionService.detectRegion();

      expect(regionInfo.countryCode, 'US');
      expect(regionInfo.region, UserRegion.other);
      expect(regionInfo.countryName, 'Debug: US');
    });

    test('should clear simulation in debug mode', () async {
      // This test only works in debug mode
      if (!kDebugMode) {
        return;
      }

      // First simulate China
      await RegionDetectionService.simulateChina();
      var regionInfo = await RegionDetectionService.detectRegion();
      expect(regionInfo.countryCode, 'CN');

      // Clear simulation
      await RegionDetectionService.clearSimulation();

      // Should now use real detection (or fallback)
      regionInfo = await RegionDetectionService.detectRegion();
      expect(regionInfo.countryCode,
          isNot('CN')); // Should not be the simulated CN
    });

    test('should persist debug region override', () async {
      // This test only works in debug mode
      if (!kDebugMode) {
        return;
      }

      // Set debug region
      await RegionDetectionService.setDebugRegion('CN');

      // Check if it's persisted
      expect(RegionDetectionService.debugRegionOverride, 'CN');

      // Clear and check
      await RegionDetectionService.clearSimulation();
      expect(RegionDetectionService.debugRegionOverride, isNull);
    });

    test('should return correct login providers for simulated regions',
        () async {
      // This test only works in debug mode
      if (!kDebugMode) {
        return;
      }

      // Test China simulation
      await RegionDetectionService.simulateChina();
      var regionInfo = await RegionDetectionService.detectRegion();
      var providers =
          RegionDetectionService.getAvailableLoginProviders(regionInfo.region);
      expect(providers, ['apple', 'wechat']);

      // Test US simulation
      await RegionDetectionService.simulateOtherRegion('US');
      regionInfo = await RegionDetectionService.detectRegion();
      providers =
          RegionDetectionService.getAvailableLoginProviders(regionInfo.region);
      expect(providers, ['apple', 'google', 'kakao', 'wechat']);
    });

    test('should not work in release mode', () async {
      // This test simulates release mode behavior
      if (kDebugMode) {
        // In debug mode, we can't really test release mode behavior
        // but we can test that the function checks for debug mode
        return;
      }

      // In release mode, debug functions should not work
      await RegionDetectionService.setDebugRegion('CN');
      expect(RegionDetectionService.debugRegionOverride, isNull);
    });

    test('should handle various country codes', () async {
      // This test only works in debug mode
      if (!kDebugMode) {
        return;
      }

      final testCases = [
        {'code': 'CN', 'expectedRegion': UserRegion.china},
        {'code': 'US', 'expectedRegion': UserRegion.other},
        {'code': 'JP', 'expectedRegion': UserRegion.other},
        {'code': 'KR', 'expectedRegion': UserRegion.other},
        {
          'code': 'HK',
          'expectedRegion': UserRegion.other
        }, // Hong Kong is now "other"
      ];

      for (final testCase in testCases) {
        await RegionDetectionService.setDebugRegion(testCase['code'] as String);
        final regionInfo = await RegionDetectionService.detectRegion();

        expect(regionInfo.countryCode, testCase['code']);
        expect(regionInfo.region, testCase['expectedRegion']);
      }
    });
  });
}
