import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';

void main() {
  group('QnaThread', () {
    late QnaThread thread;

    setUp(() {
      thread = QnaThread(
        id: 1,
        userId: 'user-1',
        title: '문의 제목',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        status: 'RECEIVED',
      );
    });

    test('필수 필드 확인', () {
      expect(thread.id, equals(1));
      expect(thread.userId, equals('user-1'));
      expect(thread.title, equals('문의 제목'));
      expect(thread.status, equals('RECEIVED'));
    });
  });

  group('QnaThreadStatusX', () {
    test('RECEIVED 상태', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );
      expect(thread.isReceived, isTrue);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isFalse);
      expect(thread.isOpen, isTrue);
      expect(thread.isClosed, isFalse);
    });

    test('IN_PROGRESS 상태', () {
      final thread = QnaThread(
        id: 2,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'IN_PROGRESS',
      );
      expect(thread.isReceived, isFalse);
      expect(thread.isInProgress, isTrue);
      expect(thread.isResolved, isFalse);
      expect(thread.isOpen, isTrue);
      expect(thread.isClosed, isFalse);
    });

    test('RESOLVED 상태', () {
      final thread = QnaThread(
        id: 3,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RESOLVED',
      );
      expect(thread.isReceived, isFalse);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isTrue);
      expect(thread.isOpen, isFalse);
      expect(thread.isClosed, isTrue);
    });

    test('소문자 상태도 인식', () {
      final thread = QnaThread(
        id: 4,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'received',
      );
      expect(thread.isReceived, isTrue);
    });

    test('혼합 대소문자 인식', () {
      final thread = QnaThread(
        id: 5,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'Resolved',
      );
      expect(thread.isResolved, isTrue);
      expect(thread.isClosed, isTrue);
    });

    test('알 수 없는 상태는 모두 false', () {
      final thread = QnaThread(
        id: 6,
        userId: 'u',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'UNKNOWN',
      );
      expect(thread.isReceived, isFalse);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isFalse);
      expect(thread.isOpen, isTrue); // not resolved → open
    });
  });
}
