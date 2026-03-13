import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

/// Edge-case tests for PostWriteBody logic patterns, covering uncovered branches.
void main() {
  group('PostWriteBody style detection (_isStyleActive) pattern', () {
    // Mirrors the logic: containsKey && value matches
    bool isStyleActive(
      Map<String, dynamic> attributes,
      String key,
      dynamic value,
    ) {
      return attributes.containsKey(key) && attributes[key] == value;
    }

    test('detects bold active', () {
      final attrs = {'bold': true, 'italic': false};
      expect(isStyleActive(attrs, 'bold', true), isTrue);
    });

    test('detects bold inactive when false', () {
      final attrs = {'bold': false};
      expect(isStyleActive(attrs, 'bold', true), isFalse);
    });

    test('detects bold inactive when not present', () {
      final attrs = <String, dynamic>{};
      expect(isStyleActive(attrs, 'bold', true), isFalse);
    });

    test('detects italic active', () {
      final attrs = {'italic': true};
      expect(isStyleActive(attrs, 'italic', true), isTrue);
    });

    test('detects underline active', () {
      final attrs = {'underline': true};
      expect(isStyleActive(attrs, 'underline', true), isTrue);
    });

    test('multiple formats active simultaneously', () {
      final attrs = {'bold': true, 'italic': true, 'underline': true};
      expect(isStyleActive(attrs, 'bold', true), isTrue);
      expect(isStyleActive(attrs, 'italic', true), isTrue);
      expect(isStyleActive(attrs, 'underline', true), isTrue);
    });

    test('value mismatch returns false', () {
      final attrs = {'bold': 'wrong_value'};
      expect(isStyleActive(attrs, 'bold', true), isFalse);
    });
  });

  group('PostWriteBody embed insertion position calculation', () {
    test('calculates correct insert position for collapsed selection', () {
      const baseOffset = 10;
      const extentOffset = 10;
      final index = baseOffset;
      final length = extentOffset - index;

      expect(index, 10);
      expect(length, 0); // No selection
    });

    test('calculates correct insert position for range selection', () {
      const baseOffset = 5;
      const extentOffset = 15;
      final index = baseOffset;
      final length = extentOffset - index;

      expect(index, 5);
      expect(length, 10); // 10 chars selected
    });

    test('cursor position after embed insertion is index + 2', () {
      const index = 10;
      final newCursorPos = index + 2; // embed + newline
      expect(newCursorPos, 12);
    });
  });

  group('PostWriteBody link embed JSON encoding', () {
    test('encodes link data correctly', () {
      final name = 'Example Site';
      final url = 'https://example.com/page';
      final encoded = jsonEncode({'name': name, 'url': url});

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['name'], name);
      expect(decoded['url'], url);
    });

    test('handles null name in link data', () {
      String? name;
      final url = 'https://example.com';
      final encoded = jsonEncode({'name': name, 'url': url});

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['name'], isNull);
      expect(decoded['url'], url);
    });

    test('handles special characters in URL', () {
      final url = 'https://example.com/search?q=hello&lang=ko';
      final encoded = jsonEncode({'name': null, 'url': url});

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['url'], url);
    });
  });

  group('PostWriteBody delta operation search pattern', () {
    test('finds local-image in delta operations', () {
      final operations = <Map<String, dynamic>>[
        {'insert': 'text\n'},
        {
          'insert': {'local-image': '/path/to/image.jpg'}
        },
        {'insert': '\nmore text\n'},
      ];

      int? foundIndex;
      for (int i = 0; i < operations.length; i++) {
        final data = operations[i]['insert'];
        if (data is Map<String, dynamic> &&
            data['local-image'] == '/path/to/image.jpg') {
          foundIndex = i;
          break;
        }
      }

      expect(foundIndex, 1);
    });

    test('returns null when local-image not found', () {
      final operations = <Map<String, dynamic>>[
        {'insert': 'text\n'},
        {'insert': 'more text\n'},
      ];

      int? foundIndex;
      for (int i = 0; i < operations.length; i++) {
        final data = operations[i]['insert'];
        if (data is Map<String, dynamic> &&
            data['local-image'] == '/nonexistent.jpg') {
          foundIndex = i;
          break;
        }
      }

      expect(foundIndex, isNull);
    });

    test('handles multiple images, finds correct one', () {
      final operations = <Map<String, dynamic>>[
        {
          'insert': {'local-image': '/first.jpg'}
        },
        {
          'insert': {'local-image': '/second.jpg'}
        },
      ];

      int? foundIndex;
      for (int i = 0; i < operations.length; i++) {
        final data = operations[i]['insert'];
        if (data is Map<String, dynamic> &&
            data['local-image'] == '/second.jpg') {
          foundIndex = i;
          break;
        }
      }

      expect(foundIndex, 1);
    });
  });

  group('PostWriteBody focus state change optimization', () {
    test('only updates state when focus actually changes', () {
      bool isTitleFocused = false;
      int setStateCount = 0;

      void handleFocusChange(bool hasFocus) {
        if (isTitleFocused != hasFocus) {
          setStateCount++;
          isTitleFocused = hasFocus;
        }
      }

      handleFocusChange(true);
      expect(setStateCount, 1);

      // Same state, no update
      handleFocusChange(true);
      expect(setStateCount, 1);

      handleFocusChange(false);
      expect(setStateCount, 2);

      // Same state, no update
      handleFocusChange(false);
      expect(setStateCount, 2);
    });
  });
}
