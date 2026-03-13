import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_usage_helper.dart';

void main() {
  group('VotingUsageHelper.getUsableBonusVotes', () {
    test('returns 0 when dailyVoteCount >= maxDaily', () {
      expect(
        VotingUsageHelper.getUsableBonusVotes(
          bonusStarCandy: 10,
          dailyVoteCount: 5,
        ),
        0,
      );
    });

    test('returns 0 when dailyVoteCount exceeds maxDaily', () {
      expect(
        VotingUsageHelper.getUsableBonusVotes(
          bonusStarCandy: 10,
          dailyVoteCount: 7,
        ),
        0,
      );
    });

    test('returns 0 when bonusStarCandy is 0', () {
      expect(
        VotingUsageHelper.getUsableBonusVotes(
          bonusStarCandy: 0,
          dailyVoteCount: 0,
        ),
        0,
      );
    });

    test('returns bonusStarCandy when less than remaining daily limit', () {
      expect(
        VotingUsageHelper.getUsableBonusVotes(
          bonusStarCandy: 3,
          dailyVoteCount: 0,
        ),
        3,
      );
    });

    test('returns remaining daily limit when less than bonusStarCandy', () {
      expect(
        VotingUsageHelper.getUsableBonusVotes(
          bonusStarCandy: 10,
          dailyVoteCount: 3,
        ),
        2,
      );
    });

    test('returns exact remaining when bonusStarCandy equals remaining', () {
      expect(
        VotingUsageHelper.getUsableBonusVotes(
          bonusStarCandy: 2,
          dailyVoteCount: 3,
        ),
        2,
      );
    });

    test('custom maxDaily', () {
      expect(
        VotingUsageHelper.getUsableBonusVotes(
          bonusStarCandy: 100,
          dailyVoteCount: 5,
          maxDaily: 10,
        ),
        5,
      );
    });

    test('returns 0 when both bonusStarCandy and remaining are 0', () {
      expect(
        VotingUsageHelper.getUsableBonusVotes(
          bonusStarCandy: 0,
          dailyVoteCount: 5,
        ),
        0,
      );
    });
  });

  group('VotingUsageHelper.getRequiredStarCandy', () {
    test('returns 0 for zero vote amount', () {
      expect(
        VotingUsageHelper.getRequiredStarCandy(
          voteAmount: 0,
          usableBonusVotes: 5,
        ),
        0,
      );
    });

    test('uses 1:1 ratio when vote amount <= bonus', () {
      expect(
        VotingUsageHelper.getRequiredStarCandy(
          voteAmount: 3,
          usableBonusVotes: 5,
        ),
        3,
      );
    });

    test('uses 1:1 for bonus portion and 30:1 for remainder', () {
      // 5 votes: 3 bonus (cost 3) + 2 regular (cost 60) = 63
      expect(
        VotingUsageHelper.getRequiredStarCandy(
          voteAmount: 5,
          usableBonusVotes: 3,
        ),
        63,
      );
    });

    test('all regular when no bonus available', () {
      // 10 votes * 30 = 300
      expect(
        VotingUsageHelper.getRequiredStarCandy(
          voteAmount: 10,
          usableBonusVotes: 0,
        ),
        300,
      );
    });

    test('exact bonus match', () {
      expect(
        VotingUsageHelper.getRequiredStarCandy(
          voteAmount: 5,
          usableBonusVotes: 5,
        ),
        5,
      );
    });

    test('single vote with no bonus', () {
      expect(
        VotingUsageHelper.getRequiredStarCandy(
          voteAmount: 1,
          usableBonusVotes: 0,
        ),
        30,
      );
    });

    test('single vote with bonus', () {
      expect(
        VotingUsageHelper.getRequiredStarCandy(
          voteAmount: 1,
          usableBonusVotes: 1,
        ),
        1,
      );
    });

    test('large vote amount with small bonus', () {
      // 100 votes: 2 bonus (cost 2) + 98 regular (cost 2940) = 2942
      expect(
        VotingUsageHelper.getRequiredStarCandy(
          voteAmount: 100,
          usableBonusVotes: 2,
        ),
        2942,
      );
    });
  });

  group('VotingUsageHelper.getMaxPossibleVotes', () {
    test('returns only bonus votes when no regular candy', () {
      expect(
        VotingUsageHelper.getMaxPossibleVotes(
          starCandy: 0,
          usableBonusVotes: 5,
        ),
        5,
      );
    });

    test('returns only regular votes when no bonus', () {
      // 300 / 30 = 10
      expect(
        VotingUsageHelper.getMaxPossibleVotes(
          starCandy: 300,
          usableBonusVotes: 0,
        ),
        10,
      );
    });

    test('combines bonus and regular votes', () {
      // 5 bonus + 300/30 = 5 + 10 = 15
      expect(
        VotingUsageHelper.getMaxPossibleVotes(
          starCandy: 300,
          usableBonusVotes: 5,
        ),
        15,
      );
    });

    test('truncates partial regular votes', () {
      // 29 / 30 = 0, so only bonus
      expect(
        VotingUsageHelper.getMaxPossibleVotes(
          starCandy: 29,
          usableBonusVotes: 3,
        ),
        3,
      );
    });

    test('returns 0 when nothing available', () {
      expect(
        VotingUsageHelper.getMaxPossibleVotes(
          starCandy: 0,
          usableBonusVotes: 0,
        ),
        0,
      );
    });

    test('large values', () {
      // 5 bonus + 90000/30 = 5 + 3000 = 3005
      expect(
        VotingUsageHelper.getMaxPossibleVotes(
          starCandy: 90000,
          usableBonusVotes: 5,
        ),
        3005,
      );
    });
  });

  group('VotingUsageHelper.validateJmaVote', () {
    test('returns canVote false for zero vote amount', () {
      final result = VotingUsageHelper.validateJmaVote(
        voteAmount: 0,
        maxPossibleVotes: 100,
        requiredStarCandy: 0,
        totalStarCandy: 500,
      );
      expect(result.canVote, false);
      expect(result.validationMessage, '');
    });

    test('returns canVote false for negative vote amount', () {
      final result = VotingUsageHelper.validateJmaVote(
        voteAmount: -1,
        maxPossibleVotes: 100,
        requiredStarCandy: 0,
        totalStarCandy: 500,
      );
      expect(result.canVote, false);
      expect(result.validationMessage, '');
    });

    test('returns canVote true when within limits', () {
      final result = VotingUsageHelper.validateJmaVote(
        voteAmount: 5,
        maxPossibleVotes: 10,
        requiredStarCandy: 50,
        totalStarCandy: 500,
      );
      expect(result.canVote, true);
      expect(result.validationMessage, '');
    });

    test('returns error when exceeding max possible votes', () {
      final result = VotingUsageHelper.validateJmaVote(
        voteAmount: 15,
        maxPossibleVotes: 10,
        requiredStarCandy: 450,
        totalStarCandy: 500,
        maxVotesExceededMessage: (max) => 'Max: $max',
      );
      expect(result.canVote, false);
      expect(result.validationMessage, 'Max: 10');
    });

    test('returns error when star candy insufficient', () {
      final result = VotingUsageHelper.validateJmaVote(
        voteAmount: 5,
        maxPossibleVotes: 100,
        requiredStarCandy: 600,
        totalStarCandy: 500,
        starCandyShortageMessage: (shortfall) => 'Short: $shortfall',
      );
      expect(result.canVote, false);
      expect(result.validationMessage, 'Short: 100');
    });

    test('max votes exceeded takes priority over star candy shortage', () {
      final result = VotingUsageHelper.validateJmaVote(
        voteAmount: 200,
        maxPossibleVotes: 10,
        requiredStarCandy: 6000,
        totalStarCandy: 500,
        maxVotesExceededMessage: (max) => 'Max: $max',
        starCandyShortageMessage: (s) => 'Short: $s',
      );
      expect(result.canVote, false);
      expect(result.validationMessage, 'Max: 10');
    });

    test('uses default messages when callbacks not provided', () {
      final result = VotingUsageHelper.validateJmaVote(
        voteAmount: 100,
        maxPossibleVotes: 5,
        requiredStarCandy: 3000,
        totalStarCandy: 100,
      );
      expect(result.canVote, false);
      expect(result.validationMessage, contains('5'));
    });

    test('exact boundary - vote amount equals max possible', () {
      final result = VotingUsageHelper.validateJmaVote(
        voteAmount: 10,
        maxPossibleVotes: 10,
        requiredStarCandy: 300,
        totalStarCandy: 300,
      );
      expect(result.canVote, true);
    });

    test('exact boundary - required equals total candy', () {
      final result = VotingUsageHelper.validateJmaVote(
        voteAmount: 5,
        maxPossibleVotes: 100,
        requiredStarCandy: 500,
        totalStarCandy: 500,
      );
      expect(result.canVote, true);
    });
  });

  group('VotingUsageHelper.buildCalculationMessage', () {
    String fmt(dynamic n) => n.toString();

    test('bonus only message', () {
      final msg = VotingUsageHelper.buildCalculationMessage(
        voteAmount: 3,
        usableBonusVotes: 5,
        formatNumber: fmt,
      );
      expect(msg, 'JMA 3투표 = 보너스 3개');
    });

    test('bonus + regular message', () {
      final msg = VotingUsageHelper.buildCalculationMessage(
        voteAmount: 7,
        usableBonusVotes: 3,
        formatNumber: fmt,
      );
      // 7-3=4 regular, 4*30=120
      expect(msg, 'JMA 7투표 = 보너스 3개 + 별사탕 120개');
    });

    test('regular only message', () {
      final msg = VotingUsageHelper.buildCalculationMessage(
        voteAmount: 10,
        usableBonusVotes: 0,
        formatNumber: fmt,
      );
      // 10*30=300
      expect(msg, 'JMA 10투표 = 별사탕 300개');
    });

    test('exact bonus match', () {
      final msg = VotingUsageHelper.buildCalculationMessage(
        voteAmount: 5,
        usableBonusVotes: 5,
        formatNumber: fmt,
      );
      expect(msg, 'JMA 5투표 = 보너스 5개');
    });
  });

  group('VotingUsageHelper constants', () {
    test('maxDailyBonusVotes is 5', () {
      expect(VotingUsageHelper.maxDailyBonusVotes, 5);
    });

    test('starCandyPerVote is 30', () {
      expect(VotingUsageHelper.starCandyPerVote, 30);
    });
  });
}
