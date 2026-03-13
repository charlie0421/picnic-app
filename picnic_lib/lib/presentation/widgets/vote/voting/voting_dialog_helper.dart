import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure-logic helpers extracted from [VotingDialog] for testability.
///
/// NOTE: Vote amount parsing, validation, batch calculation, and usage
/// calculation live in [VotingUsageHelper]. Completion result parsing lives
/// in [VotingCompleteHelper]. This file covers the remaining presentation
/// logic that doesn't depend on Flutter widgets or Riverpod providers.
class VotingDialogHelper {
  const VotingDialogHelper._();

  // ---------------------------------------------------------------------------
  // Artist image resolution
  // ---------------------------------------------------------------------------

  /// Returns the image URL to display for a vote item.
  ///
  /// If the item has an individual artist (non-zero id), uses the artist image.
  /// Otherwise falls back to the artist group image. Returns `null` when
  /// neither is available.
  @visibleForTesting
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

  // ---------------------------------------------------------------------------
  // Dialog type routing
  // ---------------------------------------------------------------------------

  /// Whether the JMA voting dialog should be used.
  ///
  /// Returns `true` only when the portal is *not* PIC and the partner field
  /// (case-insensitive) equals `'jma'`.
  @visibleForTesting
  static bool shouldUseJmaDialog({
    required bool isPicPortal,
    required String? partner,
  }) {
    if (isPicPortal) return false;
    return partner?.toLowerCase() == 'jma';
  }

  /// Returns the Supabase Edge Function name to invoke for a vote.
  @visibleForTesting
  static String getVotingFunctionName({required bool isPicPortal}) {
    return isPicPortal ? 'pic-voting-v2' : 'voting-v2';
  }

  // ---------------------------------------------------------------------------
  // Vote button state
  // ---------------------------------------------------------------------------

  /// Determines the vote button state from the current dialog flags.
  @visibleForTesting
  static VoteButtonState determineVoteButtonState({
    required bool canVote,
    required bool isVoting,
  }) {
    if (isVoting) return VoteButtonState.loading;
    if (canVote) return VoteButtonState.enabled;
    return VoteButtonState.disabled;
  }

  // ---------------------------------------------------------------------------
  // Error message visibility
  // ---------------------------------------------------------------------------

  /// Whether the "need recharge" error message should be visible.
  ///
  /// Shown when the user has typed a value but it exceeds their balance.
  @visibleForTesting
  static bool shouldShowErrorMessage({
    required bool canVote,
    required bool hasValue,
  }) {
    return !canVote && hasValue;
  }

  // ---------------------------------------------------------------------------
  // Vote input formatting
  // ---------------------------------------------------------------------------

  /// Processes raw digit input for the vote amount field.
  ///
  /// - Strips leading zeros.
  /// - Returns `null` when the resulting value is empty or zero (caller should
  ///   clear the field).
  /// - Otherwise returns the comma-formatted string.
  @visibleForTesting
  static String? formatVoteInput(String rawDigits) {
    // Remove any existing commas (defensive)
    String cleaned = rawDigits.replaceAll(',', '');

    // Strip leading zeros
    cleaned = cleaned.replaceFirst(RegExp(r'^0+'), '');

    if (cleaned.isEmpty) return null;

    final parsed = int.tryParse(cleaned);
    if (parsed == null || parsed == 0) return null;

    return _formatWithCommas(cleaned);
  }

  /// Formats a numeric string with comma thousand-separators.
  static String _formatWithCommas(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // "Use all" toggle
  // ---------------------------------------------------------------------------

  /// Computes the new state when the "use all" checkbox is toggled.
  ///
  /// Returns a record of (checkAll, hasValue, formattedAmount).
  /// [formattedAmount] is `null` when the checkbox is being unchecked
  /// (caller should clear the text field).
  @visibleForTesting
  static ({bool checkAll, bool hasValue, String? formattedAmount})
      computeCheckAllToggle({
    required bool currentCheckAll,
    required int availableStarCandy,
    required String Function(dynamic) formatNumber,
  }) {
    final newCheckAll = !currentCheckAll;
    if (newCheckAll) {
      return (
        checkAll: true,
        hasValue: true,
        formattedAmount: formatNumber(availableStarCandy),
      );
    }
    return (checkAll: false, hasValue: false, formattedAmount: null);
  }

  // ---------------------------------------------------------------------------
  // Total star candy calculation
  // ---------------------------------------------------------------------------

  /// Computes total available star candy (regular + bonus).
  @visibleForTesting
  static int computeTotalStarCandy({
    required int starCandy,
    required int starCandyBonus,
  }) {
    return starCandy + starCandyBonus;
  }

  // ---------------------------------------------------------------------------
  // Vote pre-check
  // ---------------------------------------------------------------------------

  /// Validates a vote before submission and returns a failure reason, or `null`
  /// if the vote is valid.
  ///
  /// Possible failure reasons:
  /// - [VoteFailReason.zeroAmount] if [voteAmount] is 0.
  /// - [VoteFailReason.insufficientBalance] if [voteAmount] > [availableStarCandy].
  @visibleForTesting
  static VoteFailReason? preCheckVote({
    required int voteAmount,
    required int availableStarCandy,
  }) {
    if (voteAmount == 0) return VoteFailReason.zeroAmount;
    if (voteAmount > availableStarCandy) {
      return VoteFailReason.insufficientBalance;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Partnership display
  // ---------------------------------------------------------------------------

  /// Whether the partner logo section should be displayed.
  @visibleForTesting
  static bool hasPartnerLogo({
    required bool? isPartnership,
    required String? partner,
  }) {
    return (isPartnership ?? false) &&
        partner != null &&
        partner.isNotEmpty;
  }
}

/// Represents the visual state of the vote button.
enum VoteButtonState { disabled, enabled, loading }

/// Reasons a vote may fail pre-check validation.
enum VoteFailReason {
  zeroAmount,
  insufficientBalance,
}
