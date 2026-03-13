import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog_helper.dart';

void main() {
  group('JmaVotingDialogHelper', () {
    // -----------------------------------------------------------------------
    // parseVoteAmount
    // -----------------------------------------------------------------------
    group('parseVoteAmount', () {
      test('returns integer from plain numeric string', () {
        expect(JmaVotingDialogHelper.parseVoteAmount('123'), 123);
      });

      test('strips commas before parsing', () {
        expect(JmaVotingDialogHelper.parseVoteAmount('1,234'), 1234);
        expect(JmaVotingDialogHelper.parseVoteAmount('1,000,000'), 1000000);
      });

      test('returns 0 for empty string', () {
        expect(JmaVotingDialogHelper.parseVoteAmount(''), 0);
      });

      test('returns 0 for non-numeric string', () {
        expect(JmaVotingDialogHelper.parseVoteAmount('abc'), 0);
      });

      test('returns 0 for string with only commas', () {
        expect(JmaVotingDialogHelper.parseVoteAmount(',,,'), 0);
      });
    });

    // -----------------------------------------------------------------------
    // stripLeadingZeros
    // -----------------------------------------------------------------------
    group('stripLeadingZeros', () {
      test('removes leading zeros', () {
        expect(JmaVotingDialogHelper.stripLeadingZeros('007'), '7');
        expect(JmaVotingDialogHelper.stripLeadingZeros('000123'), '123');
      });

      test('returns empty string for all zeros', () {
        expect(JmaVotingDialogHelper.stripLeadingZeros('000'), '');
      });

      test('leaves non-zero leading digit alone', () {
        expect(JmaVotingDialogHelper.stripLeadingZeros('42'), '42');
      });

      test('returns empty for empty input', () {
        expect(JmaVotingDialogHelper.stripLeadingZeros(''), '');
      });
    });

    // -----------------------------------------------------------------------
    // totalStarCandy
    // -----------------------------------------------------------------------
    group('totalStarCandy', () {
      test('sums regular and bonus', () {
        expect(
          JmaVotingDialogHelper.totalStarCandy(
            regularStarCandy: 300,
            bonusStarCandy: 10,
          ),
          310,
        );
      });

      test('works with zeros', () {
        expect(
          JmaVotingDialogHelper.totalStarCandy(
            regularStarCandy: 0,
            bonusStarCandy: 0,
          ),
          0,
        );
      });
    });

    // -----------------------------------------------------------------------
    // usableBonusVotes
    // -----------------------------------------------------------------------
    group('usableBonusVotes', () {
      test('returns min(bonus, remaining daily)', () {
        // bonus=3, remaining=5-2=3 → 3
        expect(
          JmaVotingDialogHelper.usableBonusVotes(
            bonusStarCandy: 3,
            dailyVoteCount: 2,
          ),
          3,
        );
      });

      test('caps at remaining daily when bonus is larger', () {
        // bonus=10, remaining=5-3=2 → 2
        expect(
          JmaVotingDialogHelper.usableBonusVotes(
            bonusStarCandy: 10,
            dailyVoteCount: 3,
          ),
          2,
        );
      });

      test('returns 0 when daily limit is exhausted', () {
        expect(
          JmaVotingDialogHelper.usableBonusVotes(
            bonusStarCandy: 10,
            dailyVoteCount: 5,
          ),
          0,
        );
      });

      test('returns 0 when daily limit is exceeded', () {
        expect(
          JmaVotingDialogHelper.usableBonusVotes(
            bonusStarCandy: 10,
            dailyVoteCount: 7,
          ),
          0,
        );
      });

      test('returns 0 when bonus candy is 0', () {
        expect(
          JmaVotingDialogHelper.usableBonusVotes(
            bonusStarCandy: 0,
            dailyVoteCount: 0,
          ),
          0,
        );
      });

      test('respects custom maxDaily', () {
        expect(
          JmaVotingDialogHelper.usableBonusVotes(
            bonusStarCandy: 20,
            dailyVoteCount: 5,
            maxDaily: 10,
          ),
          5,
        );
      });
    });

    // -----------------------------------------------------------------------
    // requiredStarCandy
    // -----------------------------------------------------------------------
    group('requiredStarCandy', () {
      test('returns 0 for zero votes', () {
        expect(
          JmaVotingDialogHelper.requiredStarCandy(
            voteAmount: 0,
            usableBonusVoteCount: 3,
          ),
          0,
        );
      });

      test('returns 0 for negative votes', () {
        expect(
          JmaVotingDialogHelper.requiredStarCandy(
            voteAmount: -1,
            usableBonusVoteCount: 3,
          ),
          0,
        );
      });

      test('uses only bonus when votes <= usable bonus', () {
        // 3 votes, 5 bonus available → cost = 3 (1:1)
        expect(
          JmaVotingDialogHelper.requiredStarCandy(
            voteAmount: 3,
            usableBonusVoteCount: 5,
          ),
          3,
        );
      });

      test('combines bonus and regular when votes > usable bonus', () {
        // 8 votes, 3 bonus available → 3 bonus + (8-3)*30 = 3 + 150 = 153
        expect(
          JmaVotingDialogHelper.requiredStarCandy(
            voteAmount: 8,
            usableBonusVoteCount: 3,
          ),
          153,
        );
      });

      test('uses only regular when no bonus available', () {
        // 5 votes, 0 bonus → 5 * 30 = 150
        expect(
          JmaVotingDialogHelper.requiredStarCandy(
            voteAmount: 5,
            usableBonusVoteCount: 0,
          ),
          150,
        );
      });

      test('exactly at bonus boundary uses only bonus', () {
        expect(
          JmaVotingDialogHelper.requiredStarCandy(
            voteAmount: 5,
            usableBonusVoteCount: 5,
          ),
          5,
        );
      });

      test('one over bonus boundary adds regular candy', () {
        // 6 votes, 5 bonus → 5 bonus + 1*30 = 35
        expect(
          JmaVotingDialogHelper.requiredStarCandy(
            voteAmount: 6,
            usableBonusVoteCount: 5,
          ),
          35,
        );
      });
    });

    // -----------------------------------------------------------------------
    // maxPossibleVotes
    // -----------------------------------------------------------------------
    group('maxPossibleVotes', () {
      test('combines bonus and regular votes', () {
        // 300 regular candy → 300/30=10, bonus=3 → 13
        expect(
          JmaVotingDialogHelper.maxPossibleVotes(
            regularStarCandy: 300,
            usableBonusVoteCount: 3,
          ),
          13,
        );
      });

      test('uses floor division for regular candy', () {
        // 299 → 299/30=9 (floor), bonus=0 → 9
        expect(
          JmaVotingDialogHelper.maxPossibleVotes(
            regularStarCandy: 299,
            usableBonusVoteCount: 0,
          ),
          9,
        );
      });

      test('returns only bonus when no regular candy', () {
        expect(
          JmaVotingDialogHelper.maxPossibleVotes(
            regularStarCandy: 0,
            usableBonusVoteCount: 5,
          ),
          5,
        );
      });

      test('returns 0 when user has nothing', () {
        expect(
          JmaVotingDialogHelper.maxPossibleVotes(
            regularStarCandy: 0,
            usableBonusVoteCount: 0,
          ),
          0,
        );
      });

      test('handles large values', () {
        expect(
          JmaVotingDialogHelper.maxPossibleVotes(
            regularStarCandy: 30000,
            usableBonusVoteCount: 5,
          ),
          1005,
        );
      });
    });

    // -----------------------------------------------------------------------
    // validateVote
    // -----------------------------------------------------------------------
    group('validateVote', () {
      String maxExceeded(int n) => 'Max $n votes exceeded';
      String shortage(int n) => 'Short by $n';

      test('zero vote amount → cannot vote, no message', () {
        final r = JmaVotingDialogHelper.validateVote(
          voteAmount: 0,
          maxPossibleVoteCount: 10,
          requiredStarCandyAmount: 0,
          totalStarCandyAmount: 100,
          maxVotesExceededMessage: maxExceeded,
          starCandyShortageMessage: shortage,
        );
        expect(r.canVote, false);
        expect(r.hasValue, false);
        expect(r.validationMessage, '');
      });

      test('negative vote amount → cannot vote, no message', () {
        final r = JmaVotingDialogHelper.validateVote(
          voteAmount: -5,
          maxPossibleVoteCount: 10,
          requiredStarCandyAmount: 0,
          totalStarCandyAmount: 100,
          maxVotesExceededMessage: maxExceeded,
          starCandyShortageMessage: shortage,
        );
        expect(r.canVote, false);
        expect(r.hasValue, false);
      });

      test('exceeds max possible votes → error message', () {
        final r = JmaVotingDialogHelper.validateVote(
          voteAmount: 15,
          maxPossibleVoteCount: 10,
          requiredStarCandyAmount: 300,
          totalStarCandyAmount: 300,
          maxVotesExceededMessage: maxExceeded,
          starCandyShortageMessage: shortage,
        );
        expect(r.canVote, false);
        expect(r.hasValue, true);
        expect(r.validationMessage, 'Max 10 votes exceeded');
      });

      test('insufficient star candy → shortage message', () {
        final r = JmaVotingDialogHelper.validateVote(
          voteAmount: 5,
          maxPossibleVoteCount: 20,
          requiredStarCandyAmount: 150,
          totalStarCandyAmount: 100,
          maxVotesExceededMessage: maxExceeded,
          starCandyShortageMessage: shortage,
        );
        expect(r.canVote, false);
        expect(r.hasValue, true);
        expect(r.validationMessage, 'Short by 50');
      });

      test('valid vote → can vote, no message', () {
        final r = JmaVotingDialogHelper.validateVote(
          voteAmount: 5,
          maxPossibleVoteCount: 20,
          requiredStarCandyAmount: 50,
          totalStarCandyAmount: 100,
          maxVotesExceededMessage: maxExceeded,
          starCandyShortageMessage: shortage,
        );
        expect(r.canVote, true);
        expect(r.hasValue, true);
        expect(r.validationMessage, '');
      });

      test('exactly at max and exact star candy → valid', () {
        final r = JmaVotingDialogHelper.validateVote(
          voteAmount: 10,
          maxPossibleVoteCount: 10,
          requiredStarCandyAmount: 100,
          totalStarCandyAmount: 100,
          maxVotesExceededMessage: maxExceeded,
          starCandyShortageMessage: shortage,
        );
        expect(r.canVote, true);
        expect(r.hasValue, true);
        expect(r.validationMessage, '');
      });

      test('max exceeded takes priority over star candy shortage', () {
        // Both conditions would be true, but max-exceeded check comes first.
        final r = JmaVotingDialogHelper.validateVote(
          voteAmount: 25,
          maxPossibleVoteCount: 10,
          requiredStarCandyAmount: 500,
          totalStarCandyAmount: 100,
          maxVotesExceededMessage: maxExceeded,
          starCandyShortageMessage: shortage,
        );
        expect(r.canVote, false);
        expect(r.validationMessage, contains('Max'));
      });
    });

    // -----------------------------------------------------------------------
    // calculateUsage
    // -----------------------------------------------------------------------
    group('calculateUsage', () {
      test('all bonus when votes <= usable bonus', () {
        final u = JmaVotingDialogHelper.calculateUsage(
          voteAmount: 3,
          usableBonusVoteCount: 5,
        );
        expect(u.starCandyUsage, 0);
        expect(u.starCandyBonusUsage, 3);
      });

      test('mixed when votes > usable bonus', () {
        final u = JmaVotingDialogHelper.calculateUsage(
          voteAmount: 8,
          usableBonusVoteCount: 3,
        );
        expect(u.starCandyBonusUsage, 3);
        expect(u.starCandyUsage, 150); // (8-3)*30
      });

      test('all regular when no bonus', () {
        final u = JmaVotingDialogHelper.calculateUsage(
          voteAmount: 4,
          usableBonusVoteCount: 0,
        );
        expect(u.starCandyBonusUsage, 0);
        expect(u.starCandyUsage, 120); // 4*30
      });

      test('exactly at bonus boundary', () {
        final u = JmaVotingDialogHelper.calculateUsage(
          voteAmount: 5,
          usableBonusVoteCount: 5,
        );
        expect(u.starCandyBonusUsage, 5);
        expect(u.starCandyUsage, 0);
      });
    });

    // -----------------------------------------------------------------------
    // bonusVotesUsed
    // -----------------------------------------------------------------------
    group('bonusVotesUsed', () {
      test('returns voteAmount when within bonus range', () {
        expect(
          JmaVotingDialogHelper.bonusVotesUsed(
            voteAmount: 3,
            usableBonusVoteCount: 5,
          ),
          3,
        );
      });

      test('returns usable bonus when exceeding', () {
        expect(
          JmaVotingDialogHelper.bonusVotesUsed(
            voteAmount: 10,
            usableBonusVoteCount: 5,
          ),
          5,
        );
      });

      test('returns 0 when no bonus available', () {
        expect(
          JmaVotingDialogHelper.bonusVotesUsed(
            voteAmount: 10,
            usableBonusVoteCount: 0,
          ),
          0,
        );
      });
    });

    // -----------------------------------------------------------------------
    // calculationResultMessage
    // -----------------------------------------------------------------------
    group('calculationResultMessage', () {
      String fmt(dynamic v) => v.toString();

      test('bonus-only message', () {
        final msg = JmaVotingDialogHelper.calculationResultMessage(
          voteAmount: 3,
          usableBonusVoteCount: 5,
          formatNumber: fmt,
        );
        expect(msg, 'JMA 3투표 = 보너스 3개');
      });

      test('mixed bonus + regular message', () {
        final msg = JmaVotingDialogHelper.calculationResultMessage(
          voteAmount: 8,
          usableBonusVoteCount: 3,
          formatNumber: fmt,
        );
        expect(msg, 'JMA 8투표 = 보너스 3개 + 별사탕 150개');
      });

      test('regular-only message', () {
        final msg = JmaVotingDialogHelper.calculationResultMessage(
          voteAmount: 5,
          usableBonusVoteCount: 0,
          formatNumber: fmt,
        );
        expect(msg, 'JMA 5투표 = 별사탕 150개');
      });
    });

    // -----------------------------------------------------------------------
    // remainingDailyVotes / hasDailyVotesRemaining
    // -----------------------------------------------------------------------
    group('remainingDailyVotes', () {
      test('returns correct remaining', () {
        expect(
          JmaVotingDialogHelper.remainingDailyVotes(dailyVoteCount: 2),
          3,
        );
      });

      test('returns 0 at limit', () {
        expect(
          JmaVotingDialogHelper.remainingDailyVotes(dailyVoteCount: 5),
          0,
        );
      });

      test('returns 0 when over limit', () {
        expect(
          JmaVotingDialogHelper.remainingDailyVotes(dailyVoteCount: 7),
          0,
        );
      });

      test('works with custom maxDaily', () {
        expect(
          JmaVotingDialogHelper.remainingDailyVotes(
            dailyVoteCount: 3,
            maxDaily: 10,
          ),
          7,
        );
      });
    });

    group('hasDailyVotesRemaining', () {
      test('true when votes remain', () {
        expect(
          JmaVotingDialogHelper.hasDailyVotesRemaining(dailyVoteCount: 4),
          true,
        );
      });

      test('false when exhausted', () {
        expect(
          JmaVotingDialogHelper.hasDailyVotesRemaining(dailyVoteCount: 5),
          false,
        );
      });
    });

    // -----------------------------------------------------------------------
    // resolveArtistImageUrl
    // -----------------------------------------------------------------------
    group('resolveArtistImageUrl', () {
      test('returns artist image when artistId is non-zero', () {
        expect(
          JmaVotingDialogHelper.resolveArtistImageUrl(
            artistId: 42,
            artistImage: 'artist.jpg',
            artistGroupImage: 'group.jpg',
          ),
          'artist.jpg',
        );
      });

      test('returns group image when artistId is 0', () {
        expect(
          JmaVotingDialogHelper.resolveArtistImageUrl(
            artistId: 0,
            artistImage: 'artist.jpg',
            artistGroupImage: 'group.jpg',
          ),
          'group.jpg',
        );
      });

      test('returns group image when artistId is null', () {
        expect(
          JmaVotingDialogHelper.resolveArtistImageUrl(
            artistId: null,
            artistImage: 'artist.jpg',
            artistGroupImage: 'group.jpg',
          ),
          'group.jpg',
        );
      });

      test('returns null when both images are null and artistId is 0', () {
        expect(
          JmaVotingDialogHelper.resolveArtistImageUrl(
            artistId: 0,
            artistImage: null,
            artistGroupImage: null,
          ),
          null,
        );
      });
    });

    // -----------------------------------------------------------------------
    // isSoloArtist
    // -----------------------------------------------------------------------
    group('isSoloArtist', () {
      test('true for non-zero id', () {
        expect(JmaVotingDialogHelper.isSoloArtist(artistId: 1), true);
      });

      test('false for zero id', () {
        expect(JmaVotingDialogHelper.isSoloArtist(artistId: 0), false);
      });

      test('false for null id', () {
        expect(JmaVotingDialogHelper.isSoloArtist(artistId: null), false);
      });
    });

    // -----------------------------------------------------------------------
    // regularStarCandyVotes
    // -----------------------------------------------------------------------
    group('regularStarCandyVotes', () {
      test('floor division by 30', () {
        expect(
          JmaVotingDialogHelper.regularStarCandyVotes(regularStarCandy: 90),
          3,
        );
        expect(
          JmaVotingDialogHelper.regularStarCandyVotes(regularStarCandy: 89),
          2,
        );
        expect(
          JmaVotingDialogHelper.regularStarCandyVotes(regularStarCandy: 0),
          0,
        );
        expect(
          JmaVotingDialogHelper.regularStarCandyVotes(regularStarCandy: 29),
          0,
        );
      });
    });

    // -----------------------------------------------------------------------
    // Integration: end-to-end scenario
    // -----------------------------------------------------------------------
    group('integration scenario', () {
      test('full voting flow calculation', () {
        // User has 300 regular candy, 10 bonus candy, used 2 today
        const regularCandy = 300;
        const bonusCandy = 10;
        const dailyUsed = 2;

        final usableBonus = JmaVotingDialogHelper.usableBonusVotes(
          bonusStarCandy: bonusCandy,
          dailyVoteCount: dailyUsed,
        );
        expect(usableBonus, 3); // min(10, 5-2) = 3

        final maxVotes = JmaVotingDialogHelper.maxPossibleVotes(
          regularStarCandy: regularCandy,
          usableBonusVoteCount: usableBonus,
        );
        expect(maxVotes, 13); // 300/30 + 3 = 13

        // User wants to vote 7
        const desiredVotes = 7;

        final required = JmaVotingDialogHelper.requiredStarCandy(
          voteAmount: desiredVotes,
          usableBonusVoteCount: usableBonus,
        );
        // 3 bonus (1:1) + 4 regular (4*30=120) = 3 + 120 = 123
        expect(required, 123);

        final total = JmaVotingDialogHelper.totalStarCandy(
          regularStarCandy: regularCandy,
          bonusStarCandy: bonusCandy,
        );
        expect(total, 310);

        final validation = JmaVotingDialogHelper.validateVote(
          voteAmount: desiredVotes,
          maxPossibleVoteCount: maxVotes,
          requiredStarCandyAmount: required,
          totalStarCandyAmount: total,
          maxVotesExceededMessage: (n) => 'Max $n',
          starCandyShortageMessage: (n) => 'Short $n',
        );
        expect(validation.canVote, true);

        final usage = JmaVotingDialogHelper.calculateUsage(
          voteAmount: desiredVotes,
          usableBonusVoteCount: usableBonus,
        );
        expect(usage.starCandyBonusUsage, 3);
        expect(usage.starCandyUsage, 120); // (7-3)*30
      });
    });
  });
}
