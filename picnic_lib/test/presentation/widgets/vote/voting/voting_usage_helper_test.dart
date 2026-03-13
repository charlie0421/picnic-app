import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_usage_helper.dart';

void main() {
  group('VotingUsageHelper.calculateUsage', () {
    test('uses bonus candy first when bonus covers full amount', () {
      final result = VotingUsageHelper.calculateUsage(
        totalAmount: 50,
        starCandyBonus: 100,
      );
      expect(result['star_candy_usage'], 0);
      expect(result['star_candy_bonus_usage'], 50);
    });

    test('uses bonus candy first then regular candy for remainder', () {
      final result = VotingUsageHelper.calculateUsage(
        totalAmount: 100,
        starCandyBonus: 30,
      );
      expect(result['star_candy_bonus_usage'], 30);
      expect(result['star_candy_usage'], 70);
    });

    test('uses only regular candy when no bonus available', () {
      final result = VotingUsageHelper.calculateUsage(
        totalAmount: 100,
        starCandyBonus: 0,
      );
      expect(result['star_candy_usage'], 100);
      expect(result['star_candy_bonus_usage'], 0);
    });

    test('zero amount results in zero usage', () {
      final result = VotingUsageHelper.calculateUsage(
        totalAmount: 0,
        starCandyBonus: 100,
      );
      expect(result['star_candy_usage'], 0);
      expect(result['star_candy_bonus_usage'], 0);
    });

    test('exact bonus match uses all bonus, no regular candy', () {
      final result = VotingUsageHelper.calculateUsage(
        totalAmount: 50,
        starCandyBonus: 50,
      );
      expect(result['star_candy_bonus_usage'], 50);
      expect(result['star_candy_usage'], 0);
    });

    test('large amount with small bonus', () {
      final result = VotingUsageHelper.calculateUsage(
        totalAmount: 10000,
        starCandyBonus: 5,
      );
      expect(result['star_candy_bonus_usage'], 5);
      expect(result['star_candy_usage'], 9995);
    });

    test('amount of 1 with bonus of 0', () {
      final result = VotingUsageHelper.calculateUsage(
        totalAmount: 1,
        starCandyBonus: 0,
      );
      expect(result['star_candy_usage'], 1);
      expect(result['star_candy_bonus_usage'], 0);
    });

    test('amount of 1 with bonus of 1', () {
      final result = VotingUsageHelper.calculateUsage(
        totalAmount: 1,
        starCandyBonus: 1,
      );
      expect(result['star_candy_usage'], 0);
      expect(result['star_candy_bonus_usage'], 1);
    });
  });

  group('VotingUsageHelper.isValidVoteAmount', () {
    test('returns true for valid amount within balance', () {
      expect(VotingUsageHelper.isValidVoteAmount(50, 100), isTrue);
    });

    test('returns true for amount equal to balance', () {
      expect(VotingUsageHelper.isValidVoteAmount(100, 100), isTrue);
    });

    test('returns false for amount exceeding balance', () {
      expect(VotingUsageHelper.isValidVoteAmount(101, 100), isFalse);
    });

    test('returns false for zero amount', () {
      expect(VotingUsageHelper.isValidVoteAmount(0, 100), isFalse);
    });

    test('returns false for negative amount', () {
      expect(VotingUsageHelper.isValidVoteAmount(-1, 100), isFalse);
    });

    test('returns false for zero balance with positive amount', () {
      expect(VotingUsageHelper.isValidVoteAmount(1, 0), isFalse);
    });

    test('returns true for 1 with balance of 1', () {
      expect(VotingUsageHelper.isValidVoteAmount(1, 1), isTrue);
    });
  });

  group('VotingUsageHelper.parseVoteAmount', () {
    test('parses plain number string', () {
      expect(VotingUsageHelper.parseVoteAmount('100'), 100);
    });

    test('parses comma-formatted string', () {
      expect(VotingUsageHelper.parseVoteAmount('1,000'), 1000);
    });

    test('parses multi-comma string', () {
      expect(VotingUsageHelper.parseVoteAmount('1,234,567'), 1234567);
    });

    test('returns 0 for empty string', () {
      expect(VotingUsageHelper.parseVoteAmount(''), 0);
    });

    test('returns 0 for non-numeric string', () {
      expect(VotingUsageHelper.parseVoteAmount('abc'), 0);
    });

    test('parses string with only commas as 0', () {
      expect(VotingUsageHelper.parseVoteAmount(',,,'), 0);
    });

    test('parses single digit', () {
      expect(VotingUsageHelper.parseVoteAmount('5'), 5);
    });

    test('parses zero', () {
      expect(VotingUsageHelper.parseVoteAmount('0'), 0);
    });
  });

  group('VotingUsageHelper.calculateBatches', () {
    test('returns single batch for small amount', () {
      final batches = VotingUsageHelper.calculateBatches(500);
      expect(batches, [500]);
    });

    test('returns single batch for exactly batch size', () {
      final batches = VotingUsageHelper.calculateBatches(1000);
      expect(batches, [1000]);
    });

    test('returns two batches for amount just over batch size', () {
      final batches = VotingUsageHelper.calculateBatches(1001);
      expect(batches, [1000, 1]);
    });

    test('returns correct batches for large amount', () {
      final batches = VotingUsageHelper.calculateBatches(3500);
      expect(batches, [1000, 1000, 1000, 500]);
    });

    test('returns empty list for zero amount', () {
      final batches = VotingUsageHelper.calculateBatches(0);
      expect(batches, isEmpty);
    });

    test('returns empty list for negative amount', () {
      final batches = VotingUsageHelper.calculateBatches(-10);
      expect(batches, isEmpty);
    });

    test('custom batch size', () {
      final batches = VotingUsageHelper.calculateBatches(250, batchSize: 100);
      expect(batches, [100, 100, 50]);
    });

    test('batch size larger than amount', () {
      final batches = VotingUsageHelper.calculateBatches(50, batchSize: 5000);
      expect(batches, [50]);
    });
  });

  group('VotingUsageHelper.calculateBatchUsages', () {
    test('all bonus covers all batches', () {
      final usages = VotingUsageHelper.calculateBatchUsages(
        batches: [1000, 1000, 500],
        totalBonusUsage: 2500,
      );
      expect(usages[0], {'bonus': 1000, 'candy': 0});
      expect(usages[1], {'bonus': 1000, 'candy': 0});
      expect(usages[2], {'bonus': 500, 'candy': 0});
    });

    test('bonus runs out mid-batch', () {
      final usages = VotingUsageHelper.calculateBatchUsages(
        batches: [1000, 1000],
        totalBonusUsage: 1500,
      );
      expect(usages[0], {'bonus': 1000, 'candy': 0});
      expect(usages[1], {'bonus': 500, 'candy': 500});
    });

    test('no bonus at all', () {
      final usages = VotingUsageHelper.calculateBatchUsages(
        batches: [1000, 500],
        totalBonusUsage: 0,
      );
      expect(usages[0], {'bonus': 0, 'candy': 1000});
      expect(usages[1], {'bonus': 0, 'candy': 500});
    });

    test('empty batches returns empty list', () {
      final usages = VotingUsageHelper.calculateBatchUsages(
        batches: [],
        totalBonusUsage: 100,
      );
      expect(usages, isEmpty);
    });

    test('single batch fully covered by bonus', () {
      final usages = VotingUsageHelper.calculateBatchUsages(
        batches: [500],
        totalBonusUsage: 500,
      );
      expect(usages, [{'bonus': 500, 'candy': 0}]);
    });

    test('single batch partially covered by bonus', () {
      final usages = VotingUsageHelper.calculateBatchUsages(
        batches: [500],
        totalBonusUsage: 200,
      );
      expect(usages, [{'bonus': 200, 'candy': 300}]);
    });
  });
}
