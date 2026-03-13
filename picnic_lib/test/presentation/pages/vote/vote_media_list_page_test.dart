import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_media_list_page.dart';

void main() {
  group('VoteMediaListPage widget', () {
    test('can be const-constructed', () {
      const page = VoteMediaListPage();
      expect(page, isA<VoteMediaListPage>());
    });

    test('has correct pageName', () {
      const page = VoteMediaListPage();
      expect(page.pageName, 'page_title_vote_gather');
    });

    test('with key can be constructed', () {
      const page = VoteMediaListPage(key: ValueKey('vote_media'));
      expect(page.key, equals(const ValueKey('vote_media')));
    });
  });
}
