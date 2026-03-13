import 'package:flutter/foundation.dart';
import 'package:picnic_lib/data/models/community/board.dart';

/// Pure helper functions extracted from boards_provider for testability.
@visibleForTesting
class BoardsProviderHelper {
  const BoardsProviderHelper._();

  /// Parses a single JSON map into a [BoardModel], or returns null if [response] is null.
  @visibleForTesting
  static BoardModel? parseBoardDetail(Map<String, dynamic>? response) {
    return response == null ? null : BoardModel.fromJson(response);
  }

  /// Parses a list of JSON maps into a list of [BoardModel] instances.
  @visibleForTesting
  static List<BoardModel> parseBoardList(
      List<Map<String, dynamic>> response) {
    return response.map((data) => BoardModel.fromJson(data)).toList();
  }

  /// Builds the data map used to create a new board request.
  @visibleForTesting
  static Map<String, dynamic> buildCreateBoardData({
    required int artistId,
    required String title,
    required String description,
    required String requestMessage,
    required String userId,
  }) {
    return {
      'artist_id': artistId,
      'name': {'ko': title, 'en': title, 'ja': title, 'zh_CN': title},
      'description': description,
      'status': 'pending',
      'request_message': requestMessage,
      'creator_id': userId,
      'is_official': false,
      'order': 0,
      'features': <String>[],
    };
  }
}
