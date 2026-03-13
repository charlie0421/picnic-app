import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/repositories/qna_repository_helper.dart';

void main() {
  group('QnaRepositoryHelper.generateUuidName', () {
    test('strips dashes from UUID and appends extension with dot', () {
      final result = QnaRepositoryHelper.generateUuidName(
        '550e8400-e29b-41d4-a716-446655440000',
        '.png',
      );
      expect(result, '550e8400e29b41d4a716446655440000.png');
    });

    test('prepends dot when extension lacks one', () {
      final result = QnaRepositoryHelper.generateUuidName(
        'abcd1234-0000-0000-0000-000000000000',
        'jpg',
      );
      expect(result, 'abcd1234000000000000000000000000.jpg');
    });

    test('returns UUID only when extension is empty', () {
      final result = QnaRepositoryHelper.generateUuidName(
        '11111111-2222-3333-4444-555555555555',
        '',
      );
      expect(result, '11111111222233334444555555555555');
    });

    test('handles UUID without dashes', () {
      final result = QnaRepositoryHelper.generateUuidName(
        'abcdef1234567890abcdef1234567890',
        '.webp',
      );
      expect(result, 'abcdef1234567890abcdef1234567890.webp');
    });

    test('handles multi-part extension', () {
      final result = QnaRepositoryHelper.generateUuidName(
        '00000000-0000-0000-0000-000000000000',
        '.tar.gz',
      );
      expect(result, '00000000000000000000000000000000.tar.gz');
    });
  });

  group('QnaRepositoryHelper.normalizeThreadStatus', () {
    test('returns RECEIVED for null', () {
      expect(QnaRepositoryHelper.normalizeThreadStatus(null), 'RECEIVED');
    });

    test('returns RECEIVED for empty string', () {
      expect(QnaRepositoryHelper.normalizeThreadStatus(''), 'RECEIVED');
    });

    test('returns RECEIVED for whitespace-only string', () {
      expect(QnaRepositoryHelper.normalizeThreadStatus('   '), 'RECEIVED');
    });

    test('returns trimmed status for valid value', () {
      expect(QnaRepositoryHelper.normalizeThreadStatus('IN_PROGRESS'),
          'IN_PROGRESS');
    });

    test('trims surrounding whitespace', () {
      expect(
          QnaRepositoryHelper.normalizeThreadStatus('  RESOLVED  '), 'RESOLVED');
    });

    test('preserves RECEIVED when explicitly set', () {
      expect(QnaRepositoryHelper.normalizeThreadStatus('RECEIVED'), 'RECEIVED');
    });
  });

  group('QnaRepositoryHelper.buildAttachmentPath', () {
    test('builds correct path', () {
      expect(
        QnaRepositoryHelper.buildAttachmentPath('user-123', 42, 'file.png'),
        'qna/user-123/42/file.png',
      );
    });

    test('handles special characters in userId', () {
      expect(
        QnaRepositoryHelper.buildAttachmentPath(
            '550e8400-e29b-41d4-a716-446655440000', 1, 'img.jpg'),
        'qna/550e8400-e29b-41d4-a716-446655440000/1/img.jpg',
      );
    });
  });

  group('QnaRepositoryHelper.buildAttachmentRecord', () {
    test('builds correct record map', () {
      final result = QnaRepositoryHelper.buildAttachmentRecord(
        messageId: 10,
        fileName: 'abc.png',
        filePath: 'qna/user-1/10/abc.png',
        fileType: 'image/png',
        fileSize: 2048,
      );

      expect(result, {
        'message_id': 10,
        'file_name': 'abc.png',
        'file_path': 'qna/user-1/10/abc.png',
        'file_type': 'image/png',
        'file_size': 2048,
      });
    });

    test('handles null fileType', () {
      final result = QnaRepositoryHelper.buildAttachmentRecord(
        messageId: 5,
        fileName: 'unknown',
        filePath: 'qna/user-1/5/unknown',
        fileType: null,
        fileSize: 0,
      );

      expect(result['file_type'], isNull);
      expect(result['file_size'], 0);
    });
  });

  group('QnaRepositoryHelper.resolveCategoryLabel', () {
    String mockResolve(Map<String, dynamic> json) {
      return json['en'] as String? ?? '';
    }

    test('returns resolved text for Map field', () {
      expect(
        QnaRepositoryHelper.resolveCategoryLabel(
            {'en': 'Account', 'ko': '계정'}, mockResolve),
        'Account',
      );
    });

    test('returns null for empty resolved text', () {
      expect(
        QnaRepositoryHelper.resolveCategoryLabel({'ko': '계정'}, mockResolve),
        isNull,
      );
    });

    test('returns null for non-Map field', () {
      expect(
        QnaRepositoryHelper.resolveCategoryLabel('plain string', mockResolve),
        isNull,
      );
    });

    test('returns null for null field', () {
      expect(
        QnaRepositoryHelper.resolveCategoryLabel(null, mockResolve),
        isNull,
      );
    });

    test('returns null for integer field', () {
      expect(
        QnaRepositoryHelper.resolveCategoryLabel(42, mockResolve),
        isNull,
      );
    });
  });

  group('QnaRepositoryHelper.parseCategoryRow', () {
    String mockResolve(Map<String, dynamic> json) {
      return json['en'] as String? ?? '';
    }

    test('parses row with all fields', () {
      final row = {
        'code': 'ACCOUNT',
        'label': {'en': 'Account', 'ko': '계정'},
        'question_template': {'en': 'Account question', 'ko': '계정 질문'},
        'answer_template': {'en': 'Account answer', 'ko': '계정 답변'},
        'order_number': 1,
        'active': true,
      };

      final result = QnaRepositoryHelper.parseCategoryRow(row, mockResolve);

      expect(result.label, 'Account');
      expect(result.questionTemplate, 'Account question');
      expect(result.answerTemplate, 'Account answer');
    });

    test('returns empty label when label JSON is null', () {
      final row = {
        'code': 'TEST',
        'label': null,
        'question_template': null,
        'answer_template': null,
      };

      final result = QnaRepositoryHelper.parseCategoryRow(row, mockResolve);

      expect(result.label, '');
      expect(result.questionTemplate, isNull);
      expect(result.answerTemplate, isNull);
    });

    test('returns null templates when fields are null', () {
      final row = {
        'code': 'PAYMENT',
        'label': {'en': 'Payment'},
        'question_template': null,
        'answer_template': null,
      };

      final result = QnaRepositoryHelper.parseCategoryRow(row, mockResolve);

      expect(result.label, 'Payment');
      expect(result.questionTemplate, isNull);
      expect(result.answerTemplate, isNull);
    });

    test('handles partial templates', () {
      final row = {
        'code': 'MIXED',
        'label': {'en': 'Mixed'},
        'question_template': {'en': 'Q template'},
        'answer_template': null,
      };

      final result = QnaRepositoryHelper.parseCategoryRow(row, mockResolve);

      expect(result.label, 'Mixed');
      expect(result.questionTemplate, 'Q template');
      expect(result.answerTemplate, isNull);
    });
  });
}
