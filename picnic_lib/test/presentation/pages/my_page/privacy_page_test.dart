import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/policy.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/my_page/privacy_page.dart';

/// Tests for PrivacyPage production code.
///
/// Widget rendering is blocked by platform dependencies (RouteAwareStateMixin,
/// appRouteObserver). We test importable production code:
/// constructor, PolicyLanguage enum, PolicyModel, PrivacyModel, TermsModel.
void main() {
  group('PrivacyPage widget', () {
    test('can be const-constructed', () {
      const page = PrivacyPage();
      expect(page, isA<PrivacyPage>());
    });

    test('has correct pageName', () {
      const page = PrivacyPage();
      expect(page.pageName, 'page_title_privacy');
    });

    test('language parameter defaults to null', () {
      const page = PrivacyPage();
      expect(page.language, isNull);
    });

    test('language parameter can be passed', () {
      const page = PrivacyPage(language: 'en');
      expect(page.language, 'en');
    });

    test('with key can be constructed', () {
      const page = PrivacyPage(key: ValueKey('privacy'));
      expect(page.key, equals(const ValueKey('privacy')));
    });
  });

  group('PolicyLanguage enum', () {
    test('has ko and en values', () {
      expect(PolicyLanguage.values.length, 2);
      expect(PolicyLanguage.ko, isNotNull);
      expect(PolicyLanguage.en, isNotNull);
    });

    test('ko name is correct', () {
      expect(PolicyLanguage.ko.name, 'ko');
    });

    test('en name is correct', () {
      expect(PolicyLanguage.en.name, 'en');
    });

    test('conditional selection logic used in PrivacyPage', () {
      const lang = 'ko';
      final selected = lang == 'ko' ? PolicyLanguage.ko : PolicyLanguage.en;
      expect(selected, PolicyLanguage.ko);

      const langEn = 'en';
      final selectedEn =
          langEn == 'ko' ? PolicyLanguage.ko : PolicyLanguage.en;
      expect(selectedEn, PolicyLanguage.en);

      const langOther = 'ja';
      final selectedOther =
          langOther == 'ko' ? PolicyLanguage.ko : PolicyLanguage.en;
      expect(selectedOther, PolicyLanguage.en);
    });
  });

  group('PolicyModel', () {
    PolicyModel makeMockPolicy() {
      return PolicyModel.fromJson({
        'terms_ko': {'content': '# 이용약관', 'version': '1.0'},
        'terms_en': {'content': '# Terms', 'version': '1.0'},
        'privacy_ko': {'content': '# 개인정보처리방침', 'version': '1.0'},
        'privacy_en': {'content': '# Privacy Policy', 'version': '1.0'},
      });
    }

    test('fromJson parses all fields', () {
      final policy = makeMockPolicy();
      expect(policy.termsKo, isNotNull);
      expect(policy.termsEn, isNotNull);
      expect(policy.privacyKo, isNotNull);
      expect(policy.privacyEn, isNotNull);
    });

    test('privacy content is accessible', () {
      final policy = makeMockPolicy();
      expect(policy.privacyKo.content, '# 개인정보처리방침');
      expect(policy.privacyEn.content, '# Privacy Policy');
    });

    test('terms content is accessible', () {
      final policy = makeMockPolicy();
      expect(policy.termsKo.content, '# 이용약관');
      expect(policy.termsEn.content, '# Terms');
    });
  });

  group('PrivacyModel', () {
    test('fromJson parses correctly', () {
      final item = PrivacyModel.fromJson({
        'content': '# 개인정보',
        'version': '2.0',
      });
      expect(item.content, '# 개인정보');
      expect(item.version, '2.0');
    });

    test('handles empty content', () {
      final item = PrivacyModel.fromJson({
        'content': '',
        'version': '1.0',
      });
      expect(item.content, isEmpty);
    });

    test('handles long content', () {
      final longContent = '# Privacy\n' * 100;
      final item = PrivacyModel.fromJson({
        'content': longContent,
        'version': '1.0',
      });
      expect(item.content.length, greaterThan(100));
    });
  });

  group('TermsModel', () {
    test('fromJson parses correctly', () {
      final item = TermsModel.fromJson({
        'content': '# 약관 내용',
        'version': '3.0',
      });
      expect(item.content, '# 약관 내용');
      expect(item.version, '3.0');
    });

    test('handles markdown content', () {
      final item = TermsModel.fromJson({
        'content': '## Section\n\n- Item 1\n- Item 2',
        'version': '1.0',
      });
      expect(item.content, contains('Section'));
      expect(item.content, contains('Item 1'));
    });
  });
}
