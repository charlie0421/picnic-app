import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';

/// Tests for QnaThreadListPage production code.
///
/// Widget rendering is blocked by platform dependencies (shimmer,
/// ImageThumbnailFromUrl, VideoThumbnailFromUrl, cached_network_image).
/// We test all importable production models: QnaThread (fromJson, toJson,
/// extensions, copyWith), QnaMessage, QnaAttachment.
void main() {
  QnaThread buildThread({
    int id = 1,
    String status = 'RECEIVED',
    DateTime? createdAt,
    DateTime? updatedAt,
    String title = 'Test Thread',
  }) {
    return QnaThread(
      id: id,
      userId: 'user-1',
      title: title,
      createdAt: createdAt ?? DateTime(2026, 3, 1, 10, 30),
      updatedAt: updatedAt ?? DateTime(2026, 3, 1, 14, 30),
      status: status,
    );
  }

  group('QnaThread model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 42,
        'user_id': 'user-abc',
        'title': 'Question',
        'created_at': '2026-03-01T10:00:00.000',
        'updated_at': '2026-03-01T14:00:00.000',
        'status': 'RECEIVED',
      };
      final thread = QnaThread.fromJson(json);
      expect(thread.id, 42);
      expect(thread.userId, 'user-abc');
      expect(thread.title, 'Question');
      expect(thread.status, 'RECEIVED');
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

    test('fromJson -> toJson roundtrip', () {
      final original = buildThread(id: 99, title: 'Roundtrip');
      final json = original.toJson();
      final restored = QnaThread.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.title, original.title);
      expect(restored.status, original.status);
    });
  });

  group('QnaThread status extensions', () {
    test('isReceived for RECEIVED', () {
      final thread = buildThread(status: 'RECEIVED');
      expect(thread.isReceived, isTrue);
      expect(thread.isInProgress, isFalse);
      expect(thread.isResolved, isFalse);
    });

    test('isInProgress for IN_PROGRESS', () {
      final thread = buildThread(status: 'IN_PROGRESS');
      expect(thread.isReceived, isFalse);
      expect(thread.isInProgress, isTrue);
      expect(thread.isResolved, isFalse);
    });

    test('isResolved for RESOLVED', () {
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

    test('case-insensitive status check', () {
      final thread = QnaThread(
        id: 1, userId: 'u', title: 't',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        status: 'received',
      );
      expect(thread.isReceived, isTrue);
    });
  });

  group('QnaThread copyWith', () {
    test('changes status', () {
      final thread = buildThread(status: 'RECEIVED');
      final updated = thread.copyWith(status: 'RESOLVED');
      expect(updated.status, 'RESOLVED');
      expect(updated.id, thread.id);
      expect(updated.title, thread.title);
    });

    test('changes title', () {
      final thread = buildThread(title: 'Original');
      final updated = thread.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.status, thread.status);
    });

    test('preserves userId', () {
      final thread = buildThread();
      final updated = thread.copyWith(title: 'New');
      expect(updated.userId, thread.userId);
    });
  });

  group('QnaThread date formatting', () {
    test('formats updatedAt in yyyy-MM-dd HH:mm', () {
      final thread = buildThread(
        updatedAt: DateTime(2026, 3, 11, 14, 30),
      );
      final formatted = DateFormat('yyyy-MM-dd HH:mm')
          .format(thread.updatedAt.toLocal());
      expect(formatted, contains('2026-03-11'));
    });

    test('formats createdAt', () {
      final thread = buildThread(
        createdAt: DateTime(2026, 1, 5, 9, 5),
      );
      final formatted = DateFormat('yyyy-MM-dd HH:mm')
          .format(thread.createdAt.toLocal());
      expect(formatted, equals('2026-01-05 09:05'));
    });
  });

  group('QnaThread equality (freezed)', () {
    test('two threads with same data are equal', () {
      final t1 = buildThread(id: 1, title: 'Test');
      final t2 = buildThread(id: 1, title: 'Test');
      expect(t1, equals(t2));
    });

    test('two threads with different id are not equal', () {
      final t1 = buildThread(id: 1);
      final t2 = buildThread(id: 2);
      expect(t1, isNot(equals(t2)));
    });
  });

  group('QnaMessage model', () {
    test('fromJson with attachments', () {
      final json = {
        'id': 10,
        'thread_id': 1,
        'user_id': 'user-1',
        'content': 'Test',
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

    test('toJson', () {
      final message = QnaMessage(
        id: 1, threadId: 1, userId: 'u',
        content: 'test', createdAt: DateTime.now(),
        isAdminMessage: false,
      );
      final json = message.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('content'), isTrue);
    });
  });

  group('QnaAttachment model', () {
    test('fromJson', () {
      final json = {
        'id': 5,
        'message_id': 10,
        'file_name': 'doc.pdf',
        'file_path': 'qna/1/doc.pdf',
        'file_type': 'application/pdf',
        'file_size': 2048,
        'created_at': '2026-03-01T00:00:00.000',
      };
      final att = QnaAttachment.fromJson(json);
      expect(att.id, 5);
      expect(att.fileName, 'doc.pdf');
    });

    test('image MIME detection', () {
      final att = QnaAttachment(
        id: 1, messageId: 1, fileName: 'a.jpg', filePath: 'p',
        fileType: 'image/jpeg', createdAt: DateTime.now(),
      );
      expect(att.fileType?.startsWith('image/'), isTrue);
    });

    test('video MIME detection', () {
      final att = QnaAttachment(
        id: 1, messageId: 1, fileName: 'a.mp4', filePath: 'p',
        fileType: 'video/mp4', createdAt: DateTime.now(),
      );
      expect(att.fileType?.startsWith('video/'), isTrue);
    });

    test('null fileType', () {
      final att = QnaAttachment(
        id: 1, messageId: 1, fileName: 'a.bin', filePath: 'p',
        fileType: null, createdAt: DateTime.now(),
      );
      expect(att.fileType, isNull);
    });
  });
}
