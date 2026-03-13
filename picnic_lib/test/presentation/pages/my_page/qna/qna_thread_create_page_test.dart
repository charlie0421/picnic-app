import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';

/// Tests for QnaThreadCreatePage production code.
///
/// Widget rendering is blocked by platform dependencies (dart:io File,
/// ImageThumbnailFromFile, VideoThumbnailFromFile).
/// We test all importable production models: QnaCategory, QnaThread,
/// QnaMessage, QnaAttachment.
void main() {
  group('QnaCategory model', () {
    test('constructor with required fields', () {
      final category = QnaCategory(code: 'general', label: '일반 문의');
      expect(category.code, 'general');
      expect(category.label, '일반 문의');
      expect(category.questionTemplate, isNull);
      expect(category.answerTemplate, isNull);
    });

    test('constructor with all fields', () {
      final category = QnaCategory(
        code: 'payment',
        label: '결제 문의',
        questionTemplate: '주문번호:\n문제 내용:',
        answerTemplate: '답변 템플릿',
      );
      expect(category.code, 'payment');
      expect(category.label, '결제 문의');
      expect(category.questionTemplate, contains('주문번호'));
      expect(category.answerTemplate, '답변 템플릿');
    });

    test('empty code category', () {
      final category = QnaCategory(code: '', label: '카테고리 선택');
      expect(category.code.isEmpty, isTrue);
    });

    test('category code isEmpty check for selection', () {
      final selected = QnaCategory(code: 'account', label: '계정 문의');
      final unselected = QnaCategory(code: '', label: '선택하세요');
      expect(selected.code.isNotEmpty, isTrue);
      expect(unselected.code.isNotEmpty, isFalse);
    });

    test('questionTemplate is null when not provided', () {
      final category = QnaCategory(code: 'general', label: '일반');
      expect(category.questionTemplate, isNull);
    });

    test('answerTemplate is null when not provided', () {
      final category = QnaCategory(code: 'general', label: '일반');
      expect(category.answerTemplate, isNull);
    });

    test('finding category by code in list', () {
      final categories = [
        QnaCategory(code: 'general', label: '일반 문의'),
        QnaCategory(code: 'account', label: '계정 문의'),
        QnaCategory(code: 'payment', label: '결제 문의'),
      ];

      final found = categories.firstWhere(
        (c) => c.code == 'account',
        orElse: () => categories.first,
      );
      expect(found.code, equals('account'));
      expect(found.label, equals('계정 문의'));
    });

    test('unfound code falls back to first category', () {
      final categories = [
        QnaCategory(code: 'general', label: '일반 문의'),
      ];

      final found = categories.firstWhere(
        (c) => c.code == 'nonexistent',
        orElse: () => categories.first,
      );
      expect(found.code, equals('general'));
    });
  });

  group('QnaThread model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'user_id': 'user-1',
        'title': 'Test',
        'created_at': '2026-03-01T10:00:00.000',
        'updated_at': '2026-03-01T14:00:00.000',
        'status': 'RECEIVED',
      };
      final thread = QnaThread.fromJson(json);
      expect(thread.id, 1);
      expect(thread.userId, 'user-1');
      expect(thread.title, 'Test');
      expect(thread.status, 'RECEIVED');
    });

    test('toJson roundtrip', () {
      final original = QnaThread(
        id: 1,
        userId: 'u',
        title: 't',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        status: 'IN_PROGRESS',
      );
      final json = original.toJson();
      final restored = QnaThread.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.status, original.status);
    });

    test('isReceived extension', () {
      final thread = QnaThread(
        id: 1, userId: 'u', title: 't',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );
      expect(thread.isReceived, isTrue);
      expect(thread.isOpen, isTrue);
    });

    test('isResolved extension', () {
      final thread = QnaThread(
        id: 1, userId: 'u', title: 't',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        status: 'RESOLVED',
      );
      expect(thread.isResolved, isTrue);
      expect(thread.isClosed, isTrue);
    });

    test('copyWith', () {
      final thread = QnaThread(
        id: 1, userId: 'u', title: 'Original',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );
      final updated = thread.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.id, 1);
    });
  });

  group('QnaMessage model', () {
    test('fromJson with attachments', () {
      final json = {
        'id': 10,
        'thread_id': 1,
        'user_id': 'user-1',
        'content': 'Hello',
        'created_at': '2026-03-01T10:00:00.000',
        'is_admin_message': false,
        'qna_attachments': [
          {
            'id': 1,
            'message_id': 10,
            'file_name': 'photo.jpg',
            'file_path': 'qna/1/photo.jpg',
            'file_type': 'image/jpeg',
            'file_size': 1024,
            'created_at': '2026-03-01T00:00:00.000',
          }
        ],
      };
      final message = QnaMessage.fromJson(json);
      expect(message.id, 10);
      expect(message.attachments.length, 1);
    });

    test('fromJson with null content', () {
      final json = {
        'id': 11,
        'thread_id': 1,
        'user_id': 'user-1',
        'content': null,
        'created_at': '2026-03-01T10:00:00.000',
        'is_admin_message': true,
      };
      final message = QnaMessage.fromJson(json);
      expect(message.content, isNull);
      expect(message.isAdminMessage, isTrue);
    });

    test('toJson produces correct keys', () {
      final message = QnaMessage(
        id: 1, threadId: 1, userId: 'u',
        content: 'test', createdAt: DateTime.now(),
        isAdminMessage: false,
      );
      final json = message.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('thread_id'), isTrue);
      expect(json.containsKey('content'), isTrue);
    });
  });

  group('QnaAttachment model', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 5,
        'message_id': 10,
        'file_name': 'document.pdf',
        'file_path': 'qna/1/document.pdf',
        'file_type': 'application/pdf',
        'file_size': 2048,
        'created_at': '2026-03-01T00:00:00.000',
      };
      final att = QnaAttachment.fromJson(json);
      expect(att.id, 5);
      expect(att.fileName, 'document.pdf');
      expect(att.fileType, 'application/pdf');
      expect(att.fileSize, 2048);
    });

    test('fromJson with null optional fields', () {
      final json = {
        'id': 6,
        'message_id': 10,
        'file_name': 'unknown.bin',
        'file_path': 'qna/1/unknown.bin',
        'file_type': null,
        'file_size': null,
        'created_at': '2026-03-01T00:00:00.000',
      };
      final att = QnaAttachment.fromJson(json);
      expect(att.fileType, isNull);
      expect(att.fileSize, isNull);
    });

    test('toJson roundtrip', () {
      final original = QnaAttachment(
        id: 77,
        messageId: 1,
        fileName: 'roundtrip.png',
        filePath: 'qna/1/roundtrip.png',
        fileType: 'image/png',
        fileSize: 512,
        createdAt: DateTime(2026, 3, 1),
      );
      final json = original.toJson();
      final restored = QnaAttachment.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.fileName, original.fileName);
      expect(restored.fileType, original.fileType);
    });

    test('image MIME type detection', () {
      final att = QnaAttachment(
        id: 1, messageId: 1, fileName: 'a.jpg', filePath: 'p',
        fileType: 'image/jpeg', createdAt: DateTime.now(),
      );
      expect(att.fileType?.startsWith('image/'), isTrue);
    });

    test('video MIME type detection', () {
      final att = QnaAttachment(
        id: 1, messageId: 1, fileName: 'a.mp4', filePath: 'p',
        fileType: 'video/mp4', createdAt: DateTime.now(),
      );
      expect(att.fileType?.startsWith('video/'), isTrue);
    });
  });
}
