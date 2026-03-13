import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/presentation/providers/community/comment_like_helper.dart';

CommentModel _makeComment({
  required String commentId,
  int likes = 0,
  bool isLikedByMe = false,
  List<CommentModel>? children,
}) {
  final now = DateTime.now();
  return CommentModel(
    commentId: commentId,
    userId: 'user-1',
    children: children,
    myLike: null,
    user: null,
    likes: likes,
    replies: 0,
    content: {'text': 'test'},
    isLikedByMe: isLikedByMe,
    isReportedByMe: false,
    isBlindedByAdmin: false,
    isRepliedByMe: false,
    post: null,
    locale: 'ko',
    parentCommentId: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CommentLikeHelper.updateCommentLikeStatus', () {
    test('likes a top-level comment', () {
      final comments = [
        _makeComment(commentId: 'c1', likes: 5, isLikedByMe: false),
        _makeComment(commentId: 'c2', likes: 3, isLikedByMe: false),
      ];

      final result =
          CommentLikeHelper.updateCommentLikeStatus(comments, 'c1', true);

      expect(result[0].isLikedByMe, isTrue);
      expect(result[0].likes, 6);
      // Other comment unchanged
      expect(result[1].isLikedByMe, isFalse);
      expect(result[1].likes, 3);
    });

    test('unlikes a top-level comment', () {
      final comments = [
        _makeComment(commentId: 'c1', likes: 5, isLikedByMe: true),
      ];

      final result =
          CommentLikeHelper.updateCommentLikeStatus(comments, 'c1', false);

      expect(result[0].isLikedByMe, isFalse);
      expect(result[0].likes, 4);
    });

    test('likes a nested child comment', () {
      final comments = [
        _makeComment(
          commentId: 'parent',
          likes: 10,
          children: [
            _makeComment(commentId: 'child1', likes: 2, isLikedByMe: false),
            _makeComment(commentId: 'child2', likes: 0, isLikedByMe: false),
          ],
        ),
      ];

      final result = CommentLikeHelper.updateCommentLikeStatus(
          comments, 'child1', true);

      // Parent unchanged
      expect(result[0].likes, 10);
      // Child updated
      expect(result[0].children![0].isLikedByMe, isTrue);
      expect(result[0].children![0].likes, 3);
      // Other child unchanged
      expect(result[0].children![1].isLikedByMe, isFalse);
      expect(result[0].children![1].likes, 0);
    });

    test('likes a deeply nested comment', () {
      final comments = [
        _makeComment(
          commentId: 'root',
          likes: 1,
          children: [
            _makeComment(
              commentId: 'level1',
              likes: 2,
              children: [
                _makeComment(
                    commentId: 'level2', likes: 0, isLikedByMe: false),
              ],
            ),
          ],
        ),
      ];

      final result = CommentLikeHelper.updateCommentLikeStatus(
          comments, 'level2', true);

      expect(result[0].children![0].children![0].isLikedByMe, isTrue);
      expect(result[0].children![0].children![0].likes, 1);
    });

    test('returns unchanged list when commentId not found', () {
      final comments = [
        _makeComment(commentId: 'c1', likes: 5, isLikedByMe: false),
      ];

      final result = CommentLikeHelper.updateCommentLikeStatus(
          comments, 'nonexistent', true);

      expect(result[0].likes, 5);
      expect(result[0].isLikedByMe, isFalse);
    });

    test('handles empty list', () {
      final result =
          CommentLikeHelper.updateCommentLikeStatus([], 'c1', true);
      expect(result, isEmpty);
    });

    test('handles comment with null children', () {
      final comments = [
        _makeComment(commentId: 'c1', likes: 3, children: null),
      ];

      final result = CommentLikeHelper.updateCommentLikeStatus(
          comments, 'nonexistent', true);

      expect(result[0].likes, 3);
    });

    test('handles comment with empty children list', () {
      final comments = [
        _makeComment(commentId: 'c1', likes: 3, children: []),
      ];

      final result = CommentLikeHelper.updateCommentLikeStatus(
          comments, 'nonexistent', true);

      expect(result[0].likes, 3);
    });

    test('only updates the matching comment among siblings', () {
      final comments = [
        _makeComment(commentId: 'c1', likes: 1),
        _makeComment(commentId: 'c2', likes: 2),
        _makeComment(commentId: 'c3', likes: 3),
      ];

      final result =
          CommentLikeHelper.updateCommentLikeStatus(comments, 'c2', true);

      expect(result[0].likes, 1);
      expect(result[1].likes, 3);
      expect(result[1].isLikedByMe, isTrue);
      expect(result[2].likes, 3);
    });

    test('preserves list length', () {
      final comments = [
        _makeComment(commentId: 'c1'),
        _makeComment(commentId: 'c2'),
        _makeComment(commentId: 'c3'),
      ];

      final result =
          CommentLikeHelper.updateCommentLikeStatus(comments, 'c1', true);

      expect(result.length, 3);
    });
  });
}
