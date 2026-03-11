import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/policy.dart';

void main() {
  group('PrivacyModel', () {
    test('생성', () {
      const privacy = PrivacyModel(
        content: '개인정보 처리방침 내용',
        version: '1.0.0',
      );
      expect(privacy.content, equals('개인정보 처리방침 내용'));
      expect(privacy.version, equals('1.0.0'));
    });
  });

  group('TermsModel', () {
    test('생성', () {
      const terms = TermsModel(
        content: '이용약관 내용',
        version: '2.1.0',
      );
      expect(terms.content, equals('이용약관 내용'));
      expect(terms.version, equals('2.1.0'));
    });
  });

  group('PolicyModel', () {
    test('한국어/영어 정책 포함', () {
      const policy = PolicyModel(
        privacyEn: PrivacyModel(content: 'Privacy Policy', version: '1.0'),
        termsEn: TermsModel(content: 'Terms of Service', version: '1.0'),
        privacyKo: PrivacyModel(content: '개인정보 처리방침', version: '1.0'),
        termsKo: TermsModel(content: '이용약관', version: '1.0'),
      );
      expect(policy.privacyEn.content, equals('Privacy Policy'));
      expect(policy.privacyKo.content, equals('개인정보 처리방침'));
      expect(policy.termsEn.content, equals('Terms of Service'));
      expect(policy.termsKo.content, equals('이용약관'));
    });

    test('다른 버전', () {
      const policy = PolicyModel(
        privacyEn: PrivacyModel(content: 'EN privacy v2', version: '2.0'),
        termsEn: TermsModel(content: 'EN terms v3', version: '3.0'),
        privacyKo: PrivacyModel(content: 'KO privacy v1', version: '1.5'),
        termsKo: TermsModel(content: 'KO terms v2', version: '2.5'),
      );
      expect(policy.privacyEn.version, equals('2.0'));
      expect(policy.termsEn.version, equals('3.0'));
      expect(policy.privacyKo.version, equals('1.5'));
      expect(policy.termsKo.version, equals('2.5'));
    });
  });
}
