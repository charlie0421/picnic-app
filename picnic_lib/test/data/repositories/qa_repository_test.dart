import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qa_repository.dart';

void main() {
  group('QaRepository', () {
    group('QaThreadWithMessages 헬퍼 클래스', () {
      test('필수 파라미터로 객체를 생성할 수 있다', () {
        final thread = QnaThread(
          id: 1,
          userId: 'user-123',
          title: '테스트 스레드',
          createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
          updatedAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
          status: 'RECEIVED',
        );

        final messages = <QnaMessage>[
          QnaMessage(
            id: 1,
            threadId: 1,
            userId: 'user-123',
            content: '테스트 메시지',
            createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
            isAdminMessage: false,
          ),
        ];

        final result = QaThreadWithMessages(
          thread: thread,
          messages: messages,
        );

        expect(result.thread, equals(thread));
        expect(result.messages, equals(messages));
        expect(result.messages.length, equals(1));
      });

      test('빈 메시지 리스트로 생성할 수 있다', () {
        final thread = QnaThread(
          id: 2,
          userId: 'user-456',
          title: '빈 스레드',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'RECEIVED',
        );

        final result = QaThreadWithMessages(
          thread: thread,
          messages: [],
        );

        expect(result.messages, isEmpty);
      });
    });
  });

  group('QnaThread 모델 파싱', () {
    test('유효한 JSON에서 QnaThread를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'user_id': 'user-123',
        'title': '문의 제목',
        'created_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-01T12:00:00.000Z',
        'status': 'RECEIVED',
      };

      final thread = QnaThread.fromJson(json);

      expect(thread.id, equals(1));
      expect(thread.userId, equals('user-123'));
      expect(thread.title, equals('문의 제목'));
      expect(thread.status, equals('RECEIVED'));
      expect(thread.createdAt,
          equals(DateTime.parse('2025-06-01T10:00:00.000Z')));
    });

    test('toJson으로 다시 JSON 변환이 가능하다', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '문의',
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-06-01T12:00:00.000Z'),
        status: 'IN_PROGRESS',
      );

      final json = thread.toJson();
      expect(json['id'], equals(1));
      expect(json['user_id'], equals('user-123'));
      expect(json['status'], equals('IN_PROGRESS'));
    });

    test('copyWith으로 상태를 변경할 수 있다', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '원래 제목',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );

      final modified = thread.copyWith(status: 'RESOLVED');
      expect(modified.status, equals('RESOLVED'));
      expect(modified.title, equals('원래 제목'));
    });

    test('동일한 값을 가진 두 QnaThread는 같다', () {
      final dateTime = DateTime.parse('2025-06-01T10:00:00.000Z');
      final thread1 = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '동일',
        createdAt: dateTime,
        updatedAt: dateTime,
        status: 'RECEIVED',
      );
      final thread2 = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '동일',
        createdAt: dateTime,
        updatedAt: dateTime,
        status: 'RECEIVED',
      );
      expect(thread1, equals(thread2));
    });
  });

  group('QnaThread 상태 확장 메서드', () {
    late QnaThread receivedThread;
    late QnaThread inProgressThread;
    late QnaThread resolvedThread;

    setUp(() {
      final now = DateTime.now();
      receivedThread = QnaThread(
        id: 1,
        userId: 'user-123',
        title: '접수됨',
        createdAt: now,
        updatedAt: now,
        status: 'RECEIVED',
      );
      inProgressThread = receivedThread.copyWith(status: 'IN_PROGRESS');
      resolvedThread = receivedThread.copyWith(status: 'RESOLVED');
    });

    test('RECEIVED 상태일 때 isReceived가 true이다', () {
      expect(receivedThread.isReceived, isTrue);
      expect(receivedThread.isInProgress, isFalse);
      expect(receivedThread.isResolved, isFalse);
    });

    test('IN_PROGRESS 상태일 때 isInProgress가 true이다', () {
      expect(inProgressThread.isReceived, isFalse);
      expect(inProgressThread.isInProgress, isTrue);
      expect(inProgressThread.isResolved, isFalse);
    });

    test('RESOLVED 상태일 때 isResolved가 true이다', () {
      expect(resolvedThread.isReceived, isFalse);
      expect(resolvedThread.isInProgress, isFalse);
      expect(resolvedThread.isResolved, isTrue);
    });

    test('RECEIVED/IN_PROGRESS 상태는 isOpen이 true이다', () {
      expect(receivedThread.isOpen, isTrue);
      expect(inProgressThread.isOpen, isTrue);
    });

    test('RESOLVED 상태는 isClosed가 true이다', () {
      expect(resolvedThread.isClosed, isTrue);
      expect(resolvedThread.isOpen, isFalse);
    });
  });

  group('QnaMessage 모델 파싱', () {
    test('유효한 JSON에서 QnaMessage를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '안녕하세요, 문의드립니다.',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [],
      };

      final message = QnaMessage.fromJson(json);

      expect(message.id, equals(1));
      expect(message.threadId, equals(10));
      expect(message.userId, equals('user-123'));
      expect(message.content, equals('안녕하세요, 문의드립니다.'));
      expect(message.isAdminMessage, isFalse);
      expect(message.attachments, isEmpty);
    });

    test('첨부파일이 포함된 JSON을 파싱할 수 있다', () {
      final json = {
        'id': 2,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '첨부파일 포함 메시지',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [
          {
            'id': 1,
            'message_id': 2,
            'file_name': 'screenshot.png',
            'file_path': 'qna/user-123/2/screenshot.png',
            'file_type': 'image/png',
            'file_size': 1024,
            'created_at': '2025-06-01T10:00:00.000Z',
          },
        ],
      };

      final message = QnaMessage.fromJson(json);
      expect(message.attachments.length, equals(1));
      expect(message.attachments[0].fileName, equals('screenshot.png'));
      expect(message.attachments[0].fileType, equals('image/png'));
    });

    test('관리자 메시지를 파싱할 수 있다', () {
      final json = {
        'id': 3,
        'thread_id': 10,
        'user_id': 'admin-001',
        'content': '답변드립니다.',
        'created_at': '2025-06-01T11:00:00.000Z',
        'is_admin_message': true,
        'qna_attachments': [],
      };

      final message = QnaMessage.fromJson(json);
      expect(message.isAdminMessage, isTrue);
    });

    test('content가 null인 메시지를 파싱할 수 있다', () {
      final json = {
        'id': 4,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': null,
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
      };

      final message = QnaMessage.fromJson(json);
      expect(message.content, isNull);
    });

    test('toJson으로 JSON 변환이 가능하다', () {
      final message = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '테스트',
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
        isAdminMessage: false,
      );

      final json = message.toJson();
      expect(json['id'], equals(1));
      expect(json['thread_id'], equals(10));
      expect(json['user_id'], equals('user-123'));
      expect(json['is_admin_message'], isFalse);
    });
  });
}
