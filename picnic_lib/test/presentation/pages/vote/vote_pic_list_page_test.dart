import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_pic_list_page.dart';

/// Tests for VotePicListPage production code.
///
/// Widget rendering requires multiple providers (vote list, app settings, user info).
/// We test importable production code: constructor.
void main() {
  group('VotePicListPage widget', () {
    test('can be const-constructed', () {
      const page = VotePicListPage();
      expect(page, isA<VotePicListPage>());
    });

    test('with key can be constructed', () {
      const page = VotePicListPage(key: ValueKey('vote_pic_list'));
      expect(page.key, equals(const ValueKey('vote_pic_list')));
    });
  });
}
