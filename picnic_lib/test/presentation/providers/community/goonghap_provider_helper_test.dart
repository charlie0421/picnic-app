import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_provider.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_provider_helper.dart';

void main() {
  group('GoonghapProviderHelper.shouldSkipSetGoonghap', () {
    test('returns true when isLoading is true', () {
      expect(
        GoonghapProviderHelper.shouldSkipSetGoonghap(
          isLoading: true,
          hasValue: false,
          currentId: null,
          incomingId: 'id-1',
        ),
        true,
      );
    });

    test('returns true when hasValue and same id', () {
      expect(
        GoonghapProviderHelper.shouldSkipSetGoonghap(
          isLoading: false,
          hasValue: true,
          currentId: 'id-1',
          incomingId: 'id-1',
        ),
        true,
      );
    });

    test('returns false when hasValue but different id', () {
      expect(
        GoonghapProviderHelper.shouldSkipSetGoonghap(
          isLoading: false,
          hasValue: true,
          currentId: 'id-1',
          incomingId: 'id-2',
        ),
        false,
      );
    });

    test('returns false when not loading and no value', () {
      expect(
        GoonghapProviderHelper.shouldSkipSetGoonghap(
          isLoading: false,
          hasValue: false,
          currentId: null,
          incomingId: 'id-1',
        ),
        false,
      );
    });

    test('returns true when loading even with different id', () {
      expect(
        GoonghapProviderHelper.shouldSkipSetGoonghap(
          isLoading: true,
          hasValue: true,
          currentId: 'id-1',
          incomingId: 'id-2',
        ),
        true,
      );
    });

    test('returns false when hasValue is false and currentId is null', () {
      expect(
        GoonghapProviderHelper.shouldSkipSetGoonghap(
          isLoading: false,
          hasValue: false,
          currentId: null,
          incomingId: 'any-id',
        ),
        false,
      );
    });
  });

  group('GoonghapProviderHelper.shouldSkipLoadGoonghap', () {
    test('returns true when isLoading', () {
      expect(
        GoonghapProviderHelper.shouldSkipLoadGoonghap(
          isLoading: true,
          hasValue: false,
          currentId: null,
          requestedId: 'id-1',
          forceRefresh: false,
        ),
        true,
      );
    });

    test('returns true when same id and not forceRefresh', () {
      expect(
        GoonghapProviderHelper.shouldSkipLoadGoonghap(
          isLoading: false,
          hasValue: true,
          currentId: 'id-1',
          requestedId: 'id-1',
          forceRefresh: false,
        ),
        true,
      );
    });

    test('returns false when same id but forceRefresh is true', () {
      expect(
        GoonghapProviderHelper.shouldSkipLoadGoonghap(
          isLoading: false,
          hasValue: true,
          currentId: 'id-1',
          requestedId: 'id-1',
          forceRefresh: true,
        ),
        false,
      );
    });

    test('returns false when different id', () {
      expect(
        GoonghapProviderHelper.shouldSkipLoadGoonghap(
          isLoading: false,
          hasValue: true,
          currentId: 'id-1',
          requestedId: 'id-2',
          forceRefresh: false,
        ),
        false,
      );
    });

    test('returns false when no current value', () {
      expect(
        GoonghapProviderHelper.shouldSkipLoadGoonghap(
          isLoading: false,
          hasValue: false,
          currentId: null,
          requestedId: 'id-1',
          forceRefresh: false,
        ),
        false,
      );
    });

    test('returns true when loading even with forceRefresh', () {
      expect(
        GoonghapProviderHelper.shouldSkipLoadGoonghap(
          isLoading: true,
          hasValue: true,
          currentId: 'id-1',
          requestedId: 'id-1',
          forceRefresh: true,
        ),
        true,
      );
    });
  });

  group('GoonghapProviderHelper.validateCreateGoonghapInput', () {
    test('returns notAuthenticated when userId is null', () {
      expect(
        GoonghapProviderHelper.validateCreateGoonghapInput(
          userId: null,
          artistBirthDate: DateTime(1995, 10, 13),
        ),
        CreateGoonghapValidationError.notAuthenticated,
      );
    });

    test('returns missingArtistBirthDate when artistBirthDate is null', () {
      expect(
        GoonghapProviderHelper.validateCreateGoonghapInput(
          userId: 'user-123',
          artistBirthDate: null,
        ),
        CreateGoonghapValidationError.missingArtistBirthDate,
      );
    });

    test('returns null when all inputs are valid', () {
      expect(
        GoonghapProviderHelper.validateCreateGoonghapInput(
          userId: 'user-123',
          artistBirthDate: DateTime(1995, 10, 13),
        ),
        isNull,
      );
    });

    test('prioritizes notAuthenticated over missingArtistBirthDate', () {
      expect(
        GoonghapProviderHelper.validateCreateGoonghapInput(
          userId: null,
          artistBirthDate: null,
        ),
        CreateGoonghapValidationError.notAuthenticated,
      );
    });
  });

  group('GoonghapProviderHelper.buildCreateGoonghapData', () {
    test('builds correct data map', () {
      final artist = ArtistModel(
        id: 1,
        name: {'ko': '지민', 'en': 'Jimin'},
        birthDateRaw: DateTime(1995, 10, 13),
      );

      final result = GoonghapProviderHelper.buildCreateGoonghapData(
        userId: 'user-123',
        artist: artist,
        birthDate: DateTime(2000, 1, 1),
        gender: 'female',
      );

      expect(result['user_id'], 'user-123');
      expect(result['artist_id'], 1);
      expect(result['idol_birth_date'], contains('1995'));
      expect(result['user_birth_date'], contains('2000'));
      expect(result['user_birth_time'], isNull);
      expect(result['gender'], 'female');
      expect(result['status'], 'pending');
      expect(result['is_paid'], false);
    });

    test('includes birthTime when provided', () {
      final artist = ArtistModel(
        id: 1,
        name: {'ko': '지민'},
        birthDateRaw: DateTime(1995, 10, 13),
      );

      final result = GoonghapProviderHelper.buildCreateGoonghapData(
        userId: 'user-123',
        artist: artist,
        birthDate: DateTime(2000, 1, 1),
        gender: 'male',
        birthTime: '14:30',
      );

      expect(result['user_birth_time'], '14:30');
    });

    test('sets status to pending and is_paid to false', () {
      final artist = ArtistModel(
        id: 2,
        name: {'en': 'Test'},
        birthDateRaw: DateTime(1990, 5, 15),
      );

      final result = GoonghapProviderHelper.buildCreateGoonghapData(
        userId: 'user-456',
        artist: artist,
        birthDate: DateTime(1998, 3, 20),
        gender: 'male',
      );

      expect(result['status'], 'pending');
      expect(result['is_paid'], false);
    });
  });

  group('GoonghapProviderHelper.buildRetryExhaustedErrorMessage', () {
    test('builds correct message with error details', () {
      final msg = GoonghapProviderHelper.buildRetryExhaustedErrorMessage(
        maxRetries: 3,
        lastErrorMessage: 'Connection timeout',
      );

      expect(msg, 'Failed after 3 attempts: Connection timeout');
    });

    test('handles null lastErrorMessage', () {
      final msg = GoonghapProviderHelper.buildRetryExhaustedErrorMessage(
        maxRetries: 5,
        lastErrorMessage: null,
      );

      expect(msg, 'Failed after 5 attempts: null');
    });

    test('handles empty lastErrorMessage', () {
      final msg = GoonghapProviderHelper.buildRetryExhaustedErrorMessage(
        maxRetries: 3,
        lastErrorMessage: '',
      );

      expect(msg, 'Failed after 3 attempts: ');
    });
  });

  group('GoonghapProviderHelper.shouldTurnOffLoading', () {
    test('returns true for completed status', () {
      expect(
        GoonghapProviderHelper.shouldTurnOffLoading(GoonghapStatus.completed),
        true,
      );
    });

    test('returns true for error status', () {
      expect(
        GoonghapProviderHelper.shouldTurnOffLoading(GoonghapStatus.error),
        true,
      );
    });

    test('returns false for pending status', () {
      expect(
        GoonghapProviderHelper.shouldTurnOffLoading(GoonghapStatus.pending),
        false,
      );
    });

    test('returns true for input status', () {
      expect(
        GoonghapProviderHelper.shouldTurnOffLoading(GoonghapStatus.input),
        true,
      );
    });
  });

  group('GoonghapProviderHelper.isAlreadyPaidInState', () {
    test('returns true when hasValue, same id, and isPaid', () {
      expect(
        GoonghapProviderHelper.isAlreadyPaidInState(
          hasValue: true,
          currentId: 'goonghap-1',
          isPaid: true,
          goonghapId: 'goonghap-1',
        ),
        true,
      );
    });

    test('returns false when different id', () {
      expect(
        GoonghapProviderHelper.isAlreadyPaidInState(
          hasValue: true,
          currentId: 'goonghap-1',
          isPaid: true,
          goonghapId: 'goonghap-2',
        ),
        false,
      );
    });

    test('returns false when not paid', () {
      expect(
        GoonghapProviderHelper.isAlreadyPaidInState(
          hasValue: true,
          currentId: 'goonghap-1',
          isPaid: false,
          goonghapId: 'goonghap-1',
        ),
        false,
      );
    });

    test('returns false when no value', () {
      expect(
        GoonghapProviderHelper.isAlreadyPaidInState(
          hasValue: false,
          currentId: null,
          isPaid: null,
          goonghapId: 'goonghap-1',
        ),
        false,
      );
    });

    test('returns false when isPaid is null', () {
      expect(
        GoonghapProviderHelper.isAlreadyPaidInState(
          hasValue: true,
          currentId: 'goonghap-1',
          isPaid: null,
          goonghapId: 'goonghap-1',
        ),
        false,
      );
    });
  });

  group('GoonghapProviderHelper.parseOpenGoonghapError', () {
    test('returns insufficientBalance for PAYMENT_FAILED with 부족', () {
      expect(
        GoonghapProviderHelper.parseOpenGoonghapError({
          'code': 'PAYMENT_FAILED',
          'message': '별사탕이 부족합니다',
        }),
        OpenGoonghapResult.insufficientBalance,
      );
    });

    test('returns insufficientBalance for PAYMENT_FAILED with insufficient',
        () {
      expect(
        GoonghapProviderHelper.parseOpenGoonghapError({
          'code': 'PAYMENT_FAILED',
          'message': 'insufficient balance',
        }),
        OpenGoonghapResult.insufficientBalance,
      );
    });

    test('returns error for PAYMENT_FAILED without balance keywords', () {
      expect(
        GoonghapProviderHelper.parseOpenGoonghapError({
          'code': 'PAYMENT_FAILED',
          'message': 'Unknown payment error',
        }),
        OpenGoonghapResult.error,
      );
    });

    test('returns error for non-PAYMENT_FAILED code', () {
      expect(
        GoonghapProviderHelper.parseOpenGoonghapError({
          'code': 'SERVER_ERROR',
          'message': 'Internal server error',
        }),
        OpenGoonghapResult.error,
      );
    });

    test('returns error for null error data', () {
      expect(
        GoonghapProviderHelper.parseOpenGoonghapError(null),
        OpenGoonghapResult.error,
      );
    });

    test('returns error for empty error data', () {
      expect(
        GoonghapProviderHelper.parseOpenGoonghapError({}),
        OpenGoonghapResult.error,
      );
    });

    test('returns error when code is null', () {
      expect(
        GoonghapProviderHelper.parseOpenGoonghapError({
          'message': '부족합니다',
        }),
        OpenGoonghapResult.error,
      );
    });

    test('returns error for PAYMENT_FAILED with null message', () {
      expect(
        GoonghapProviderHelper.parseOpenGoonghapError({
          'code': 'PAYMENT_FAILED',
        }),
        OpenGoonghapResult.error,
      );
    });
  });

  group('GoonghapProviderHelper.determineOpenGoonghapResult', () {
    test('returns alreadyPaid when alreadyPaid is true', () {
      expect(
        GoonghapProviderHelper.determineOpenGoonghapResult(
            {'alreadyPaid': true}),
        OpenGoonghapResult.alreadyPaid,
      );
    });

    test('returns success when alreadyPaid is false', () {
      expect(
        GoonghapProviderHelper.determineOpenGoonghapResult(
            {'alreadyPaid': false}),
        OpenGoonghapResult.success,
      );
    });

    test('returns success when alreadyPaid is not present', () {
      expect(
        GoonghapProviderHelper.determineOpenGoonghapResult({}),
        OpenGoonghapResult.success,
      );
    });

    test('returns success for null response data', () {
      expect(
        GoonghapProviderHelper.determineOpenGoonghapResult(null),
        OpenGoonghapResult.success,
      );
    });

    test('returns success when alreadyPaid is non-boolean', () {
      expect(
        GoonghapProviderHelper.determineOpenGoonghapResult(
            {'alreadyPaid': 'yes'}),
        OpenGoonghapResult.success,
      );
    });
  });

  group('GoonghapProviderHelper.mergeResponseWithI18n', () {
    test('merges i18n data into response', () {
      final result = GoonghapProviderHelper.mergeResponseWithI18n(
        mainResponse: {'id': '1', 'status': 'pending'},
        i18nData: [
          {'language': 'ko', 'score': 85}
        ],
      );

      expect(result['id'], '1');
      expect(result['status'], 'pending');
      expect(result['i18n'], isA<List>());
      expect((result['i18n'] as List).length, 1);
    });

    test('overrides status to error when completed but no i18n data', () {
      final result = GoonghapProviderHelper.mergeResponseWithI18n(
        mainResponse: {'id': '1', 'status': 'completed'},
        i18nData: [],
      );

      expect(result['status'], 'error');
      expect(result['error_message'], 'No results found');
      expect(result['i18n'], isEmpty);
    });

    test('keeps completed status when i18n data is present', () {
      final result = GoonghapProviderHelper.mergeResponseWithI18n(
        mainResponse: {'id': '1', 'status': 'completed'},
        i18nData: [
          {'language': 'ko', 'score': 90}
        ],
      );

      expect(result['status'], 'completed');
      expect(result['error_message'], isNull);
    });

    test('does not modify original mainResponse map', () {
      final original = {'id': '1', 'status': 'completed'};
      GoonghapProviderHelper.mergeResponseWithI18n(
        mainResponse: original,
        i18nData: [],
      );

      // Original should not be modified
      expect(original['status'], 'completed');
      expect(original.containsKey('error_message'), false);
    });

    test('preserves existing error_message for non-completed status', () {
      final result = GoonghapProviderHelper.mergeResponseWithI18n(
        mainResponse: {
          'id': '1',
          'status': 'error',
          'error_message': 'Original error'
        },
        i18nData: [],
      );

      expect(result['status'], 'error');
      expect(result['error_message'], 'Original error');
    });

    test('pending status is not affected by empty i18n', () {
      final result = GoonghapProviderHelper.mergeResponseWithI18n(
        mainResponse: {'id': '1', 'status': 'pending'},
        i18nData: [],
      );

      expect(result['status'], 'pending');
    });
  });

  group('GoonghapProviderHelper.isRetryExhausted', () {
    test('returns false when retryCount is 0', () {
      expect(GoonghapProviderHelper.isRetryExhausted(0), false);
    });

    test('returns false when retryCount is less than maxRetries', () {
      expect(GoonghapProviderHelper.isRetryExhausted(1), false);
      expect(GoonghapProviderHelper.isRetryExhausted(2), false);
    });

    test('returns true when retryCount equals maxRetries', () {
      expect(GoonghapProviderHelper.isRetryExhausted(3), true);
    });

    test('returns true when retryCount exceeds maxRetries', () {
      expect(GoonghapProviderHelper.isRetryExhausted(4), true);
      expect(GoonghapProviderHelper.isRetryExhausted(100), true);
    });
  });

  group('GoonghapProviderHelper.calculateRetryDelay', () {
    test('returns zero duration for retryCount 0', () {
      final delay = GoonghapProviderHelper.calculateRetryDelay(retryCount: 0);
      expect(delay, Duration.zero);
    });

    test('returns baseDelay * retryCount', () {
      final delay = GoonghapProviderHelper.calculateRetryDelay(retryCount: 1);
      expect(delay, const Duration(seconds: 2));
    });

    test('returns double baseDelay for retryCount 2', () {
      final delay = GoonghapProviderHelper.calculateRetryDelay(retryCount: 2);
      expect(delay, const Duration(seconds: 4));
    });

    test('returns triple baseDelay for retryCount 3', () {
      final delay = GoonghapProviderHelper.calculateRetryDelay(retryCount: 3);
      expect(delay, const Duration(seconds: 6));
    });

    test('uses custom baseDelay when provided', () {
      final delay = GoonghapProviderHelper.calculateRetryDelay(
        retryCount: 2,
        baseDelay: const Duration(seconds: 5),
      );
      expect(delay, const Duration(seconds: 10));
    });
  });

  group('CreateGoonghapValidationError', () {
    test('enum values exist', () {
      expect(CreateGoonghapValidationError.values.length, 2);
      expect(CreateGoonghapValidationError.notAuthenticated, isNotNull);
      expect(
          CreateGoonghapValidationError.missingArtistBirthDate, isNotNull);
    });

    test('enum names are correct', () {
      expect(CreateGoonghapValidationError.notAuthenticated.name,
          'notAuthenticated');
      expect(CreateGoonghapValidationError.missingArtistBirthDate.name,
          'missingArtistBirthDate');
    });
  });

  group('GoonghapProviderHelper.maxRetries', () {
    test('is 3', () {
      expect(GoonghapProviderHelper.maxRetries, 3);
    });
  });
}
