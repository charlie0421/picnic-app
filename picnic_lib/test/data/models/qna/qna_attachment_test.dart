import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';

void main() {
  group('QnaAttachment', () {
    test('필수 필드로 생성', () {
      final attachment = QnaAttachment(
        id: 1,
        messageId: 100,
        fileName: 'screenshot.png',
        filePath: '/uploads/screenshot.png',
        createdAt: DateTime(2025, 3, 1),
      );
      expect(attachment.id, equals(1));
      expect(attachment.messageId, equals(100));
      expect(attachment.fileName, equals('screenshot.png'));
      expect(attachment.filePath, equals('/uploads/screenshot.png'));
      expect(attachment.fileType, isNull);
      expect(attachment.fileSize, isNull);
    });

    test('선택 필드 포함 생성', () {
      final attachment = QnaAttachment(
        id: 2,
        messageId: 100,
        fileName: 'document.pdf',
        filePath: '/uploads/document.pdf',
        fileType: 'application/pdf',
        fileSize: 1024000,
        createdAt: DateTime(2025, 3, 1),
      );
      expect(attachment.fileType, equals('application/pdf'));
      expect(attachment.fileSize, equals(1024000));
    });
  });
}
