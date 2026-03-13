import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/policy.dart';

void main() {
  group('PolicyModel fromJson', () {
    test('parses from full JSON', () {
      final policy = PolicyModel.fromJson({
        'privacy_en': {'content': 'Privacy Policy EN', 'version': '1.0'},
        'terms_en': {'content': 'Terms EN', 'version': '1.0'},
        'privacy_ko': {'content': '개인정보 처리방침', 'version': '1.0'},
        'terms_ko': {'content': '이용약관', 'version': '1.0'},
      });
      expect(policy.privacyEn.content, 'Privacy Policy EN');
      expect(policy.termsEn.content, 'Terms EN');
      expect(policy.privacyKo.content, '개인정보 처리방침');
      expect(policy.termsKo.content, '이용약관');
    });

    test('preserves version info from JSON', () {
      final policy = PolicyModel.fromJson({
        'privacy_en': {'content': 'c', 'version': '2.1.0'},
        'terms_en': {'content': 'c', 'version': '3.0.0'},
        'privacy_ko': {'content': 'c', 'version': '1.5.0'},
        'terms_ko': {'content': 'c', 'version': '4.2.1'},
      });
      expect(policy.privacyEn.version, '2.1.0');
      expect(policy.termsEn.version, '3.0.0');
      expect(policy.privacyKo.version, '1.5.0');
      expect(policy.termsKo.version, '4.2.1');
    });
  });

  group('PrivacyModel fromJson', () {
    test('parses correctly', () {
      final privacy = PrivacyModel.fromJson({
        'content': 'Test privacy content',
        'version': '1.2.3',
      });
      expect(privacy.content, 'Test privacy content');
      expect(privacy.version, '1.2.3');
    });

    test('handles empty content', () {
      final privacy = PrivacyModel.fromJson({
        'content': '',
        'version': '0.0.0',
      });
      expect(privacy.content, '');
      expect(privacy.version, '0.0.0');
    });

    test('handles long content', () {
      final longContent = 'A' * 10000;
      final privacy = PrivacyModel.fromJson({
        'content': longContent,
        'version': '1.0',
      });
      expect(privacy.content.length, 10000);
    });

    test('handles markdown content', () {
      final privacy = PrivacyModel.fromJson({
        'content': '# Title\n\n## Section\n\n- Item 1\n- Item 2',
        'version': '1.0',
      });
      expect(privacy.content, contains('# Title'));
      expect(privacy.content, contains('- Item 1'));
    });
  });

  group('TermsModel fromJson', () {
    test('parses correctly', () {
      final terms = TermsModel.fromJson({
        'content': 'Terms content here',
        'version': '2.0.0',
      });
      expect(terms.content, 'Terms content here');
      expect(terms.version, '2.0.0');
    });

    test('handles unicode content', () {
      final terms = TermsModel.fromJson({
        'content': '이용약관 내용입니다. Terms & Conditions.',
        'version': '1.0',
      });
      expect(terms.content, contains('이용약관'));
      expect(terms.content, contains('Terms'));
    });
  });

  group('PolicyModel copyWith', () {
    test('copies with new privacyEn', () {
      const original = PolicyModel(
        privacyEn: PrivacyModel(content: 'old', version: '1.0'),
        termsEn: TermsModel(content: 'terms', version: '1.0'),
        privacyKo: PrivacyModel(content: 'ko', version: '1.0'),
        termsKo: TermsModel(content: 'ko terms', version: '1.0'),
      );
      final copy = original.copyWith(
        privacyEn: const PrivacyModel(content: 'new', version: '2.0'),
      );
      expect(copy.privacyEn.content, 'new');
      expect(copy.privacyEn.version, '2.0');
      expect(copy.termsEn.content, 'terms');
      expect(copy.privacyKo.content, 'ko');
      expect(copy.termsKo.content, 'ko terms');
    });

    test('copies with new termsKo', () {
      const original = PolicyModel(
        privacyEn: PrivacyModel(content: 'en', version: '1.0'),
        termsEn: TermsModel(content: 'en terms', version: '1.0'),
        privacyKo: PrivacyModel(content: 'ko', version: '1.0'),
        termsKo: TermsModel(content: 'old ko terms', version: '1.0'),
      );
      final copy = original.copyWith(
        termsKo: const TermsModel(content: 'new ko terms', version: '3.0'),
      );
      expect(copy.termsKo.content, 'new ko terms');
      expect(copy.termsKo.version, '3.0');
      expect(copy.privacyEn.content, 'en');
    });

    test('copies with no changes returns equal object', () {
      const original = PolicyModel(
        privacyEn: PrivacyModel(content: 'a', version: '1'),
        termsEn: TermsModel(content: 'b', version: '2'),
        privacyKo: PrivacyModel(content: 'c', version: '3'),
        termsKo: TermsModel(content: 'd', version: '4'),
      );
      final copy = original.copyWith();
      expect(copy.privacyEn.content, original.privacyEn.content);
      expect(copy.termsEn.content, original.termsEn.content);
      expect(copy.privacyKo.content, original.privacyKo.content);
      expect(copy.termsKo.content, original.termsKo.content);
    });
  });

  group('PrivacyModel copyWith', () {
    test('copies with new content', () {
      const original = PrivacyModel(content: 'old content', version: '1.0');
      final copy = original.copyWith(content: 'new content');
      expect(copy.content, 'new content');
      expect(copy.version, '1.0');
    });

    test('copies with new version', () {
      const original = PrivacyModel(content: 'content', version: '1.0');
      final copy = original.copyWith(version: '2.0');
      expect(copy.content, 'content');
      expect(copy.version, '2.0');
    });
  });

  group('TermsModel copyWith', () {
    test('copies with new content', () {
      const original = TermsModel(content: 'old terms', version: '1.0');
      final copy = original.copyWith(content: 'updated terms');
      expect(copy.content, 'updated terms');
      expect(copy.version, '1.0');
    });

    test('copies with new version', () {
      const original = TermsModel(content: 'terms', version: '1.0');
      final copy = original.copyWith(version: '3.5');
      expect(copy.content, 'terms');
      expect(copy.version, '3.5');
    });
  });
}
