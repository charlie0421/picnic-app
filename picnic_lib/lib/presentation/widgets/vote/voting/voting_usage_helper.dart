import 'package:flutter/foundation.dart';

/// Helper class for voting star candy usage calculations.
/// Extracted from _VotingDialogState._calculateUsage for testability.
class VotingUsageHelper {
  /// Calculate star_candy and star_candy_bonus usage for a vote amount.
  ///
  /// Uses bonus candy first, then regular star candy for the remainder.
  ///
  /// Returns a map with 'star_candy_usage' and 'star_candy_bonus_usage'.
  @visibleForTesting
  static Map<String, int> calculateUsage({
    required int totalAmount,
    required int starCandyBonus,
  }) {
    int starCandyUsage = 0;
    int starCandyBonusUsage = 0;
    int remainingAmount = totalAmount;

    // 1. Use bonus candy first
    if (starCandyBonus > 0 && remainingAmount > 0) {
      if (starCandyBonus >= remainingAmount) {
        starCandyBonusUsage = remainingAmount;
        remainingAmount = 0;
      } else {
        starCandyBonusUsage = starCandyBonus;
        remainingAmount -= starCandyBonus;
      }
    }

    // 2. Use regular star candy for the rest
    if (remainingAmount > 0) {
      starCandyUsage = remainingAmount;
    }

    return {
      'star_candy_usage': starCandyUsage,
      'star_candy_bonus_usage': starCandyBonusUsage,
    };
  }

  /// Validate a vote amount against the available star candy.
  ///
  /// Returns true if the vote amount is valid (> 0 and <= available).
  @visibleForTesting
  static bool isValidVoteAmount(int voteAmount, int availableStarCandy) {
    return voteAmount > 0 && voteAmount <= availableStarCandy;
  }

  /// Parse a vote amount string (may contain commas) to an integer.
  @visibleForTesting
  static int parseVoteAmount(String text) {
    return int.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  /// Calculate batch sizes for large votes to prevent timeouts.
  ///
  /// Returns a list of batch amounts that sum to [totalAmount].
  @visibleForTesting
  static List<int> calculateBatches(int totalAmount, {int batchSize = 1000}) {
    if (totalAmount <= 0) return [];
    final batches = <int>[];
    int remaining = totalAmount;
    while (remaining > 0) {
      final batch = remaining > batchSize ? batchSize : remaining;
      batches.add(batch);
      remaining -= batch;
    }
    return batches;
  }

  /// Calculate per-batch bonus and candy usage.
  ///
  /// Returns a list of maps with 'bonus' and 'candy' keys for each batch.
  @visibleForTesting
  static List<Map<String, int>> calculateBatchUsages({
    required List<int> batches,
    required int totalBonusUsage,
  }) {
    final result = <Map<String, int>>[];
    int remainingBonus = totalBonusUsage;

    for (final batch in batches) {
      final batchBonus = remainingBonus >= batch ? batch : remainingBonus;
      final batchCandy = batch - batchBonus;
      result.add({'bonus': batchBonus, 'candy': batchCandy});
      remainingBonus -= batchBonus;
    }

    return result;
  }

  // --- JMA Voting calculation methods ---

  /// Maximum daily bonus votes allowed per user.
  static const int maxDailyBonusVotes = 5;

  /// Star candy cost per regular vote in JMA voting.
  static const int starCandyPerVote = 30;

  /// Calculate usable bonus votes considering daily limit.
  ///
  /// Returns the minimum of available bonus star candy and
  /// remaining daily bonus usage (maxDaily - dailyUsed).
  @visibleForTesting
  static int getUsableBonusVotes({
    required int bonusStarCandy,
    required int dailyVoteCount,
    int maxDaily = maxDailyBonusVotes,
  }) {
    final remainingBonusUsage = maxDaily - dailyVoteCount;
    if (remainingBonusUsage <= 0 || bonusStarCandy <= 0) {
      return 0;
    }
    return bonusStarCandy < remainingBonusUsage
        ? bonusStarCandy
        : remainingBonusUsage;
  }

  /// Calculate the required star candy for a given vote amount.
  ///
  /// Bonus votes cost 1:1. Regular votes cost [starCandyPerVote]:1.
  /// Bonus is used first.
  @visibleForTesting
  static int getRequiredStarCandy({
    required int voteAmount,
    required int usableBonusVotes,
  }) {
    if (voteAmount == 0) return 0;
    if (voteAmount <= usableBonusVotes) {
      return voteAmount; // 1:1 for bonus
    }
    final remainingVotes = voteAmount - usableBonusVotes;
    final regularCost = remainingVotes * starCandyPerVote;
    return usableBonusVotes + regularCost;
  }

  /// Calculate maximum possible votes given star candy and bonus.
  @visibleForTesting
  static int getMaxPossibleVotes({
    required int starCandy,
    required int usableBonusVotes,
  }) {
    final regularVotes = starCandy ~/ starCandyPerVote;
    return usableBonusVotes + regularVotes;
  }

  /// Validate a JMA vote and return a validation result.
  ///
  /// Returns a record of (canVote, validationMessage).
  @visibleForTesting
  static ({bool canVote, String validationMessage}) validateJmaVote({
    required int voteAmount,
    required int maxPossibleVotes,
    required int requiredStarCandy,
    required int totalStarCandy,
    String Function(int)? maxVotesExceededMessage,
    String Function(int)? starCandyShortageMessage,
  }) {
    if (voteAmount <= 0) {
      return (canVote: false, validationMessage: '');
    }

    if (voteAmount > maxPossibleVotes) {
      final msg = maxVotesExceededMessage?.call(maxPossibleVotes) ??
          'Max votes exceeded: $maxPossibleVotes';
      return (canVote: false, validationMessage: msg);
    }

    if (requiredStarCandy > totalStarCandy) {
      final shortfall = requiredStarCandy - totalStarCandy;
      final msg = starCandyShortageMessage?.call(shortfall) ??
          'Star candy shortage: $shortfall';
      return (canVote: false, validationMessage: msg);
    }

    return (canVote: true, validationMessage: '');
  }

  /// Build a calculation result message for admin display.
  @visibleForTesting
  static String buildCalculationMessage({
    required int voteAmount,
    required int usableBonusVotes,
    required String Function(dynamic) formatNumber,
  }) {
    if (voteAmount <= usableBonusVotes) {
      return "JMA ${formatNumber(voteAmount)}투표 = 보너스 ${formatNumber(voteAmount)}개";
    } else if (usableBonusVotes > 0) {
      final regularCost = (voteAmount - usableBonusVotes) * starCandyPerVote;
      return "JMA ${formatNumber(voteAmount)}투표 = 보너스 ${formatNumber(usableBonusVotes)}개 + 별사탕 ${formatNumber(regularCost)}개";
    } else {
      final regularCost = voteAmount * starCandyPerVote;
      return "JMA ${formatNumber(voteAmount)}투표 = 별사탕 ${formatNumber(regularCost)}개";
    }
  }
}
