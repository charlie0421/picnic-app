import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';

void main() {
  QnaMessage _createMessage({
    required DateTime createdAt,
    bool isAdminMessage = false,
    String userId = 'user1',
  }) {
    return QnaMessage(
      id: 1,
      threadId: 1,
      userId: userId,
      content: 'test',
      createdAt: createdAt,
      isAdminMessage: isAdminMessage,
    );
  }

  group('shouldShowAutoCloseNotice', () {
    test('returns false for resolved thread', () {
      final result = shouldShowAutoCloseNotice(
        threadStatus: 'RESOLVED',
        messages: [
          _createMessage(
            createdAt: DateTime(2024, 1, 1),
            isAdminMessage: true,
          ),
        ],
      );
      expect(result, isFalse);
    });

    test('returns false for empty messages', () {
      final result = shouldShowAutoCloseNotice(
        threadStatus: 'IN_PROGRESS',
        messages: [],
      );
      expect(result, isFalse);
    });

    test('returns true when latest message is admin message and not resolved',
        () {
      final result = shouldShowAutoCloseNotice(
        threadStatus: 'IN_PROGRESS',
        messages: [
          _createMessage(
            createdAt: DateTime(2024, 1, 1),
            isAdminMessage: false,
          ),
          _createMessage(
            createdAt: DateTime(2024, 1, 2),
            isAdminMessage: true,
          ),
        ],
      );
      expect(result, isTrue);
    });

    test(
        'returns false when latest message is user message and not resolved',
        () {
      final result = shouldShowAutoCloseNotice(
        threadStatus: 'IN_PROGRESS',
        messages: [
          _createMessage(
            createdAt: DateTime(2024, 1, 1),
            isAdminMessage: true,
          ),
          _createMessage(
            createdAt: DateTime(2024, 1, 2),
            isAdminMessage: false,
          ),
        ],
      );
      expect(result, isFalse);
    });

    test('returns true for RECEIVED status with admin last message', () {
      final result = shouldShowAutoCloseNotice(
        threadStatus: 'RECEIVED',
        messages: [
          _createMessage(
            createdAt: DateTime(2024, 1, 1),
            isAdminMessage: true,
          ),
        ],
      );
      expect(result, isTrue);
    });

    test('handles case-insensitive resolved status', () {
      final result = shouldShowAutoCloseNotice(
        threadStatus: 'resolved',
        messages: [
          _createMessage(
            createdAt: DateTime(2024, 1, 1),
            isAdminMessage: true,
          ),
        ],
      );
      expect(result, isFalse);
    });
  });

  group('shouldShowDateDivider', () {
    test('returns true for the last item (first chronologically)', () {
      final messages = [
        _createMessage(createdAt: DateTime(2024, 1, 2)),
        _createMessage(createdAt: DateTime(2024, 1, 1)),
      ];
      final result = shouldShowDateDivider(
        reversedMessages: messages,
        index: 1,
      );
      expect(result, isTrue);
    });

    test('returns true when dates differ between adjacent messages', () {
      final messages = [
        _createMessage(createdAt: DateTime(2024, 1, 2, 10)),
        _createMessage(createdAt: DateTime(2024, 1, 1, 15)),
      ];
      final result = shouldShowDateDivider(
        reversedMessages: messages,
        index: 0,
      );
      expect(result, isTrue);
    });

    test('returns false when dates are the same', () {
      final messages = [
        _createMessage(createdAt: DateTime(2024, 1, 1, 15)),
        _createMessage(createdAt: DateTime(2024, 1, 1, 10)),
      ];
      final result = shouldShowDateDivider(
        reversedMessages: messages,
        index: 0,
      );
      expect(result, isFalse);
    });

    test('detects month boundary', () {
      final messages = [
        _createMessage(createdAt: DateTime(2024, 2, 1)),
        _createMessage(createdAt: DateTime(2024, 1, 31)),
      ];
      final result = shouldShowDateDivider(
        reversedMessages: messages,
        index: 0,
      );
      expect(result, isTrue);
    });

    test('detects year boundary', () {
      final messages = [
        _createMessage(createdAt: DateTime(2025, 1, 1)),
        _createMessage(createdAt: DateTime(2024, 12, 31)),
      ];
      final result = shouldShowDateDivider(
        reversedMessages: messages,
        index: 0,
      );
      expect(result, isTrue);
    });
  });

  group('isImageAttachment', () {
    test('returns true for image MIME type', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'photo.txt',
        filePath: '/path/photo.txt',
        fileType: 'image/jpeg',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isImageAttachment(att), isTrue);
    });

    test('returns true for image extension even without MIME type', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'photo.jpg',
        filePath: '/path/photo.jpg',
        fileType: null,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isImageAttachment(att), isTrue);
    });

    test('returns true for .png extension', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'photo.png',
        filePath: '/path/photo.png',
        fileType: null,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isImageAttachment(att), isTrue);
    });

    test('returns true for .gif extension', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'animation.gif',
        filePath: '/path/animation.gif',
        fileType: null,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isImageAttachment(att), isTrue);
    });

    test('returns true for .jpeg extension', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'photo.jpeg',
        filePath: '/path/photo.jpeg',
        fileType: null,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isImageAttachment(att), isTrue);
    });

    test('returns false for video MIME type', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'video.mp4',
        filePath: '/path/video.mp4',
        fileType: 'video/mp4',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isImageAttachment(att), isFalse);
    });

    test('returns false for non-image file', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'document.pdf',
        filePath: '/path/document.pdf',
        fileType: 'application/pdf',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isImageAttachment(att), isFalse);
    });

    test('case-insensitive extension matching', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'PHOTO.JPG',
        filePath: '/path/PHOTO.JPG',
        fileType: null,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isImageAttachment(att), isTrue);
    });
  });

  group('isVideoAttachment', () {
    test('returns true for video MIME type', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'video.mp4',
        filePath: '/path/video.mp4',
        fileType: 'video/mp4',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isVideoAttachment(att), isTrue);
    });

    test('returns false for image MIME type', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'photo.jpg',
        filePath: '/path/photo.jpg',
        fileType: 'image/jpeg',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isVideoAttachment(att), isFalse);
    });

    test('returns false for null MIME type', () {
      final att = QnaAttachment(
        id: 1,
        messageId: 1,
        fileName: 'video.mp4',
        filePath: '/path/video.mp4',
        fileType: null,
        createdAt: DateTime(2024, 1, 1),
      );
      expect(isVideoAttachment(att), isFalse);
    });
  });
}
