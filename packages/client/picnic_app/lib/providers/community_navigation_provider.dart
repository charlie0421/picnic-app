import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/common/community_navigation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_navigation_provider.g.dart';

@Riverpod(keepAlive: true)
class CommunityStateInfo extends _$CommunityStateInfo {
  @override
  CommunityState build() {
    return CommunityState();
  }

  void setCurrentArtistId(int artistId, String artistName) {
    logger.d('setCurrentArtistId: $artistId');
    logger.d('setCurrentArtistName: $artistName');
    state = state.copyWith(
      currentArtistId: artistId,
      currentArtistName: artistName,
    );
  }

  void setCurrentBoardId(String boardId, boardName) {
    logger.d('setCurrentBoardId: $boardId');
    logger.d('setCurrentBoardName: $boardName');
    state = state.copyWith(
      currentBoardId: boardId,
      currentBoardName: boardName,
    );
  }
}
