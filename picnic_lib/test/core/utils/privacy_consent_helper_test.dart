import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/privacy_consent_helper.dart';

void main() {
  group('PrivacyConsentHelper', () {
    group('canShowPersonalizedAds', () {
      test('returns true when ATT authorized and UMP obtained', () {
        expect(
          PrivacyConsentHelper.canShowPersonalizedAds(
            attAuthorized: true,
            umpStatus: 'obtained',
          ),
          isTrue,
        );
      });

      test('returns true when ATT authorized and UMP notRequired', () {
        expect(
          PrivacyConsentHelper.canShowPersonalizedAds(
            attAuthorized: true,
            umpStatus: 'notRequired',
          ),
          isTrue,
        );
      });

      test('returns false when ATT not authorized', () {
        expect(
          PrivacyConsentHelper.canShowPersonalizedAds(
            attAuthorized: false,
            umpStatus: 'obtained',
          ),
          isFalse,
        );
      });

      test('returns false when UMP required', () {
        expect(
          PrivacyConsentHelper.canShowPersonalizedAds(
            attAuthorized: true,
            umpStatus: 'required',
          ),
          isFalse,
        );
      });

      test('returns false when UMP unknown', () {
        expect(
          PrivacyConsentHelper.canShowPersonalizedAds(
            attAuthorized: true,
            umpStatus: 'unknown',
          ),
          isFalse,
        );
      });

      test('returns false when both conditions fail', () {
        expect(
          PrivacyConsentHelper.canShowPersonalizedAds(
            attAuthorized: false,
            umpStatus: 'required',
          ),
          isFalse,
        );
      });
    });

    group('isAttAuthorized', () {
      test('returns true for authorized', () {
        expect(PrivacyConsentHelper.isAttAuthorized('authorized'), isTrue);
      });

      test('returns false for denied', () {
        expect(PrivacyConsentHelper.isAttAuthorized('denied'), isFalse);
      });

      test('returns false for restricted', () {
        expect(PrivacyConsentHelper.isAttAuthorized('restricted'), isFalse);
      });

      test('returns false for notDetermined', () {
        expect(
          PrivacyConsentHelper.isAttAuthorized('notDetermined'),
          isFalse,
        );
      });

      test('returns false for empty string', () {
        expect(PrivacyConsentHelper.isAttAuthorized(''), isFalse);
      });
    });

    group('shouldRequestAttConsent', () {
      test('returns true for notDetermined', () {
        expect(
          PrivacyConsentHelper.shouldRequestAttConsent('notDetermined'),
          isTrue,
        );
      });

      test('returns false for authorized', () {
        expect(
          PrivacyConsentHelper.shouldRequestAttConsent('authorized'),
          isFalse,
        );
      });

      test('returns false for denied', () {
        expect(
          PrivacyConsentHelper.shouldRequestAttConsent('denied'),
          isFalse,
        );
      });

      test('returns false for restricted', () {
        expect(
          PrivacyConsentHelper.shouldRequestAttConsent('restricted'),
          isFalse,
        );
      });
    });

    group('shouldUseNonPersonalizedAds', () {
      test('returns false when ATT authorized and UMP obtained', () {
        expect(
          PrivacyConsentHelper.shouldUseNonPersonalizedAds(
            attAuthorized: true,
            umpStatus: 'obtained',
          ),
          isFalse,
        );
      });

      test('returns false when ATT authorized and UMP notRequired', () {
        expect(
          PrivacyConsentHelper.shouldUseNonPersonalizedAds(
            attAuthorized: true,
            umpStatus: 'notRequired',
          ),
          isFalse,
        );
      });

      test('returns true when ATT not authorized', () {
        expect(
          PrivacyConsentHelper.shouldUseNonPersonalizedAds(
            attAuthorized: false,
            umpStatus: 'obtained',
          ),
          isTrue,
        );
      });

      test('returns true when UMP required', () {
        expect(
          PrivacyConsentHelper.shouldUseNonPersonalizedAds(
            attAuthorized: true,
            umpStatus: 'required',
          ),
          isTrue,
        );
      });

      test('returns true when both bad', () {
        expect(
          PrivacyConsentHelper.shouldUseNonPersonalizedAds(
            attAuthorized: false,
            umpStatus: 'required',
          ),
          isTrue,
        );
      });
    });

    group('getInitializationOrder', () {
      test('returns ATT first for iOS', () {
        final order = PrivacyConsentHelper.getInitializationOrder(isIOS: true);
        expect(order, ['att', 'ump', 'admob']);
        expect(order.first, 'att');
      });

      test('returns UMP first for Android', () {
        final order = PrivacyConsentHelper.getInitializationOrder(isIOS: false);
        expect(order, ['ump', 'att', 'admob']);
        expect(order.first, 'ump');
      });

      test('always ends with admob', () {
        expect(
          PrivacyConsentHelper.getInitializationOrder(isIOS: true).last,
          'admob',
        );
        expect(
          PrivacyConsentHelper.getInitializationOrder(isIOS: false).last,
          'admob',
        );
      });

      test('always has 3 steps', () {
        expect(
          PrivacyConsentHelper.getInitializationOrder(isIOS: true).length,
          3,
        );
        expect(
          PrivacyConsentHelper.getInitializationOrder(isIOS: false).length,
          3,
        );
      });
    });

    group('isPlatformSupported', () {
      test('returns false for web', () {
        expect(
          PrivacyConsentHelper.isPlatformSupported(
            isWeb: true,
            isIOS: false,
            isAndroid: false,
          ),
          isFalse,
        );
      });

      test('returns false for web even if iOS', () {
        expect(
          PrivacyConsentHelper.isPlatformSupported(
            isWeb: true,
            isIOS: true,
            isAndroid: false,
          ),
          isFalse,
        );
      });

      test('returns true for iOS', () {
        expect(
          PrivacyConsentHelper.isPlatformSupported(
            isWeb: false,
            isIOS: true,
            isAndroid: false,
          ),
          isTrue,
        );
      });

      test('returns true for Android', () {
        expect(
          PrivacyConsentHelper.isPlatformSupported(
            isWeb: false,
            isIOS: false,
            isAndroid: true,
          ),
          isTrue,
        );
      });

      test('returns false for desktop', () {
        expect(
          PrivacyConsentHelper.isPlatformSupported(
            isWeb: false,
            isIOS: false,
            isAndroid: false,
          ),
          isFalse,
        );
      });
    });
  });
}
