import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:picnic_lib/core/services/auth/edge_auth_retry.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum VotingAuthRecoveryPhase {
  refreshStarted,
  refreshSucceeded,
  refreshFailed,
  retryFailed,
}

extension VotingAuthRecoveryPhaseName on VotingAuthRecoveryPhase {
  String get sentryValue => switch (this) {
    VotingAuthRecoveryPhase.refreshStarted => 'refresh_started',
    VotingAuthRecoveryPhase.refreshSucceeded => 'refresh_succeeded',
    VotingAuthRecoveryPhase.refreshFailed => 'refresh_failed',
    VotingAuthRecoveryPhase.retryFailed => 'retry_failed',
  };
}

class VotingAuthRecoveryEvent {
  const VotingAuthRecoveryEvent(this.phase, {required this.status});

  final VotingAuthRecoveryPhase phase;
  final int status;
}

/// Pure-logic helpers extracted from [VotingDialog] for testability.
///
/// NOTE: Vote amount parsing, validation, batch calculation, and usage
/// calculation live in [VotingUsageHelper]. Completion result parsing lives
/// in [VotingCompleteHelper]. This file covers the remaining presentation
/// logic that doesn't depend on Flutter widgets or Riverpod providers.
class VotingDialogHelper {
  const VotingDialogHelper._();

  /// Best-effort wallet refresh for post-failure recovery.
  ///
  /// A vote failure must surface its error and restore the dialog immediately;
  /// the follow-up wallet refresh is advisory only. This never rethrows and is
  /// bounded by [timeout], so a hanging or failing refresh can neither block
  /// dialog dismissal nor mask the original vote error.
  static Future<void> bestEffortWalletRefresh(
    Future<void> Function() refresh, {
    Duration timeout = const Duration(seconds: 5),
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      await refresh().timeout(timeout);
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }

  static Future<T> invokeVotingWithAuthRecovery<T>({
    required Future<T> Function() invoke,
    required Future<bool> Function() refresh,
    void Function(VotingAuthRecoveryEvent event)? onRecovery,
  }) async {
    try {
      return await invokeWithAuthRecovery(
        invoke: invoke,
        onRetryFailure: (error) => onRecovery?.call(
          VotingAuthRecoveryEvent(
            VotingAuthRecoveryPhase.retryFailed,
            status: _httpStatus(error),
          ),
        ),
        refresh: () async {
          onRecovery?.call(
            const VotingAuthRecoveryEvent(
              VotingAuthRecoveryPhase.refreshStarted,
              status: 401,
            ),
          );
          try {
            final refreshed = await refresh();
            onRecovery?.call(
              VotingAuthRecoveryEvent(
                refreshed
                    ? VotingAuthRecoveryPhase.refreshSucceeded
                    : VotingAuthRecoveryPhase.refreshFailed,
                status: 401,
              ),
            );
            return refreshed;
          } catch (_) {
            onRecovery?.call(
              const VotingAuthRecoveryEvent(
                VotingAuthRecoveryPhase.refreshFailed,
                status: 401,
              ),
            );
            rethrow;
          }
        },
      );
    } on EdgeAuthRecoveryException {
      rethrow;
    }
  }

  static int _httpStatus(Object error) {
    if (error is FunctionException) return error.status;
    return 0;
  }

  static Map<String, String> authRecoveryTags({
    required String portal,
    required VotingAuthRecoveryEvent event,
  }) => {
    'portal': portal,
    'phase': event.phase.sentryValue,
    'status': event.status.toString(),
  };

  static String resolveVoteFailureMessage({
    required Object? error,
    required String reLoginMessage,
    required String genericMessage,
    required String endedMessage,
    required String upcomingMessage,
    required String insufficientBalanceMessage,
  }) {
    if (error is EdgeAuthRecoveryException) return reLoginMessage;
    if (error is FunctionException) {
      final details = error.details;
      final reason = details is Map ? details['reason'] : null;
      if (error.status == 403) {
        if (reason == 'ended') return endedMessage;
        if (reason == 'not_started') return upcomingMessage;
      }
      // The Edge Function answers `{"error": "WALLET_INSUFFICIENT_BALANCE"}`,
      // which carries no `message`, so this used to fall through to the generic
      // "vote failed" title — the most common vote failure in production told
      // the user nothing. Matched against the stringified details so a JSON
      // string body reads the same as a decoded map.
      if (error.status == 409 &&
          '$details'.contains('WALLET_INSUFFICIENT_BALANCE')) {
        return insufficientBalanceMessage;
      }
      final serverMessage = details is Map ? details['message'] : null;
      if (serverMessage is String && serverMessage.trim().isNotEmpty) {
        return serverMessage;
      }
    }
    return genericMessage;
  }

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
  static bool shouldUseJmaDialog({
    required bool isPicPortal,
    required String? partner,
  }) {
    return !isPicPortal && partner?.trim().toLowerCase() == 'jma';
  }

  /// Returns the Supabase Edge Function name to invoke for a vote.
  static String getVotingFunctionName({required bool isPicPortal}) {
    return isPicPortal ? 'pic-voting-v2' : 'voting-v2';
  }

  static bool hasGeneralVoteBalance(WalletSummaryModel wallet, BigInt amount) =>
      amount <= wallet.cotton + wallet.bonus + wallet.star;

  static const int generalVoteMaximum = 2147483647;

  static BigInt cappedGeneralVoteBalance(WalletSummaryModel wallet) {
    final balance = wallet.cotton + wallet.bonus + wallet.star;
    final maximum = BigInt.from(generalVoteMaximum);
    return balance > maximum ? maximum : balance;
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
    return (isPartnership ?? false) && partner != null && partner.isNotEmpty;
  }
}

/// Represents the visual state of the vote button.
enum VoteButtonState { disabled, enabled, loading }

/// Reasons a vote may fail pre-check validation.
enum VoteFailReason { zeroAmount, insufficientBalance }
