import 'package:flutter/foundation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

/// Helper class with pure logic extracted from ArtistSelectListView
/// for testability.
class ArtistListHelper {
  /// Determine if the item at [index] is the first bookmark item in [items].
  @visibleForTesting
  static bool isFirstBookmarkItem(List<ArtistModel> items, int index) {
    if (items[index].isBookmarked != true) return false;
    if (index == 0) return true;
    return items[index - 1].isBookmarked != true;
  }

  /// Determine if the item at [index] is the first non-bookmark item in [items].
  @visibleForTesting
  static bool isFirstNonBookmarkItem(List<ArtistModel> items, int index) {
    if (items[index].isBookmarked == true) return false;
    if (index == 0) return true;
    return items[index - 1].isBookmarked == true;
  }

  /// Whether section headers should be shown given config and search query.
  @visibleForTesting
  static bool shouldShowSectionHeaders({
    required bool hideSectionHeaderOnSearch,
    required String searchQuery,
  }) {
    return hideSectionHeaderOnSearch ? searchQuery.isEmpty : true;
  }

  /// Reorder items after a bookmark state change.
  ///
  /// Returns a new list with the item at [artistId] moved to the correct
  /// section based on [isBookmarked].
  @visibleForTesting
  static List<ArtistModel> reorderAfterBookmarkChange({
    required List<ArtistModel> items,
    required int artistId,
    required bool isBookmarked,
  }) {
    final result = List<ArtistModel>.from(items);
    final itemIndex = result.indexWhere((item) => item.id == artistId);
    if (itemIndex == -1) return result;

    final item = result[itemIndex];
    final updatedItem = item.copyWith(isBookmarked: isBookmarked);
    result.removeAt(itemIndex);

    if (isBookmarked) {
      // Insert after last bookmark
      final lastBookmarkIndex =
          result.lastIndexWhere((i) => i.isBookmarked == true);
      result.insert(lastBookmarkIndex + 1, updatedItem);
    } else {
      // Insert at first non-bookmark position
      final firstNonBookmarkIndex =
          result.indexWhere((i) => i.isBookmarked != true);
      final insertIndex =
          firstNonBookmarkIndex == -1 ? result.length : firstNonBookmarkIndex;
      result.insert(insertIndex, updatedItem);
    }

    return result;
  }

  /// Resolve the image URL for an artist item.
  @visibleForTesting
  static String resolveImageUrl(ArtistModel item) {
    return item.image ?? 'artist/${item.id}/image.png';
  }

  /// Determine whether to load more data based on scroll position.
  @visibleForTesting
  static bool shouldLoadMore({
    required double currentPixels,
    required double maxScrollExtent,
    double threshold = 200.0,
  }) {
    return currentPixels >= maxScrollExtent - threshold;
  }

  /// Determine whether there are more pages based on result count.
  @visibleForTesting
  static bool hasMorePages({
    required int resultCount,
    required int pageSize,
  }) {
    return resultCount >= pageSize;
  }
}
