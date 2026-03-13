import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/data/models/community/board.dart';

/// Pure logic helpers extracted from [BoardListPage] for testability.
///
/// All methods are static and free of Flutter/widget dependencies.
class BoardListHelper {
  const BoardListHelper._();

  /// Filters boards by matching a search [query] against board names
  /// and artist names (supports Korean initials, Korean text, and English).
  ///
  /// Returns all boards when [query] is empty.
  static List<BoardModel> filterBoards(List<BoardModel> boards, String query) {
    if (query.isEmpty) return boards;

    final lowerQuery = query.toLowerCase();

    return boards.where((board) {
      // Board name search (Korean + English + initials)
      final boardNameKo = board.name['ko']?.toString() ?? '';
      final boardNameEn = board.name['en']?.toString() ?? '';

      if (KoreanSearchUtils.matchesKoreanInitials(boardNameKo, query) ||
          boardNameEn.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Artist name search (Korean + English + initials)
      if (board.artist?.name != null) {
        final artistNameKo = board.artist!.name['ko']?.toString() ?? '';
        final artistNameEn = board.artist!.name['en']?.toString() ?? '';

        if (KoreanSearchUtils.matchesKoreanInitials(artistNameKo, query) ||
            artistNameEn.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  /// Groups boards by their artist ID.
  ///
  /// Boards without an artist are excluded. Returns an empty map for
  /// an empty input list.
  static Map<String, List<BoardModel>> groupBoardsByArtist(
      List<BoardModel> boards) {
    if (boards.isEmpty) return {};

    final map = <String, List<BoardModel>>{};

    for (var board in boards) {
      if (board.artist == null) continue;

      final key = board.artist!.id.toString();
      map.putIfAbsent(key, () => <BoardModel>[]).add(board);
    }

    return map;
  }

  /// Merges [existingBoards] with [newBoards], removing duplicates by boardId.
  ///
  /// When [isRefresh] is true, only [newBoards] are used (existing are ignored).
  /// When false, existing boards take precedence and new boards are appended.
  static List<BoardModel> deduplicateBoards({
    required List<BoardModel> existingBoards,
    required List<BoardModel> newBoards,
    required bool isRefresh,
  }) {
    final existingBoardIds = <String>{};
    final result = <BoardModel>[];

    if (isRefresh) {
      for (var board in newBoards) {
        if (!existingBoardIds.contains(board.boardId)) {
          existingBoardIds.add(board.boardId);
          result.add(board);
        }
      }
    } else {
      for (var board in existingBoards) {
        if (!existingBoardIds.contains(board.boardId)) {
          existingBoardIds.add(board.boardId);
          result.add(board);
        }
      }
      for (var board in newBoards) {
        if (!existingBoardIds.contains(board.boardId)) {
          existingBoardIds.add(board.boardId);
          result.add(board);
        }
      }
    }

    return result;
  }

  /// Returns whether more data is available based on page size.
  static bool hasMoreData(int resultCount, int pageSize) {
    return resultCount >= pageSize;
  }

  /// Determines the board chip color key based on official status.
  ///
  /// Returns `'primary'` for official boards, `'default'` otherwise.
  @visibleForTesting
  static String boardChipColorKey(bool? isOfficial) {
    return (isOfficial ?? false) ? 'primary' : 'default';
  }
}
