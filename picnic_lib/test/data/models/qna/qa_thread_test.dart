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
}
