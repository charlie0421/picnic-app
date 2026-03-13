import 'package:flutter/foundation.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

/// Pure helper methods extracted from post_provider.dart for testability.
@visibleForTesting
class PostProviderHelper {
  /// Extracts blocked user IDs from a list of block response rows.
  ///
  /// Each row is expected to have a 'blocked_user_id' key.
  static List<String> extractBlockedUserIds(
      List<Map<String, dynamic>> blockedResponse) {
    return blockedResponse
        .map((row) => row['blocked_user_id'] as String)
        .toList();
  }

  /// Builds a Supabase OR filter string to exclude posts by blocked users.
  ///
  /// Returns null if the list is empty (no filter needed).
  static String? buildBlockedUserFilter(List<String> blockedUserIds) {
    if (blockedUserIds.isEmpty) return null;
    return 'and(user_id.not.in.(${blockedUserIds.join(',')}))';
  }

  /// Builds the full report reason string from reason and optional text.
  static String buildReportReason(String reason, String text) {
    return reason + (text.isNotEmpty ? ' - $text' : '');
  }

  /// Determines whether a post has been scraped based on the post_scraps field.
  static bool determineIsScraped(dynamic postScraps) {
    return postScraps != null && postScraps is List && postScraps.isNotEmpty;
  }

  /// Creates an updated response map with the 'is_scraped' field set.
  static Map<String, dynamic> addIsScrapedToResponse(
      Map<String, dynamic> response) {
    final isScraped = determineIsScraped(response['post_scraps']);
    return {
      ...response,
      'is_scraped': isScraped,
    };
  }

  /// Calculates the start and end indices for Supabase range pagination.
  ///
  /// Returns a record (start, end) for use with `.range(start, end)`.
  static (int, int) calculateRange(int page, int limit) {
    return ((page - 1) * limit, page * limit - 1);
  }

  /// Parses a post response row from the postsByUser query, attaching
  /// user profile and board data via copyWith.
  static PostModel parsePostWithUserAndBoard(Map<String, dynamic> data) {
    final post = PostModel.fromJson(data);
    final userProfile = UserProfilesModel.fromJson(data['user_profiles']);
    final board =
        data['boards'] != null ? BoardModel.fromJson(data['boards']) : null;
    return post.copyWith(userProfiles: userProfile, board: board);
  }
}
