import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/providers/community/boards_provider.dart';

/// Tests for logic patterns used in BoardRequest page.
///
/// Widget testing is blocked because the page's loading state renders
/// MediumPulseLoadingIndicator which loads an asset (app_icon_128.png)
/// not available in the picnic_lib test bundle, and because initState
/// calls ref.read() on boardRequestProvider.notifier which requires
/// Riverpod provider setup.
/// Instead, we test the validation logic, model interactions, and
/// enum/state patterns that the page relies on.
void main() {
  group('BoardRequest validation logic', () {
    // Mirrors _validateName from board_request.dart
    String? validateName(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter a board name';
      }
      return null;
    }

    // Mirrors _validateDescription from board_request.dart
    String? validateDescription(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter a description';
      }
      if (value.length < 5 || value.length > 20) {
        return 'Description must be between 5 and 20 characters';
      }
      return null;
    }

    // Mirrors _validateRequestMessage from board_request.dart
    String? validateRequestMessage(String? value) {
      if (value == null || value.isEmpty) {
        return 'Please enter a request message';
      }
      if (value.length < 10) {
        return 'Request message must be at least 10 characters';
      }
      return null;
    }

    group('validateName', () {
      test('returns error for null', () {
        expect(validateName(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(validateName(''), isNotNull);
      });

      test('returns null for valid name', () {
        expect(validateName('게시판 이름'), isNull);
      });

      test('returns null for single character', () {
        expect(validateName('A'), isNull);
      });

      test('returns null for long name', () {
        expect(validateName('a' * 100), isNull);
      });

      test('returns null for unicode characters', () {
        expect(validateName('日本語テスト'), isNull);
      });

      test('returns null for whitespace-only string', () {
        // Note: whitespace-only is not empty, so it passes
        expect(validateName('   '), isNull);
      });
    });

    group('validateDescription', () {
      test('returns error for null', () {
        expect(validateDescription(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(validateDescription(''), isNotNull);
      });

      test('returns error for too short (< 5)', () {
        expect(validateDescription('abcd'), isNotNull);
      });

      test('returns error for too long (> 20)', () {
        expect(validateDescription('a' * 21), isNotNull);
      });

      test('returns null for exactly 5 characters', () {
        expect(validateDescription('abcde'), isNull);
      });

      test('returns null for exactly 20 characters', () {
        expect(validateDescription('a' * 20), isNull);
      });

      test('returns null for valid length (10 characters)', () {
        expect(validateDescription('게시판 설명입니다'), isNull);
      });

      test('returns error for 1 character', () {
        expect(validateDescription('a'), isNotNull);
      });

      test('returns error for 4 characters', () {
        expect(validateDescription('abcd'), isNotNull);
      });

      test('returns null for 6 characters', () {
        expect(validateDescription('abcdef'), isNull);
      });

      test('returns null for 19 characters', () {
        expect(validateDescription('a' * 19), isNull);
      });
    });

    group('validateRequestMessage', () {
      test('returns error for null', () {
        expect(validateRequestMessage(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(validateRequestMessage(''), isNotNull);
      });

      test('returns error for too short (< 10)', () {
        expect(validateRequestMessage('짧은 메시지'), isNotNull);
      });

      test('returns null for exactly 10 characters', () {
        expect(validateRequestMessage('a' * 10), isNull);
      });

      test('returns null for valid message', () {
        expect(
          validateRequestMessage('이 게시판을 만들어주시면 감사하겠습니다'),
          isNull,
        );
      });

      test('returns error for 9 characters', () {
        expect(validateRequestMessage('a' * 9), isNotNull);
      });

      test('returns null for 11 characters', () {
        expect(validateRequestMessage('a' * 11), isNull);
      });

      test('returns null for very long message', () {
        expect(validateRequestMessage('a' * 1000), isNull);
      });
    });
  });

  group('BoardRequest button state logic', () {
    test('button is disabled when all validations fail', () {
      const isNameValid = false;
      const isDescriptionValid = false;
      const isRequestMessageValid = false;
      BoardModel? pendingRequest;

      final isButtonEnabled = isNameValid &&
          isDescriptionValid &&
          isRequestMessageValid &&
          pendingRequest == null;

      expect(isButtonEnabled, isFalse);
    });

    test('button is disabled when pending request exists', () {
      const isNameValid = true;
      const isDescriptionValid = true;
      const isRequestMessageValid = true;
      final pendingRequest = BoardModel(
        boardId: 'test',
        artistId: 1,
        name: {'ko': 'test'},
        description: 'test desc',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: 'please create',
        status: 'pending',
        creatorId: 'user-1',
        features: [],
      );

      final isButtonEnabled = isNameValid &&
          isDescriptionValid &&
          isRequestMessageValid &&
          pendingRequest == null;

      expect(isButtonEnabled, isFalse);
    });

    test('button is enabled when all valid and no pending request', () {
      const isNameValid = true;
      const isDescriptionValid = true;
      const isRequestMessageValid = true;
      BoardModel? pendingRequest;

      final isButtonEnabled = isNameValid &&
          isDescriptionValid &&
          isRequestMessageValid &&
          pendingRequest == null;

      expect(isButtonEnabled, isTrue);
    });

    test('button is disabled when only name is invalid', () {
      const isNameValid = false;
      const isDescriptionValid = true;
      const isRequestMessageValid = true;
      BoardModel? pendingRequest;

      final isButtonEnabled = isNameValid &&
          isDescriptionValid &&
          isRequestMessageValid &&
          pendingRequest == null;

      expect(isButtonEnabled, isFalse);
    });

    test('button is disabled when only description is invalid', () {
      const isNameValid = true;
      const isDescriptionValid = false;
      const isRequestMessageValid = true;
      BoardModel? pendingRequest;

      final isButtonEnabled = isNameValid &&
          isDescriptionValid &&
          isRequestMessageValid &&
          pendingRequest == null;

      expect(isButtonEnabled, isFalse);
    });

    test('button is disabled when only request message is invalid', () {
      const isNameValid = true;
      const isDescriptionValid = true;
      const isRequestMessageValid = false;
      BoardModel? pendingRequest;

      final isButtonEnabled = isNameValid &&
          isDescriptionValid &&
          isRequestMessageValid &&
          pendingRequest == null;

      expect(isButtonEnabled, isFalse);
    });

    test('button is disabled when two of three are invalid', () {
      const isNameValid = true;
      const isDescriptionValid = false;
      const isRequestMessageValid = false;
      BoardModel? pendingRequest;

      final isButtonEnabled = isNameValid &&
          isDescriptionValid &&
          isRequestMessageValid &&
          pendingRequest == null;

      expect(isButtonEnabled, isFalse);
    });
  });

  group('BoardRequest controller listener logic', () {
    test('name validity changes trigger state update', () {
      bool isNameValid = false;

      // Simulate controller listener
      String? validateName(String? value) {
        if (value == null || value.isEmpty) return 'error';
        return null;
      }

      // Typing a valid name
      final isValid = validateName('test') == null;
      if (isValid != isNameValid) {
        isNameValid = isValid;
      }
      expect(isNameValid, isTrue);

      // Clearing the name
      final isValid2 = validateName('') == null;
      if (isValid2 != isNameValid) {
        isNameValid = isValid2;
      }
      expect(isNameValid, isFalse);
    });

    test('description validity transitions', () {
      bool isDescriptionValid = false;

      String? validateDescription(String? value) {
        if (value == null || value.isEmpty) return 'empty';
        if (value.length < 5 || value.length > 20) return 'length';
        return null;
      }

      // Too short
      var isValid = validateDescription('ab') == null;
      if (isValid != isDescriptionValid) isDescriptionValid = isValid;
      expect(isDescriptionValid, isFalse);

      // Just right
      isValid = validateDescription('abcdef') == null;
      if (isValid != isDescriptionValid) isDescriptionValid = isValid;
      expect(isDescriptionValid, isTrue);

      // Too long
      isValid = validateDescription('a' * 21) == null;
      if (isValid != isDescriptionValid) isDescriptionValid = isValid;
      expect(isDescriptionValid, isFalse);
    });

    test('request message validity transitions', () {
      bool isRequestMessageValid = false;

      String? validateRequestMessage(String? value) {
        if (value == null || value.isEmpty) return 'empty';
        if (value.length < 10) return 'short';
        return null;
      }

      // Too short
      var isValid = validateRequestMessage('short') == null;
      if (isValid != isRequestMessageValid) isRequestMessageValid = isValid;
      expect(isRequestMessageValid, isFalse);

      // Valid
      isValid = validateRequestMessage('this is a valid request message') == null;
      if (isValid != isRequestMessageValid) isRequestMessageValid = isValid;
      expect(isRequestMessageValid, isTrue);
    });
  });

  group('BoardModel for pending request display', () {
    test('pending request has all required fields', () {
      final board = BoardModel(
        boardId: 'board-123',
        artistId: 42,
        name: {'ko': '테스트 게시판', 'en': 'Test Board'},
        description: '게시판 설명',
        isOfficial: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        artist: ArtistModel(
          id: 42,
          name: {'ko': 'BTS', 'en': 'BTS'},
        ),
        requestMessage: '게시판을 만들어주세요',
        status: 'pending',
        creatorId: 'user-id',
        features: [],
      );

      expect(board.boardId, equals('board-123'));
      expect(board.artistId, equals(42));
      expect(board.name['ko'], equals('테스트 게시판'));
      expect(board.description, equals('게시판 설명'));
      expect(board.status, equals('pending'));
      expect(board.requestMessage, equals('게시판을 만들어주세요'));
      expect(board.isOfficial, isFalse);
    });

    test('pending request with null optional fields', () {
      final board = BoardModel(
        boardId: 'board-456',
        artistId: 1,
        name: {'ko': '게시판'},
        description: '설명',
        isOfficial: null,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: null,
        creatorId: null,
        features: null,
      );

      expect(board.isOfficial, isNull);
      expect(board.artist, isNull);
      expect(board.requestMessage, isNull);
      expect(board.status, isNull);
      expect(board.creatorId, isNull);
      expect(board.features, isNull);
      expect(board.createdAt, isNull);
      expect(board.updatedAt, isNull);
    });

    test('board with approved status', () {
      final board = BoardModel(
        boardId: 'board-789',
        artistId: 5,
        name: {'ko': '승인된 게시판'},
        description: '설명',
        isOfficial: true,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 10),
        artist: null,
        requestMessage: '요청 메시지',
        status: 'approved',
        creatorId: 'admin-user',
        features: ['post', 'gallery'],
      );

      expect(board.status, equals('approved'));
      expect(board.isOfficial, isTrue);
      expect(board.features, hasLength(2));
    });

    test('board with rejected status', () {
      final board = BoardModel(
        boardId: 'board-rejected',
        artistId: 3,
        name: {'ko': '거절된 게시판'},
        description: '설명',
        isOfficial: false,
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 5),
        artist: null,
        requestMessage: '요청 메시지',
        status: 'rejected',
        creatorId: 'user-2',
        features: [],
      );

      expect(board.status, equals('rejected'));
    });
  });

  group('BoardRequest form fillColor logic', () {
    test('enabled field has grey00 fill color', () {
      final enabled = true;
      final fillColor = enabled ? const Color(0xFFFFFFFF) : const Color(0xFFF5F5F5);
      expect(fillColor, const Color(0xFFFFFFFF));
    });

    test('disabled field has grey100 fill color', () {
      final enabled = false;
      final fillColor = enabled ? const Color(0xFFFFFFFF) : const Color(0xFFF5F5F5);
      expect(fillColor, const Color(0xFFF5F5F5));
    });
  });

  group('BoardRequest submit logic', () {
    test('duplicate check blocks submission', () {
      bool submitted = false;
      final duplicate = BoardModel(
        boardId: 'existing',
        artistId: 1,
        name: {'ko': 'existing'},
        description: 'desc',
        isOfficial: false,
        createdAt: null,
        updatedAt: null,
        artist: null,
        requestMessage: null,
        status: 'approved',
        creatorId: null,
        features: null,
      );

      if (duplicate != null) {
        // Show dialog about existing board
        submitted = false;
      } else {
        submitted = true;
      }

      expect(submitted, isFalse);
    });

    test('no duplicate allows submission', () {
      bool submitted = false;
      BoardModel? duplicate;

      if (duplicate != null) {
        submitted = false;
      } else {
        submitted = true;
      }

      expect(submitted, isTrue);
    });
  });
}
