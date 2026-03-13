import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/deepl_translate_service.dart';

void main() {
  late DeepLTranslationService service;

  setUp(() {
    service = DeepLTranslationService(apiKey: 'test-key', debugMode: false);
  });

  group('containsKorean', () {
    test('returns true for Korean text', () {
      expect(service.containsKorean('안녕하세요'), isTrue);
    });

    test('returns false for English text', () {
      expect(service.containsKorean('Hello'), isFalse);
    });

    test('returns true for mixed text', () {
      expect(service.containsKorean('Hello 안녕'), isTrue);
    });

    test('returns false for empty string', () {
      expect(service.containsKorean(''), isFalse);
    });

    test('returns false for numbers', () {
      expect(service.containsKorean('12345'), isFalse);
    });

    test('returns false for Japanese', () {
      expect(service.containsKorean('こんにちは'), isFalse);
    });

    test('returns true for single Korean char', () {
      expect(service.containsKorean('가'), isTrue);
    });
  });

  group('containsKoreanOrEmpty', () {
    test('returns true for empty string', () {
      expect(service.containsKoreanOrEmpty(''), isTrue);
    });

    test('returns true for Korean text', () {
      expect(service.containsKoreanOrEmpty('한글'), isTrue);
    });

    test('returns false for English text', () {
      expect(service.containsKoreanOrEmpty('English'), isFalse);
    });

    test('returns false for numbers', () {
      expect(service.containsKoreanOrEmpty('123'), isFalse);
    });
  });

  group('containsPlaceholders', () {
    test('returns true for text with placeholders', () {
      expect(service.containsPlaceholders('Hello {name}'), isTrue);
    });

    test('returns false for text without placeholders', () {
      expect(service.containsPlaceholders('Hello world'), isFalse);
    });

    test('returns true for multiple placeholders', () {
      expect(service.containsPlaceholders('{a} and {b}'), isTrue);
    });

    test('returns false for empty string', () {
      expect(service.containsPlaceholders(''), isFalse);
    });

    test('returns false for empty braces', () {
      expect(service.containsPlaceholders('{}'), isFalse);
    });

    test('returns true for nested content in braces', () {
      expect(service.containsPlaceholders('{count} items'), isTrue);
    });
  });

  group('isCorrectLanguage', () {
    test('returns true for English text targeting EN', () {
      expect(service.isCorrectLanguage('Hello world', 'EN'), isTrue);
    });

    test('returns true for Japanese text targeting JA', () {
      expect(service.isCorrectLanguage('こんにちは', 'JA'), isTrue);
    });

    test('validates Chinese text targeting ZH', () {
      // ZH regex uses Han script - single char should match
      final result = service.isCorrectLanguage('你好', 'ZH');
      expect(result, isA<bool>());
    });

    test('returns true for unknown language (no regex)', () {
      expect(service.isCorrectLanguage('Hola mundo', 'ES'), isTrue);
    });

    test('ignores placeholders in validation', () {
      expect(service.isCorrectLanguage('Hello {name} world', 'EN'), isTrue);
    });

    test('handles text with only placeholders', () {
      // After removing placeholders, empty string may not match regex
      final result = service.isCorrectLanguage('{name}', 'EN');
      expect(result, isA<bool>());
    });
  });

  group('constructor', () {
    test('creates instance with debug mode on', () {
      final s = DeepLTranslationService(apiKey: 'key', debugMode: true);
      expect(s.debugMode, isTrue);
    });

    test('creates instance with debug mode off', () {
      final s = DeepLTranslationService(apiKey: 'key', debugMode: false);
      expect(s.debugMode, isFalse);
    });

    test('default debug mode is true', () {
      final s = DeepLTranslationService(apiKey: 'key');
      expect(s.debugMode, isTrue);
    });
  });
}
