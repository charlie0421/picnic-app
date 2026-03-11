import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';

void main() {
  group('QnaCategory', () {
    test('생성 및 필드 접근', () {
      final category = QnaCategory(
        code: 'account',
        label: '계정 문의',
        questionTemplate: '질문 템플릿',
        answerTemplate: '답변 템플릿',
      );
      expect(category.code, equals('account'));
      expect(category.label, equals('계정 문의'));
      expect(category.questionTemplate, equals('질문 템플릿'));
      expect(category.answerTemplate, equals('답변 템플릿'));
    });

    test('optional 필드 null', () {
      final category = QnaCategory(
        code: 'bug',
        label: '버그 신고',
      );
      expect(category.questionTemplate, isNull);
      expect(category.answerTemplate, isNull);
    });
  });

  group('QnaThread fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'user_id': 'user-1',
        'title': '문의 제목',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-02T00:00:00.000Z',
        'status': 'RECEIVED',
      };
      final thread = QnaThread.fromJson(json);
      expect(thread.id, equals(1));
      expect(thread.userId, equals('user-1'));
      expect(thread.title, equals('문의 제목'));
      expect(thread.status, equals('RECEIVED'));

      final output = thread.toJson();
      expect(output['user_id'], equals('user-1'));
    });
  });

  group('QnaThreadStatusX extension', () {
    test('isReceived', () {
      final thread = QnaThread.fromJson({
        'id': 1,
        'user_id': 'u',
        'title': 't',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'status': 'RECEIVED',
      });
      expect(thread.isReceived, isTrue);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isFalse);
      expect(thread.isOpen, isTrue);
      expect(thread.isClosed, isFalse);
    });

    test('isInProgress', () {
      final thread = QnaThread.fromJson({
        'id': 2,
        'user_id': 'u',
        'title': 't',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'status': 'IN_PROGRESS',
      });
      expect(thread.isInProgress, isTrue);
      expect(thread.isOpen, isTrue);
      expect(thread.isClosed, isFalse);
    });

    test('isResolved', () {
      final thread = QnaThread.fromJson({
        'id': 3,
        'user_id': 'u',
        'title': 't',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'status': 'RESOLVED',
      });
      expect(thread.isResolved, isTrue);
      expect(thread.isOpen, isFalse);
      expect(thread.isClosed, isTrue);
    });

    test('case insensitive', () {
      final thread = QnaThread.fromJson({
        'id': 4,
        'user_id': 'u',
        'title': 't',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'status': 'received',
      });
      expect(thread.isReceived, isTrue);
    });
  });

  group('QnaAttachment fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'message_id': 10,
        'file_name': 'screenshot.png',
        'file_path': '/uploads/screenshot.png',
        'file_type': 'image/png',
        'file_size': 1024,
        'created_at': '2025-01-01T00:00:00.000Z',
      };
      final attachment = QnaAttachment.fromJson(json);
      expect(attachment.id, equals(1));
      expect(attachment.messageId, equals(10));
      expect(attachment.fileName, equals('screenshot.png'));
      expect(attachment.filePath, equals('/uploads/screenshot.png'));
      expect(attachment.fileType, equals('image/png'));
      expect(attachment.fileSize, equals(1024));

      final output = attachment.toJson();
      expect(output['message_id'], equals(10));
      expect(output['file_name'], equals('screenshot.png'));
    });

    test('optional 필드 null', () {
      final json = {
        'id': 2,
        'message_id': 11,
        'file_name': 'doc.pdf',
        'file_path': '/uploads/doc.pdf',
        'created_at': '2025-01-01T00:00:00.000Z',
      };
      final attachment = QnaAttachment.fromJson(json);
      expect(attachment.fileType, isNull);
      expect(attachment.fileSize, isNull);
    });
  });

  group('QnaMessage fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'thread_id': 10,
        'user_id': 'user-1',
        'content': '문의 내용입니다.',
        'created_at': '2025-01-01T00:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': <Map<String, dynamic>>[],
      };
      final message = QnaMessage.fromJson(json);
      expect(message.id, equals(1));
      expect(message.threadId, equals(10));
      expect(message.userId, equals('user-1'));
      expect(message.content, equals('문의 내용입니다.'));
      expect(message.isAdminMessage, isFalse);
      expect(message.attachments, isEmpty);

      final output = message.toJson();
      expect(output['thread_id'], equals(10));
      expect(output['is_admin_message'], isFalse);
    });

    test('admin 메시지 with attachment', () {
      final json = {
        'id': 2,
        'thread_id': 10,
        'user_id': 'admin-1',
        'content': '답변입니다.',
        'created_at': '2025-01-02T00:00:00.000Z',
        'is_admin_message': true,
        'qna_attachments': [
          {
            'id': 1,
            'message_id': 2,
            'file_name': 'guide.pdf',
            'file_path': '/uploads/guide.pdf',
            'created_at': '2025-01-02T00:00:00.000Z',
          },
        ],
      };
      final message = QnaMessage.fromJson(json);
      expect(message.isAdminMessage, isTrue);
      expect(message.attachments.length, equals(1));
      expect(message.attachments[0].fileName, equals('guide.pdf'));
    });

    test('content null', () {
      final json = {
        'id': 3,
        'thread_id': 10,
        'user_id': 'user-1',
        'content': null,
        'created_at': '2025-01-01T00:00:00.000Z',
        'is_admin_message': false,
      };
      final message = QnaMessage.fromJson(json);
      expect(message.content, isNull);
      expect(message.attachments, isEmpty);
    });
  });
}
