import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure logic helper for JmaVotingDialog.
///
/// All methods are static, free of Flutter/UI/provider dependencies,
/// and therefore easy to unit-test.
@visibleForTesting
class JmaVotingDialogHelper {
  JmaVotingDialogHelper._(); // prevent instantiation

  /// Daily maximum bonus star candy usage.
  static const int maxDailyVotes = 5;

  /// Exchange rate: regular star candy per 1 JMA vote.
  static const int regularCandyPerVote = 30;

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Parse the vote amount from raw text input (may contain commas).
  /// Returns 0 when the text is empty or not a valid integer.
  static int parseVoteAmount(String text) {
    return int.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  /// Strip leading zeros from a numeric string.
  /// Returns empty string when input is all zeros or empty.
  static String stripLeadingZeros(String text) {
    final stripped = text.replaceFirst(RegExp(r'^0+'), '');
    return stripped;
  }

  // ---------------------------------------------------------------------------
  // Star-candy / bonus calculations
  // ---------------------------------------------------------------------------

  /// Total star candy = regular + bonus.
  static int totalStarCandy({
    required int regularStarCandy,
    required int bonusStarCandy,
  }) {
    return regularStarCandy + bonusStarCandy;
  }

  /// How many bonus votes are actually usable today, considering
  /// the daily cap and how many bonus candies the user holds.
  static int usableBonusVotes({
    required int bonusStarCandy,
    required int dailyVoteCount,
    int maxDaily = maxDailyVotes,
  }) {
    final remaining = maxDaily - dailyVoteCount;
    if (remaining <= 0 || bonusStarCandy <= 0) return 0;
    return bonusStarCandy < remaining ? bonusStarCandy : remaining;
  }

  /// The total star-candy cost for [voteAmount] votes.
  ///
  /// Bonus candy is consumed first at a 1:1 ratio, then regular candy
  /// at [regularCandyPerVote]:1.
  static int requiredStarCandy({
    required int voteAmount,
    required int usableBonusVoteCount,
  }) {
    if (voteAmount <= 0) return 0;

    if (voteAmount <= usableBonusVoteCount) {
      return voteAmount; // all covered by bonus (1:1)
    }

    final regularVotes = voteAmount - usableBonusVoteCount;
    return usableBonusVoteCount + regularVotes * regularCandyPerVote;
  }

  /// Maximum votes the user can cast, combining bonus and regular candy.
  static int maxPossibleVotes({
    required int regularStarCandy,
    required int usableBonusVoteCount,
  }) {
    final regularVotes = regularStarCandy ~/ regularCandyPerVote;
    return usableBonusVoteCount + regularVotes;
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Result of vote-amount validation.
  static ({bool canVote, bool hasValue, String validationMessage}) validateVote({
    required int voteAmount,
    required int maxPossibleVoteCount,
    required int requiredStarCandyAmount,
    required int totalStarCandyAmount,
    /// Localised message generator for "max votes exceeded".
    required String Function(int maxVotes) maxVotesExceededMessage,
    /// Localised message generator for "star candy shortage".
    required String Function(int shortfall) starCandyShortageMessage,
  }) {
    if (voteAmount <= 0) {
      return (canVote: false, hasValue: false, validationMessage: '');
    }

    if (voteAmount > maxPossibleVoteCount) {
      return (
        canVote: false,
        hasValue: true,
        validationMessage: maxVotesExceededMessage(maxPossibleVoteCount),
      );
    }

    if (requiredStarCandyAmount > totalStarCandyAmount) {
      final shortfall = requiredStarCandyAmount - totalStarCandyAmount;
      return (
        canVote: false,
        hasValue: true,
        validationMessage: starCandyShortageMessage(shortfall),
      );
    }

    return (canVote: true, hasValue: true, validationMessage: '');
  }

  // ---------------------------------------------------------------------------
  // Usage breakdown (sent to the edge function)
  // ---------------------------------------------------------------------------

  /// Returns the star-candy usage split between regular and bonus.
  ///
  /// `starCandyUsage` = regular star candy *count* consumed.
  /// `starCandyBonusUsage` = bonus star candy *count* consumed.
  static ({int starCandyUsage, int starCandyBonusUsage}) calculateUsage({
    required int voteAmount,
    required int usableBonusVoteCount,
  }) {
    if (voteAmount <= usableBonusVoteCount) {
      return (starCandyUsage: 0, starCandyBonusUsage: voteAmount);
    }

    final regularVotes = voteAmount - usableBonusVoteCount;
    return (
      starCandyUsage: regularVotes * regularCandyPerVote,
      starCandyBonusUsage: usableBonusVoteCount,
    );
  }

  /// Determine how many bonus votes are actually used for a given voteAmount.
  static int bonusVotesUsed({
    required int voteAmount,
    required int usableBonusVoteCount,
  }) {
    return voteAmount <= usableBonusVoteCount ? voteAmount : usableBonusVoteCount;
  }

  // ---------------------------------------------------------------------------
  // Display / formatting helpers
  // ---------------------------------------------------------------------------

  /// Build the admin-facing calculation result message.
  ///
  /// [formatNumber] should be a function like `formatNumberWithComma`.
  static String calculationResultMessage({
    required int voteAmount,
    required int usableBonusVoteCount,
    required String Function(dynamic) formatNumber,
  }) {
    if (voteAmount <= usableBonusVoteCount) {
      return 'JMA ${formatNumber(voteAmount)}투표 = '
          '보너스 ${formatNumber(voteAmount)}개';
    } else if (usableBonusVoteCount > 0) {
      final regularCandyNeeded =
          (voteAmount - usableBonusVoteCount) * regularCandyPerVote;
      return 'JMA ${formatNumber(voteAmount)}투표 = '
          '보너스 ${formatNumber(usableBonusVoteCount)}개 + '
          '별사탕 ${formatNumber(regularCandyNeeded)}개';
    } else {
      final regularCandyNeeded = voteAmount * regularCandyPerVote;
      return 'JMA ${formatNumber(voteAmount)}투표 = '
          '별사탕 ${formatNumber(regularCandyNeeded)}개';
    }
  }

  /// Remaining bonus votes for today.
  static int remainingDailyVotes({
    required int dailyVoteCount,
    int maxDaily = maxDailyVotes,
  }) {
    final remaining = maxDaily - dailyVoteCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Whether the user still has remaining daily bonus votes.
  static bool hasDailyVotesRemaining({
    required int dailyVoteCount,
    int maxDaily = maxDailyVotes,
  }) {
    return remainingDailyVotes(dailyVoteCount: dailyVoteCount, maxDaily: maxDaily) > 0;
  }

  /// Resolve artist image URL from vote item data.
  ///
  /// If the vote item has a solo artist (non-zero id), use the artist image;
  /// otherwise fall back to the artist group image.
  static String? resolveArtistImageUrl({
    required int? artistId,
    required String? artistImage,
    required String? artistGroupImage,
  }) {
    if ((artistId ?? 0) != 0) {
      return artistImage;
    }
    return artistGroupImage;
  }

  /// Whether to show solo-artist vs group display.
  /// Returns `true` when the vote item represents a solo artist.
  static bool isSoloArtist({required int? artistId}) {
    return (artistId ?? 0) != 0;
  }

  /// Number of regular-star-candy-based votes (floor division).
  static int regularStarCandyVotes({required int regularStarCandy}) {
    return regularStarCandy ~/ regularCandyPerVote;
  }
}
