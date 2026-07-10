import 'dart:math' as math;

import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';

/// Pure logic helper for VoteDetailPage.
/// All methods are static and free of widget/state dependencies.
class VoteDetailHelper {
  VoteDetailHelper._();

  /// Fraction digits used to render [pct] as a percentage string.
  ///
  /// Two significant digits, clamped to 2..4. picnic votes are extremely
  /// top-heavy — the top three candidates hold 90%+ and everyone below rank 4
  /// falls off a cliff — so a fixed two-decimal format collapses most of the
  /// list to "0.00%".
  static int sharePercentDecimals(double pct) {
    if (pct <= 0) return 2;
    final magnitude = (math.log(pct) / math.ln10).floor();
    return (2 - magnitude - 1).clamp(2, 4);
  }

  /// Format [votes] as a share of [total].
  ///
  /// Returns an em dash when there is nothing to show, and a floor marker
  /// rather than a string of zeros for vanishingly small shares.
  static String formatSharePercent(int? votes, int total) {
    final v = votes ?? 0;
    if (v <= 0 || total <= 0) return '—';

    final pct = v / total * 100;
    if (pct < 0.0001) return '<0.0001%';

    return '${pct.toStringAsFixed(sharePercentDecimals(pct))}%';
  }

  /// Sum of every item's voteTotal. Null items and null totals count as 0.
  static int sumVoteTotals(List<VoteItemModel?> items) {
    var sum = 0;
    for (final item in items) {
      sum += item?.voteTotal ?? 0;
    }
    return sum;
  }

  /// Compute rank map from a list of vote items.
  /// Items with the same voteTotal share the same rank.
  /// Returns a map of item id -> rank.
  static Map<int, int> computeRanks(List<VoteItemModel?> items) {
    final ranks = <int, int>{};
    final sortedItems = items.where((item) => item != null).toList()
      ..sort((a, b) => (b!.voteTotal ?? 0).compareTo(a!.voteTotal ?? 0));

    int currentRank = 1;
    int? previousVoteTotal;

    for (var i = 0; i < sortedItems.length; i++) {
      final item = sortedItems[i]!;

      if (previousVoteTotal != null && item.voteTotal == previousVoteTotal) {
        // Same rank maintained
      } else {
        currentRank = i + 1;
      }

      ranks[item.id] = currentRank;
      previousVoteTotal = item.voteTotal;
    }

    return ranks;
  }

  /// Pick the single item that should carry the "N votes behind #1" tooltip.
  ///
  /// Returns null unless exactly one item holds rank 2 and its gap to the
  /// leader is positive. [computeRanks] uses competition ranking, so a tie at
  /// rank 2 yields several rank-2 items (the tooltip would be drawn on each)
  /// and a tie at rank 1 yields no rank-2 item at all.
  static GapTooltipTarget? pickGapTooltipTarget(
    List<VoteItemModel?> items,
    Map<int, int> ranks,
  ) {
    int? leaderVotes;
    VoteItemModel? runnerUp;
    var rank2Count = 0;

    for (final item in items) {
      if (item == null) continue;
      final rank = ranks[item.id];
      if (rank == 1) {
        leaderVotes ??= item.voteTotal ?? 0;
      } else if (rank == 2) {
        rank2Count++;
        runnerUp = item;
      }
    }

    if (leaderVotes == null || runnerUp == null || rank2Count != 1) return null;

    final gap = leaderVotes - (runnerUp.voteTotal ?? 0);
    if (gap <= 0) return null;

    return GapTooltipTarget(itemId: runnerUp.id, gapVotes: gap);
  }

  /// Compare two lists of VoteItemModel by id and voteTotal.
  static bool areDataListsEqual(
    List<VoteItemModel?> list1,
    List<VoteItemModel?> list2,
  ) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      final item1 = list1[i];
      final item2 = list2[i];

      if (item1 == null && item2 == null) continue;
      if (item1 == null || item2 == null) return false;

      if (item1.id != item2.id || item1.voteTotal != item2.voteTotal) {
        return false;
      }
    }

    return true;
  }

  /// Return the text from [nameMap] whose language matches the [query].
  /// Checks Korean (including initial consonant matching) first, then English.
  /// Falls back to [fallbackText] if neither matches.
  static String getMatchingText(
    Map<String, dynamic> nameMap,
    String query, {
    String fallbackText = '',
  }) {
    final lowerQuery = query.toLowerCase();

    // Korean text match (plain + initial consonant)
    final koText = nameMap['ko']?.toString() ?? '';
    if (koText.isNotEmpty &&
        (koText.toLowerCase().contains(lowerQuery) ||
            KoreanSearchUtils.matchesKoreanInitials(koText, query))) {
      return koText;
    }

    // English text match
    final enText = nameMap['en']?.toString() ?? '';
    if (enText.isNotEmpty && enText.toLowerCase().contains(lowerQuery)) {
      return enText;
    }

    return fallbackText;
  }

  /// Convert a relative image path to an absolute URL using the given [cdnUrl].
  /// If [imageUrl] is already absolute or empty, return as-is.
  static String makeFullImageUrl(String imageUrl, String cdnUrl) {
    if (imageUrl.isEmpty) {
      return imageUrl;
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    final cleanCdnUrl =
        cdnUrl.endsWith('/') ? cdnUrl.substring(0, cdnUrl.length - 1) : cdnUrl;
    final cleanImageUrl =
        imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;

    return '$cleanCdnUrl/$cleanImageUrl';
  }

  /// Calculate the vote count difference for an item.
  ///
  /// Returns the difference between [currentVoteTotal] and [previousVoteTotal].
  /// If either is null, returns 0.
  static int calculateVoteCountDiff(int? currentVoteTotal, int? previousVoteTotal) {
    if (currentVoteTotal == null || previousVoteTotal == null) return 0;
    return currentVoteTotal - previousVoteTotal;
  }

  /// Determine whether a rank has changed and the direction of change.
  ///
  /// Returns a [RankChangeResult] indicating whether the rank changed and
  /// whether it went up (lower number = higher rank).
  static RankChangeResult detectRankChange(int currentRank, int previousRank) {
    final changed = previousRank != currentRank;
    final rankUp = changed && previousRank > currentRank;
    return RankChangeResult(changed: changed, rankUp: rankUp);
  }

  /// Get the image URL for a vote item, preferring artist image over group image.
  ///
  /// Returns empty string if no image is available.
  static String getVoteItemImageUrl(VoteItemModel item) {
    if ((item.artist?.id ?? 0) != 0) {
      return item.artist?.image ?? '';
    }
    return item.artistGroup?.image ?? '';
  }

  /// Get display name for a vote item.
  ///
  /// Uses artist name if available, otherwise falls back to group name.
  /// Returns the name map for further locale processing.
  static Map<String, dynamic> getVoteItemNameMap(VoteItemModel item) {
    if ((item.artist?.id ?? 0) != 0) {
      return item.artist?.name ?? {};
    }
    return item.artistGroup?.name ?? {};
  }

  /// Get the group name map for a vote item's artist (if any).
  ///
  /// Returns null if the item has no artist or the artist has no group.
  static Map<String, dynamic>? getVoteItemGroupNameMap(VoteItemModel item) {
    if ((item.artist?.id ?? 0) != 0 && item.artist?.artistGroup?.name != null) {
      return item.artist!.artistGroup!.name;
    }
    return null;
  }

  /// Filter vote item indices by search query.
  /// Searches artist name (ko/en + Korean initials), artist group name,
  /// and direct group name.
  /// Returns all indices when [query] is empty.
  static List<int> getFilteredIndices(
    List<VoteItemModel?> data,
    String query,
  ) {
    if (query.isEmpty) {
      return List<int>.generate(data.length, (index) => index);
    }

    final lowerQuery = query.toLowerCase();

    return List<int>.generate(data.length, (index) => index).where((index) {
      final item = data[index];
      if (item == null) return false;

      // Artist name search (Korean + English + initials)
      if (item.artist?.id != null && (item.artist?.id ?? 0) != 0) {
        final artistNameKo = item.artist?.name['ko']?.toString() ?? '';
        final artistNameEn = item.artist?.name['en']?.toString() ?? '';

        if ((artistNameKo.isNotEmpty &&
                (artistNameKo.toLowerCase().contains(lowerQuery) ||
                    KoreanSearchUtils.matchesKoreanInitials(
                      artistNameKo,
                      query,
                    ))) ||
            (artistNameEn.isNotEmpty &&
                artistNameEn.toLowerCase().contains(lowerQuery))) {
          return true;
        }

        // Artist's group name search
        if (item.artist?.artistGroup?.name != null) {
          final artistGroupNameKo =
              item.artist!.artistGroup!.name['ko']?.toString() ?? '';
          final artistGroupNameEn =
              item.artist!.artistGroup!.name['en']?.toString() ?? '';

          if ((artistGroupNameKo.isNotEmpty &&
                  (artistGroupNameKo.toLowerCase().contains(lowerQuery) ||
                      KoreanSearchUtils.matchesKoreanInitials(
                        artistGroupNameKo,
                        query,
                      ))) ||
              (artistGroupNameEn.isNotEmpty &&
                  artistGroupNameEn.toLowerCase().contains(lowerQuery))) {
            return true;
          }
        }
      }

      // Direct group search (no artist, group only)
      if (item.artistGroup?.id != null && (item.artistGroup?.id ?? 0) != 0) {
        final groupNameKo = item.artistGroup?.name['ko']?.toString() ?? '';
        final groupNameEn = item.artistGroup?.name['en']?.toString() ?? '';

        if ((groupNameKo.isNotEmpty &&
                (groupNameKo.toLowerCase().contains(lowerQuery) ||
                    KoreanSearchUtils.matchesKoreanInitials(
                      groupNameKo,
                      query,
                    ))) ||
            (groupNameEn.isNotEmpty &&
                groupNameEn.toLowerCase().contains(lowerQuery))) {
          return true;
        }
      }

      return false;
    }).toList();
  }
}

/// Result of [VoteDetailHelper.detectRankChange].
class RankChangeResult {
  final bool changed;
  final bool rankUp;

  const RankChangeResult({required this.changed, required this.rankUp});
}

/// Result of [VoteDetailHelper.pickGapTooltipTarget].
class GapTooltipTarget {
  final int itemId;
  final int gapVotes;

  const GapTooltipTarget({required this.itemId, required this.gapVotes});
}
