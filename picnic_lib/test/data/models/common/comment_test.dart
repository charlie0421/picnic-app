import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/pic/comment_like.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

void main() {
  group('CommentModel', () {
    final now = DateTime.utc(2025, 6, 1, 12, 0, 0);
    final later = DateTime.utc(2025, 6, 2, 12, 0, 0);

    Map<String, dynamic> _fullJson() => {
          'comment_id': 'c-100',
          'user_id': 'u-200',
          'children': <Map<String, dynamic>>[],
          'my_like': {
            'id': 1,
            'user_id': 42,
            'created_at': now.toIso8601String(),
          },
          'user_profiles': {
            'id': 'u-200',
            'nickname': 'tester',
            'avatar_url': 'https://example.com/a.png',
            'country_code': 'KR',
            'is_admin': false,
            'star_candy': 10,
            'star_candy_bonus': 0,
            'jma_candy': 5,
          },
          'likes': 7,
          'replies': 2,
          'content': {'type': 'text', 'value': 'hello'},
          'is_liked_by_me': true,
          'is_reported_by_me': false,
          'is_blinded_by_admin': false,
          'is_replied_by_me': true,
          'post': null,
          'locale': 'ko',
          'parent_comment_id': 'c-50',
          'created_at': now.toIso8601String(),
          'updated_at': later.toIso8601String(),
          'deleted_at': null,
        };

    Map<String, dynamic> _minimalJson() => {
          'comment_id': 'c-min',
          'children': null,
          'my_like': null,
          'user_profiles': null,
          'likes': 0,
          'replies': 0,
          'content': null,
          'is_liked_by_me': null,
          'is_reported_by_me': null,
          'is_blinded_by_admin': null,
          'is_replied_by_me': null,
          'post': null,
          'locale': null,
          'parent_comment_id': null,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

    test('fromJson with all fields', () {
      final comment = CommentModel.fromJson(_fullJson());

      expect(comment.commentId, 'c-100');
      expect(comment.userId, 'u-200');
      expect(comment.children, isNotNull);
      expect(comment.children, isEmpty);
      expect(comment.myLike, isNotNull);
      expect(comment.myLike!.id, 1);
      expect(comment.user, isNotNull);
      expect(comment.user!.nickname, 'tester');
      expect(comment.likes, 7);
      expect(comment.replies, 2);
      expect(comment.content, {'type': 'text', 'value': 'hello'});
      expect(comment.isLikedByMe, isTrue);
      expect(comment.isReportedByMe, isFalse);
      expect(comment.isBlindedByAdmin, isFalse);
      expect(comment.isRepliedByMe, isTrue);
      expect(comment.post, isNull);
      expect(comment.locale, 'ko');
      expect(comment.parentCommentId, 'c-50');
      expect(comment.createdAt, now);
      expect(comment.updatedAt, later);
      expect(comment.deletedAt, isNull);
    });

    test('fromJson with minimal fields (nulls where possible)', () {
      final comment = CommentModel.fromJson(_minimalJson());

      expect(comment.commentId, 'c-min');
      expect(comment.userId, isNull);
      expect(comment.children, isNull);
      expect(comment.myLike, isNull);
      expect(comment.user, isNull);
      expect(comment.likes, 0);
      expect(comment.replies, 0);
      expect(comment.content, isNull);
      expect(comment.isLikedByMe, isNull);
      expect(comment.isReportedByMe, isNull);
      expect(comment.isBlindedByAdmin, isNull);
      expect(comment.isRepliedByMe, isNull);
      expect(comment.post, isNull);
      expect(comment.locale, isNull);
      expect(comment.parentCommentId, isNull);
      expect(comment.deletedAt, isNull);
    });

    test('toJson round-trip', () {
      final original = CommentModel.fromJson(_fullJson());
      final json = original.toJson();
      final restored = CommentModel.fromJson(json);

      expect(restored.commentId, original.commentId);
      expect(restored.userId, original.userId);
      expect(restored.likes, original.likes);
      expect(restored.replies, original.replies);
      expect(restored.content, original.content);
      expect(restored.isLikedByMe, original.isLikedByMe);
      expect(restored.isReportedByMe, original.isReportedByMe);
      expect(restored.isBlindedByAdmin, original.isBlindedByAdmin);
      expect(restored.isRepliedByMe, original.isRepliedByMe);
      expect(restored.locale, original.locale);
      expect(restored.parentCommentId, original.parentCommentId);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.deletedAt, original.deletedAt);
      expect(restored.myLike?.id, original.myLike?.id);
      expect(restored.user?.nickname, original.user?.nickname);
    });

    test('copyWith changing fields', () {
      final original = CommentModel.fromJson(_fullJson());

      final updated = original.copyWith(
        likes: 99,
        isLikedByMe: false,
        locale: 'en',
        deletedAt: later,
      );

      expect(updated.commentId, original.commentId);
      expect(updated.likes, 99);
      expect(updated.isLikedByMe, isFalse);
      expect(updated.locale, 'en');
      expect(updated.deletedAt, later);
      // unchanged fields
      expect(updated.userId, original.userId);
      expect(updated.replies, original.replies);
      expect(updated.createdAt, original.createdAt);
    });

    test('children list with nested comments', () {
      final childJson = {
        'comment_id': 'child-1',
        'user_id': 'u-300',
        'children': null,
        'my_like': null,
        'user_profiles': null,
        'likes': 1,
        'replies': 0,
        'content': {'type': 'text', 'value': 'reply'},
        'is_liked_by_me': false,
        'is_reported_by_me': false,
        'is_blinded_by_admin': false,
        'is_replied_by_me': false,
        'post': null,
        'locale': 'ko',
        'parent_comment_id': 'c-100',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final parentJson = _fullJson()
        ..['children'] = [childJson];

      final parent = CommentModel.fromJson(parentJson);

      expect(parent.children, isNotNull);
      expect(parent.children!.length, 1);
      expect(parent.children![0].commentId, 'child-1');
      expect(parent.children![0].parentCommentId, 'c-100');
      expect(parent.children![0].children, isNull);

      // round-trip with children
      final json = parent.toJson();
      final restored = CommentModel.fromJson(json);
      expect(restored.children!.length, 1);
      expect(restored.children![0].commentId, 'child-1');
    });
  });
}
