import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/comment/comment_list.dart';

/// Tests for CommentList data models and logic patterns.
///
/// Widget rendering tests are limited because CommentList requires
/// commentsProvider, parentItemProvider, and other async notifiers
/// that depend on Supabase queries. Instead we test the supporting
/// data structures and equality logic.
void main() {
  group('CommentsPageParams', () {
    test('creates with required fields', () {
      const params = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      expect(params.postId, 'post-1');
      expect(params.pageKey, 1);
      expect(params.pageSize, 10);
    });

    test('equality works with same values', () {
      const params1 = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      const params2 = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      expect(params1, equals(params2));
      expect(params1.hashCode, equals(params2.hashCode));
    });

    test('inequality with different postId', () {
      const params1 = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      const params2 = CommentsPageParams(
        postId: 'post-2',
        pageKey: 1,
        pageSize: 10,
      );
      expect(params1, isNot(equals(params2)));
    });

    test('inequality with different pageKey', () {
      const params1 = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      const params2 = CommentsPageParams(
        postId: 'post-1',
        pageKey: 2,
        pageSize: 10,
      );
      expect(params1, isNot(equals(params2)));
    });

    test('inequality with different pageSize', () {
      const params1 = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      const params2 = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 20,
      );
      expect(params1, isNot(equals(params2)));
    });

    test('inequality with different type', () {
      const params = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      expect(params, isNot(equals('not a params')));
    });

    test('hashCode differs for different values', () {
      const params1 = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      const params2 = CommentsPageParams(
        postId: 'post-2',
        pageKey: 2,
        pageSize: 20,
      );
      // They could theoretically collide, but very unlikely
      expect(params1.hashCode, isNot(equals(params2.hashCode)));
    });

    test('identical returns true for same instance', () {
      const params = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      expect(params == params, isTrue);
    });

    test('works with empty postId', () {
      const params = CommentsPageParams(
        postId: '',
        pageKey: 0,
        pageSize: 0,
      );
      expect(params.postId, '');
      expect(params.pageKey, 0);
      expect(params.pageSize, 0);
    });

    test('works with large values', () {
      const params = CommentsPageParams(
        postId: 'very-long-post-id-12345678',
        pageKey: 9999,
        pageSize: 100,
      );
      expect(params.postId, 'very-long-post-id-12345678');
      expect(params.pageKey, 9999);
    });
  });
}
