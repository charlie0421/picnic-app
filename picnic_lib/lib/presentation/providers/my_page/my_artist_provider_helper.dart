import 'package:flutter/foundation.dart';

/// Pure helper functions extracted from my_artist_provider for testability.
@visibleForTesting
class MyArtistProviderHelper {
  const MyArtistProviderHelper._();

  /// Maximum number of artist bookmarks a user may have.
  static const int maxBookmarks = 5;

  /// Returns true if the current bookmark [count] has reached the maximum.
  @visibleForTesting
  static bool isBookmarkLimitReached(int count) {
    return count >= maxBookmarks;
  }
}
