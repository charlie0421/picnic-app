import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/write/post_write_body_helper.dart';

void main() {
  // ---------------------------------------------------------------------------
  // isTitleValid
  // ---------------------------------------------------------------------------
  group('PostWriteBodyHelper.isTitleValid', () {
    test('returns false for empty string', () {
      expect(PostWriteBodyHelper.isTitleValid(''), isFalse);
    });

    test('returns false for whitespace-only string', () {
      expect(PostWriteBodyHelper.isTitleValid('   '), isFalse);
    });

    test('returns false for tab-only string', () {
      expect(PostWriteBodyHelper.isTitleValid('\t\t'), isFalse);
    });

    test('returns false for newline-only string', () {
      expect(PostWriteBodyHelper.isTitleValid('\n'), isFalse);
    });

    test('returns true for non-empty string', () {
      expect(PostWriteBodyHelper.isTitleValid('Hello'), isTrue);
    });

    test('returns true for string with surrounding whitespace', () {
      expect(PostWriteBodyHelper.isTitleValid('  Title  '), isTrue);
    });

    test('returns true for single character', () {
      expect(PostWriteBodyHelper.isTitleValid('A'), isTrue);
    });

    test('returns true for Korean characters', () {
      expect(PostWriteBodyHelper.isTitleValid('제목입니다'), isTrue);
    });

    test('returns true for emoji', () {
      expect(PostWriteBodyHelper.isTitleValid('🎉'), isTrue);
    });

    test('returns true for numeric string', () {
      expect(PostWriteBodyHelper.isTitleValid('123'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // calculateEditorHeight
  // ---------------------------------------------------------------------------
  group('PostWriteBodyHelper.calculateEditorHeight', () {
    test('returns screenHeight - 420 when on web', () {
      final height = PostWriteBodyHelper.calculateEditorHeight(
        screenHeight: 800,
        keyboardHeight: 300,
        isKeyboardVisible: true,
        isWeb: true,
      );
      expect(height, 380); // 800 - 420
    });

    test('returns screenHeight - 420 when keyboard is not visible', () {
      final height = PostWriteBodyHelper.calculateEditorHeight(
        screenHeight: 800,
        keyboardHeight: 300,
        isKeyboardVisible: false,
        isWeb: false,
      );
      expect(height, 380);
    });

    test('subtracts keyboard height with +40 offset on native when keyboard visible', () {
      final height = PostWriteBodyHelper.calculateEditorHeight(
        screenHeight: 800,
        keyboardHeight: 250,
        isKeyboardVisible: true,
        isWeb: false,
      );
      // (800 - 420) - 250 + 40 = 170
      expect(height, 170);
    });

    test('handles zero keyboard height on native with keyboard visible', () {
      final height = PostWriteBodyHelper.calculateEditorHeight(
        screenHeight: 800,
        keyboardHeight: 0,
        isKeyboardVisible: true,
        isWeb: false,
      );
      // (800 - 420) - 0 + 40 = 420
      expect(height, 420);
    });

    test('handles large keyboard height that would produce negative', () {
      final height = PostWriteBodyHelper.calculateEditorHeight(
        screenHeight: 500,
        keyboardHeight: 400,
        isKeyboardVisible: true,
        isWeb: false,
      );
      // (500 - 420) - 400 + 40 = -280
      expect(height, -280);
    });
  });

  // ---------------------------------------------------------------------------
  // isBoardFeatureEnabled
  // ---------------------------------------------------------------------------
  group('PostWriteBodyHelper.isBoardFeatureEnabled', () {
    test('returns false when features list is null', () {
      expect(PostWriteBodyHelper.isBoardFeatureEnabled(null, 'image'), isFalse);
    });

    test('returns false when features list is empty', () {
      expect(PostWriteBodyHelper.isBoardFeatureEnabled([], 'image'), isFalse);
    });

    test('returns false when feature is not in the list', () {
      expect(
        PostWriteBodyHelper.isBoardFeatureEnabled(['link', 'youtube'], 'image'),
        isFalse,
      );
    });

    test('returns true when feature is in the list', () {
      expect(
        PostWriteBodyHelper.isBoardFeatureEnabled(
            ['image', 'link', 'youtube'], 'image'),
        isTrue,
      );
    });

    test('returns true for each supported feature type', () {
      final features = ['image', 'link', 'youtube', 'attachment'];
      for (final f in features) {
        expect(
          PostWriteBodyHelper.isBoardFeatureEnabled(features, f),
          isTrue,
          reason: 'Expected $f to be enabled',
        );
      }
    });

    test('is case-sensitive', () {
      expect(
        PostWriteBodyHelper.isBoardFeatureEnabled(['Image'], 'image'),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // encodeLinkEmbedData
  // ---------------------------------------------------------------------------
  group('PostWriteBodyHelper.encodeLinkEmbedData', () {
    test('returns null when url is null', () {
      expect(PostWriteBodyHelper.encodeLinkEmbedData(url: null), isNull);
    });

    test('returns null when url is empty', () {
      expect(PostWriteBodyHelper.encodeLinkEmbedData(url: ''), isNull);
    });

    test('encodes valid url with name', () {
      final result = PostWriteBodyHelper.encodeLinkEmbedData(
        name: 'Google',
        url: 'https://google.com',
      );
      expect(result, isNotNull);
      final decoded = jsonDecode(result!) as Map<String, dynamic>;
      expect(decoded['name'], 'Google');
      expect(decoded['url'], 'https://google.com');
    });

    test('encodes valid url with null name', () {
      final result = PostWriteBodyHelper.encodeLinkEmbedData(
        url: 'https://example.com',
      );
      expect(result, isNotNull);
      final decoded = jsonDecode(result!) as Map<String, dynamic>;
      expect(decoded['name'], isNull);
      expect(decoded['url'], 'https://example.com');
    });

    test('encodes url with special characters', () {
      final result = PostWriteBodyHelper.encodeLinkEmbedData(
        name: 'Search',
        url: 'https://example.com/search?q=hello&lang=ko',
      );
      expect(result, isNotNull);
      final decoded = jsonDecode(result!) as Map<String, dynamic>;
      expect(decoded['url'], 'https://example.com/search?q=hello&lang=ko');
    });
  });

  // ---------------------------------------------------------------------------
  // isYouTubeResultValid
  // ---------------------------------------------------------------------------
  group('PostWriteBodyHelper.isYouTubeResultValid', () {
    test('returns false for null', () {
      expect(PostWriteBodyHelper.isYouTubeResultValid(null), isFalse);
    });

    test('returns false for empty string', () {
      expect(PostWriteBodyHelper.isYouTubeResultValid(''), isFalse);
    });

    test('returns true for non-empty string', () {
      expect(
        PostWriteBodyHelper.isYouTubeResultValid(
            'https://youtube.com/watch?v=abc'),
        isTrue,
      );
    });

    test('returns true for whitespace-only string (not trimmed)', () {
      // The method only checks isNotEmpty, not trim
      expect(PostWriteBodyHelper.isYouTubeResultValid('  '), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // isLinkResultValid
  // ---------------------------------------------------------------------------
  group('PostWriteBodyHelper.isLinkResultValid', () {
    test('returns false for null', () {
      expect(PostWriteBodyHelper.isLinkResultValid(null), isFalse);
    });

    test('returns false when url key is missing', () {
      expect(PostWriteBodyHelper.isLinkResultValid({'name': 'test'}), isFalse);
    });

    test('returns false when url is empty', () {
      expect(
        PostWriteBodyHelper.isLinkResultValid({'url': ''}),
        isFalse,
      );
    });

    test('returns true when url is non-empty', () {
      expect(
        PostWriteBodyHelper.isLinkResultValid(
            {'url': 'https://example.com', 'name': 'Example'}),
        isTrue,
      );
    });

    test('returns true when url is present but name is missing', () {
      expect(
        PostWriteBodyHelper.isLinkResultValid({'url': 'https://example.com'}),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // findLocalImageIndex
  // ---------------------------------------------------------------------------
  group('PostWriteBodyHelper.findLocalImageIndex', () {
    test('returns -1 for empty list', () {
      expect(PostWriteBodyHelper.findLocalImageIndex([], '/path/img.png'), -1);
    });

    test('returns -1 when no match found', () {
      final ops = [
        {
          'data': {'local-image': '/other/path.png'}
        },
        {
          'data': 'plain text'
        },
      ];
      expect(
        PostWriteBodyHelper.findLocalImageIndex(ops, '/path/img.png'),
        -1,
      );
    });

    test('returns correct index when match found', () {
      final ops = [
        {
          'data': 'text'
        },
        {
          'data': {'local-image': '/path/img.png'}
        },
        {
          'data': 'more text'
        },
      ];
      expect(
        PostWriteBodyHelper.findLocalImageIndex(ops, '/path/img.png'),
        1,
      );
    });

    test('returns first match index when multiple matches exist', () {
      final ops = [
        {
          'data': {'local-image': '/path/img.png'}
        },
        {
          'data': {'local-image': '/path/img.png'}
        },
      ];
      expect(
        PostWriteBodyHelper.findLocalImageIndex(ops, '/path/img.png'),
        0,
      );
    });

    test('ignores non-map data entries', () {
      final ops = [
        {'data': 'string data'},
        {'data': 42},
        {
          'data': {'local-image': '/path/img.png'}
        },
      ];
      expect(
        PostWriteBodyHelper.findLocalImageIndex(ops, '/path/img.png'),
        2,
      );
    });

    test('ignores map data without local-image key', () {
      final ops = [
        {
          'data': {'image': '/path/img.png'}
        },
        {
          'data': {'local-image': '/path/img.png'}
        },
      ];
      expect(
        PostWriteBodyHelper.findLocalImageIndex(ops, '/path/img.png'),
        1,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // effectiveKeyboardHeight
  // ---------------------------------------------------------------------------
  group('PostWriteBodyHelper.effectiveKeyboardHeight', () {
    test('returns 0 when listener not initialized', () {
      expect(
        PostWriteBodyHelper.effectiveKeyboardHeight(
          isListenerInitialized: false,
          isWeb: false,
          rawHeight: 300,
        ),
        0,
      );
    });

    test('returns 0 on web regardless of listener state', () {
      expect(
        PostWriteBodyHelper.effectiveKeyboardHeight(
          isListenerInitialized: true,
          isWeb: true,
          rawHeight: 300,
        ),
        0,
      );
    });

    test('returns raw height when listener initialized and not web', () {
      expect(
        PostWriteBodyHelper.effectiveKeyboardHeight(
          isListenerInitialized: true,
          isWeb: false,
          rawHeight: 250,
        ),
        250,
      );
    });

    test('returns 0 when both not initialized and on web', () {
      expect(
        PostWriteBodyHelper.effectiveKeyboardHeight(
          isListenerInitialized: false,
          isWeb: true,
          rawHeight: 300,
        ),
        0,
      );
    });

    test('returns 0.0 raw height correctly', () {
      expect(
        PostWriteBodyHelper.effectiveKeyboardHeight(
          isListenerInitialized: true,
          isWeb: false,
          rawHeight: 0,
        ),
        0,
      );
    });
  });
}
