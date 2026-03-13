import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/presentation/providers/community/comments_provider_helper.dart';

final _now = DateTime(2026, 1, 1);
final _later = DateTime(2026, 1, 2);

CommentModel _makeComment({
  required String commentId,
  String userId = 'user-1',
  int likes = 0,
  int replies = 0,
  bool isLikedByMe = false,
  bool isReportedByMe = false,
  List<CommentModel>? children,
  String? parentCommentId,
  DateTime? createdAt,
}) {
  return CommentModel(
    commentId: commentId,
    userId: userId,
    children: children,
    myLike: null,
    user: null,
    likes: likes,
    replies: replies,
    content: {'ko': 'test'},
    isLikedByMe: isLikedByMe,
    isReportedByMe: isReportedByMe,
    isBlindedByAdmin: false,
    isRepliedByMe: false,
    post: null,
    locale: 'ko',
    parentCommentId: parentCommentId,
    createdAt: createdAt ?? _now,
    updatedAt: _now,
  );
}

Map<String, dynamic> _makeRow({
  required String commentId,
  String userId = 'user-1',
  int likes = 0,
  int replies = 0,
  String? parentCommentId,
  List<Map<String, dynamic>>? commentLikes,
  dynamic commentReports,
}) {
  return {
    'comment_id': commentId,
    'user_id': userId,
    'parent_comment_id': parentCommentId,
    'likes': likes,
    'replies': replies,
    'content': {'ko': 'test'},
    'locale': 'ko',
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'deleted_at': null,
    'user_profiles': {
      'nickname': 'TestUser',
      'avatar_url': 'https://example.com/avatar.png',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': null,
    },
    'comment_reports': commentReports,
    'comment_likes': commentLikes ?? <Map<String, dynamic>>[],
    'post': {
      'post_id': 'post-1',
      'board_id': 'board-1',
      'title': 'Test',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': null,
    },
  };
}

void main() {
  group('CommentsProviderHelper.parseCommentRow', () {
    test('sets isLikedByMe true when current user has active like', () {
      final row = _makeRow(
        commentId: 'c1',
        commentLikes: [
          {'comment_id': 'c1', 'user_id': 'me', 'deleted_at': null},
        ],
      );

      final result = CommentsProviderHelper.parseCommentRow(row, 'me');

      expect(result.isLikedByMe, isTrue);
      expect(result.commentId, 'c1');
    });

    test('sets isLikedByMe false when like is from another user', () {
      final row = _makeRow(
        commentId: 'c1',
        commentLikes: [
          {'comment_id': 'c1', 'user_id': 'other', 'deleted_at': null},
        ],
      );

      final result = CommentsProviderHelper.parseCommentRow(row, 'me');

      expect(result.isLikedByMe, isFalse);
    });

    test('sets isLikedByMe false when like has deleted_at', () {
      final row = _makeRow(
        commentId: 'c1',
        commentLikes: [
          {
            'comment_id': 'c1',
            'user_id': 'me',
            'deleted_at': '2026-01-02T00:00:00Z',
          },
        ],
      );

      final result = CommentsProviderHelper.parseCommentRow(row, 'me');

      expect(result.isLikedByMe, isFalse);
    });

    test('sets isLikedByMe false when no likes exist', () {
      final row = _makeRow(commentId: 'c1');

      final result = CommentsProviderHelper.parseCommentRow(row, 'me');

      expect(result.isLikedByMe, isFalse);
    });

    test('sets isLikedByMe false when currentUserId is null', () {
      final row = _makeRow(
        commentId: 'c1',
        commentLikes: [
          {'comment_id': 'c1', 'user_id': 'me', 'deleted_at': null},
        ],
      );

      final result = CommentsProviderHelper.parseCommentRow(row, null);

      expect(result.isLikedByMe, isFalse);
    });

    test('sets isReportedByMe true when comment_reports is non-empty', () {
      final row = _makeRow(
        commentId: 'c1',
        commentReports: [
          {'comment_id': 'c1'},
        ],
      );

      final result = CommentsProviderHelper.parseCommentRow(row, 'me');

      expect(result.isReportedByMe, isTrue);
    });

    test('sets isReportedByMe false when comment_reports is empty', () {
      final row = _makeRow(
        commentId: 'c1',
        commentReports: <Map<String, dynamic>>[],
      );

      final result = CommentsProviderHelper.parseCommentRow(row, 'me');

      expect(result.isReportedByMe, isFalse);
    });

    test('sets isReportedByMe false when comment_reports is null', () {
      final row = _makeRow(
        commentId: 'c1',
        commentReports: null,
      );

      final result = CommentsProviderHelper.parseCommentRow(row, 'me');

      expect(result.isReportedByMe, isFalse);
    });

    test('handles comment_likes being null in row', () {
      final row = _makeRow(commentId: 'c1');
      row['comment_likes'] = null;

      final result = CommentsProviderHelper.parseCommentRow(row, 'me');

      expect(result.isLikedByMe, isFalse);
    });

    test('multiple likes only checks current user', () {
      final row = _makeRow(
        commentId: 'c1',
        commentLikes: [
          {'comment_id': 'c1', 'user_id': 'other1', 'deleted_at': null},
          {'comment_id': 'c1', 'user_id': 'me', 'deleted_at': null},
          {'comment_id': 'c1', 'user_id': 'other2', 'deleted_at': null},
        ],
      );

      final result = CommentsProviderHelper.parseCommentRow(row, 'me');

      expect(result.isLikedByMe, isTrue);
    });
  });

  group('CommentsProviderHelper.buildCommentTree', () {
    test('returns empty list when no root comments', () {
      final result = CommentsProviderHelper.buildCommentTree([], []);

      expect(result, isEmpty);
    });

    test('returns root comments with empty children when no children', () {
      final roots = [
        _makeComment(commentId: 'r1'),
        _makeComment(commentId: 'r2'),
      ];

      final result = CommentsProviderHelper.buildCommentTree(roots, []);

      expect(result.length, 2);
      expect(result[0].children, isEmpty);
      expect(result[1].children, isEmpty);
    });

    test('attaches children to correct parent', () {
      final roots = [
        _makeComment(commentId: 'r1'),
      ];
      final children = [
        _makeComment(commentId: 'c1', parentCommentId: 'r1'),
        _makeComment(commentId: 'c2', parentCommentId: 'r1'),
      ];

      final result = CommentsProviderHelper.buildCommentTree(roots, children);

      expect(result.length, 1);
      expect(result[0].children!.length, 2);
      expect(result[0].children![0].commentId, 'c1');
      expect(result[0].children![1].commentId, 'c2');
    });

    test('children with non-existent parent are ignored', () {
      final roots = [
        _makeComment(commentId: 'r1'),
      ];
      final children = [
        _makeComment(commentId: 'c1', parentCommentId: 'non-existent'),
      ];

      final result = CommentsProviderHelper.buildCommentTree(roots, children);

      expect(result.length, 1);
      expect(result[0].children, isEmpty);
    });

    test('sorts result by createdAt descending', () {
      final roots = [
        _makeComment(commentId: 'old', createdAt: _now),
        _makeComment(commentId: 'new', createdAt: _later),
      ];

      final result = CommentsProviderHelper.buildCommentTree(roots, []);

      expect(result[0].commentId, 'new');
      expect(result[1].commentId, 'old');
    });

    test('multiple roots with different children', () {
      final roots = [
        _makeComment(commentId: 'r1'),
        _makeComment(commentId: 'r2'),
      ];
      final children = [
        _makeComment(commentId: 'c1', parentCommentId: 'r1'),
        _makeComment(commentId: 'c2', parentCommentId: 'r2'),
        _makeComment(commentId: 'c3', parentCommentId: 'r1'),
      ];

      final result = CommentsProviderHelper.buildCommentTree(roots, children);

      final r1 = result.firstWhere((c) => c.commentId == 'r1');
      final r2 = result.firstWhere((c) => c.commentId == 'r2');
      expect(r1.children!.length, 2);
      expect(r2.children!.length, 1);
    });
  });

  group('CommentsProviderHelper.filterBlockedUsers', () {
    test('returns all comments when blocked list is empty', () {
      final comments = [
        _makeComment(commentId: 'c1', userId: 'u1'),
        _makeComment(commentId: 'c2', userId: 'u2'),
      ];

      final result =
          CommentsProviderHelper.filterBlockedUsers(comments, []);

      expect(result.length, 2);
    });

    test('filters out blocked user comments', () {
      final comments = [
        _makeComment(commentId: 'c1', userId: 'u1'),
        _makeComment(commentId: 'c2', userId: 'u2'),
        _makeComment(commentId: 'c3', userId: 'u3'),
      ];

      final result =
          CommentsProviderHelper.filterBlockedUsers(comments, ['u2']);

      expect(result.length, 2);
      expect(result.any((c) => c.userId == 'u2'), isFalse);
    });

    test('filters out multiple blocked users', () {
      final comments = [
        _makeComment(commentId: 'c1', userId: 'u1'),
        _makeComment(commentId: 'c2', userId: 'u2'),
        _makeComment(commentId: 'c3', userId: 'u3'),
      ];

      final result =
          CommentsProviderHelper.filterBlockedUsers(comments, ['u1', 'u3']);

      expect(result.length, 1);
      expect(result[0].userId, 'u2');
    });

    test('returns empty when all users blocked', () {
      final comments = [
        _makeComment(commentId: 'c1', userId: 'u1'),
      ];

      final result =
          CommentsProviderHelper.filterBlockedUsers(comments, ['u1']);

      expect(result, isEmpty);
    });

    test('handles empty comments list', () {
      final result =
          CommentsProviderHelper.filterBlockedUsers([], ['u1']);

      expect(result, isEmpty);
    });
  });

  group('CommentsProviderHelper.markCommentAsReported', () {
    test('marks the matching comment as reported', () {
      final comments = [
        _makeComment(commentId: 'c1', isReportedByMe: false),
        _makeComment(commentId: 'c2', isReportedByMe: false),
      ];

      final result =
          CommentsProviderHelper.markCommentAsReported(comments, 'c1');

      expect(result[0].isReportedByMe, isTrue);
      expect(result[1].isReportedByMe, isFalse);
    });

    test('does not change other fields', () {
      final comments = [
        _makeComment(commentId: 'c1', likes: 5, isLikedByMe: true),
      ];

      final result =
          CommentsProviderHelper.markCommentAsReported(comments, 'c1');

      expect(result[0].likes, 5);
      expect(result[0].isLikedByMe, isTrue);
      expect(result[0].isReportedByMe, isTrue);
    });

    test('returns unchanged list when commentId not found', () {
      final comments = [
        _makeComment(commentId: 'c1', isReportedByMe: false),
      ];

      final result = CommentsProviderHelper.markCommentAsReported(
          comments, 'nonexistent');

      expect(result[0].isReportedByMe, isFalse);
    });

    test('handles empty list', () {
      final result =
          CommentsProviderHelper.markCommentAsReported([], 'c1');

      expect(result, isEmpty);
    });
  });

  group('CommentsProviderHelper.filterCommentsByUserId', () {
    test('removes all comments from specified user', () {
      final comments = [
        _makeComment(commentId: 'c1', userId: 'u1'),
        _makeComment(commentId: 'c2', userId: 'u2'),
        _makeComment(commentId: 'c3', userId: 'u1'),
      ];

      final result =
          CommentsProviderHelper.filterCommentsByUserId(comments, 'u1');

      expect(result.length, 1);
      expect(result[0].commentId, 'c2');
    });

    test('returns all comments when userId not found', () {
      final comments = [
        _makeComment(commentId: 'c1', userId: 'u1'),
      ];

      final result = CommentsProviderHelper.filterCommentsByUserId(
          comments, 'nonexistent');

      expect(result.length, 1);
    });

    test('handles empty list', () {
      final result =
          CommentsProviderHelper.filterCommentsByUserId([], 'u1');

      expect(result, isEmpty);
    });
  });

  group('CommentsProviderHelper.removeComment', () {
    test('removes the matching comment', () {
      final comments = [
        _makeComment(commentId: 'c1'),
        _makeComment(commentId: 'c2'),
        _makeComment(commentId: 'c3'),
      ];

      final result =
          CommentsProviderHelper.removeComment(comments, 'c2');

      expect(result.length, 2);
      expect(result.any((c) => c.commentId == 'c2'), isFalse);
    });

    test('returns unchanged list when commentId not found', () {
      final comments = [
        _makeComment(commentId: 'c1'),
      ];

      final result =
          CommentsProviderHelper.removeComment(comments, 'nonexistent');

      expect(result.length, 1);
    });

    test('returns empty list when removing only comment', () {
      final comments = [
        _makeComment(commentId: 'c1'),
      ];

      final result =
          CommentsProviderHelper.removeComment(comments, 'c1');

      expect(result, isEmpty);
    });

    test('handles empty list', () {
      final result =
          CommentsProviderHelper.removeComment([], 'c1');

      expect(result, isEmpty);
    });

    test('preserves order of remaining comments', () {
      final comments = [
        _makeComment(commentId: 'c1'),
        _makeComment(commentId: 'c2'),
        _makeComment(commentId: 'c3'),
      ];

      final result =
          CommentsProviderHelper.removeComment(comments, 'c2');

      expect(result[0].commentId, 'c1');
      expect(result[1].commentId, 'c3');
    });
  });
}
