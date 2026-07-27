import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

/// Pure helper functions extracted from VoteHomePage.
/// All methods are static and free of Flutter/UI dependencies.
class VoteHomeHelper {
  VoteHomeHelper._();

  /// Default page size used for pagination.
  static const int pageSize = 20;

  /// Image-cache usage threshold (70 %) that triggers partial eviction.
  static const double cacheUsageThreshold = 0.7;

  /// Target cache ratio after eviction.
  static const double cacheTargetRatio = 0.5;

  // ---------------------------------------------------------------------------
  // Vote status
  // ---------------------------------------------------------------------------

  /// Determine the [VoteStatus] of a vote based on the current time.
  /// Returns [VoteStatus.upcoming] when [startAt] is in the future,
  /// otherwise [VoteStatus.active].
  static VoteStatus determineVoteStatus(DateTime startAt, {DateTime? now}) {
    final reference = now ?? DateTime.now().toUtc();
    return startAt.isAfter(reference) ? VoteStatus.upcoming : VoteStatus.active;
  }

  // ---------------------------------------------------------------------------
  // Deduplication
  // ---------------------------------------------------------------------------

  /// Merge two vote lists and remove duplicates by [VoteModel.id].
  /// When the same id appears in both lists the first occurrence wins.
  static List<VoteModel> deduplicateVotes(
    List<VoteModel> listA,
    List<VoteModel> listB,
  ) {
    final byId = <int, VoteModel>{};
    for (final v in [...listA, ...listB]) {
      byId.putIfAbsent(v.id, () => v);
    }
    return byId.values.toList();
  }

  // ---------------------------------------------------------------------------
  // Category filtering
  // ---------------------------------------------------------------------------

  /// Returns `true` when a vote's category is considered an image/weekly type.
  static bool isImageOrWeeklyCategory(String? voteCategory) {
    final cat = (voteCategory ?? '').toLowerCase();
    return cat.contains('image') || cat.contains('weekly');
  }

  // ---------------------------------------------------------------------------
  // Sorting
  // ---------------------------------------------------------------------------

  /// Sort votes by [VoteModel.stopAt] in ascending order (earliest first).
  /// Votes with a `null` stopAt are treated as epoch-zero.
  static List<VoteModel> sortByStopAtAsc(List<VoteModel> votes) {
    final copy = List<VoteModel>.of(votes);
    copy.sort((a, b) {
      final aTs = a.stopAt?.millisecondsSinceEpoch ?? 0;
      final bTs = b.stopAt?.millisecondsSinceEpoch ?? 0;
      return aTs.compareTo(bTs);
    });
    return copy;
  }

  // ---------------------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------------------

  /// Take the first [pageSize] items from [votes].
  static List<VoteModel> takePageSlice(
    List<VoteModel> votes, [
    int size = pageSize,
  ]) {
    return votes.take(size).toList();
  }

  /// Returns `true` when the number of returned items is less than [size],
  /// indicating that no more pages are available.
  static bool isLastPage(int itemCount, [int size = pageSize]) {
    return itemCount < size;
  }

  /// Calculate the next page key for the paging controller.
  /// Returns `null` when the current page is the last one.
  static int? nextPageKey({
    required List<VoteModel>? items,
    required int? lastKey,
    int size = pageSize,
  }) {
    if (items == null) return 1;
    if (isLastPage(items.length, size)) return null;
    return (lastKey ?? 0) + 1;
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when the vote portal is active and at the root level,
  /// meaning the page title should be cleared.
  static bool shouldClearTitle({
    required bool isVoteActive,
    required bool isAtRoot,
    required String pageTitle,
  }) {
    return isVoteActive && isAtRoot && pageTitle.isNotEmpty;
  }

  /// Returns `true` when [navigationStack] is `null` or has at most one entry,
  /// meaning the user is at the navigation root.
  static bool isNavigationRoot(List<Object>? navigationStack) {
    return navigationStack == null || navigationStack.length <= 1;
  }

  // ---------------------------------------------------------------------------
  // Reward helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` for the first 3 items (index 0–2), which receive high
  /// image loading priority.
  static bool isHighPriorityReward(int index) => index < 3;

  // ---------------------------------------------------------------------------
  // Image cache helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when the image cache usage exceeds [cacheUsageThreshold].
  static bool shouldOptimizeCache(int currentBytes, int maximumBytes) {
    if (maximumBytes <= 0) return false;
    return currentBytes / maximumBytes > cacheUsageThreshold;
  }

  /// Calculate the target cache size after a partial eviction.
  static int targetCacheSize(int maximumBytes) {
    return (maximumBytes * cacheTargetRatio).round();
  }
}
