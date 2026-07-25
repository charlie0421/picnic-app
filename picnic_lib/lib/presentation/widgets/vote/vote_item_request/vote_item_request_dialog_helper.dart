import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

/// Pure logic helper for VoteItemRequestDialog.
/// Extracted for testability - all methods are static and pure
/// (no Flutter/widget dependencies).
///
/// This class is annotated with {@macro visibleForTesting} to indicate
/// it was created primarily to improve test coverage.
class VoteItemRequestDialogHelper {
  /// Determines if an error message represents a success message.
  /// Success messages start with the checkmark emoji.
  static bool isSuccessMessage(String message) {
    return message.startsWith('\u2705'); // ✅
  }

  /// Generates an appropriate error message string from an exception.
  /// Returns a localized message for 'already_applied' errors,
  /// otherwise a generic error without exception details.
  static String getErrorMessageFromException(
    Object error, {
    String genericErrorMessage =
        '\uc2e0\uccad \uc911 \uc624\ub958\uac00 \ubc1c\uc0dd\ud588\uc2b5\ub2c8\ub2e4',
    String alreadyAppliedMessage =
        '\uc774\ubbf8 \uc2e0\uccad\ud55c \uc544\ud2f0\uc2a4\ud2b8\uc785\ub2c8\ub2e4',
  }) {
    final errorStr = error.toString();
    if (errorStr.contains('already_applied')) {
      return alreadyAppliedMessage;
    }
    return genericErrorMessage;
  }

  /// Checks whether a search token is still valid (matches the latest token).
  /// Returns true if the token should be ignored (i.e., a newer search has started).
  static bool shouldIgnoreSearchResult(
    String? resultToken,
    String? currentToken,
  ) {
    if (resultToken == null) return false;
    return currentToken != resultToken;
  }

  /// Determines if loading more results should be skipped.
  /// Returns true if we should NOT load more (i.e., skip the load).
  static bool shouldSkipLoadMore(bool isLoadingMore, bool hasMoreResults) {
    return isLoadingMore || !hasMoreResults;
  }

  /// Updates the search results info map to mark an artist as submitting.
  /// Returns a new map entry if the artist exists, or null if not found.
  static ArtistApplicationInfo? markArtistAsSubmitting(
    Map<String, ArtistApplicationInfo> searchResultsInfo,
    String artistId,
  ) {
    if (!searchResultsInfo.containsKey(artistId)) return null;
    return searchResultsInfo[artistId]!.copyWith(isSubmitting: true);
  }

  /// Updates the search results info map after a successful application submission.
  /// Returns a new ArtistApplicationInfo with updated status and count,
  /// or null if the artist is not in the map.
  static ArtistApplicationInfo? markApplicationSuccess(
    Map<String, ArtistApplicationInfo> searchResultsInfo,
    String artistId,
    String pendingStatusText,
  ) {
    if (!searchResultsInfo.containsKey(artistId)) return null;
    final existing = searchResultsInfo[artistId]!;
    return existing.copyWith(
      isSubmitting: false,
      applicationStatus: pendingStatusText,
      applicationCount: existing.applicationCount + 1,
    );
  }

  /// Updates the search results info map after a failed application submission.
  /// Returns a new ArtistApplicationInfo with isSubmitting reset to false,
  /// or null if the artist is not in the map.
  static ArtistApplicationInfo? markApplicationFailure(
    Map<String, ArtistApplicationInfo> searchResultsInfo,
    String artistId,
  ) {
    if (!searchResultsInfo.containsKey(artistId)) return null;
    return searchResultsInfo[artistId]!.copyWith(isSubmitting: false);
  }

  /// Merges new search results into the existing list.
  /// If [isInitial] is true, replaces the list entirely; otherwise appends.
  static List<T> mergeSearchResults<T>(
    List<T> existing,
    List<T> newResults, {
    required bool isInitial,
  }) {
    if (isInitial) {
      return List<T>.from(newResults);
    }
    return [...existing, ...newResults];
  }

  /// Determines whether the refresh should re-run the search query
  /// or just reload application data.
  /// Returns 'reloadApplicationData' if results exist,
  /// 'rerunSearch' if query exists but no results,
  /// 'nothing' otherwise.
  static String determineRefreshStrategy(
    List<dynamic> searchResults,
    String currentSearchQuery,
  ) {
    if (searchResults.isNotEmpty) {
      return 'reloadApplicationData';
    }
    if (currentSearchQuery.isNotEmpty) {
      return 'rerunSearch';
    }
    return 'nothing';
  }

  /// Returns the success message string after a successful application.
  static String get successMessage =>
      '\u2705 \uc2e0\uccad\uc774 \uc644\ub8cc\ub418\uc5c8\uc2b5\ub2c8\ub2e4!'; // ✅ 신청이 완료되었습니다!

  /// Checks if the user is logged in (has a non-null id).
  static bool isUserLoggedIn(String? userId) {
    return userId != null;
  }
}
