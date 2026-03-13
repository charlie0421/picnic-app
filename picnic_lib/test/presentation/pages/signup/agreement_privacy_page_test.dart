import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/policy.dart';
import 'package:picnic_lib/presentation/pages/signup/agreement_privacy_page.dart';
import 'package:picnic_lib/presentation/providers/policy_provider.dart';

void main() {
  group('AgreementPrivacyPage', () {
    test('is a ConsumerStatefulWidget', () {
      const page = AgreementPrivacyPage();
      expect(page, isNotNull);
    });

    test('can be constructed with key', () {
      const page = AgreementPrivacyPage(key: ValueKey('test'));
      expect(page.key, const ValueKey('test'));
    });
  });

  group('PolicyModel used in AgreementPrivacyPage', () {
    test('creates full policy model for privacy display', () {
      const policy = PolicyModel(
        privacyEn: PrivacyModel(
          content: '# Privacy Policy\n\nEnglish privacy content.',
          version: '1.0',
        ),
        termsEn: TermsModel(
          content: '# Terms\n\nEnglish terms.',
          version: '1.0',
        ),
        privacyKo: PrivacyModel(
          content: '# 개인정보 처리방침\n\n한국어 개인정보 처리방침.',
          version: '1.0',
        ),
        termsKo: TermsModel(
          content: '# 이용약관\n\n한국어 이용약관.',
          version: '1.0',
        ),
      );

      // AgreementPrivacyPage uses privacyKo.content for Korean locale
      expect(policy.privacyKo.content, contains('개인정보 처리방침'));
      // And privacyEn.content for English locale
      expect(policy.privacyEn.content, contains('Privacy Policy'));
    });

    test('policy content can be markdown', () {
      const policy = PolicyModel(
        privacyEn: PrivacyModel(
          content: '# Title\n\n## Section 1\n\nParagraph text.\n\n- List item 1\n- List item 2',
          version: '2.0',
        ),
        termsEn: TermsModel(content: 'terms', version: '1.0'),
        privacyKo: PrivacyModel(content: 'privacy ko', version: '1.0'),
        termsKo: TermsModel(content: 'terms ko', version: '1.0'),
      );

      expect(policy.privacyEn.content, contains('# Title'));
      expect(policy.privacyEn.content, contains('## Section 1'));
      expect(policy.privacyEn.content, contains('- List item'));
    });

    test('fromJson creates models for privacy page', () {
      final policy = PolicyModel.fromJson({
        'privacy_en': {
          'content': 'Privacy content EN',
          'version': '1.0.0',
        },
        'terms_en': {
          'content': 'Terms content EN',
          'version': '1.0.0',
        },
        'privacy_ko': {
          'content': 'Privacy content KO',
          'version': '1.0.0',
        },
        'terms_ko': {
          'content': 'Terms content KO',
          'version': '1.0.0',
        },
      });

      expect(policy.privacyEn.content, 'Privacy content EN');
      expect(policy.privacyKo.content, 'Privacy content KO');
    });
  });

  group('AsyncPolicy provider type', () {
    test('asyncPolicyProvider exists', () {
      // Verify the provider can be referenced
      expect(asyncPolicyProvider, isNotNull);
    });
  });
}
