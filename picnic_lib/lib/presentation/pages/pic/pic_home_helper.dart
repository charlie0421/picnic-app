import 'package:flutter/foundation.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

/// Helper class with pure logic extracted from PicHomePage for testability.
class PicHomeHelper {
  /// Determine the vote status based on current time and vote start time.
  ///
  /// If [startAt] is after [now], the vote is upcoming; otherwise active.
  @visibleForTesting
  static VoteStatus determineVoteStatus({
    required DateTime startAt,
    required DateTime now,
  }) {
    return startAt.isAfter(now) ? VoteStatus.upcoming : VoteStatus.active;
  }

  /// Whether the PIC home page should clear the page title.
  ///
  /// Returns true when PIC portal is active, at root level, and title is non-empty.
  @visibleForTesting
  static bool shouldClearTitle({
    required bool isPicActive,
    required bool isAtRoot,
    required String currentTitle,
  }) {
    return isPicActive && isAtRoot && currentTitle.isNotEmpty;
  }

  /// Filter a list of celebs to exclude the currently selected celeb.
  @visibleForTesting
  static List<T> filterOutSelectedCeleb<T>({
    required List<T> celebs,
    required dynamic selectedId,
    required dynamic Function(T) getId,
  }) {
    return celebs.where((item) => getId(item) != selectedId).toList();
  }

  /// Get the title text for a gallery item based on locale.
  @visibleForTesting
  static String getGalleryTitle(String? titleEn, String? titleKo, String locale) {
    if (locale == 'ko') {
      return titleKo ?? titleEn ?? '';
    }
    return titleEn ?? titleKo ?? '';
  }
}
