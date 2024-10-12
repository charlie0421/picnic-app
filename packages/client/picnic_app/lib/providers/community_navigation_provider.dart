import 'package:picnic_app/models/common/community_navigation.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_navigation_provider.g.dart';

@Riverpod(keepAlive: true)
class CommunityStateInfo extends _$CommunityStateInfo {
  @override
  CommunityState build() {
    return const CommunityState();
  }

  void setCurrentArtistId(int artistId, String artistName) {
    state = state.copyWith(
      currentArtistId: artistId,
      currentArtistName: artistName,
    );
  }

  void setCurrentBoardId(String boardId, boardName) {
    state = state.copyWith(
      currentBoardId: boardId,
      currentBoardName: boardName,
    );
  }

  void setCurrentPost(PostModel post) {
    state = state.copyWith(
      currentPost: post,
    );
  }

  void setCurrentPostScraped(bool isScraped) {
    state = state.copyWith(
      currentPost: state.currentPost!.copyWith(is_scraped: isScraped),
    );
  }

  void setCurrentBoard(BoardModel board) {
    state = state.copyWith(
      currentBoard: board,
    );
  }
}
