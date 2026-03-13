import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';

/// Tests for QnaThreadDetailPage production code.
///
/// Widget rendering is blocked by platform dependencies (dart:io File,
/// ImageThumbnailFromUrl, VideoThumbnailFromUrl, Supabase.instance).
/// We test all importable production models: QnaThread, QnaMessage,
/// QnaAttachment, their fromJson/toJson, extensions, and the widget constructor.
void main() {
  QnaThread buildThread({
    int id = 1,
    String status = 'RECEIVED',
    String title = 'Test Thread',
  }) {
    return QnaThread(
      id: id,
      userId: 'user-1',
      title: title,
      createdAt: DateTime(2026, 3, 1, 10, 0),
      updatedAt: DateTime(2026, 3, 1, 14, 0),
      status: status,
    );
  }

  QnaMessage buildMessage({
    int id = 1,
    int threadId = 1,
    String userId = 'user-1',
    String? content = 'Hello',
    DateTime? createdAt,
    bool isAdminMessage = false,
    List<QnaAttachment> attachments = const [],
  }) {
    return QnaMessage(
      id: id,
      threadId: threadId,
      userId: userId,
      content: content,
      createdAt: createdAt ?? DateTime(2026, 3, 1, 10, 0),
      isAdminMessage: isAdminMessage,
      attachments: attachments,
    );
  }

  QnaAttachment buildAttachment({
    int id = 1,
    int messageId = 1,
    String fileName = 'photo.jpg',
    String filePath = 'qna/1/photo.jpg',
    String? fileType = 'image/jpeg',
    int? fileSize = 1024,
  }) {
    return QnaAttachment(
      id: id,
      messageId: messageId,
      fileName: fileName,
      filePath: filePath,
      fileType: fileType,
      fileSize: fileSize,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  group('QnaThreadDetailPage widget', () {
    test('can be constructed with required parameters', () {
      final thread = buildThread();
      final page = QnaThreadDetailPage(thread: thread);
      expect(page, isA<QnaThreadDetailPage>());
      expect(page.thread, equals(thread));
    });
  });

  group('QnaThread model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 42,
        'user_id': 'user-abc',
        'title': 'My Question',
        'created_at': '2026-03-01T10:00:00.000',
        'updated_at': '2026-03-01T14:00:00.000',
        'status': 'RECEIVED',
      };
      final thread = QnaThread.fromJson(json);
      expect(thread.id, equals(42));
      expect(thread.userId, equals('user-abc'));
      expect(thread.title, equals('My Question'));
      expect(thread.status, equals('RECEIVED'));
    });

    test('toJson produces correct keys', () {
      final thread = buildThread();
      final json = thread.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('user_id'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
      expect(json.containsKey('updated_at'), isTrue);
      expect(json.containsKey('status'), isTrue);
    });

    test('fromJson -> toJson roundtrip preserves data', () {
      final original = buildThread(id: 99, title: 'Roundtrip Test');
      final json = original.toJson();
      final restored = QnaThread.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.userId, equals(original.userId));
      expect(restored.title, equals(original.title));
      expect(restored.status, equals(original.status));
    });

    test('copyWith changes status', () {
      final thread = buildThread(status: 'RECEIVED');
      final updated = thread.copyWith(status: 'RESOLVED');
      expect(updated.status, equals('RESOLVED'));
      expect(updated.id, equals(thread.id));
      expect(updated.title, equals(thread.title));
    });

    test('copyWith changes title', () {
      final thread = buildThread(title: 'Original');
      final updated = thread.copyWith(title: 'Updated');
      expect(updated.title, equals('Updated'));
      expect(updated.status, equals(thread.status));
    });

    test('copyWith preserves userId', () {
      final thread = buildThread();
      final updated = thread.copyWith(title: 'New');
      expect(updated.userId, equals(thread.userId));
    });
  });

  group('QnaThread status extensions', () {
    test('isReceived for RECEIVED status', () {
      final thread = buildThread(status: 'RECEIVED');
      expect(thread.isReceived, isTrue);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isFalse);
    });

    test('isInProgress for IN_PROGRESS status', () {
      final thread = buildThread(status: 'IN_PROGRESS');
      expect(thread.isReceived, isFalse);
      expect(thread.isInProgress, isTrue);
      expect(thread.isResolved, isFalse);
    });

    test('isResolved for RESOLVED status', () {
      final thread = buildThread(status: 'RESOLVED');
      expect(thread.isReceived, isFalse);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isTrue);
    });

    test('isOpen is true for non-resolved', () {
      expect(buildThread(status: 'RECEIVED').isOpen, isTrue);
      expect(buildThread(status: 'IN_PROGRESS').isOpen, isTrue);
      expect(buildThread(status: 'RESOLVED').isOpen, isFalse);
    });

    test('isClosed is true only for resolved', () {
      expect(buildThread(status: 'RECEIVED').isClosed, isFalse);
      expect(buildThread(status: 'IN_PROGRESS').isClosed, isFalse);
      expect(buildThread(status: 'RESOLVED').isClosed, isTrue);
    });

    test('status comparison is case-insensitive', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u1',
        title: 't',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'received',
      );
      expect(thread.isReceived, isTrue);
    });
  });

  group('QnaMessage model', () {
    test('fromJson parses message with attachments', () {
      final json = {
        'id': 10,
        'thread_id': 1,
        'user_id': 'user-1',
        'content': 'Test message',
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
      expect(message.id, equals(10));
      expect(message.content, equals('Test message'));
      expect(message.isAdminMessage, isFalse);
      expect(message.attachments.length, equals(1));
      expect(message.attachments.first.fileName, equals('photo.jpg'));
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
      expect(message.attachments, isEmpty);
    });

    test('toJson produces correct keys', () {
      final message = buildMessage();
      final json = message.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('thread_id'), isTrue);
      expect(json.containsKey('user_id'), isTrue);
      expect(json.containsKey('content'), isTrue);
      expect(json.containsKey('is_admin_message'), isTrue);
      expect(json.containsKey('qna_attachments'), isTrue);
    });

    test('message fields are accessible', () {
      final message = buildMessage(
        id: 5,
        threadId: 3,
        userId: 'user-2',
        content: 'Test',
        isAdminMessage: true,
      );
      expect(message.id, equals(5));
      expect(message.threadId, equals(3));
      expect(message.userId, equals('user-2'));
      expect(message.content, equals('Test'));
      expect(message.isAdminMessage, isTrue);
    });

    test('message with null content', () {
      final message = buildMessage(content: null);
      expect(message.content, isNull);
    });

    test('message with empty content', () {
      final message = buildMessage(content: '');
      expect(message.content, equals(''));
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
      expect(att.id, equals(5));
      expect(att.messageId, equals(10));
      expect(att.fileName, equals('document.pdf'));
      expect(att.filePath, equals('qna/1/document.pdf'));
      expect(att.fileType, equals('application/pdf'));
      expect(att.fileSize, equals(2048));
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

    test('toJson produces correct keys', () {
      final att = buildAttachment();
      final json = att.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('message_id'), isTrue);
      expect(json.containsKey('file_name'), isTrue);
      expect(json.containsKey('file_path'), isTrue);
      expect(json.containsKey('file_type'), isTrue);
      expect(json.containsKey('file_size'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
    });

    test('fromJson -> toJson roundtrip', () {
      final original = buildAttachment(id: 77, fileName: 'roundtrip.png');
      final json = original.toJson();
      final restored = QnaAttachment.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.fileName, equals(original.fileName));
      expect(restored.filePath, equals(original.filePath));
    });

    test('attachment with image MIME type', () {
      final att = buildAttachment(fileType: 'image/jpeg');
      expect(att.fileType?.startsWith('image/'), isTrue);
    });

    test('attachment with video MIME type', () {
      final att = buildAttachment(fileType: 'video/mp4');
      expect(att.fileType?.startsWith('video/'), isTrue);
    });

    test('attachment with null fileType', () {
      final att = buildAttachment(fileType: null);
      expect(att.fileType, isNull);
    });
  });

  group('QnaMessage with attachments integration', () {
    test('message with multiple attachments', () {
      final att1 = buildAttachment(id: 1, fileName: 'a.jpg');
      final att2 = buildAttachment(id: 2, fileName: 'b.png');
      final message = buildMessage(attachments: [att1, att2]);
      expect(message.attachments.length, equals(2));
      expect(message.attachments[0].fileName, equals('a.jpg'));
      expect(message.attachments[1].fileName, equals('b.png'));
    });

    test('message with no attachments', () {
      final message = buildMessage(attachments: []);
      expect(message.attachments, isEmpty);
    });

    test('admin message flag', () {
      final adminMsg = buildMessage(isAdminMessage: true);
      final userMsg = buildMessage(isAdminMessage: false);
      expect(adminMsg.isAdminMessage, isTrue);
      expect(userMsg.isAdminMessage, isFalse);
    });
  });

  group('QnaThread equality and construction', () {
    test('two threads with same data are equal (freezed)', () {
      final t1 = buildThread(id: 1, title: 'Test');
      final t2 = buildThread(id: 1, title: 'Test');
      expect(t1, equals(t2));
    });

    test('two threads with different id are not equal', () {
      final t1 = buildThread(id: 1);
      final t2 = buildThread(id: 2);
      expect(t1, isNot(equals(t2)));
    });

    test('thread hashCode is consistent', () {
      final t1 = buildThread(id: 1);
      final t2 = buildThread(id: 1);
      expect(t1.hashCode, equals(t2.hashCode));
    });
  });
}
