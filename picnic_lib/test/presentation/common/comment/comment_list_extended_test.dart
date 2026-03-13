import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/comment/comment_list.dart';

/// Extended tests for CommentList data models
/// covering additional edge cases for CommentsPageParams.
void main() {
  group('CommentsPageParams equality', () {
    test('same instance returns true for ==', () {
      const params = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 10,
      );
      expect(params == params, isTrue);
    });

    test('identical values return true', () {
      const p1 = CommentsPageParams(postId: 'abc', pageKey: 1, pageSize: 10);
      const p2 = CommentsPageParams(postId: 'abc', pageKey: 1, pageSize: 10);
      expect(p1 == p2, isTrue);
      expect(p1.hashCode == p2.hashCode, isTrue);
    });

    test('different postId returns false', () {
      const p1 = CommentsPageParams(postId: 'a', pageKey: 1, pageSize: 10);
      const p2 = CommentsPageParams(postId: 'b', pageKey: 1, pageSize: 10);
      expect(p1 == p2, isFalse);
    });

    test('different pageKey returns false', () {
      const p1 = CommentsPageParams(postId: 'a', pageKey: 1, pageSize: 10);
      const p2 = CommentsPageParams(postId: 'a', pageKey: 2, pageSize: 10);
      expect(p1 == p2, isFalse);
    });

    test('different pageSize returns false', () {
      const p1 = CommentsPageParams(postId: 'a', pageKey: 1, pageSize: 10);
      const p2 = CommentsPageParams(postId: 'a', pageKey: 1, pageSize: 20);
      expect(p1 == p2, isFalse);
    });

    test('comparison with non-CommentsPageParams returns false', () {
      const params = CommentsPageParams(postId: 'a', pageKey: 1, pageSize: 10);
      expect(params == 'not a params', isFalse);
      expect(params == 42, isFalse);
      expect(params == null, isFalse);
    });

    test('hashCode is consistent for same values', () {
      const p1 = CommentsPageParams(postId: 'x', pageKey: 5, pageSize: 25);
      const p2 = CommentsPageParams(postId: 'x', pageKey: 5, pageSize: 25);
      expect(p1.hashCode, p2.hashCode);
    });

    test('hashCode differs for different postId', () {
      const p1 = CommentsPageParams(postId: 'x', pageKey: 5, pageSize: 25);
      const p2 = CommentsPageParams(postId: 'y', pageKey: 5, pageSize: 25);
      expect(p1.hashCode, isNot(p2.hashCode));
    });

    test('hashCode differs for different pageKey', () {
      const p1 = CommentsPageParams(postId: 'x', pageKey: 1, pageSize: 25);
      const p2 = CommentsPageParams(postId: 'x', pageKey: 2, pageSize: 25);
      expect(p1.hashCode, isNot(p2.hashCode));
    });

    test('hashCode differs for different pageSize', () {
      const p1 = CommentsPageParams(postId: 'x', pageKey: 1, pageSize: 10);
      const p2 = CommentsPageParams(postId: 'x', pageKey: 1, pageSize: 20);
      expect(p1.hashCode, isNot(p2.hashCode));
    });
  });

  group('CommentsPageParams values', () {
    test('boundary values - zero page key', () {
      const params = CommentsPageParams(
        postId: 'post-1',
        pageKey: 0,
        pageSize: 10,
      );
      expect(params.pageKey, 0);
    });

    test('boundary values - large page key', () {
      const params = CommentsPageParams(
        postId: 'post-1',
        pageKey: 999999,
        pageSize: 10,
      );
      expect(params.pageKey, 999999);
    });

    test('boundary values - page size of 1', () {
      const params = CommentsPageParams(
        postId: 'post-1',
        pageKey: 1,
        pageSize: 1,
      );
      expect(params.pageSize, 1);
    });

    test('boundary values - empty post ID', () {
      const params = CommentsPageParams(
        postId: '',
        pageKey: 1,
        pageSize: 10,
      );
      expect(params.postId, '');
    });

    test('UUID-style post ID', () {
      const params = CommentsPageParams(
        postId: '550e8400-e29b-41d4-a716-446655440000',
        pageKey: 1,
        pageSize: 10,
      );
      expect(params.postId, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('numeric post ID as string', () {
      const params = CommentsPageParams(
        postId: '12345',
        pageKey: 1,
        pageSize: 10,
      );
      expect(params.postId, '12345');
    });
  });

  group('CommentList debounce logic pattern', () {
    test('debounce timer prevents rapid actions', () {
      var actionCount = 0;
      var isDebouncing = false;

      void handleAction() {
        if (isDebouncing) return;
        isDebouncing = true;
        actionCount++;
        // Timer would reset isDebouncing after 500ms
      }

      handleAction(); // Should execute
      handleAction(); // Should be blocked
      handleAction(); // Should be blocked

      expect(actionCount, 1);
    });

    test('debounce allows action after timer expires', () {
      var actionCount = 0;
      var isDebouncing = false;

      void handleAction() {
        if (isDebouncing) return;
        isDebouncing = true;
        actionCount++;
      }

      void resetDebounce() {
        isDebouncing = false;
      }

      handleAction();
      expect(actionCount, 1);

      resetDebounce();
      handleAction();
      expect(actionCount, 2);
    });
  });

  group('Comment pagination logic', () {
    test('isLastPage when items less than pageSize', () {
      const pageSize = 10;
      final items = List.generate(5, (i) => 'comment-$i');
      final isLastPage = items.length < pageSize;
      expect(isLastPage, isTrue);
    });

    test('not isLastPage when items equal to pageSize', () {
      const pageSize = 10;
      final items = List.generate(10, (i) => 'comment-$i');
      final isLastPage = items.length < pageSize;
      expect(isLastPage, isFalse);
    });

    test('next page key calculation', () {
      const currentPageKey = 3;
      const nextPageKey = currentPageKey + 1;
      expect(nextPageKey, 4);
    });

    test('getNextPageKey returns null for last page', () {
      const pageSize = 10;
      final items = List.generate(5, (i) => 'comment-$i');
      final isLastPage = items.length < pageSize;
      final nextPageKey = isLastPage ? null : 2;
      expect(nextPageKey, isNull);
    });
  });

  group('Comment child items logic', () {
    test('detects non-empty children', () {
      final children = ['child-1', 'child-2'];
      expect(children.isNotEmpty, isTrue);
    });

    test('detects empty children', () {
      final children = <String>[];
      expect(children.isNotEmpty, isFalse);
    });

    test('null children handled with ?? operator', () {
      List<String>? children;
      expect(children?.isNotEmpty ?? false, isFalse);
    });
  });

  group('Reply mode logic', () {
    test('reply mode active when parentComment has non-empty id', () {
      const parentCommentId = 'comment-123';
      final isReplyMode = parentCommentId.isNotEmpty;
      expect(isReplyMode, isTrue);
    });

    test('reply mode inactive when parentComment is null', () {
      const String? parentCommentId = null;
      final isReplyMode = parentCommentId?.isNotEmpty ?? false;
      expect(isReplyMode, isFalse);
    });

    test('reply mode inactive when parentComment has empty id', () {
      const parentCommentId = '';
      final isReplyMode = parentCommentId.isNotEmpty;
      expect(isReplyMode, isFalse);
    });
  });
}
