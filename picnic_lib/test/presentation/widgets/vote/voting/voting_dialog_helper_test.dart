import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_helper.dart';

void main() {
  group('VotingDialogHelper', () {
    // -------------------------------------------------------------------------
    // resolveArtistImageUrl
    // -------------------------------------------------------------------------
    group('resolveArtistImageUrl', () {
      test('returns artist image when artistId is non-zero', () {
        expect(
          VotingDialogHelper.resolveArtistImageUrl(
            artistId: 42,
            artistImage: 'https://img/artist.png',
            artistGroupImage: 'https://img/group.png',
          ),
          'https://img/artist.png',
        );
      });

      test('returns group image when artistId is 0', () {
        expect(
          VotingDialogHelper.resolveArtistImageUrl(
            artistId: 0,
            artistImage: 'https://img/artist.png',
            artistGroupImage: 'https://img/group.png',
          ),
          'https://img/group.png',
        );
      });

      test('returns group image when artistId is null', () {
        expect(
          VotingDialogHelper.resolveArtistImageUrl(
            artistId: null,
            artistImage: 'https://img/artist.png',
            artistGroupImage: 'https://img/group.png',
          ),
          'https://img/group.png',
        );
      });

      test('returns null when both images are null and artistId is 0', () {
        expect(
          VotingDialogHelper.resolveArtistImageUrl(
            artistId: 0,
            artistImage: null,
            artistGroupImage: null,
          ),
          isNull,
        );
      });

      test('returns null artist image when artistId is non-zero but image is null', () {
        expect(
          VotingDialogHelper.resolveArtistImageUrl(
            artistId: 1,
            artistImage: null,
            artistGroupImage: 'https://img/group.png',
          ),
          isNull,
        );
      });
    });

    // -------------------------------------------------------------------------
    // shouldUseJmaDialog
    // -------------------------------------------------------------------------
    group('shouldUseJmaDialog', () {
      test('returns true for jma partner on non-PIC portal', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: false,
            partner: 'jma',
          ),
          isTrue,
        );
      });

      test('returns true for JMA partner (case insensitive)', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: false,
            partner: 'JMA',
          ),
          isTrue,
        );
      });

      test('returns false for PIC portal even with jma partner', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: true,
            partner: 'jma',
          ),
          isFalse,
        );
      });

      test('returns false when partner is null', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: false,
            partner: null,
          ),
          isFalse,
        );
      });

      test('returns false for non-jma partner', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: false,
            partner: 'other',
          ),
          isFalse,
        );
      });
    });

    // -------------------------------------------------------------------------
    // getVotingFunctionName
    // -------------------------------------------------------------------------
    group('getVotingFunctionName', () {
      test('returns pic-voting-v2 for PIC portal', () {
        expect(
          VotingDialogHelper.getVotingFunctionName(isPicPortal: true),
          'pic-voting-v2',
        );
      });

      test('returns voting-v2 for non-PIC portal', () {
        expect(
          VotingDialogHelper.getVotingFunctionName(isPicPortal: false),
          'voting-v2',
        );
      });
    });

    // -------------------------------------------------------------------------
    // determineVoteButtonState
    // -------------------------------------------------------------------------
    group('determineVoteButtonState', () {
      test('returns loading when isVoting is true', () {
        expect(
          VotingDialogHelper.determineVoteButtonState(
            canVote: true,
            isVoting: true,
          ),
          VoteButtonState.loading,
        );
      });

      test('returns enabled when canVote is true and not voting', () {
        expect(
          VotingDialogHelper.determineVoteButtonState(
            canVote: true,
            isVoting: false,
          ),
          VoteButtonState.enabled,
        );
      });

      test('returns disabled when canVote is false and not voting', () {
        expect(
          VotingDialogHelper.determineVoteButtonState(
            canVote: false,
            isVoting: false,
          ),
          VoteButtonState.disabled,
        );
      });

      test('returns loading over disabled when isVoting but cannot vote', () {
        expect(
          VotingDialogHelper.determineVoteButtonState(
            canVote: false,
            isVoting: true,
          ),
          VoteButtonState.loading,
        );
      });
    });

    // -------------------------------------------------------------------------
    // shouldShowErrorMessage
    // -------------------------------------------------------------------------
    group('shouldShowErrorMessage', () {
      test('returns true when cannot vote but has value', () {
        expect(
          VotingDialogHelper.shouldShowErrorMessage(
            canVote: false,
            hasValue: true,
          ),
          isTrue,
        );
      });

      test('returns false when can vote', () {
        expect(
          VotingDialogHelper.shouldShowErrorMessage(
            canVote: true,
            hasValue: true,
          ),
          isFalse,
        );
      });

      test('returns false when no value entered', () {
        expect(
          VotingDialogHelper.shouldShowErrorMessage(
            canVote: false,
            hasValue: false,
          ),
          isFalse,
        );
      });
    });

    // -------------------------------------------------------------------------
    // formatVoteInput
    // -------------------------------------------------------------------------
    group('formatVoteInput', () {
      test('formats a simple number with commas', () {
        expect(VotingDialogHelper.formatVoteInput('1234567'), '1,234,567');
      });

      test('strips leading zeros', () {
        expect(VotingDialogHelper.formatVoteInput('00123'), '123');
      });

      test('returns null for empty string', () {
        expect(VotingDialogHelper.formatVoteInput(''), isNull);
      });

      test('returns null for all zeros', () {
        expect(VotingDialogHelper.formatVoteInput('000'), isNull);
      });

      test('returns null for zero', () {
        expect(VotingDialogHelper.formatVoteInput('0'), isNull);
      });

      test('handles single digit', () {
        expect(VotingDialogHelper.formatVoteInput('5'), '5');
      });

      test('handles three digits without comma', () {
        expect(VotingDialogHelper.formatVoteInput('999'), '999');
      });

      test('handles four digits with comma', () {
        expect(VotingDialogHelper.formatVoteInput('1000'), '1,000');
      });

      test('strips existing commas before formatting', () {
        expect(VotingDialogHelper.formatVoteInput('1,234'), '1,234');
      });
    });

    // -------------------------------------------------------------------------
    // computeCheckAllToggle
    // -------------------------------------------------------------------------
    group('computeCheckAllToggle', () {
      String testFormat(dynamic v) => v.toString();

      test('toggles on: sets checkAll, hasValue, and formatted amount', () {
        final result = VotingDialogHelper.computeCheckAllToggle(
          currentCheckAll: false,
          availableStarCandy: 5000,
          formatNumber: testFormat,
        );
        expect(result.checkAll, isTrue);
        expect(result.hasValue, isTrue);
        expect(result.formattedAmount, '5000');
      });

      test('toggles off: clears checkAll and hasValue', () {
        final result = VotingDialogHelper.computeCheckAllToggle(
          currentCheckAll: true,
          availableStarCandy: 5000,
          formatNumber: testFormat,
        );
        expect(result.checkAll, isFalse);
        expect(result.hasValue, isFalse);
        expect(result.formattedAmount, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // computeTotalStarCandy
    // -------------------------------------------------------------------------
    group('computeTotalStarCandy', () {
      test('sums regular and bonus', () {
        expect(
          VotingDialogHelper.computeTotalStarCandy(
            starCandy: 100,
            starCandyBonus: 50,
          ),
          150,
        );
      });

      test('returns zero when both are zero', () {
        expect(
          VotingDialogHelper.computeTotalStarCandy(
            starCandy: 0,
            starCandyBonus: 0,
          ),
          0,
        );
      });
    });

    // -------------------------------------------------------------------------
    // preCheckVote
    // -------------------------------------------------------------------------
    group('preCheckVote', () {
      test('returns null for valid vote', () {
        expect(
          VotingDialogHelper.preCheckVote(
            voteAmount: 100,
            availableStarCandy: 200,
          ),
          isNull,
        );
      });

      test('returns zeroAmount when vote is 0', () {
        expect(
          VotingDialogHelper.preCheckVote(
            voteAmount: 0,
            availableStarCandy: 200,
          ),
          VoteFailReason.zeroAmount,
        );
      });

      test('returns insufficientBalance when vote exceeds balance', () {
        expect(
          VotingDialogHelper.preCheckVote(
            voteAmount: 300,
            availableStarCandy: 200,
          ),
          VoteFailReason.insufficientBalance,
        );
      });

      test('returns null when vote equals balance exactly', () {
        expect(
          VotingDialogHelper.preCheckVote(
            voteAmount: 200,
            availableStarCandy: 200,
          ),
          isNull,
        );
      });
    });

    // -------------------------------------------------------------------------
    // hasPartnerLogo
    // -------------------------------------------------------------------------
    group('hasPartnerLogo', () {
      test('returns true when partnership is active with partner name', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(
            isPartnership: true,
            partner: 'jma',
          ),
          isTrue,
        );
      });

      test('returns false when isPartnership is false', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(
            isPartnership: false,
            partner: 'jma',
          ),
          isFalse,
        );
      });

      test('returns false when isPartnership is null', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(
            isPartnership: null,
            partner: 'jma',
          ),
          isFalse,
        );
      });

      test('returns false when partner is null', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(
            isPartnership: true,
            partner: null,
          ),
          isFalse,
        );
      });

      test('returns false when partner is empty', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(
            isPartnership: true,
            partner: '',
          ),
          isFalse,
        );
      });
    });
  });
}
