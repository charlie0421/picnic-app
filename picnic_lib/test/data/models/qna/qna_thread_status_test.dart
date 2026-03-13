import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';

QnaThread _buildThread({required String status}) {
  return QnaThread(
    id: 1,
    userId: 'user-1',
    title: 'test',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    status: status,
  );
}

void main() {
  group('QnaThreadStatusX', () {
    group('isReceived', () {
      test('returns true for "RECEIVED"', () {
        expect(_buildThread(status: 'RECEIVED').isReceived, isTrue);
      });

      test('returns true for "received" (lowercase)', () {
        expect(_buildThread(status: 'received').isReceived, isTrue);
      });

      test('returns true for "Received" (mixed case)', () {
        expect(_buildThread(status: 'Received').isReceived, isTrue);
      });

      test('returns false for "IN_PROGRESS"', () {
        expect(_buildThread(status: 'IN_PROGRESS').isReceived, isFalse);
      });

      test('returns false for "RESOLVED"', () {
        expect(_buildThread(status: 'RESOLVED').isReceived, isFalse);
      });

      test('returns false for unknown status', () {
        expect(_buildThread(status: 'UNKNOWN').isReceived, isFalse);
      });
    });

    group('isInProgress', () {
      test('returns true for "IN_PROGRESS"', () {
        expect(_buildThread(status: 'IN_PROGRESS').isInProgress, isTrue);
      });

      test('returns true for "in_progress" (lowercase)', () {
        expect(_buildThread(status: 'in_progress').isInProgress, isTrue);
      });

      test('returns true for "In_Progress" (mixed case)', () {
        expect(_buildThread(status: 'In_Progress').isInProgress, isTrue);
      });

      test('returns false for "RECEIVED"', () {
        expect(_buildThread(status: 'RECEIVED').isInProgress, isFalse);
      });

      test('returns false for "RESOLVED"', () {
        expect(_buildThread(status: 'RESOLVED').isInProgress, isFalse);
      });
    });

    group('isResolved', () {
      test('returns true for "RESOLVED"', () {
        expect(_buildThread(status: 'RESOLVED').isResolved, isTrue);
      });

      test('returns true for "resolved" (lowercase)', () {
        expect(_buildThread(status: 'resolved').isResolved, isTrue);
      });

      test('returns true for "Resolved" (mixed case)', () {
        expect(_buildThread(status: 'Resolved').isResolved, isTrue);
      });

      test('returns false for "RECEIVED"', () {
        expect(_buildThread(status: 'RECEIVED').isResolved, isFalse);
      });

      test('returns false for "IN_PROGRESS"', () {
        expect(_buildThread(status: 'IN_PROGRESS').isResolved, isFalse);
      });
    });

    group('isOpen', () {
      test('returns true for "RECEIVED"', () {
        expect(_buildThread(status: 'RECEIVED').isOpen, isTrue);
      });

      test('returns true for "IN_PROGRESS"', () {
        expect(_buildThread(status: 'IN_PROGRESS').isOpen, isTrue);
      });

      test('returns true for unknown status', () {
        expect(_buildThread(status: 'UNKNOWN').isOpen, isTrue);
      });

      test('returns false for "RESOLVED"', () {
        expect(_buildThread(status: 'RESOLVED').isOpen, isFalse);
      });

      test('returns false for "resolved" (lowercase)', () {
        expect(_buildThread(status: 'resolved').isOpen, isFalse);
      });
    });

    group('isClosed', () {
      test('returns true for "RESOLVED"', () {
        expect(_buildThread(status: 'RESOLVED').isClosed, isTrue);
      });

      test('returns false for "RECEIVED"', () {
        expect(_buildThread(status: 'RECEIVED').isClosed, isFalse);
      });

      test('returns false for "IN_PROGRESS"', () {
        expect(_buildThread(status: 'IN_PROGRESS').isClosed, isFalse);
      });

      test('is the inverse of isOpen', () {
        for (final status in ['RECEIVED', 'IN_PROGRESS', 'RESOLVED', 'UNKNOWN']) {
          final thread = _buildThread(status: status);
          expect(
            thread.isClosed,
            equals(!thread.isOpen),
            reason: 'isClosed should be inverse of isOpen for status "$status"',
          );
        }
      });
    });
  });
}
