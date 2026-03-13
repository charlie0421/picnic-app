import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/deepl_translate_service_helper.dart';

void main() {
  group('buildPlaceholderMap', () {
    test('extracts single placeholder', () {
      final map =
          DeepLTranslateServiceHelper.buildPlaceholderMap('Hello {name}');
      expect(map, {'__PH0__': '{name}'});
    });

    test('extracts multiple placeholders', () {
      final map = DeepLTranslateServiceHelper.buildPlaceholderMap(
          '{greeting} {name}, you have {count} items');
      expect(map, {
        '__PH0__': '{greeting}',
        '__PH1__': '{name}',
        '__PH2__': '{count}',
      });
    });

    test('returns empty map when no placeholders', () {
      final map =
          DeepLTranslateServiceHelper.buildPlaceholderMap('Hello world');
      expect(map, isEmpty);
    });

    test('returns empty map for empty string', () {
      final map = DeepLTranslateServiceHelper.buildPlaceholderMap('');
      expect(map, isEmpty);
    });

    test('handles adjacent placeholders', () {
      final map =
          DeepLTranslateServiceHelper.buildPlaceholderMap('{a}{b}');
      expect(map, {'__PH0__': '{a}', '__PH1__': '{b}'});
    });

    test('ignores empty braces', () {
      final map =
          DeepLTranslateServiceHelper.buildPlaceholderMap('Hello {} world');
      expect(map, isEmpty);
    });
  });

  group('replacePlaceholdersWithKeys', () {
    test('replaces placeholders with temp keys', () {
      final placeholderMap = {'__PH0__': '{name}', '__PH1__': '{count}'};
      final result = DeepLTranslateServiceHelper.replacePlaceholdersWithKeys(
          'Hello {name}, {count} items', placeholderMap);
      expect(result, 'Hello __PH0__, __PH1__ items');
    });

    test('returns original text when map is empty', () {
      final result = DeepLTranslateServiceHelper.replacePlaceholdersWithKeys(
          'Hello world', {});
      expect(result, 'Hello world');
    });

    test('handles text with no matching placeholders', () {
      final placeholderMap = {'__PH0__': '{missing}'};
      final result = DeepLTranslateServiceHelper.replacePlaceholdersWithKeys(
          'Hello world', placeholderMap);
      expect(result, 'Hello world');
    });

    test('replaces duplicate placeholders', () {
      final placeholderMap = {'__PH0__': '{name}'};
      final result = DeepLTranslateServiceHelper.replacePlaceholdersWithKeys(
          '{name} and {name}', placeholderMap);
      expect(result, '__PH0__ and __PH0__');
    });
  });

  group('restorePlaceholders', () {
    test('restores temp keys back to placeholders', () {
      final placeholderMap = {'__PH0__': '{name}', '__PH1__': '{count}'};
      final result = DeepLTranslateServiceHelper.restorePlaceholders(
          'Hello __PH0__, __PH1__ items', placeholderMap);
      expect(result, 'Hello {name}, {count} items');
    });

    test('returns original text when map is empty', () {
      final result =
          DeepLTranslateServiceHelper.restorePlaceholders('Hello world', {});
      expect(result, 'Hello world');
    });

    test('handles text with no matching keys', () {
      final placeholderMap = {'__PH0__': '{name}'};
      final result = DeepLTranslateServiceHelper.restorePlaceholders(
          'Hello world', placeholderMap);
      expect(result, 'Hello world');
    });

    test('round-trip: replace then restore returns original', () {
      const original = 'Hello {name}, you have {count} items in {place}';
      final placeholderMap =
          DeepLTranslateServiceHelper.buildPlaceholderMap(original);
      final replaced = DeepLTranslateServiceHelper.replacePlaceholdersWithKeys(
          original, placeholderMap);
      final restored =
          DeepLTranslateServiceHelper.restorePlaceholders(replaced, placeholderMap);
      expect(restored, original);
    });
  });

  group('shouldRetry', () {
    test('returns true when attempts less than max', () {
      expect(DeepLTranslateServiceHelper.shouldRetry(0, 3), isTrue);
      expect(DeepLTranslateServiceHelper.shouldRetry(1, 3), isTrue);
      expect(DeepLTranslateServiceHelper.shouldRetry(2, 3), isTrue);
    });

    test('returns false when attempts equal to max', () {
      expect(DeepLTranslateServiceHelper.shouldRetry(3, 3), isFalse);
    });

    test('returns false when attempts exceed max', () {
      expect(DeepLTranslateServiceHelper.shouldRetry(5, 3), isFalse);
    });

    test('returns false when max attempts is zero', () {
      expect(DeepLTranslateServiceHelper.shouldRetry(0, 0), isFalse);
    });
  });
}
