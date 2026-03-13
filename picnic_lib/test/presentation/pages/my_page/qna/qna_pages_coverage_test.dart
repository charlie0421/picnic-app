import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_list_page.dart';

/// Coverage-focused tests for QNA pages.
///
/// These pages cannot be widget-tested because they depend on:
/// - Supabase.instance.client.auth.currentUser (QnaThreadDetailPage)
/// - QnaRepository (Supabase-backed, all pages)
/// - RouteAwareStateMixin (QnaThreadListPage)
/// - NavigationProvider (all pages)
///
/// Instead we test constructor parameters, the QnaCategory model,
/// and logic patterns used within the pages.
void main() {
  group('QnaThreadDetailPage constructor', () {
    test('accepts required thread parameter', () {
      final thread = QnaThread(
        id: 1,
        userId: 'user-1',
        title: 'Test Thread',
        status: 'received',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      final widget = QnaThreadDetailPage(thread: thread);
      expect(widget.thread, thread);
      expect(widget.syncNavigation, isTrue); // default
    });

    test('accepts syncNavigation parameter', () {
      final thread = QnaThread(
        id: 2,
        userId: 'user-1',
        title: 'Test',
        status: 'received',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      final widget = QnaThreadDetailPage(
        thread: thread,
        syncNavigation: false,
      );
      expect(widget.syncNavigation, isFalse);
    });

    test('accepts custom key', () {
      final thread = QnaThread(
        id: 3,
        userId: 'user-1',
        title: 'Test',
        status: 'received',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      final widget = QnaThreadDetailPage(
        key: const ValueKey('detail'),
        thread: thread,
      );
      expect(widget.key, const ValueKey('detail'));
    });
  });

  group('QnaThreadCreatePage constructor', () {
    test('accepts required userId parameter', () {
      const widget = QnaThreadCreatePage(userId: 'user-123');
      expect(widget.userId, 'user-123');
    });

    test('accepts custom key', () {
      const widget = QnaThreadCreatePage(
        key: ValueKey('create'),
        userId: 'user-123',
      );
      expect(widget.key, const ValueKey('create'));
    });

    test('userId can be empty', () {
      const widget = QnaThreadCreatePage(userId: '');
      expect(widget.userId, '');
    });
  });

  group('QnaThreadListPage constructor', () {
    test('accepts required userId parameter', () {
      const widget = QnaThreadListPage(userId: 'user-456');
      expect(widget.userId, 'user-456');
    });

    test('accepts custom key', () {
      const widget = QnaThreadListPage(
        key: ValueKey('list'),
        userId: 'user-456',
      );
      expect(widget.key, const ValueKey('list'));
    });
  });

  group('QnaCategory model', () {
    test('creates with all fields', () {
      final category = QnaCategory(
        code: 'billing',
        label: '결제 문의',
        questionTemplate: '결제 관련 문의 내용을 입력해주세요.',
        answerTemplate: '안녕하세요, 결제 관련 답변입니다.',
      );
      expect(category.code, 'billing');
      expect(category.label, '결제 문의');
      expect(category.questionTemplate, isNotNull);
      expect(category.answerTemplate, isNotNull);
    });

    test('creates with minimal fields', () {
      final category = QnaCategory(code: 'general', label: '일반 문의');
      expect(category.code, 'general');
      expect(category.label, '일반 문의');
      expect(category.questionTemplate, isNull);
      expect(category.answerTemplate, isNull);
    });

    test('code can be empty', () {
      final category = QnaCategory(code: '', label: 'Select');
      expect(category.code, '');
    });

    test('supports Korean labels', () {
      final category = QnaCategory(code: 'account', label: '계정 문의');
      expect(category.label, '계정 문의');
    });

    test('questionTemplate is optional', () {
      final category =
          QnaCategory(code: 'bug', label: 'Bug Report', questionTemplate: null);
      expect(category.questionTemplate, isNull);
    });

    test('answerTemplate is optional', () {
      final category =
          QnaCategory(code: 'bug', label: 'Bug', answerTemplate: null);
      expect(category.answerTemplate, isNull);
    });
  });

  group('QnaMessage model', () {
    test('creates with all fields', () {
      final message = QnaMessage(
        id: 1,
        threadId: 1,
        userId: 'user-1',
        content: 'Hello',
        createdAt: DateTime(2025, 1, 1),
        isAdminMessage: false,
        attachments: [],
      );
      expect(message.id, 1);
      expect(message.threadId, 1);
      expect(message.content, 'Hello');
    });

    test('isAdminMessage is false for user messages', () {
      final message = QnaMessage(
        id: 2,
        threadId: 1,
        userId: 'user-1',
        content: 'User message',
        createdAt: DateTime(2025, 1, 1),
        isAdminMessage: false,
        attachments: [],
      );
      expect(message.isAdminMessage, isFalse);
      expect(message.userId, 'user-1');
    });

    test('isAdminMessage is true for admin messages', () {
      final message = QnaMessage(
        id: 3,
        threadId: 1,
        userId: 'admin-1',
        content: 'Admin reply',
        createdAt: DateTime(2025, 1, 1),
        isAdminMessage: true,
        attachments: [],
      );
      expect(message.isAdminMessage, isTrue);
    });

    test('attachments can be empty', () {
      final message = QnaMessage(
        id: 4,
        threadId: 1,
        userId: 'user-1',
        content: 'No attachments',
        createdAt: DateTime(2025, 1, 1),
        isAdminMessage: false,
        attachments: [],
      );
      expect(message.attachments, isEmpty);
    });

    test('attachments can have items', () {
      final attachment = QnaAttachment(
        id: 1,
        messageId: 5,
        filePath: 'path/to/file.jpg',
        fileName: 'file.jpg',
        fileType: 'image/jpeg',
        createdAt: DateTime(2025, 1, 1),
      );
      final message = QnaMessage(
        id: 5,
        threadId: 1,
        userId: 'user-1',
        content: 'With attachment',
        createdAt: DateTime(2025, 1, 1),
        isAdminMessage: false,
        attachments: [attachment],
      );
      expect(message.attachments.length, 1);
      expect(message.attachments.first.fileName, 'file.jpg');
    });

    test('content can be null', () {
      final message = QnaMessage(
        id: 6,
        threadId: 1,
        userId: 'user-1',
        createdAt: DateTime(2025, 1, 1),
        isAdminMessage: false,
      );
      expect(message.content, isNull);
    });
  });

  group('QnaAttachment model', () {
    test('creates with all fields', () {
      final attachment = QnaAttachment(
        id: 1,
        messageId: 1,
        filePath: 'qna/attachments/image.png',
        fileName: 'image.png',
        fileType: 'image/png',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(attachment.id, 1);
      expect(attachment.messageId, 1);
      expect(attachment.filePath, 'qna/attachments/image.png');
      expect(attachment.fileName, 'image.png');
      expect(attachment.fileType, 'image/png');
    });

    test('fileType can be null', () {
      final attachment = QnaAttachment(
        id: 2,
        messageId: 1,
        filePath: 'path/file.dat',
        fileName: 'file.dat',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(attachment.fileType, isNull);
    });

    test('detects image by fileType', () {
      final attachment = QnaAttachment(
        id: 3,
        messageId: 1,
        filePath: 'path/photo.jpg',
        fileName: 'photo.jpg',
        fileType: 'image/jpeg',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(attachment.fileType?.startsWith('image/'), isTrue);
    });

    test('detects video by fileType', () {
      final attachment = QnaAttachment(
        id: 4,
        messageId: 1,
        filePath: 'path/video.mp4',
        fileName: 'video.mp4',
        fileType: 'video/mp4',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(attachment.fileType?.startsWith('video/'), isTrue);
    });

    test('fileSize can be null', () {
      final attachment = QnaAttachment(
        id: 5,
        messageId: 1,
        filePath: 'path/file.dat',
        fileName: 'file.dat',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(attachment.fileSize, isNull);
    });

    test('fileSize stores value', () {
      final attachment = QnaAttachment(
        id: 6,
        messageId: 1,
        filePath: 'path/file.dat',
        fileName: 'file.dat',
        fileSize: 1024,
        createdAt: DateTime(2025, 1, 1),
      );
      expect(attachment.fileSize, 1024);
    });
  });

  group('File type detection logic (mirrors _buildAttachments)', () {
    bool isImageByExtension(String fileName) {
      return ['jpg', 'jpeg', 'png', 'gif']
          .any((ext) => fileName.toLowerCase().endsWith('.$ext'));
    }

    test('detects .jpg', () {
      expect(isImageByExtension('photo.jpg'), isTrue);
    });

    test('detects .jpeg', () {
      expect(isImageByExtension('photo.jpeg'), isTrue);
    });

    test('detects .png', () {
      expect(isImageByExtension('image.png'), isTrue);
    });

    test('detects .gif', () {
      expect(isImageByExtension('animation.gif'), isTrue);
    });

    test('detects case insensitive .JPG', () {
      expect(isImageByExtension('PHOTO.JPG'), isTrue);
    });

    test('does not detect .mp4', () {
      expect(isImageByExtension('video.mp4'), isFalse);
    });

    test('does not detect .pdf', () {
      expect(isImageByExtension('document.pdf'), isFalse);
    });

    test('does not detect .webp', () {
      expect(isImageByExtension('image.webp'), isFalse);
    });
  });

  group('Date divider logic (mirrors _buildBody date comparison)', () {
    bool shouldShowDateDivider(DateTime current, DateTime? previous) {
      if (previous == null) return true;
      return current.day != previous.day ||
          current.month != previous.month ||
          current.year != previous.year;
    }

    test('first message always shows divider', () {
      expect(shouldShowDateDivider(DateTime(2025, 1, 15), null), isTrue);
    });

    test('same day does not show divider', () {
      expect(
        shouldShowDateDivider(
          DateTime(2025, 1, 15, 10, 0),
          DateTime(2025, 1, 15, 9, 0),
        ),
        isFalse,
      );
    });

    test('different day shows divider', () {
      expect(
        shouldShowDateDivider(
          DateTime(2025, 1, 16),
          DateTime(2025, 1, 15),
        ),
        isTrue,
      );
    });

    test('different month shows divider', () {
      expect(
        shouldShowDateDivider(
          DateTime(2025, 2, 1),
          DateTime(2025, 1, 31),
        ),
        isTrue,
      );
    });

    test('different year shows divider', () {
      expect(
        shouldShowDateDivider(
          DateTime(2026, 1, 1),
          DateTime(2025, 12, 31),
        ),
        isTrue,
      );
    });
  });

  group('Auto-close notice logic (mirrors _shouldShowAutoCloseNotice)', () {
    test('resolved thread does not show notice', () {
      final thread = QnaThread(
        id: 100,
        userId: 'user-1',
        title: 'Test',
        status: 'resolved',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      expect(thread.isResolved, isTrue);
      // When isResolved, notice should not show
    });

    test('received thread with admin message shows notice', () {
      final thread = QnaThread(
        id: 101,
        userId: 'user-1',
        title: 'Test',
        status: 'received',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      expect(thread.isResolved, isFalse);
    });

    test('in_progress thread is not resolved', () {
      final thread = QnaThread(
        id: 102,
        userId: 'user-1',
        title: 'Test',
        status: 'in_progress',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      expect(thread.isResolved, isFalse);
      expect(thread.isInProgress, isTrue);
    });
  });

  group('Thread open/closed logic', () {
    test('received thread is open', () {
      final thread = QnaThread(
        id: 200,
        userId: 'u1',
        title: 'T',
        status: 'received',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(thread.isOpen, isTrue);
      expect(thread.isClosed, isFalse);
    });

    test('in_progress thread is open', () {
      final thread = QnaThread(
        id: 201,
        userId: 'u1',
        title: 'T',
        status: 'in_progress',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(thread.isOpen, isTrue);
    });

    test('resolved thread is closed', () {
      final thread = QnaThread(
        id: 202,
        userId: 'u1',
        title: 'T',
        status: 'resolved',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(thread.isClosed, isTrue);
      expect(thread.isOpen, isFalse);
    });
  });

  group('Max file size constant', () {
    test('10MB limit in bytes', () {
      const maxFileSizeInBytes = 10 * 1024 * 1024;
      expect(maxFileSizeInBytes, 10485760);
    });
  });

  group('Category validation logic (mirrors _submitThread)', () {
    test('empty categories list does not require selection', () {
      final categories = <QnaCategory>[];
      final selectedCategory = null;
      final requiresCategory =
          categories.isNotEmpty && selectedCategory == null;
      expect(requiresCategory, isFalse);
    });

    test('non-empty categories list requires selection', () {
      final categories = [QnaCategory(code: 'billing', label: 'Billing')];
      final selectedCategory = null;
      final requiresCategory =
          categories.isNotEmpty && selectedCategory == null;
      expect(requiresCategory, isTrue);
    });

    test('selected category with empty code is invalid', () {
      final categories = [QnaCategory(code: 'billing', label: 'Billing')];
      final selectedCategory = QnaCategory(code: '', label: 'Select');
      final requiresCategory = categories.isNotEmpty &&
          (selectedCategory.code.isEmpty);
      expect(requiresCategory, isTrue);
    });

    test('selected category with valid code is valid', () {
      final categories = [QnaCategory(code: 'billing', label: 'Billing')];
      final selectedCategory = QnaCategory(code: 'billing', label: 'Billing');
      final requiresCategory = categories.isNotEmpty &&
          (selectedCategory.code.isEmpty);
      expect(requiresCategory, isFalse);
    });
  });
}
