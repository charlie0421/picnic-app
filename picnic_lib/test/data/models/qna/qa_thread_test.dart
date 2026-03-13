import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qa_thread.dart';

void main() {
  group('QnaThread (qa_thread.dart)', () {
    test('필수 필드로 생성', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-abc',
        title: '문의 제목',
        createdAt: DateTime(2025, 3, 1),
        status: 'open',
        updatedAt: DateTime(2025, 3, 1),
      );
      expect(thread.id, equals(1));
      expect(thread.userId, equals('user-abc'));
      expect(thread.title, equals('문의 제목'));
      expect(thread.status, equals('open'));
    });

    test('resolved 상태', () {
      final thread = QnaThread(
        id: 2,
        userId: 'user-xyz',
        title: '해결된 문의',
        createdAt: DateTime(2025, 1, 1),
        status: 'resolved',
        updatedAt: DateTime(2025, 2, 1),
      );
      expect(thread.status, equals('resolved'));
      expect(thread.updatedAt.isAfter(thread.createdAt), isTrue);
    });

    test('다양한 상태값', () {
      for (final status in ['open', 'in_progress', 'resolved', 'closed']) {
        final thread = QnaThread(
          id: 1,
          userId: 'user-1',
          title: '테스트',
          createdAt: DateTime(2025, 1, 1),
          status: status,
          updatedAt: DateTime(2025, 1, 1),
        );
        expect(thread.status, equals(status));
      }
    });
  });

  group('QnaThread fromJson/toJson', () {
    test('fromJson roundtrip', () {
      final json = {
        'id': 10,
        'user_id': 'user-abc',
        'title': '문의 제목',
        'created_at': '2025-03-01T00:00:00.000Z',
        'status': 'open',
        'updated_at': '2025-03-05T00:00:00.000Z',
      };
      final thread = QnaThread.fromJson(json);
      expect(thread.id, equals(10));
      expect(thread.userId, equals('user-abc'));
      expect(thread.title, equals('문의 제목'));
      expect(thread.status, equals('open'));
      expect(thread.createdAt, isA<DateTime>());
      expect(thread.updatedAt, isA<DateTime>());

      final output = thread.toJson();
      expect(output['id'], equals(10));
      expect(output['user_id'], equals('user-abc'));
      expect(output['title'], equals('문의 제목'));
      expect(output['status'], equals('open'));
    });

    test('toJson preserves all fields', () {
      final thread = QnaThread(
        id: 5,
        userId: 'u-xyz',
        title: 'Test Thread',
        createdAt: DateTime.utc(2025, 6, 1),
        status: 'resolved',
        updatedAt: DateTime.utc(2025, 6, 15),
      );
      final json = thread.toJson();
      expect(json['id'], equals(5));
      expect(json['user_id'], equals('u-xyz'));
      expect(json['title'], equals('Test Thread'));
      expect(json['status'], equals('resolved'));
    });
  });
}
