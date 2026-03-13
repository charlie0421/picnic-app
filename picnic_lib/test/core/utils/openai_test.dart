import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/openai.dart';

void main() {
  group('getFallbackResponse', () {
    test('returns map with flagged=false', () {
      final result = getFallbackResponse();
      expect(result['flagged'], isFalse);
    });

    test('contains all required categories', () {
      final result = getFallbackResponse();
      final categories = result['categories'] as Map<String, dynamic>;
      expect(categories.containsKey('sexual'), isTrue);
      expect(categories.containsKey('hate'), isTrue);
      expect(categories.containsKey('harassment'), isTrue);
      expect(categories.containsKey('self-harm'), isTrue);
      expect(categories.containsKey('violence'), isTrue);
    });

    test('all categories are false', () {
      final result = getFallbackResponse();
      final categories = result['categories'] as Map<String, dynamic>;
      for (final entry in categories.entries) {
        expect(entry.value, isFalse, reason: '${entry.key} should be false');
      }
    });

    test('contains category_scores', () {
      final result = getFallbackResponse();
      final scores = result['category_scores'] as Map<String, dynamic>;
      expect(scores, isNotEmpty);
    });

    test('all category_scores are 0.0', () {
      final result = getFallbackResponse();
      final scores = result['category_scores'] as Map<String, dynamic>;
      for (final entry in scores.entries) {
        expect(entry.value, 0.0, reason: '${entry.key} score should be 0.0');
      }
    });

    test('categories and scores have same keys', () {
      final result = getFallbackResponse();
      final categories = result['categories'] as Map<String, dynamic>;
      final scores = result['category_scores'] as Map<String, dynamic>;
      expect(categories.keys.toSet(), equals(scores.keys.toSet()));
    });

    test('has 11 category entries', () {
      final result = getFallbackResponse();
      final categories = result['categories'] as Map<String, dynamic>;
      expect(categories.length, 11);
    });

    test('includes sub-categories', () {
      final result = getFallbackResponse();
      final categories = result['categories'] as Map<String, dynamic>;
      expect(categories.containsKey('sexual/minors'), isTrue);
      expect(categories.containsKey('hate/threatening'), isTrue);
      expect(categories.containsKey('violence/graphic'), isTrue);
      expect(categories.containsKey('self-harm/intent'), isTrue);
      expect(categories.containsKey('self-harm/instructions'), isTrue);
      expect(categories.containsKey('harassment/threatening'), isTrue);
    });
  });
}
