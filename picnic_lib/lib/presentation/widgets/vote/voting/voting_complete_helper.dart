import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure-logic helpers extracted from [VotingCompleteDialog] for testability.
class VotingCompleteHelper {
  const VotingCompleteHelper._();

  /// Parses the 'updatedAt' field from a vote result map.
  ///
  /// Returns a parsed [DateTime] if the value is a valid ISO-8601 string,
  /// otherwise returns [DateTime.now].
  @visibleForTesting
  static DateTime parseUpdatedAt(Map<String, dynamic> result) {
    final updatedAtStr = result['updatedAt'] as String?;
    if (updatedAtStr == null) return DateTime.now();
    final parsed = DateTime.tryParse(updatedAtStr);
    return parsed ?? DateTime.now();
  }

  /// Extracts the 'addedVoteTotal' value from a vote result map.
  ///
  /// Returns 0 if the key is missing or null.
  @visibleForTesting
  static int extractAddedVoteTotal(Map<String, dynamic> result) {
    return (result['addedVoteTotal'] as num?)?.toInt() ?? 0;
  }

  /// Determines whether an artist (individual) or group should be displayed,
  /// and returns the appropriate name map.
  ///
  /// Returns `true` if the individual artist should be shown
  /// (i.e. artist is non-null and artist.id != 0).
  @visibleForTesting
  static bool shouldShowArtist(int? artistId) {
    return (artistId ?? 0) != 0;
  }
}
