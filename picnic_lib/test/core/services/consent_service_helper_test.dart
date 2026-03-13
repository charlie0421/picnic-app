import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/consent_service_helper.dart';

void main() {
  group('ConsentServiceHelper', () {
    group('isGdprApplicableForStatus', () {
      test('returns true for required status', () {
        expect(ConsentServiceHelper.isGdprApplicableForStatus('required'), isTrue);
      });

      test('returns true for obtained status', () {
        expect(ConsentServiceHelper.isGdprApplicableForStatus('obtained'), isTrue);
      });

      test('returns false for notRequired status', () {
        expect(
          ConsentServiceHelper.isGdprApplicableForStatus('notRequired'),
          isFalse,
        );
      });

      test('returns false for unknown status', () {
        expect(
          ConsentServiceHelper.isGdprApplicableForStatus('unknown'),
          isFalse,
        );
      });

      test('returns false for empty string', () {
        expect(ConsentServiceHelper.isGdprApplicableForStatus(''), isFalse);
      });

      test('returns false for arbitrary string', () {
        expect(
          ConsentServiceHelper.isGdprApplicableForStatus('something'),
          isFalse,
        );
      });
    });

    group('shouldShowConsentForm', () {
      test('returns true when form is available and status is required', () {
        expect(
          ConsentServiceHelper.shouldShowConsentForm(
            isFormAvailable: true,
            consentStatus: 'required',
          ),
          isTrue,
        );
      });

      test('returns false when form is not available', () {
        expect(
          ConsentServiceHelper.shouldShowConsentForm(
            isFormAvailable: false,
            consentStatus: 'required',
          ),
          isFalse,
        );
      });

      test('returns false when status is obtained', () {
        expect(
          ConsentServiceHelper.shouldShowConsentForm(
            isFormAvailable: true,
            consentStatus: 'obtained',
          ),
          isFalse,
        );
      });

      test('returns false when status is notRequired', () {
        expect(
          ConsentServiceHelper.shouldShowConsentForm(
            isFormAvailable: true,
            consentStatus: 'notRequired',
          ),
          isFalse,
        );
      });

      test('returns false when both conditions fail', () {
        expect(
          ConsentServiceHelper.shouldShowConsentForm(
            isFormAvailable: false,
            consentStatus: 'obtained',
          ),
          isFalse,
        );
      });
    });

    group('shouldShowPrivacyOptionsForm', () {
      test('returns true for required status', () {
        expect(
          ConsentServiceHelper.shouldShowPrivacyOptionsForm('required'),
          isTrue,
        );
      });

      test('returns false for not_required status', () {
        expect(
          ConsentServiceHelper.shouldShowPrivacyOptionsForm('not_required'),
          isFalse,
        );
      });

      test('returns false for empty string', () {
        expect(
          ConsentServiceHelper.shouldShowPrivacyOptionsForm(''),
          isFalse,
        );
      });
    });

    group('shouldInitialize', () {
      test('returns true when not initialized and no completer', () {
        expect(
          ConsentServiceHelper.shouldInitialize(
            isInitialized: false,
            hasCompleter: false,
          ),
          isTrue,
        );
      });

      test('returns true when not initialized but has completer', () {
        expect(
          ConsentServiceHelper.shouldInitialize(
            isInitialized: false,
            hasCompleter: true,
          ),
          isTrue,
        );
      });

      test('returns true when initialized but no completer', () {
        expect(
          ConsentServiceHelper.shouldInitialize(
            isInitialized: true,
            hasCompleter: false,
          ),
          isTrue,
        );
      });

      test('returns false when initialized and has completer', () {
        expect(
          ConsentServiceHelper.shouldInitialize(
            isInitialized: true,
            hasCompleter: true,
          ),
          isFalse,
        );
      });
    });

    group('getConsentStatusLabel', () {
      test('returns correct label for required', () {
        expect(
          ConsentServiceHelper.getConsentStatusLabel('required'),
          'Consent Required',
        );
      });

      test('returns correct label for obtained', () {
        expect(
          ConsentServiceHelper.getConsentStatusLabel('obtained'),
          'Consent Obtained',
        );
      });

      test('returns correct label for notRequired', () {
        expect(
          ConsentServiceHelper.getConsentStatusLabel('notRequired'),
          'Consent Not Required',
        );
      });

      test('returns correct label for unknown', () {
        expect(
          ConsentServiceHelper.getConsentStatusLabel('unknown'),
          'Unknown Status',
        );
      });

      test('returns unrecognized label for unexpected status', () {
        expect(
          ConsentServiceHelper.getConsentStatusLabel('weird'),
          'Unrecognized: weird',
        );
      });

      test('returns unrecognized label for empty string', () {
        expect(
          ConsentServiceHelper.getConsentStatusLabel(''),
          'Unrecognized: ',
        );
      });
    });
  });
}
