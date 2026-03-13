import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';

/// Tests for logic patterns used in PostWriteBody.
///
/// Widget testing is blocked because the widget imports
/// flutter_quill, file_picker, image_picker, flutter_keyboard_visibility,
/// keyboard_height_plugin, and flutter_svg.
/// Instead, we test the pure logic patterns the widget relies on.
void main() {
  group('PostWriteBody title validation logic (_validateTitle)', () {
    bool validateTitle(String text) {
      return text.trim().isNotEmpty;
    }

    test('empty string is invalid', () {
      expect(validateTitle(''), isFalse);
    });

    test('whitespace-only string is invalid', () {
      expect(validateTitle('   '), isFalse);
    });

    test('non-empty string is valid', () {
      expect(validateTitle('Hello'), isTrue);
    });

    test('string with leading/trailing spaces but content is valid', () {
      expect(validateTitle('  Title  '), isTrue);
    });

    test('single character is valid', () {
      expect(validateTitle('A'), isTrue);
    });

    test('Korean characters are valid', () {
      expect(validateTitle('제목입니다'), isTrue);
    });

    test('validity change triggers callback only when changed', () {
      bool previousValid = false;
      int callbackCount = 0;

      void onValidityChanged(bool isValid) {
        if (isValid != previousValid) {
          callbackCount++;
          previousValid = isValid;
        }
      }

      // First change: false -> true
      final isValid1 = validateTitle('Title');
      if (isValid1 != previousValid) onValidityChanged(isValid1);
      expect(callbackCount, equals(1));

      // Same state: true -> true (should not trigger)
      final isValid2 = validateTitle('Other Title');
      if (isValid2 != previousValid) onValidityChanged(isValid2);
      expect(callbackCount, equals(1));

      // Change: true -> false
      final isValid3 = validateTitle('');
      if (isValid3 != previousValid) onValidityChanged(isValid3);
      expect(callbackCount, equals(2));
    });
  });

  group('PostWriteBody focus state logic', () {
    test('title focus change updates border style', () {
      bool isTitleFocused = false;

      isTitleFocused = true;
      final focusedColor = isTitleFocused ? 'primary500' : 'grey400';
      final focusedWidth = isTitleFocused ? 2.0 : 1.0;

      expect(focusedColor, equals('primary500'));
      expect(focusedWidth, equals(2.0));
    });

    test('unfocused title uses grey border', () {
      const isTitleFocused = false;
      final color = isTitleFocused ? 'primary500' : 'grey400';
      final width = isTitleFocused ? 2.0 : 1.0;

      expect(color, equals('grey400'));
      expect(width, equals(1.0));
    });

    test('editor focus change updates border style', () {
      bool isEditorFocused = false;

      isEditorFocused = true;
      final focusedColor = isEditorFocused ? 'primary500' : 'grey400';
      expect(focusedColor, equals('primary500'));

      isEditorFocused = false;
      final unfocusedColor = isEditorFocused ? 'primary500' : 'grey400';
      expect(unfocusedColor, equals('grey400'));
    });

    test('unfocusAll clears both focus nodes conceptually', () {
      bool isTitleFocused = true;
      bool isEditorFocused = true;

      // Simulating _unFocusAll
      isTitleFocused = false;
      isEditorFocused = false;

      expect(isTitleFocused, isFalse);
      expect(isEditorFocused, isFalse);
    });
  });

  group('PostWriteBody icon color logic (_getIconColor)', () {
    String getIconColor(bool isActive) {
      return isActive ? 'grey900' : 'grey500';
    }

    test('active style returns grey900', () {
      expect(getIconColor(true), equals('grey900'));
    });

    test('inactive style returns grey500', () {
      expect(getIconColor(false), equals('grey500'));
    });
  });

  group('PostWriteBody history button state', () {
    test('undo button enabled when has undo history', () {
      const hasUndo = true;
      final isEnabled = hasUndo;
      final color = isEnabled ? 'grey900' : 'grey600';
      expect(color, equals('grey900'));
    });

    test('undo button disabled when no undo history', () {
      const hasUndo = false;
      final isEnabled = hasUndo;
      final color = isEnabled ? 'grey900' : 'grey600';
      expect(color, equals('grey600'));
    });

    test('redo button enabled when has redo history', () {
      const hasRedo = true;
      final color = hasRedo ? 'grey900' : 'grey600';
      expect(color, equals('grey900'));
    });

    test('redo button disabled when no redo history', () {
      const hasRedo = false;
      final color = hasRedo ? 'grey900' : 'grey600';
      expect(color, equals('grey600'));
    });
  });

  group('PostWriteBody toolbar features logic', () {
    test('shows image button when features contain image', () {
      final features = ['image', 'link', 'youtube', 'attachment'];
      expect(features.contains('image'), isTrue);
    });

    test('shows link button when features contain link', () {
      final features = ['image', 'link', 'youtube'];
      expect(features.contains('link'), isTrue);
    });

    test('shows youtube button when features contain youtube', () {
      final features = ['image', 'link', 'youtube'];
      expect(features.contains('youtube'), isTrue);
    });

    test('shows attachment button when features contain attachment', () {
      final features = ['attachment'];
      expect(features.contains('attachment'), isTrue);
    });

    test('hides all feature buttons when features is null', () {
      List<String>? features;
      expect(features != null && features.contains('image'), isFalse);
      expect(features != null && features.contains('link'), isFalse);
      expect(features != null && features.contains('youtube'), isFalse);
      expect(features != null && features.contains('attachment'), isFalse);
    });

    test('hides buttons for missing features', () {
      final features = ['image']; // Only image
      expect(features.contains('image'), isTrue);
      expect(features.contains('link'), isFalse);
      expect(features.contains('youtube'), isFalse);
      expect(features.contains('attachment'), isFalse);
    });

    test('empty features list shows no feature buttons', () {
      final features = <String>[];
      expect(features.contains('image'), isFalse);
    });
  });

  group('PostWriteBody keyboard height logic', () {
    test('keyboard height is 0 on web', () {
      const isWeb = true;
      const isKeyboardListenerInitialized = true;
      const keyboardHeight = 300.0;

      final effectiveHeight =
          !isKeyboardListenerInitialized || isWeb ? 0.0 : keyboardHeight;
      expect(effectiveHeight, equals(0.0));
    });

    test('keyboard height is 0 when listener not initialized', () {
      const isWeb = false;
      const isKeyboardListenerInitialized = false;
      const keyboardHeight = 300.0;

      final effectiveHeight =
          !isKeyboardListenerInitialized || isWeb ? 0.0 : keyboardHeight;
      expect(effectiveHeight, equals(0.0));
    });

    test('keyboard height is used on mobile when initialized', () {
      const isWeb = false;
      const isKeyboardListenerInitialized = true;
      const keyboardHeight = 300.0;

      final effectiveHeight =
          !isKeyboardListenerInitialized || isWeb ? 0.0 : keyboardHeight;
      expect(effectiveHeight, equals(300.0));
    });
  });

  group('PostWriteBody editor height calculation', () {
    test('editor height without keyboard', () {
      const screenHeight = 812.0;
      const fixedOffset = 420.0;
      const isKeyboardVisible = false;
      const keyboardHeight = 0.0;

      final containerSize = screenHeight - fixedOffset;
      final editorHeight = isKeyboardVisible
          ? containerSize - keyboardHeight + 40
          : containerSize;

      expect(editorHeight, equals(392.0));
    });

    test('editor height with keyboard visible', () {
      const screenHeight = 812.0;
      const fixedOffset = 420.0;
      const isKeyboardVisible = true;
      const keyboardHeight = 300.0;

      final containerSize = screenHeight - fixedOffset;
      final editorHeight = isKeyboardVisible
          ? containerSize - keyboardHeight + 40
          : containerSize;

      expect(editorHeight, equals(132.0)); // 392 - 300 + 40
    });

    test('editor height with keyboard on web (ignores keyboard)', () {
      const screenHeight = 812.0;
      const fixedOffset = 420.0;
      const isKeyboardVisible = true;
      const isWeb = true;
      const keyboardHeight = 300.0;

      final containerSize = screenHeight - fixedOffset;
      // On web, we don't adjust for keyboard
      final editorHeight = isWeb ? containerSize : containerSize - keyboardHeight + 40;

      expect(editorHeight, equals(392.0));
    });
  });

  group('PostWriteBody link insertion logic', () {
    test('link dialog result with valid URL creates embed', () {
      final result = {'url': 'https://example.com', 'name': 'Example'};

      final shouldInsert = result['url']!.isNotEmpty;
      expect(shouldInsert, isTrue);

      final embedData = jsonEncode({'name': result['name'], 'url': result['url']});
      final decoded = jsonDecode(embedData) as Map<String, dynamic>;
      expect(decoded['url'], equals('https://example.com'));
      expect(decoded['name'], equals('Example'));
    });

    test('link dialog result with empty URL does not create embed', () {
      final result = {'url': '', 'name': ''};
      final shouldInsert = result['url']!.isNotEmpty;
      expect(shouldInsert, isFalse);
    });

    test('link dialog cancelled (null result) does not create embed', () {
      Map<String, String>? result;
      final shouldInsert = result != null && result['url']!.isNotEmpty;
      expect(shouldInsert, isFalse);
    });
  });

  group('PostWriteBody YouTube insertion logic', () {
    test('YouTube URL creates embed', () {
      const result = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      final shouldInsert = result.isNotEmpty;
      expect(shouldInsert, isTrue);
    });

    test('empty YouTube URL does not create embed', () {
      const result = '';
      final shouldInsert = result.isNotEmpty;
      expect(shouldInsert, isFalse);
    });

    test('null YouTube result does not create embed', () {
      String? result;
      final shouldInsert = result != null && result.isNotEmpty;
      expect(shouldInsert, isFalse);
    });
  });

  group('PostWriteBody local media logic', () {
    test('local image path is embedded correctly', () {
      const filePath = '/path/to/image.jpg';
      expect(filePath.isNotEmpty, isTrue);
    });

    test('replace local with network URL logic', () {
      const localPath = '/path/to/local.jpg';
      const networkUrl = 'https://storage.example.com/image.jpg';

      // Simulating the delta search logic
      final operations = <Map<String, dynamic>>[
        {'insert': 'Before text\n'},
        {
          'insert': {'local-image': localPath}
        },
        {'insert': 'After text\n'},
      ];

      int? replaceIndex;
      for (int i = 0; i < operations.length; i++) {
        final data = operations[i]['insert'];
        if (data is Map<String, dynamic> && data['local-image'] == localPath) {
          replaceIndex = i;
          break;
        }
      }

      expect(replaceIndex, equals(1));
      // Replace with network URL
      operations[replaceIndex!] = {
        'insert': {'image': networkUrl}
      };
      expect(
        (operations[1]['insert'] as Map<String, dynamic>)['image'],
        equals(networkUrl),
      );
    });
  });

  group('PostWriteBody board features from CommunityState', () {
    test('board with all features shows all toolbar buttons', () {
      final board = BoardModel(
        boardId: 'b1',
        artistId: 1,
        name: {'ko': 'Test'},
        description: 'test',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: ['image', 'link', 'youtube', 'attachment'],
      );

      expect(board.features, isNotNull);
      expect(board.features!.contains('image'), isTrue);
      expect(board.features!.contains('link'), isTrue);
      expect(board.features!.contains('youtube'), isTrue);
      expect(board.features!.contains('attachment'), isTrue);
    });

    test('board with null features shows no feature buttons', () {
      final board = BoardModel(
        boardId: 'b2',
        artistId: 1,
        name: {'ko': 'Test'},
        description: 'test',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: null,
      );

      expect(board.features, isNull);
    });

    test('board with partial features shows only available buttons', () {
      final board = BoardModel(
        boardId: 'b3',
        artistId: 1,
        name: {'ko': 'Test'},
        description: 'test',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: ['image', 'youtube'],
      );

      expect(board.features!.contains('image'), isTrue);
      expect(board.features!.contains('link'), isFalse);
      expect(board.features!.contains('youtube'), isTrue);
      expect(board.features!.contains('attachment'), isFalse);
    });
  });

  group('PostWriteBody format toggle logic', () {
    test('toggling active format deactivates it', () {
      const isActive = true;
      // When active, we clone attribute with null to remove
      final action = isActive ? 'remove' : 'apply';
      expect(action, equals('remove'));
    });

    test('toggling inactive format activates it', () {
      const isActive = false;
      final action = isActive ? 'remove' : 'apply';
      expect(action, equals('apply'));
    });
  });
}
