import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/post.dart';

void main() {
  group('PostModel', () {
    test('필수 필드로 생성', () {
      final post = PostModel(
        postId: 'post-1',
        userId: 'user-1',
        userProfiles: null,
        boardId: 'board-1',
        title: '테스트 게시글',
        content: [
          {'type': 'text', 'value': '내용입니다'}
        ],
        viewCount: 10,
        replyCount: 3,
        isHidden: false,
        board: null,
        isAnonymous: false,
        isScraped: false,
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 1),
      );
      expect(post.postId, equals('post-1'));
      expect(post.title, equals('테스트 게시글'));
      expect(post.viewCount, equals(10));
      expect(post.replyCount, equals(3));
      expect(post.isHidden, isFalse);
      expect(post.isAnonymous, isFalse);
      expect(post.isScraped, isFalse);
      expect(post.deletedAt, isNull);
    });

    test('삭제된 게시글', () {
      final post = PostModel(
        postId: 'post-2',
        userId: null,
        userProfiles: null,
        boardId: null,
        title: null,
        content: null,
        viewCount: null,
        replyCount: null,
        isHidden: true,
        board: null,
        isAnonymous: null,
        isScraped: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 2, 1),
        deletedAt: DateTime(2025, 2, 1),
      );
      expect(post.deletedAt, isNotNull);
      expect(post.isHidden, isTrue);
    });

    test('익명 게시글', () {
      final post = PostModel(
        postId: 'post-3',
        userId: 'user-2',
        userProfiles: null,
        boardId: 'board-1',
        title: '익명 글',
        content: [],
        viewCount: 0,
        replyCount: 0,
        isHidden: false,
        board: null,
        isAnonymous: true,
        isScraped: false,
        createdAt: DateTime(2025, 3, 10),
        updatedAt: DateTime(2025, 3, 10),
      );
      expect(post.isAnonymous, isTrue);
    });
  });
}
