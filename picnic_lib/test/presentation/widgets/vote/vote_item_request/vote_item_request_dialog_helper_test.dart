import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_helper.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

void main() {
  group('VoteItemRequestDialogHelper', () {
    group('isSuccessMessage', () {
      test('returns true for message starting with checkmark emoji', () {
        expect(
          VoteItemRequestDialogHelper.isSuccessMessage('✅ 신청이 완료되었습니다!'),
          isTrue,
        );
      });

      test('returns true for any message starting with checkmark', () {
        expect(
          VoteItemRequestDialogHelper.isSuccessMessage('✅ some other success'),
          isTrue,
        );
      });

      test('returns false for error messages', () {
        expect(
          VoteItemRequestDialogHelper.isSuccessMessage('이미 신청한 아티스트입니다'),
          isFalse,
        );
      });

      test('returns false for empty string', () {
        expect(VoteItemRequestDialogHelper.isSuccessMessage(''), isFalse);
      });

      test('returns false for message with checkmark not at start', () {
        expect(VoteItemRequestDialogHelper.isSuccessMessage('완료 ✅'), isFalse);
      });
    });

    group('getErrorMessageFromException', () {
      test('returns already_applied message for already_applied error', () {
        final result = VoteItemRequestDialogHelper.getErrorMessageFromException(
          Exception('already_applied'),
        );
        expect(result, '이미 신청한 아티스트입니다');
      });

      test(
        'returns already_applied message when error contains already_applied',
        () {
          final result =
              VoteItemRequestDialogHelper.getErrorMessageFromException(
                'Error: already_applied for this vote',
              );
          expect(result, '이미 신청한 아티스트입니다');
        },
      );

      test('uses caller-provided localized already_applied message', () {
        final result = VoteItemRequestDialogHelper.getErrorMessageFromException(
          Exception('already_applied'),
          alreadyAppliedMessage: 'This artist has already been requested.',
        );

        expect(result, 'This artist has already been requested.');
      });

      test('returns generic error without exposing unknown error details', () {
        final result = VoteItemRequestDialogHelper.getErrorMessageFromException(
          Exception('relation secret_table does not exist'),
        );
        expect(result, '신청 중 오류가 발생했습니다');
        expect(result, isNot(contains('secret_table')));
      });

      test('returns generic error message for string errors', () {
        final result = VoteItemRequestDialogHelper.getErrorMessageFromException(
          'timeout',
        );
        expect(result, '신청 중 오류가 발생했습니다');
      });

      test('uses caller-provided localized generic error message', () {
        final result = VoteItemRequestDialogHelper.getErrorMessageFromException(
          Exception('relation secret_table does not exist'),
          genericErrorMessage: 'An error occurred.',
        );

        expect(result, 'An error occurred.');
      });
    });

    group('shouldIgnoreSearchResult', () {
      test('returns false when resultToken is null', () {
        expect(
          VoteItemRequestDialogHelper.shouldIgnoreSearchResult(null, '123'),
          isFalse,
        );
      });

      test('returns false when tokens match', () {
        expect(
          VoteItemRequestDialogHelper.shouldIgnoreSearchResult('123', '123'),
          isFalse,
        );
      });

      test('returns true when tokens do not match', () {
        expect(
          VoteItemRequestDialogHelper.shouldIgnoreSearchResult('123', '456'),
          isTrue,
        );
      });

      test('returns true when currentToken is null but resultToken is not', () {
        expect(
          VoteItemRequestDialogHelper.shouldIgnoreSearchResult('123', null),
          isTrue,
        );
      });
    });

    group('shouldSkipLoadMore', () {
      test('returns true when already loading more', () {
        expect(
          VoteItemRequestDialogHelper.shouldSkipLoadMore(true, true),
          isTrue,
        );
      });

      test('returns true when no more results available', () {
        expect(
          VoteItemRequestDialogHelper.shouldSkipLoadMore(false, false),
          isTrue,
        );
      });

      test('returns true when both loading and no more results', () {
        expect(
          VoteItemRequestDialogHelper.shouldSkipLoadMore(true, false),
          isTrue,
        );
      });

      test('returns false when not loading and has more results', () {
        expect(
          VoteItemRequestDialogHelper.shouldSkipLoadMore(false, true),
          isFalse,
        );
      });
    });

    group('markArtistAsSubmitting', () {
      test('returns updated info with isSubmitting true', () {
        final info = {
          '1': const ArtistApplicationInfo(
            artistName: 'Test Artist',
            applicationCount: 5,
            applicationStatus: 'pending',
            isAlreadyInVote: false,
            isSubmitting: false,
          ),
        };

        final result = VoteItemRequestDialogHelper.markArtistAsSubmitting(
          info,
          '1',
        );

        expect(result, isNotNull);
        expect(result!.isSubmitting, isTrue);
        expect(result.artistName, 'Test Artist');
        expect(result.applicationCount, 5);
      });

      test('returns null when artist is not in the map', () {
        final info = <String, ArtistApplicationInfo>{};

        final result = VoteItemRequestDialogHelper.markArtistAsSubmitting(
          info,
          '999',
        );

        expect(result, isNull);
      });

      test('preserves other fields when marking as submitting', () {
        final info = {
          '42': const ArtistApplicationInfo(
            artistName: 'BTS',
            applicationCount: 100,
            applicationStatus: '대기중',
            isAlreadyInVote: true,
          ),
        };

        final result = VoteItemRequestDialogHelper.markArtistAsSubmitting(
          info,
          '42',
        );

        expect(result!.artistName, 'BTS');
        expect(result.applicationCount, 100);
        expect(result.applicationStatus, '대기중');
        expect(result.isAlreadyInVote, isTrue);
        expect(result.isSubmitting, isTrue);
      });
    });

    group('markApplicationSuccess', () {
      test('returns updated info with success state', () {
        final info = {
          '1': const ArtistApplicationInfo(
            artistName: 'Test',
            applicationCount: 3,
            applicationStatus: '신청가능',
            isAlreadyInVote: false,
            isSubmitting: true,
          ),
        };

        final result = VoteItemRequestDialogHelper.markApplicationSuccess(
          info,
          '1',
          '대기중',
        );

        expect(result, isNotNull);
        expect(result!.isSubmitting, isFalse);
        expect(result.applicationStatus, '대기중');
        expect(result.applicationCount, 4); // incremented by 1
      });

      test('returns null when artist not in map', () {
        final result = VoteItemRequestDialogHelper.markApplicationSuccess(
          {},
          '999',
          '대기중',
        );

        expect(result, isNull);
      });

      test('increments application count by exactly 1', () {
        final info = {
          '5': const ArtistApplicationInfo(
            artistName: 'Artist',
            applicationCount: 0,
            applicationStatus: '',
            isAlreadyInVote: false,
            isSubmitting: true,
          ),
        };

        final result = VoteItemRequestDialogHelper.markApplicationSuccess(
          info,
          '5',
          'pending',
        );

        expect(result!.applicationCount, 1);
      });
    });

    group('markApplicationFailure', () {
      test('returns info with isSubmitting set to false', () {
        final info = {
          '1': const ArtistApplicationInfo(
            artistName: 'Test',
            applicationCount: 5,
            applicationStatus: 'pending',
            isAlreadyInVote: false,
            isSubmitting: true,
          ),
        };

        final result = VoteItemRequestDialogHelper.markApplicationFailure(
          info,
          '1',
        );

        expect(result, isNotNull);
        expect(result!.isSubmitting, isFalse);
        expect(result.applicationCount, 5); // unchanged
        expect(result.applicationStatus, 'pending'); // unchanged
      });

      test('returns null when artist not in map', () {
        final result = VoteItemRequestDialogHelper.markApplicationFailure(
          {},
          '999',
        );

        expect(result, isNull);
      });
    });

    group('mergeSearchResults', () {
      test('replaces list when isInitial is true', () {
        final existing = [1, 2, 3];
        final newResults = [4, 5, 6];

        final result = VoteItemRequestDialogHelper.mergeSearchResults(
          existing,
          newResults,
          isInitial: true,
        );

        expect(result, [4, 5, 6]);
      });

      test('appends to list when isInitial is false', () {
        final existing = [1, 2, 3];
        final newResults = [4, 5, 6];

        final result = VoteItemRequestDialogHelper.mergeSearchResults(
          existing,
          newResults,
          isInitial: false,
        );

        expect(result, [1, 2, 3, 4, 5, 6]);
      });

      test('returns empty list when initial with no new results', () {
        final existing = [1, 2, 3];

        final result = VoteItemRequestDialogHelper.mergeSearchResults(
          existing,
          <int>[],
          isInitial: true,
        );

        expect(result, isEmpty);
      });

      test('returns copy of existing when appending empty list', () {
        final existing = [1, 2, 3];

        final result = VoteItemRequestDialogHelper.mergeSearchResults(
          existing,
          <int>[],
          isInitial: false,
        );

        expect(result, [1, 2, 3]);
      });

      test('works with string type', () {
        final result = VoteItemRequestDialogHelper.mergeSearchResults(
          ['a', 'b'],
          ['c'],
          isInitial: false,
        );

        expect(result, ['a', 'b', 'c']);
      });

      test('initial replacement does not modify original list', () {
        final existing = [1, 2, 3];
        final newResults = [4, 5];

        VoteItemRequestDialogHelper.mergeSearchResults(
          existing,
          newResults,
          isInitial: true,
        );

        expect(existing, [1, 2, 3]); // original unchanged
      });
    });

    group('determineRefreshStrategy', () {
      test('returns reloadApplicationData when results exist', () {
        expect(
          VoteItemRequestDialogHelper.determineRefreshStrategy([
            'result1',
          ], 'query'),
          'reloadApplicationData',
        );
      });

      test(
        'returns reloadApplicationData when results exist even with empty query',
        () {
          expect(
            VoteItemRequestDialogHelper.determineRefreshStrategy([
              'result1',
            ], ''),
            'reloadApplicationData',
          );
        },
      );

      test('returns rerunSearch when no results but query exists', () {
        expect(
          VoteItemRequestDialogHelper.determineRefreshStrategy([], 'query'),
          'rerunSearch',
        );
      });

      test('returns nothing when no results and no query', () {
        expect(
          VoteItemRequestDialogHelper.determineRefreshStrategy([], ''),
          'nothing',
        );
      });
    });

    group('successMessage', () {
      test('starts with checkmark emoji', () {
        expect(
          VoteItemRequestDialogHelper.successMessage.startsWith('✅'),
          isTrue,
        );
      });

      test('is recognized as success by isSuccessMessage', () {
        expect(
          VoteItemRequestDialogHelper.isSuccessMessage(
            VoteItemRequestDialogHelper.successMessage,
          ),
          isTrue,
        );
      });
    });

    group('isUserLoggedIn', () {
      test('returns true when userId is not null', () {
        expect(VoteItemRequestDialogHelper.isUserLoggedIn('user123'), isTrue);
      });

      test('returns false when userId is null', () {
        expect(VoteItemRequestDialogHelper.isUserLoggedIn(null), isFalse);
      });

      test('returns true for empty string (still not null)', () {
        expect(VoteItemRequestDialogHelper.isUserLoggedIn(''), isTrue);
      });
    });
  });
}
