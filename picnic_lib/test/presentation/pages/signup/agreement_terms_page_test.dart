import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/signup/agreement_terms_page.dart';

void main() {
  group('AgreementTermsPage widget', () {
    test('can be const-constructed', () {
      const page = AgreementTermsPage();
      expect(page, isA<AgreementTermsPage>());
    });

    test('with key can be constructed', () {
      const page = AgreementTermsPage(key: ValueKey('agreement_terms'));
      expect(page.key, equals(const ValueKey('agreement_terms')));
    });
  });
}
