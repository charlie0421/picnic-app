import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';

void main() {
  group('QnaRepository', () {
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
        expect(result.categoryLabel, isNull);
      });

      test('categoryLabel을 포함하여 생성할 수 있다', () {
        final thread = QnaThread(
          id: 1,
          userId: 'user-123',
          title: '카테고리 포함 스레드',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'RECEIVED',
        );

        final result = QaThreadWithMessages(
          thread: thread,
          messages: [],
          categoryLabel: '결제 문의',
        );

        expect(result.categoryLabel, equals('결제 문의'));
      });

      test('빈 메시지 리스트로 생성할 수 있다', () {
        final thread = QnaThread(
          id: 2,
          userId: 'user-456',
          title: '빈 스레드',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'IN_PROGRESS',
        );

        final result = QaThreadWithMessages(
          thread: thread,
          messages: [],
        );

        expect(result.messages, isEmpty);
        expect(result.thread.status, equals('IN_PROGRESS'));
      });
    });
  });

  group('QnaThread 모델 파싱', () {
    test('유효한 JSON에서 QnaThread를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'user_id': 'user-123',
        'title': 'QnA 문의',
        'created_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-01T12:00:00.000Z',
        'status': 'RECEIVED',
      };

      final thread = QnaThread.fromJson(json);

      expect(thread.id, equals(1));
      expect(thread.userId, equals('user-123'));
      expect(thread.title, equals('QnA 문의'));
      expect(thread.status, equals('RECEIVED'));
    });

    test('fromJson -> toJson 라운드트립이 가능하다', () {
      final originalJson = {
        'id': 1,
        'user_id': 'user-123',
        'title': 'QnA 문의',
        'created_at': '2025-06-01T10:00:00.000Z',
        'updated_at': '2025-06-01T12:00:00.000Z',
        'status': 'RECEIVED',
      };

      final thread = QnaThread.fromJson(originalJson);
      final roundTripped = thread.toJson();

      expect(roundTripped['id'], equals(originalJson['id']));
      expect(roundTripped['user_id'], equals(originalJson['user_id']));
      expect(roundTripped['title'], equals(originalJson['title']));
      expect(roundTripped['status'], equals(originalJson['status']));
    });
  });

  group('QnaMessage 모델 파싱', () {
    test('유효한 JSON에서 QnaMessage를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '문의 내용입니다.',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [],
      };

      final message = QnaMessage.fromJson(json);

      expect(message.id, equals(1));
      expect(message.threadId, equals(10));
      expect(message.userId, equals('user-123'));
      expect(message.content, equals('문의 내용입니다.'));
      expect(message.isAdminMessage, isFalse);
      expect(message.attachments, isEmpty);
    });

    test('첨부파일이 포함된 메시지를 파싱할 수 있다', () {
      final json = {
        'id': 2,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '파일 첨부',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [
          {
            'id': 100,
            'message_id': 2,
            'file_name': 'image.jpg',
            'file_path': 'qna/user-123/2/image.jpg',
            'file_type': 'image/jpeg',
            'file_size': 2048,
            'created_at': '2025-06-01T10:00:00.000Z',
          },
          {
            'id': 101,
            'message_id': 2,
            'file_name': 'doc.pdf',
            'file_path': 'qna/user-123/2/doc.pdf',
            'file_type': 'application/pdf',
            'file_size': 4096,
            'created_at': '2025-06-01T10:01:00.000Z',
          },
        ],
      };

      final message = QnaMessage.fromJson(json);
      expect(message.attachments.length, equals(2));
      expect(message.attachments[0].fileName, equals('image.jpg'));
      expect(message.attachments[1].fileName, equals('doc.pdf'));
      expect(message.attachments[0].fileSize, equals(2048));
    });

    test('qna_attachments가 없는 JSON도 파싱할 수 있다 (기본값 빈 리스트)', () {
      final json = {
        'id': 3,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '첨부 없음',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
      };

      final message = QnaMessage.fromJson(json);
      expect(message.attachments, isEmpty);
    });

    test('관리자 메시지와 일반 메시지를 구분할 수 있다', () {
      final userJson = {
        'id': 1,
        'thread_id': 10,
        'user_id': 'user-123',
        'content': '질문',
        'created_at': '2025-06-01T10:00:00.000Z',
        'is_admin_message': false,
      };

      final adminJson = {
        'id': 2,
        'thread_id': 10,
        'user_id': 'admin-001',
        'content': '답변',
        'created_at': '2025-06-01T11:00:00.000Z',
        'is_admin_message': true,
      };

      final userMsg = QnaMessage.fromJson(userJson);
      final adminMsg = QnaMessage.fromJson(adminJson);

      expect(userMsg.isAdminMessage, isFalse);
      expect(adminMsg.isAdminMessage, isTrue);
    });

    test('toJson으로 변환 시 올바른 키 이름을 사용한다', () {
      final message = QnaMessage(
        id: 1,
        threadId: 10,
        userId: 'user-123',
        content: '테스트',
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
        isAdminMessage: false,
      );

      final json = message.toJson();
      expect(json.containsKey('thread_id'), isTrue);
      expect(json.containsKey('user_id'), isTrue);
      expect(json.containsKey('is_admin_message'), isTrue);
      expect(json.containsKey('qna_attachments'), isTrue);
    });
  });

  group('QnaAttachment 모델 파싱', () {
    test('유효한 JSON에서 QnaAttachment를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'message_id': 10,
        'file_name': 'screenshot.png',
        'file_path': 'qna/user-123/10/screenshot.png',
        'file_type': 'image/png',
        'file_size': 1024,
        'created_at': '2025-06-01T10:00:00.000Z',
      };

      final attachment = QnaAttachment.fromJson(json);

      expect(attachment.id, equals(1));
      expect(attachment.messageId, equals(10));
      expect(attachment.fileName, equals('screenshot.png'));
      expect(attachment.filePath, equals('qna/user-123/10/screenshot.png'));
      expect(attachment.fileType, equals('image/png'));
      expect(attachment.fileSize, equals(1024));
    });

    test('선택 필드(fileType, fileSize)가 null인 경우를 처리할 수 있다', () {
      final json = {
        'id': 2,
        'message_id': 10,
        'file_name': 'unknown_file',
        'file_path': 'qna/user-123/10/unknown_file',
        'file_type': null,
        'file_size': null,
        'created_at': '2025-06-01T10:00:00.000Z',
      };

      final attachment = QnaAttachment.fromJson(json);
      expect(attachment.fileType, isNull);
      expect(attachment.fileSize, isNull);
    });

    test('toJson으로 JSON 변환이 가능하다', () {
      final attachment = QnaAttachment(
        id: 1,
        messageId: 10,
        fileName: 'test.png',
        filePath: 'qna/test/10/test.png',
        fileType: 'image/png',
        fileSize: 512,
        createdAt: DateTime.parse('2025-06-01T10:00:00.000Z'),
      );

      final json = attachment.toJson();
      expect(json['id'], equals(1));
      expect(json['message_id'], equals(10));
      expect(json['file_name'], equals('test.png'));
      expect(json['file_path'], equals('qna/test/10/test.png'));
    });

    test('동일한 값을 가진 두 QnaAttachment는 같다', () {
      final dateTime = DateTime.parse('2025-06-01T10:00:00.000Z');
      final att1 = QnaAttachment(
        id: 1,
        messageId: 10,
        fileName: 'file.png',
        filePath: 'path/file.png',
        createdAt: dateTime,
      );
      final att2 = QnaAttachment(
        id: 1,
        messageId: 10,
        fileName: 'file.png',
        filePath: 'path/file.png',
        createdAt: dateTime,
      );
      expect(att1, equals(att2));
    });

    test('copyWith으로 특정 필드를 변경할 수 있다', () {
      final attachment = QnaAttachment(
        id: 1,
        messageId: 10,
        fileName: 'original.png',
        filePath: 'path/original.png',
        createdAt: DateTime.now(),
      );

      final modified = attachment.copyWith(fileName: 'modified.png');
      expect(modified.fileName, equals('modified.png'));
      expect(modified.id, equals(1));
      expect(modified.messageId, equals(10));
    });
  });
}
