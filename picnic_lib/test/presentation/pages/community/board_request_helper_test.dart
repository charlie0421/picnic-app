import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/board_request_helper.dart';

void main() {
  group('BoardRequestHelper.validateName', () {
    test('returns empty for null', () {
      expect(BoardRequestHelper.validateName(null), 'empty');
    });

    test('returns empty for empty string', () {
      expect(BoardRequestHelper.validateName(''), 'empty');
    });

    test('returns null for valid name', () {
      expect(BoardRequestHelper.validateName('My Board'), isNull);
    });

    test('returns null for single character', () {
      expect(BoardRequestHelper.validateName('A'), isNull);
    });
  });

  group('BoardRequestHelper.validateDescription', () {
    test('returns empty for null', () {
      expect(BoardRequestHelper.validateDescription(null), 'empty');
    });

    test('returns empty for empty string', () {
      expect(BoardRequestHelper.validateDescription(''), 'empty');
    });

    test('returns length for too short (< 5)', () {
      expect(BoardRequestHelper.validateDescription('abcd'), 'length');
    });

    test('returns length for too long (> 20)', () {
      expect(BoardRequestHelper.validateDescription('a' * 21), 'length');
    });

    test('returns null for valid description (5 chars)', () {
      expect(BoardRequestHelper.validateDescription('abcde'), isNull);
    });

    test('returns null for valid description (20 chars)', () {
      expect(BoardRequestHelper.validateDescription('a' * 20), isNull);
    });

    test('returns null for description in valid range', () {
      expect(BoardRequestHelper.validateDescription('Hello World'), isNull);
    });
  });

  group('BoardRequestHelper.validateRequestMessage', () {
    test('returns empty for null', () {
      expect(BoardRequestHelper.validateRequestMessage(null), 'empty');
    });

    test('returns empty for empty string', () {
      expect(BoardRequestHelper.validateRequestMessage(''), 'empty');
    });

    test('returns length for too short (< 10)', () {
      expect(BoardRequestHelper.validateRequestMessage('short'), 'length');
    });

    test('returns length for 9 characters', () {
      expect(BoardRequestHelper.validateRequestMessage('a' * 9), 'length');
    });

    test('returns null for exactly 10 characters', () {
      expect(BoardRequestHelper.validateRequestMessage('a' * 10), isNull);
    });

    test('returns null for long message', () {
      expect(BoardRequestHelper.validateRequestMessage('a' * 100), isNull);
    });
  });

  group('BoardRequestHelper.isFormValid', () {
    test('returns true when all fields valid', () {
      expect(
        BoardRequestHelper.isFormValid('Name', 'Hello World', 'Please create this board'),
        isTrue,
      );
    });

    test('returns false when name is empty', () {
      expect(
        BoardRequestHelper.isFormValid('', 'Hello World', 'Please create this board'),
        isFalse,
      );
    });

    test('returns false when description too short', () {
      expect(
        BoardRequestHelper.isFormValid('Name', 'Hi', 'Please create this board'),
        isFalse,
      );
    });

    test('returns false when request message too short', () {
      expect(
        BoardRequestHelper.isFormValid('Name', 'Hello World', 'short'),
        isFalse,
      );
    });

    test('returns false when all fields invalid', () {
      expect(
        BoardRequestHelper.isFormValid('', '', ''),
        isFalse,
      );
    });
  });
}
