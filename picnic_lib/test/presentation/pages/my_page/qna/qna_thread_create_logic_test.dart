import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';

void main() {
  group('isValidQnaTitle', () {
    test('returns false for null', () {
      expect(isValidQnaTitle(null), isFalse);
    });

    test('returns false for empty string', () {
      expect(isValidQnaTitle(''), isFalse);
    });

    test('returns false for string shorter than 5 chars', () {
      expect(isValidQnaTitle('abcd'), isFalse);
    });

    test('returns false for whitespace-only string shorter than 5 chars', () {
      expect(isValidQnaTitle('  ab  '), isFalse);
    });

    test('returns true for exactly 5 characters', () {
      expect(isValidQnaTitle('abcde'), isTrue);
    });

    test('returns true for string longer than 5 chars', () {
      expect(isValidQnaTitle('Hello World'), isTrue);
    });

    test('trims whitespace before checking length', () {
      expect(isValidQnaTitle('  ab  '), isFalse);
      expect(isValidQnaTitle('  abcde  '), isTrue);
    });
  });

  group('isValidQnaContent', () {
    test('returns false for null', () {
      expect(isValidQnaContent(null), isFalse);
    });

    test('returns false for empty string', () {
      expect(isValidQnaContent(''), isFalse);
    });

    test('returns false for string shorter than 10 chars', () {
      expect(isValidQnaContent('short'), isFalse);
    });

    test('returns true for exactly 10 characters', () {
      expect(isValidQnaContent('1234567890'), isTrue);
    });

    test('returns true for string longer than 10 chars', () {
      expect(isValidQnaContent('This is a long enough message'), isTrue);
    });

    test('trims whitespace before checking length', () {
      expect(isValidQnaContent('   short   '), isFalse);
      expect(isValidQnaContent('   1234567890   '), isTrue);
    });
  });

  group('isCategorySelectionRequired', () {
    test('returns false when no categories available', () {
      expect(
        isCategorySelectionRequired(
          hasCategoriesAvailable: false,
          selectedCategoryCode: null,
        ),
        isFalse,
      );
    });

    test('returns true when categories available but none selected', () {
      expect(
        isCategorySelectionRequired(
          hasCategoriesAvailable: true,
          selectedCategoryCode: null,
        ),
        isTrue,
      );
    });

    test('returns true when categories available but empty code selected', () {
      expect(
        isCategorySelectionRequired(
          hasCategoriesAvailable: true,
          selectedCategoryCode: '',
        ),
        isTrue,
      );
    });

    test('returns false when categories available and valid code selected', () {
      expect(
        isCategorySelectionRequired(
          hasCategoriesAvailable: true,
          selectedCategoryCode: 'general',
        ),
        isFalse,
      );
    });
  });
}
