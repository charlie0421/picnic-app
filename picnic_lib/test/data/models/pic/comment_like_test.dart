import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/comment_like.dart';

void main() {
  group('UserCommentLikeModel', () {
    test('creates from constructor', () {
      final model = UserCommentLikeModel(
        id: 1,
        userId: 42,
        createdAt: DateTime(2025, 1, 15),
      );
      expect(model.id, 1);
      expect(model.userId, 42);
      expect(model.createdAt, DateTime(2025, 1, 15));
    });

    test('creates from JSON', () {
      final json = {
        'id': 5,
        'user_id': 100,
        'created_at': '2025-06-01T12:00:00.000Z',
      };
      final model = UserCommentLikeModel.fromJson(json);
      expect(model.id, 5);
      expect(model.userId, 100);
    });

    test('toJson serializes correctly', () {
      final model = UserCommentLikeModel(
        id: 1,
        userId: 42,
        createdAt: DateTime.utc(2025, 1, 15),
      );
      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['user_id'], 42);
    });

    test('copyWith updates fields', () {
      final model = UserCommentLikeModel(
        id: 1,
        userId: 42,
        createdAt: DateTime(2025, 1, 15),
      );
      final updated = model.copyWith(userId: 99);
      expect(updated.userId, 99);
      expect(updated.id, 1);
    });

    test('equality works', () {
      final now = DateTime(2025, 1, 15);
      final a = UserCommentLikeModel(id: 1, userId: 42, createdAt: now);
      final b = UserCommentLikeModel(id: 1, userId: 42, createdAt: now);
      expect(a, equals(b));
    });
  });
}
