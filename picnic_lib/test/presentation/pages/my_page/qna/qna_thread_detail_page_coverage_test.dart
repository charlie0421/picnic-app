import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';

/// Coverage tests for QnaThreadDetailPage pure logic functions
/// (shouldShowAutoCloseNotice, shouldShowDateDivider, isImageAttachment, isVideoAttachment)
/// and QnaThread model edge cases.
///
/// Widget render tests are excluded because QnaThreadDetailPage creates QnaRepository
/// internally using Supabase.instance.client which cannot be mocked via testSupabaseClient.
void main() {
  QnaMessage _buildMessage({
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

  QnaAttachment _buildAttachment({
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

  group('shouldShowAutoCloseNotice', () {
    test('returns false for RESOLVED status', () {
      expect(
        shouldShowAutoCloseNotice(
          threadStatus: 'RESOLVED',
          messages: [_buildMessage(isAdminMessage: true)],
        ),
        isFalse,
      );
    });

    test('returns false for empty messages', () {
      expect(
        shouldShowAutoCloseNotice(threadStatus: 'RECEIVED', messages: []),
        isFalse,
      );
    });

    test('returns true when latest message is admin (RECEIVED)', () {
      expect(
        shouldShowAutoCloseNotice(
          threadStatus: 'RECEIVED',
          messages: [
            _buildMessage(id: 1, createdAt: DateTime(2026, 3, 1), isAdminMessage: false),
            _buildMessage(id: 2, createdAt: DateTime(2026, 3, 2), isAdminMessage: true),
          ],
        ),
        isTrue,
      );
    });

    test('returns true when latest message is admin (IN_PROGRESS)', () {
      expect(
        shouldShowAutoCloseNotice(
          threadStatus: 'IN_PROGRESS',
          messages: [
            _buildMessage(id: 1, createdAt: DateTime(2026, 3, 1), isAdminMessage: false),
            _buildMessage(id: 2, createdAt: DateTime(2026, 3, 2), isAdminMessage: true),
          ],
        ),
        isTrue,
      );
    });

    test('returns false when latest message is user', () {
      expect(
        shouldShowAutoCloseNotice(
          threadStatus: 'IN_PROGRESS',
          messages: [
            _buildMessage(id: 1, createdAt: DateTime(2026, 3, 1), isAdminMessage: true),
            _buildMessage(id: 2, createdAt: DateTime(2026, 3, 2), isAdminMessage: false),
          ],
        ),
        isFalse,
      );
    });

    test('returns false for resolved even with admin latest message', () {
      expect(
        shouldShowAutoCloseNotice(
          threadStatus: 'resolved',
          messages: [_buildMessage(isAdminMessage: true)],
        ),
        isFalse,
      );
    });

    test('handles single admin message', () {
      expect(
        shouldShowAutoCloseNotice(
          threadStatus: 'RECEIVED',
          messages: [_buildMessage(isAdminMessage: true)],
        ),
        isTrue,
      );
    });

    test('handles single user message', () {
      expect(
        shouldShowAutoCloseNotice(
          threadStatus: 'RECEIVED',
          messages: [_buildMessage(isAdminMessage: false)],
        ),
        isFalse,
      );
    });

    test('picks latest by createdAt not by list order', () {
      // Admin message is second in list but has earlier date
      expect(
        shouldShowAutoCloseNotice(
          threadStatus: 'RECEIVED',
          messages: [
            _buildMessage(id: 2, createdAt: DateTime(2026, 3, 5), isAdminMessage: false),
            _buildMessage(id: 1, createdAt: DateTime(2026, 3, 1), isAdminMessage: true),
          ],
        ),
        isFalse,
      );
    });
  });

  group('shouldShowDateDivider', () {
    test('returns true for last item in reversed list', () {
      expect(
        shouldShowDateDivider(
          reversedMessages: [_buildMessage()],
          index: 0,
        ),
        isTrue,
      );
    });

    test('returns true when dates differ (day)', () {
      final messages = [
        _buildMessage(id: 2, createdAt: DateTime(2026, 3, 2, 14, 0)),
        _buildMessage(id: 1, createdAt: DateTime(2026, 3, 1, 10, 0)),
      ];
      expect(shouldShowDateDivider(reversedMessages: messages, index: 0), isTrue);
    });

    test('returns true when dates differ (month)', () {
      final messages = [
        _buildMessage(id: 2, createdAt: DateTime(2026, 4, 1)),
        _buildMessage(id: 1, createdAt: DateTime(2026, 3, 1)),
      ];
      expect(shouldShowDateDivider(reversedMessages: messages, index: 0), isTrue);
    });

    test('returns true when dates differ (year)', () {
      final messages = [
        _buildMessage(id: 2, createdAt: DateTime(2027, 1, 1)),
        _buildMessage(id: 1, createdAt: DateTime(2026, 12, 31)),
      ];
      expect(shouldShowDateDivider(reversedMessages: messages, index: 0), isTrue);
    });

    test('returns false when dates are same day', () {
      final messages = [
        _buildMessage(id: 2, createdAt: DateTime(2026, 3, 1, 14, 0)),
        _buildMessage(id: 1, createdAt: DateTime(2026, 3, 1, 10, 0)),
      ];
      expect(shouldShowDateDivider(reversedMessages: messages, index: 0), isFalse);
    });

    test('returns true for first item in multi-item list (last index)', () {
      final messages = [
        _buildMessage(id: 2, createdAt: DateTime(2026, 3, 2)),
        _buildMessage(id: 1, createdAt: DateTime(2026, 3, 1)),
      ];
      expect(shouldShowDateDivider(reversedMessages: messages, index: 1), isTrue);
    });
  });

  group('isImageAttachment', () {
    test('returns true for image/jpeg MIME', () {
      expect(isImageAttachment(_buildAttachment(fileType: 'image/jpeg')), isTrue);
    });

    test('returns true for image/png MIME', () {
      expect(isImageAttachment(_buildAttachment(fileType: 'image/png')), isTrue);
    });

    test('returns true for image/gif MIME', () {
      expect(isImageAttachment(_buildAttachment(fileType: 'image/gif')), isTrue);
    });

    test('returns true for .jpg extension without MIME', () {
      expect(
        isImageAttachment(_buildAttachment(fileName: 'photo.jpg', fileType: null)),
        isTrue,
      );
    });

    test('returns true for .jpeg extension', () {
      expect(
        isImageAttachment(_buildAttachment(fileName: 'photo.jpeg', fileType: null)),
        isTrue,
      );
    });

    test('returns true for .png extension', () {
      expect(
        isImageAttachment(_buildAttachment(fileName: 'photo.png', fileType: null)),
        isTrue,
      );
    });

    test('returns true for .gif extension', () {
      expect(
        isImageAttachment(_buildAttachment(fileName: 'anim.gif', fileType: null)),
        isTrue,
      );
    });

    test('returns true for .PNG (case insensitive extension)', () {
      expect(
        isImageAttachment(_buildAttachment(fileName: 'photo.PNG', fileType: null)),
        isTrue,
      );
    });

    test('returns false for application/pdf', () {
      expect(
        isImageAttachment(_buildAttachment(fileName: 'doc.pdf', fileType: 'application/pdf')),
        isFalse,
      );
    });

    test('returns false for video/mp4', () {
      expect(
        isImageAttachment(_buildAttachment(fileName: 'clip.mp4', fileType: 'video/mp4')),
        isFalse,
      );
    });

    test('returns false for null type and non-image extension', () {
      expect(
        isImageAttachment(_buildAttachment(fileName: 'doc.txt', fileType: null)),
        isFalse,
      );
    });
  });

  group('isVideoAttachment', () {
    test('returns true for video/mp4', () {
      expect(
        isVideoAttachment(_buildAttachment(fileName: 'clip.mp4', fileType: 'video/mp4')),
        isTrue,
      );
    });

    test('returns true for video/quicktime', () {
      expect(
        isVideoAttachment(_buildAttachment(fileName: 'clip.mov', fileType: 'video/quicktime')),
        isTrue,
      );
    });

    test('returns false for image/jpeg', () {
      expect(
        isVideoAttachment(_buildAttachment(fileType: 'image/jpeg')),
        isFalse,
      );
    });

    test('returns false for null fileType', () {
      expect(
        isVideoAttachment(_buildAttachment(fileName: 'unknown.bin', fileType: null)),
        isFalse,
      );
    });

    test('returns false for application/pdf', () {
      expect(
        isVideoAttachment(_buildAttachment(fileName: 'doc.pdf', fileType: 'application/pdf')),
        isFalse,
      );
    });
  });

  group('QnaThread status edge cases', () {
    test('lowercase status works with extensions', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u1',
        title: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'received',
      );
      expect(thread.isReceived, isTrue);
      expect(thread.isOpen, isTrue);
      expect(thread.isClosed, isFalse);
    });

    test('mixed case status works', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u1',
        title: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'In_Progress',
      );
      expect(thread.isInProgress, isTrue);
      expect(thread.isOpen, isTrue);
    });

    test('resolved thread is closed and not open', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u1',
        title: 'test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RESOLVED',
      );
      expect(thread.isResolved, isTrue);
      expect(thread.isClosed, isTrue);
      expect(thread.isOpen, isFalse);
    });
  });

  group('QnaThreadDetailPage constructor', () {
    test('can be constructed with required params', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u1',
        title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );
      final page = QnaThreadDetailPage(thread: thread);
      expect(page.thread, equals(thread));
      expect(page.syncNavigation, isTrue);
    });

    test('can be constructed with syncNavigation false', () {
      final thread = QnaThread(
        id: 1,
        userId: 'u1',
        title: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );
      final page = QnaThreadDetailPage(thread: thread, syncNavigation: false);
      expect(page.syncNavigation, isFalse);
    });
  });
}
