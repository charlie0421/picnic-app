import 'package:test/test.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';

void main() {
  group('PrivacyConsentManager', () {
    test('PrivacyConsentManager 클래스가 존재한다', () {
      expect(PrivacyConsentManager, isA<Type>());
    });

    test('initialize 정적 메서드가 존재하고 Future<void>를 반환한다', () {
      expect(
        PrivacyConsentManager.initialize,
        isA<Future<void> Function()>(),
      );
    });

    test('canShowPersonalizedAds 정적 메서드가 존재하고 Future<bool>를 반환한다', () {
      expect(
        PrivacyConsentManager.canShowPersonalizedAds,
        isA<Future<bool> Function()>(),
      );
    });

    test('canShowPersonalizedAds는 비모바일 환경에서 false를 반환한다', () async {
      // 테스트 환경은 모바일이 아니므로 isMobile()이 false를 반환하여
      // canShowPersonalizedAds도 false를 반환해야 한다
      final result = await PrivacyConsentManager.canShowPersonalizedAds();
      expect(result, isFalse);
    });

    test('initialize는 비모바일 환경에서 즉시 반환된다', () async {
      // 테스트 환경은 모바일이 아니므로 isMobile()이 false를 반환하여
      // initialize가 플랫폼 의존성 없이 즉시 반환되어야 한다
      await expectLater(
        PrivacyConsentManager.initialize(),
        completes,
      );
    });

    test('initialize can be called multiple times safely', () async {
      // Multiple calls should not cause errors
      await PrivacyConsentManager.initialize();
      await PrivacyConsentManager.initialize();
      await PrivacyConsentManager.initialize();
    });

    test('canShowPersonalizedAds returns false consistently on non-mobile', () async {
      // Call multiple times to verify consistency
      final r1 = await PrivacyConsentManager.canShowPersonalizedAds();
      final r2 = await PrivacyConsentManager.canShowPersonalizedAds();
      final r3 = await PrivacyConsentManager.canShowPersonalizedAds();
      expect(r1, isFalse);
      expect(r2, isFalse);
      expect(r3, isFalse);
    });

    test('initialize followed by canShowPersonalizedAds returns false on non-mobile', () async {
      await PrivacyConsentManager.initialize();
      final result = await PrivacyConsentManager.canShowPersonalizedAds();
      expect(result, isFalse);
    });

    test('canShowPersonalizedAds followed by initialize completes', () async {
      final result = await PrivacyConsentManager.canShowPersonalizedAds();
      expect(result, isFalse);
      await expectLater(PrivacyConsentManager.initialize(), completes);
    });
  });
}
