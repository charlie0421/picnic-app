import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_models.dart';

/// Pure logic helper for VoteItemRequestService.
/// Extracted for testability - all methods are static and pure
/// (no Flutter/widget dependencies, no Supabase calls, no Riverpod).
class VoteItemRequestServiceHelper {
  // ---------------------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------------------

  /// Determines whether more pages are available based on result count.
  /// If the returned list length equals the requested page size, we assume
  /// there may be more results.
  static bool hasMoreResults(int resultCount, int pageSize) {
    return resultCount == pageSize;
  }

  /// Builds a standard pagination result map.
  static Map<String, dynamic> buildPaginationResult({
    required List<dynamic> artists,
    required bool hasMore,
    required int currentPage,
  }) {
    return {
      'artists': artists,
      'hasMore': hasMore,
      'currentPage': currentPage,
    };
  }

  /// Builds an empty pagination result (used on error).
  static Map<String, dynamic> buildEmptyPaginationResult(int currentPage) {
    return {
      'artists': <dynamic>[],
      'hasMore': false,
      'currentPage': currentPage,
    };
  }

  // ---------------------------------------------------------------------------
  // Batching
  // ---------------------------------------------------------------------------

  /// Splits a list into batches of [batchSize].
  static List<List<T>> splitIntoBatches<T>(List<T> items, int batchSize) {
    if (batchSize <= 0) {
      throw ArgumentError.value(batchSize, 'batchSize', 'must be positive');
    }
    final batches = <List<T>>[];
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize > items.length) ? items.length : i + batchSize;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }

  /// Returns true when the list exceeds [maxBatchSize] and should be split.
  static bool needsBatching(int listLength, int maxBatchSize) {
    return listLength > maxBatchSize;
  }

  // ---------------------------------------------------------------------------
  // Artist name extraction
  // ---------------------------------------------------------------------------

  /// Extracts Korean and English names from an artist name map.
  static ({String ko, String en}) extractNames(Map<String, dynamic> nameMap) {
    final ko = nameMap['ko'] as String? ?? '';
    final en = nameMap['en'] as String? ?? '';
    return (ko: ko, en: en);
  }

  /// Collects all non-empty Korean and English names from a list of artist
  /// name maps.
  static List<String> collectArtistNames(
      List<Map<String, dynamic>> artistNameMaps) {
    final names = <String>[];
    for (final nameMap in artistNameMaps) {
      final extracted = extractNames(nameMap);
      if (extracted.ko.isNotEmpty) names.add(extracted.ko);
      if (extracted.en.isNotEmpty) names.add(extracted.en);
    }
    return names;
  }

  // ---------------------------------------------------------------------------
  // Application count aggregation
  // ---------------------------------------------------------------------------

  /// Aggregates application counts for an artist by summing counts found
  /// under both their Korean and English names. Avoids double-counting when
  /// the two names are identical.
  static int aggregateApplicationCount(
    Map<String, int> countsByName,
    String koreanName,
    String englishName,
  ) {
    int total = 0;
    if (koreanName.isNotEmpty) {
      total += countsByName[koreanName] ?? 0;
    }
    if (englishName.isNotEmpty && englishName != koreanName) {
      total += countsByName[englishName] ?? 0;
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // "Already in vote" resolution
  // ---------------------------------------------------------------------------

  /// Checks if an artist is already registered in the vote by looking up
  /// both the Korean and English name in the provided map.
  static bool resolveIsAlreadyInVote(
    Map<String, bool> alreadyInVoteMap,
    String koreanName,
    String englishName,
  ) {
    if (koreanName.isNotEmpty && (alreadyInVoteMap[koreanName] ?? false)) {
      return true;
    }
    if (englishName.isNotEmpty && (alreadyInVoteMap[englishName] ?? false)) {
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Application status resolution (priority: ID > ko > en > default)
  // ---------------------------------------------------------------------------

  /// Resolves the user's application status for a given artist using a
  /// priority order: artist ID first, then Korean name, then English name.
  /// Falls back to [defaultStatus] if none match.
  static String resolveApplicationStatus({
    required Map<String, String> userStatuses,
    required String artistId,
    required String koreanName,
    required String englishName,
    required String? userId,
    required String defaultStatus,
  }) {
    if (userId == null) return defaultStatus;

    if (userStatuses.containsKey(artistId)) {
      return userStatuses[artistId]!;
    }
    if (koreanName.isNotEmpty && userStatuses.containsKey(koreanName)) {
      return userStatuses[koreanName]!;
    }
    if (englishName.isNotEmpty && userStatuses.containsKey(englishName)) {
      return userStatuses[englishName]!;
    }
    return defaultStatus;
  }

  // ---------------------------------------------------------------------------
  // Status text mapping (pure – caller provides display strings)
  // ---------------------------------------------------------------------------

  /// Maps a raw status string (e.g. 'pending') to its corresponding
  /// display text. The caller must supply the [statusTextMap] so that
  /// this function stays free of l10n / BuildContext dependencies.
  ///
  /// [statusTextMap] keys should be lowercase status codes:
  ///   'pending', 'approved', 'rejected', 'in-progress', 'cancelled'
  /// [defaultText] is returned when the status is not found.
  static String getStatusDisplayText(
    String status,
    Map<String, String> statusTextMap,
    String defaultText,
  ) {
    return statusTextMap[status.toLowerCase()] ?? defaultText;
  }

  // ---------------------------------------------------------------------------
  // Status count calculation
  // ---------------------------------------------------------------------------

  /// Counts occurrences of each status value in a list of status strings.
  static Map<String, int> countStatuses(List<String> statuses) {
    final counts = <String, int>{};
    for (final status in statuses) {
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  // ---------------------------------------------------------------------------
  // Artist application summary building & sorting
  // ---------------------------------------------------------------------------

  /// Builds a summary map for one artist group of requests.
  ///
  /// [statusCounts] is pre-computed via [countStatuses].
  static Map<String, dynamic> buildArtistApplicationSummary({
    required int artistId,
    required Map<String, dynamic>? artistJson,
    required int totalApplications,
    required Map<String, int> statusCounts,
    required List<dynamic> requests,
  }) {
    return {
      'artistId': artistId,
      'artist': artistJson,
      'totalApplications': totalApplications,
      'pendingCount': statusCounts['pending'] ?? 0,
      'approvedCount': statusCounts['approved'] ?? 0,
      'rejectedCount': statusCounts['rejected'] ?? 0,
      'statusCounts': statusCounts,
      'requests': requests,
      'latestRequest': requests.isNotEmpty ? requests.first : null,
    };
  }

  /// Sorts a list of artist application summaries by totalApplications
  /// in descending order. Returns a new sorted list.
  static List<Map<String, dynamic>> sortSummariesByCount(
    List<Map<String, dynamic>> summaries,
  ) {
    final sorted = List<Map<String, dynamic>>.from(summaries);
    sorted.sort((a, b) => (b['totalApplications'] as int)
        .compareTo(a['totalApplications'] as int));
    return sorted;
  }

  // ---------------------------------------------------------------------------
  // Empty / error result builders
  // ---------------------------------------------------------------------------

  /// Builds the default (empty) result for [loadApplicationCounts].
  static Map<String, dynamic> buildEmptyApplicationCountsResult() {
    return {
      'userApplications': <dynamic>[],
      'userApplicationsWithDetails': <Map<String, dynamic>>[],
      'userApplicationCounts': <String, int>{},
    };
  }

  /// Builds the default (empty) result for [loadAllApplicationsByArtist].
  static Map<String, dynamic> buildEmptyAllApplicationsResult() {
    return {
      'artistApplicationSummaries': <Map<String, dynamic>>[],
      'totalApplications': 0,
    };
  }

  /// Builds a default [ArtistApplicationInfo] for error/fallback scenarios.
  static ArtistApplicationInfo buildDefaultApplicationInfo({
    required String artistName,
    required String canApplyText,
  }) {
    return ArtistApplicationInfo(
      artistName: artistName,
      applicationCount: 0,
      applicationStatus: canApplyText,
      isAlreadyInVote: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Artist name matching
  // ---------------------------------------------------------------------------

  /// Finds an exact match for [targetName] in a list of artist name maps.
  /// Each entry in [candidates] should have the structure
  /// `{'displayName': String, 'ko': String, 'en': String}`.
  /// Returns the index of the first match, or -1 if no match is found.
  static int findExactArtistMatch(
    List<Map<String, String>> candidates,
    String targetName,
  ) {
    for (int i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      if (c['displayName'] == targetName ||
          c['ko'] == targetName ||
          c['en'] == targetName) {
        return i;
      }
    }
    return -1;
  }

  /// Checks whether [artistName] matches any name variant in a vote item's
  /// artist name map (Korean, English, or display name).
  static bool artistNameMatchesVoteItem({
    required String artistName,
    required String koreanNameFromDb,
    required String englishNameFromDb,
    required String displayNameFromDb,
  }) {
    return koreanNameFromDb == artistName ||
        englishNameFromDb == artistName ||
        displayNameFromDb == artistName;
  }

  // ---------------------------------------------------------------------------
  // Application count accumulation from response rows
  // ---------------------------------------------------------------------------

  /// Accumulates application counts from response rows that contain nested
  /// artist name data. Returns a map from name to count.
  static Map<String, int> accumulateApplicationCounts(
    List<Map<String, dynamic>> rows,
    List<String> relevantNames,
  ) {
    final counts = <String, int>{};
    for (final row in rows) {
      final artistData = row['artist'] as Map<String, dynamic>?;
      if (artistData == null) continue;

      final nameData = artistData['name'] as Map<String, dynamic>? ?? {};
      final ko = nameData['ko'] as String? ?? '';
      final en = nameData['en'] as String? ?? '';

      if (ko.isNotEmpty && relevantNames.contains(ko)) {
        counts[ko] = (counts[ko] ?? 0) + 1;
      }
      if (en.isNotEmpty && relevantNames.contains(en)) {
        counts[en] = (counts[en] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Extracts "already in vote" flags from vote item response rows.
  static Map<String, bool> extractAlreadyInVoteFlags(
    List<Map<String, dynamic>> rows,
    List<String> relevantNames,
  ) {
    final flags = <String, bool>{};
    for (final item in rows) {
      final artistData = item['artist'] as Map<String, dynamic>?;
      if (artistData == null) continue;

      final nameData = artistData['name'] as Map<String, dynamic>? ?? {};
      final ko = nameData['ko'] as String? ?? '';
      final en = nameData['en'] as String? ?? '';

      if (ko.isNotEmpty && relevantNames.contains(ko)) {
        flags[ko] = true;
      }
      if (en.isNotEmpty && relevantNames.contains(en)) {
        flags[en] = true;
      }
    }
    return flags;
  }

  /// Extracts user application statuses from response rows.
  /// Uses [getStatusText] callback to convert raw status to display text.
  static Map<String, String> extractUserApplicationStatuses(
    List<Map<String, dynamic>> rows,
    List<String> relevantNames,
    String Function(String rawStatus) getStatusText,
  ) {
    final statuses = <String, String>{};
    for (final row in rows) {
      final artistData = row['artist'] as Map<String, dynamic>?;
      if (artistData == null) continue;

      final nameData = artistData['name'] as Map<String, dynamic>? ?? {};
      final ko = nameData['ko'] as String? ?? '';
      final en = nameData['en'] as String? ?? '';
      final status = row['status'] as String? ?? '';
      final artistId = row['artist_id'];

      final statusText = getStatusText(status);

      if (ko.isNotEmpty && relevantNames.contains(ko)) {
        statuses[ko] = statusText;
      }
      if (en.isNotEmpty && relevantNames.contains(en)) {
        statuses[en] = statusText;
      }
      if (artistId != null) {
        statuses[artistId.toString()] = statusText;
      }
    }
    return statuses;
  }
}
