import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/presentation/providers/comment_list_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  PagingController<int, CommentModel> _createPagingController() {
    return PagingController<int, CommentModel>(
      getNextPageKey: (state) => (state.keys?.last ?? 0) + 1,
      fetchPage: (pageKey) async => [],
    );
  }

  group('CommentState', () {
    test('stores all fields correctly', () {
      final controller = _createPagingController();
      addTearDown(() => controller.dispose());

      final state = CommentState(
        articleId: 42,
        page: 2,
        limit: 20,
        sort: 'article_comment.id',
        order: 'ASC',
        pagingController: controller,
        commentCount: 15,
      );

      expect(state.articleId, 42);
      expect(state.page, 2);
      expect(state.limit, 20);
      expect(state.sort, 'article_comment.id');
      expect(state.order, 'ASC');
      expect(state.pagingController, controller);
      expect(state.commentCount, 15);
    });

    test('different instances with same values', () {
      final controller = _createPagingController();
      addTearDown(() => controller.dispose());

      final state1 = CommentState(
        articleId: 1,
        page: 1,
        limit: 10,
        sort: 'id',
        order: 'ASC',
        pagingController: controller,
        commentCount: 0,
      );
      final state2 = CommentState(
        articleId: 1,
        page: 1,
        limit: 10,
        sort: 'id',
        order: 'ASC',
        pagingController: controller,
        commentCount: 0,
      );

      // CommentState doesn't implement == so these are different instances
      expect(state1.articleId, state2.articleId);
      expect(state1.page, state2.page);
    });

    test('stores zero commentCount', () {
      final controller = _createPagingController();
      addTearDown(() => controller.dispose());

      final state = CommentState(
        articleId: 1,
        page: 1,
        limit: 10,
        sort: 'id',
        order: 'DESC',
        pagingController: controller,
        commentCount: 0,
      );
      expect(state.commentCount, 0);
      expect(state.order, 'DESC');
    });
  });

  // Note: AsyncCommentList.build and fetch use .count() which requires
  // special mock handling. The submitComment method uses .insert() which
  // works with the standard mock. Testing the provider build would require
  // extended mock support for count queries.

  group('ParentItem provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    CommentModel _makeComment(String id) => CommentModel(
          commentId: id,
          userId: 'u-1',
          children: null,
          myLike: null,
          user: null,
          likes: 0,
          replies: 0,
          content: {'type': 'text', 'value': 'test'},
          isLikedByMe: false,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          isRepliedByMe: false,
          post: null,
          locale: 'ko',
          parentCommentId: null,
          createdAt: DateTime.utc(2025, 6, 1),
          updatedAt: DateTime.utc(2025, 6, 1),
        );

    test('initial state is null', () {
      final state = container.read(parentItemProvider);
      expect(state, isNull);
    });

    test('setParentItem sets a CommentModel', () {
      final comment = _makeComment('c-1');
      container.read(parentItemProvider.notifier).setParentItem(comment);

      final state = container.read(parentItemProvider);
      expect(state, isNotNull);
      expect(state!.commentId, 'c-1');
    });

    test('setParentItem(null) resets to null', () {
      final comment = _makeComment('c-2');
      container.read(parentItemProvider.notifier).setParentItem(comment);
      expect(container.read(parentItemProvider), isNotNull);

      container.read(parentItemProvider.notifier).setParentItem(null);
      expect(container.read(parentItemProvider), isNull);
    });
  });
}
