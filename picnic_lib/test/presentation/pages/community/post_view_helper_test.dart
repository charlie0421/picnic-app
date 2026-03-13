import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_helper.dart';

void main() {
  group('PostViewHelper.parseContent', () {
    test('returns newline insert for null content', () {
      final result = PostViewHelper.parseContent(null);
      expect(result, [
        {"insert": "\n"}
      ]);
    });

    test('returns list as-is when content is List', () {
      final input = [
        {"insert": "Hello"},
        {"insert": "\n"}
      ];
      final result = PostViewHelper.parseContent(input);
      expect(result, input);
    });

    test('extracts ops from Map with ops key', () {
      final input = {
        "ops": [
          {"insert": "From ops"}
        ]
      };
      final result = PostViewHelper.parseContent(input);
      expect(result, [
        {"insert": "From ops"}
      ]);
    });

    test('wraps Map without ops as single-element list', () {
      final input = {"insert": "standalone"};
      final result = PostViewHelper.parseContent(input);
      expect(result, [input]);
    });

    test('returns newline insert for empty string', () {
      final result = PostViewHelper.parseContent('');
      expect(result, [
        {"insert": "\n"}
      ]);
    });

    test('returns newline insert for whitespace-only string', () {
      final result = PostViewHelper.parseContent('   ');
      expect(result, [
        {"insert": "\n"}
      ]);
    });

    test('decodes JSON array string', () {
      final result = PostViewHelper.parseContent('[{"insert":"decoded"}]');
      expect(result, [
        {"insert": "decoded"}
      ]);
    });

    test('decodes JSON object string with ops', () {
      final result =
          PostViewHelper.parseContent('{"ops":[{"insert":"from json"}]}');
      expect(result, [
        {"insert": "from json"}
      ]);
    });

    test('treats non-JSON string as plain text', () {
      final result = PostViewHelper.parseContent('Hello World');
      expect(result, [
        {"insert": "Hello World"}
      ]);
    });

    test('converts other types to string insert', () {
      final result = PostViewHelper.parseContent(42);
      expect(result, [
        {"insert": "42"}
      ]);
    });

    test('handles JSON object string without ops as single-element list', () {
      final result =
          PostViewHelper.parseContent('{"key":"value"}');
      expect(result, [
        {"key": "value"}
      ]);
    });
  });

  group('PostViewHelper.extractOpsFromMap', () {
    test('returns ops list when present', () {
      final result = PostViewHelper.extractOpsFromMap({
        "ops": [
          {"insert": "text"}
        ]
      });
      expect(result, [
        {"insert": "text"}
      ]);
    });

    test('returns delta list when present', () {
      final result = PostViewHelper.extractOpsFromMap({
        "delta": [
          {"insert": "delta text"}
        ]
      });
      expect(result, [
        {"insert": "delta text"}
      ]);
    });

    test('returns nested delta.ops when present', () {
      final result = PostViewHelper.extractOpsFromMap({
        "delta": {
          "ops": [
            {"insert": "nested"}
          ]
        }
      });
      expect(result, [
        {"insert": "nested"}
      ]);
    });

    test('returns null when no ops or delta', () {
      final result =
          PostViewHelper.extractOpsFromMap({"key": "value"});
      expect(result, isNull);
    });

    test('returns null when ops is not a List', () {
      final result =
          PostViewHelper.extractOpsFromMap({"ops": "not a list"});
      expect(result, isNull);
    });

    test('returns null when delta is a Map without ops', () {
      final result = PostViewHelper.extractOpsFromMap({
        "delta": {"key": "value"}
      });
      expect(result, isNull);
    });
  });

  group('PostViewHelper.extractFallbackText', () {
    test('returns empty string for null', () {
      expect(PostViewHelper.extractFallbackText(null), '');
    });

    test('returns string as-is', () {
      expect(PostViewHelper.extractFallbackText('hello'), 'hello');
    });

    test('JSON-encodes map', () {
      final result = PostViewHelper.extractFallbackText({"key": "value"});
      expect(result, '{"key":"value"}');
    });

    test('JSON-encodes list', () {
      final result = PostViewHelper.extractFallbackText([1, 2, 3]);
      expect(result, '[1,2,3]');
    });

    test('converts other types to string', () {
      expect(PostViewHelper.extractFallbackText(123), '123');
    });
  });

  group('PostViewHelper.classifyError', () {
    test('classifies SocketException as network', () {
      expect(
        PostViewHelper.classifyError(
            const SocketException('Connection failed')),
        'network',
      );
    });

    test('classifies TimeoutException as timeout', () {
      expect(
        PostViewHelper.classifyError(TimeoutException('Timed out')),
        'timeout',
      );
    });

    test('classifies FormatException as format', () {
      expect(
        PostViewHelper.classifyError(const FormatException('Bad format')),
        'format',
      );
    });

    test('classifies other exceptions as unknown', () {
      expect(
        PostViewHelper.classifyError(Exception('Something')),
        'unknown',
      );
    });

    test('classifies string error as unknown', () {
      expect(PostViewHelper.classifyError('error'), 'unknown');
    });
  });

  group('PostViewHelper.isPostDeleted', () {
    test('returns true when deletedAt is not null', () {
      expect(PostViewHelper.isPostDeleted(DateTime.now()), isTrue);
    });

    test('returns false when deletedAt is null', () {
      expect(PostViewHelper.isPostDeleted(null), isFalse);
    });
  });

  group('PostViewHelper.resolveAuthorName', () {
    test('returns anonymous label when isAnonymous is true', () {
      expect(
        PostViewHelper.resolveAuthorName(
          isAnonymous: true,
          nickname: 'User1',
          anonymousLabel: '익명',
        ),
        '익명',
      );
    });

    test('returns nickname when not anonymous', () {
      expect(
        PostViewHelper.resolveAuthorName(
          isAnonymous: false,
          nickname: 'User1',
          anonymousLabel: '익명',
        ),
        'User1',
      );
    });

    test('returns empty string when not anonymous and nickname is null', () {
      expect(
        PostViewHelper.resolveAuthorName(
          isAnonymous: false,
          nickname: null,
          anonymousLabel: '익명',
        ),
        '',
      );
    });
  });
}
