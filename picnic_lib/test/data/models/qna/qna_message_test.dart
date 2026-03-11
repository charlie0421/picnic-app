import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';

void main() {
  group('QnaMessage', () {
    test('기본 생성', () {
      final msg = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-1',
        content: '문의 내용입니다',
        createdAt: DateTime(2025, 3, 1),
        isAdminMessage: false,
      );
      expect(msg.id, equals(1));
      expect(msg.threadId, equals(10));
      expect(msg.content, equals('문의 내용입니다'));
      expect(msg.isAdminMessage, isFalse);
      expect(msg.attachments, isEmpty);
    });

    test('관리자 메시지', () {
      final msg = QnaMessage(
        id: 2,
        threadId: 10,
        userId: 'admin-1',
        content: '답변입니다',
        createdAt: DateTime(2025, 3, 2),
        isAdminMessage: true,
      );
      expect(msg.isAdminMessage, isTrue);
    });

    test('content null 허용', () {
      final msg = QnaMessage(
        id: 3,
        threadId: 10,
        userId: 'user-1',
        content: null,
        createdAt: DateTime(2025, 3, 1),
        isAdminMessage: false,
      );
      expect(msg.content, isNull);
    });
  });
}
