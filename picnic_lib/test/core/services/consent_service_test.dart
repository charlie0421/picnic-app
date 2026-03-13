import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/consent_service.dart';

void main() {
  group('ConsentService', () {
    test('is a singleton - factory returns same instance', () {
      final a = ConsentService();
      final b = ConsentService();
      expect(identical(a, b), isTrue);
    });

    test('is a ConsentService type', () {
      final service = ConsentService();
      expect(service, isA<ConsentService>());
    });

    test('initialize method exists and is callable', () {
      final service = ConsentService();
      expect(service.initialize, isA<Function>());
    });

    test('canRequestAds method exists and is callable', () {
      final service = ConsentService();
      expect(service.canRequestAds, isA<Function>());
    });

    test('getConsentStatus method exists and is callable', () {
      final service = ConsentService();
      expect(service.getConsentStatus, isA<Function>());
    });

    test('isGdprApplicable method exists and is callable', () {
      final service = ConsentService();
      expect(service.isGdprApplicable, isA<Function>());
    });

    test('reset method exists and is callable', () {
      final service = ConsentService();
      expect(service.reset, isA<Function>());
    });

    test('resetAndReinitialize method exists and is callable', () {
      final service = ConsentService();
      expect(service.resetAndReinitialize, isA<Function>());
    });

    test('showPrivacyOptionsForm method exists and is callable', () {
      final service = ConsentService();
      expect(service.showPrivacyOptionsForm, isA<Function>());
    });

    test('logCurrentState method exists and is callable', () {
      final service = ConsentService();
      expect(service.logCurrentState, isA<Function>());
    });

    // Note: The actual method behavior (initialize, canRequestAds, etc.)
    // cannot be unit tested because they depend on google_mobile_ads
    // platform channels (ConsentInformation.instance, ConsentForm, etc.)
    // which require a running mobile platform.
    // Integration tests on a real device/emulator are needed for those.

    test('multiple singleton accesses return same instance', () {
      final a = ConsentService();
      final b = ConsentService();
      final c = ConsentService();
      expect(identical(a, b), isTrue);
      expect(identical(b, c), isTrue);
    });
  });
}
