import 'package:flutter/foundation.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';

/// Pure helper methods extracted from celeb_list_provider for testability.
@visibleForTesting
class CelebListProviderHelper {
  /// Parses a list of JSON maps into [CelebModel] instances.
  /// This is the logic used by [AsyncCelebList._fetchCelebList].
  static List<CelebModel> parseCelebList(List<Map<String, dynamic>> response) {
    return List<CelebModel>.from(
        response.map((e) => CelebModel.fromJson(e)));
  }

  /// Parses a bookmark-join response where each row contains a nested 'celeb' key.
  /// This is the logic used by [AsyncMyCelebList.fetchMyCelebList].
  static List<CelebModel> parseMyCelebList(
      List<Map<String, dynamic>> response) {
    return List<CelebModel>.from(
        response.map((e) => CelebModel.fromJson(e['celeb'])));
  }
}
