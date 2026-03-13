import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

void main() {
  group('PostModel', () {
    final now = DateTime.utc(2025, 6, 1, 12, 0, 0);
    final later = DateTime.utc(2025, 6, 2, 12, 0, 0);

    Map<String, dynamic> _fullJson() => {
          'post_id': 'p-100',
          'user_id': 'u-200',
          'user_profiles': {
            'id': 'u-200',
            'nickname': 'writer',
            'avatar_url': null,
            'country_code': 'KR',
            'is_admin': false,
            'star_candy': 0,
            'star_candy_bonus': 0,
            'jma_candy': 0,
          },
          'board_id': 'b-10',
          'title': 'Test Post',
          'content': [
            {'type': 'text', 'value': 'Hello world'}
          ],
          'view_count': 42,
          'reply_count': 5,
          'is_hidden': false,
          'boards': {
            'board_id': 'b-10',
            'artist_id': 1,
            'name': {'ko': '자유게시판', 'en': 'Free Board'},
            'description': 'desc',
            'is_official': true,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'artist': null,
            'request_message': null,
            'status': 'active',
            'creator_id': null,
            'features': ['post', 'comment'],
          },
          'is_anonymous': false,
          'is_scraped': true,
          'created_at': now.toIso8601String(),
          'updated_at': later.toIso8601String(),
          'deleted_at': null,
        };

    Map<String, dynamic> _minimalJson() => {
          'post_id': 'p-min',
          'user_id': null,
          'user_profiles': null,
          'board_id': null,
          'title': null,
          'content': null,
          'view_count': null,
          'reply_count': null,
          'is_hidden': null,
          'boards': null,
          'is_anonymous': null,
          'is_scraped': null,
          'created_at': null,
          'updated_at': null,
        };

    test('fromJson with all fields', () {
      final post = PostModel.fromJson(_fullJson());

      expect(post.postId, 'p-100');
      expect(post.userId, 'u-200');
      expect(post.userProfiles, isNotNull);
      expect(post.userProfiles!.nickname, 'writer');
      expect(post.boardId, 'b-10');
      expect(post.title, 'Test Post');
      expect(post.content, isNotNull);
      expect(post.content!.length, 1);
      expect(post.viewCount, 42);
      expect(post.replyCount, 5);
      expect(post.isHidden, isFalse);
      expect(post.board, isNotNull);
      expect(post.board!.boardId, 'b-10');
      expect(post.isAnonymous, isFalse);
      expect(post.isScraped, isTrue);
      expect(post.createdAt, now);
      expect(post.updatedAt, later);
      expect(post.deletedAt, isNull);
    });

    test('fromJson with minimal fields', () {
      final post = PostModel.fromJson(_minimalJson());

      expect(post.postId, 'p-min');
      expect(post.userId, isNull);
      expect(post.userProfiles, isNull);
      expect(post.boardId, isNull);
      expect(post.title, isNull);
      expect(post.content, isNull);
      expect(post.viewCount, isNull);
      expect(post.replyCount, isNull);
      expect(post.isHidden, isNull);
      expect(post.board, isNull);
      expect(post.isAnonymous, isNull);
      expect(post.isScraped, isNull);
      expect(post.createdAt, isNull);
      expect(post.updatedAt, isNull);
      expect(post.deletedAt, isNull);
    });

    test('copyWith', () {
      final original = PostModel.fromJson(_fullJson());

      final updated = original.copyWith(
        title: 'Updated Title',
        viewCount: 100,
        isHidden: true,
        deletedAt: later,
      );

      expect(updated.postId, original.postId);
      expect(updated.title, 'Updated Title');
      expect(updated.viewCount, 100);
      expect(updated.isHidden, isTrue);
      expect(updated.deletedAt, later);
      // unchanged
      expect(updated.userId, original.userId);
      expect(updated.replyCount, original.replyCount);
      expect(updated.isScraped, original.isScraped);
    });

    test('toJson round-trip', () {
      final original = PostModel.fromJson(_fullJson());
      final json = original.toJson();
      final restored = PostModel.fromJson(json);

      expect(restored.postId, original.postId);
      expect(restored.userId, original.userId);
      expect(restored.boardId, original.boardId);
      expect(restored.title, original.title);
      expect(restored.viewCount, original.viewCount);
      expect(restored.replyCount, original.replyCount);
      expect(restored.isHidden, original.isHidden);
      expect(restored.isAnonymous, original.isAnonymous);
      expect(restored.isScraped, original.isScraped);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.deletedAt, original.deletedAt);
      expect(restored.userProfiles?.nickname, original.userProfiles?.nickname);
      expect(restored.board?.boardId, original.board?.boardId);
    });
  });
}
