import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';

void main() {
  group('DescriptionConverter', () {
    const converter = DescriptionConverter();

    group('fromJson', () {
      test('handles Map<String, dynamic>', () {
        final result = converter.fromJson({'en': 'Hello', 'ko': '안녕'});
        expect(result, isA<Map<String, dynamic>>());
        expect(result['en'], 'Hello');
      });

      test('handles String', () {
        final result = converter.fromJson('Simple description');
        expect(result, 'Simple description');
      });

      test('throws for unexpected type', () {
        expect(
          () => converter.fromJson(123),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws for list type', () {
        expect(
          () => converter.fromJson(['a', 'b']),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toJson', () {
      test('handles Map<String, dynamic>', () {
        final result = converter.toJson({'en': 'Hello'});
        expect(result, isA<Map<String, dynamic>>());
      });

      test('handles String', () {
        final result = converter.toJson('text');
        expect(result, 'text');
      });

      test('throws for unexpected type', () {
        expect(
          () => converter.toJson(42),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
