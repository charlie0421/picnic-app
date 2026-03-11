import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/post_scrap.dart';

void main() {
  group('PostScrapModel', () {
    test('필수 필드로 생성', () {
      final scrap = PostScrapModel(
        postId: 'post-1',
        userId: 'user-1',
        userProfiles: null,
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 1),
        board: null,
        post: null,
      );
      expect(scrap.postId, equals('post-1'));
      expect(scrap.userId, equals('user-1'));
      expect(scrap.userProfiles, isNull);
      expect(scrap.board, isNull);
      expect(scrap.post, isNull);
      expect(scrap.deletedAt, isNull);
    });

    test('삭제된 스크랩', () {
      final scrap = PostScrapModel(
        postId: 'post-2',
        userId: 'user-2',
        userProfiles: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 2, 1),
        board: null,
        post: null,
        deletedAt: DateTime(2025, 2, 1),
      );
      expect(scrap.deletedAt, isNotNull);
      expect(scrap.updatedAt, equals(scrap.deletedAt));
    });

    test('날짜 비교', () {
      final scrap = PostScrapModel(
        postId: 'post-3',
        userId: 'user-3',
        userProfiles: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 15),
        board: null,
        post: null,
      );
      expect(scrap.updatedAt.isAfter(scrap.createdAt), isTrue);
    });
  });
}
