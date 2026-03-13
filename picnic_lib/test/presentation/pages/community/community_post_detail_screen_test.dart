import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/community_post_detail_screen.dart';

void main() {
  group('CommunityPostDetailScreen widget', () {
    test('can be constructed with postId', () {
      const page = CommunityPostDetailScreen(postId: 'post_123');
      expect(page, isA<CommunityPostDetailScreen>());
      expect(page.postId, 'post_123');
    });

    test('with key can be constructed', () {
      const page = CommunityPostDetailScreen(
        key: ValueKey('post_detail'),
        postId: '456',
      );
      expect(page.key, equals(const ValueKey('post_detail')));
      expect(page.postId, '456');
    });

    test('different postIds produce different widgets', () {
      const p1 = CommunityPostDetailScreen(postId: 'abc');
      const p2 = CommunityPostDetailScreen(postId: 'def');
      expect(p1.postId, isNot(p2.postId));
    });
  });
}
