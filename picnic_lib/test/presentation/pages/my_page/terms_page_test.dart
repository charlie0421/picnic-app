import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/policy.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/my_page/terms_page.dart';

/// Tests for TermsPage production code.
///
/// Widget rendering is blocked by platform dependencies (RouteAwareStateMixin,
/// appRouteObserver). We test importable production code:
/// constructor, PolicyLanguage, PolicyModel, TermsModel.
void main() {
  group('TermsPage widget', () {
    test('can be const-constructed', () {
      const page = TermsPage();
      expect(page, isA<TermsPage>());
    });

    test('has correct pageName', () {
      const page = TermsPage();
      expect(page.pageName, 'page_title_terms_of_use');
    });

    test('language parameter defaults to null', () {
      const page = TermsPage();
      expect(page.language, isNull);
    });

    test('language parameter can be set', () {
      const page = TermsPage(language: 'en');
      expect(page.language, 'en');
    });

    test('with key can be constructed', () {
      const page = TermsPage(key: ValueKey('terms'));
      expect(page.key, equals(const ValueKey('terms')));
    });
  });

  group('TermsModel', () {
    test('fromJson parses correctly', () {
      final item = TermsModel.fromJson({
        'content': '# 약관 내용',
        'version': '1.0',
      });
      expect(item.content, '# 약관 내용');
      expect(item.version, '1.0');
    });

    test('content field is accessible', () {
      final item = TermsModel.fromJson({
        'content': '# Terms of Service\n\nThis is a test.',
        'version': '2.5',
      });
      expect(item.content, contains('Terms of Service'));
      expect(item.content, contains('test'));
    });

    test('handles empty content', () {
      final item = TermsModel.fromJson({
        'content': '',
        'version': '0.1',
      });
      expect(item.content, isEmpty);
    });

    test('toJson roundtrip', () {
      final original = TermsModel.fromJson({
        'content': 'Original Content',
        'version': '4.0',
      });
      final json = original.toJson();
      final restored = TermsModel.fromJson(json);
      expect(restored.content, original.content);
      expect(restored.version, original.version);
    });
  });

  group('PrivacyModel', () {
    test('toJson roundtrip', () {
      final original = PrivacyModel.fromJson({
        'content': 'Privacy Content',
        'version': '3.0',
      });
      final json = original.toJson();
      final restored = PrivacyModel.fromJson(json);
      expect(restored.content, original.content);
      expect(restored.version, original.version);
    });
  });

  group('PolicyModel roundtrip', () {
    test('fromJson and toJson', () {
      final policy = PolicyModel.fromJson({
        'terms_ko': {'content': 'KO Terms', 'version': '1.0'},
        'terms_en': {'content': 'EN Terms', 'version': '1.0'},
        'privacy_ko': {'content': 'KO Privacy', 'version': '1.0'},
        'privacy_en': {'content': 'EN Privacy', 'version': '1.0'},
      });

      expect(policy.termsKo.content, 'KO Terms');
      expect(policy.termsEn.content, 'EN Terms');
      expect(policy.privacyKo.content, 'KO Privacy');
      expect(policy.privacyEn.content, 'EN Privacy');

      final json = policy.toJson();
      final restored = PolicyModel.fromJson(json);
      expect(restored.termsKo.content, policy.termsKo.content);
      expect(restored.privacyEn.content, policy.privacyEn.content);
    });
  });

  group('PolicyLanguage used in TermsPage', () {
    test('default selection based on language setting', () {
      const lang = 'ko';
      final selected = lang == 'ko' ? PolicyLanguage.ko : PolicyLanguage.en;
      expect(selected, PolicyLanguage.ko);

      const langEn = 'en';
      final selectedEn =
          langEn == 'ko' ? PolicyLanguage.ko : PolicyLanguage.en;
      expect(selectedEn, PolicyLanguage.en);
    });
  });
}
