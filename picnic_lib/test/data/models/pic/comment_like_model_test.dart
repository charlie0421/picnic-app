import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/comment_like.dart';

void main() {
  group('UserCommentLikeModel', () {
    test('필수 필드로 생성', () {
      final like = UserCommentLikeModel(
        id: 1,
        userId: 42,
        createdAt: DateTime(2025, 3, 1, 10, 30),
      );
      expect(like.id, equals(1));
      expect(like.userId, equals(42));
      expect(like.createdAt, equals(DateTime(2025, 3, 1, 10, 30)));
    });

    test('다른 유저', () {
      final like = UserCommentLikeModel(
        id: 100,
        userId: 999,
        createdAt: DateTime(2025, 6, 15),
      );
      expect(like.userId, equals(999));
    });
  });
}
