import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/community_my_page.dart';

/// Tests for CommunityMyPage production code.
///
/// Widget rendering requires multiple providers (navigation, user info, settings).
/// We test importable production code: constructor.
void main() {
  group('CommunityMyPage widget', () {
    test('can be const-constructed', () {
      const page = CommunityMyPage();
      expect(page, isA<CommunityMyPage>());
    });

    test('with key can be constructed', () {
      const page = CommunityMyPage(key: ValueKey('community_my_page'));
      expect(page.key, equals(const ValueKey('community_my_page')));
    });
  });
}
