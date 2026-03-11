import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';

void main() {
  group('CommentModel', () {
    test('필수 필드로 생성', () {
      final comment = CommentModel(
        commentId: 'comment-1',
        children: null,
        myLike: null,
        user: null,
        likes: 10,
        replies: 3,
        content: {'type': 'text', 'value': '댓글 내용'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 1),
      );
      expect(comment.commentId, equals('comment-1'));
      expect(comment.likes, equals(10));
      expect(comment.replies, equals(3));
      expect(comment.isLikedByMe, isFalse);
      expect(comment.isReportedByMe, isFalse);
      expect(comment.isBlindedByAdmin, isFalse);
      expect(comment.deletedAt, isNull);
      expect(comment.parentCommentId, isNull);
    });

    test('삭제된 댓글', () {
      final comment = CommentModel(
        commentId: 'comment-2',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: null,
        isLikedByMe: null,
        isReportedByMe: null,
        isBlindedByAdmin: null,
        isRepliedByMe: null,
        post: null,
        locale: null,
        parentCommentId: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 2, 1),
        deletedAt: DateTime(2025, 2, 1),
      );
      expect(comment.deletedAt, isNotNull);
      expect(comment.content, isNull);
    });

    test('대댓글 (parentCommentId 있음)', () {
      final reply = CommentModel(
        commentId: 'reply-1',
        children: null,
        myLike: null,
        user: null,
        likes: 5,
        replies: 0,
        content: {'type': 'text', 'value': '대댓글입니다'},
        isLikedByMe: true,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: 'comment-1',
        createdAt: DateTime(2025, 3, 2),
        updatedAt: DateTime(2025, 3, 2),
      );
      expect(reply.parentCommentId, equals('comment-1'));
      expect(reply.isLikedByMe, isTrue);
    });

    test('자식 댓글 포함', () {
      final child = CommentModel(
        commentId: 'child-1',
        children: null,
        myLike: null,
        user: null,
        likes: 2,
        replies: 0,
        content: {'type': 'text', 'value': '자식'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: 'parent-1',
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 1),
      );

      final parent = CommentModel(
        commentId: 'parent-1',
        children: [child],
        myLike: null,
        user: null,
        likes: 20,
        replies: 1,
        content: {'type': 'text', 'value': '부모'},
        isLikedByMe: false,
        isReportedByMe: false,
        isBlindedByAdmin: false,
        isRepliedByMe: true,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 1),
      );
      expect(parent.children, isNotNull);
      expect(parent.children!.length, equals(1));
      expect(parent.children![0].commentId, equals('child-1'));
      expect(parent.isRepliedByMe, isTrue);
    });

    test('관리자 블라인드 처리된 댓글', () {
      final blinded = CommentModel(
        commentId: 'blinded-1',
        children: null,
        myLike: null,
        user: null,
        likes: 0,
        replies: 0,
        content: {'type': 'text', 'value': '부적절한 내용'},
        isLikedByMe: false,
        isReportedByMe: true,
        isBlindedByAdmin: true,
        isRepliedByMe: false,
        post: null,
        locale: 'ko',
        parentCommentId: null,
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 5),
      );
      expect(blinded.isBlindedByAdmin, isTrue);
      expect(blinded.isReportedByMe, isTrue);
    });
  });
}
