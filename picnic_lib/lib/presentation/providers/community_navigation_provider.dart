import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/community_navigation_provider.g.dart';

@Riverpod(keepAlive: true)
class CommunityStateInfo extends _$CommunityStateInfo {
  @override
  CommunityState build() {
    return const CommunityState();
  }

  void setCurrentArtist(ArtistModel? artist) {
    state = state.copyWith(
      currentArtist: artist,
    );
  }

  void setCurrentPost(PostModel post) {
    state = state.copyWith(
      currentPost: post,
    );
  }

  void setCurrentPostScraped(bool isScraped) {
    state = state.copyWith(
      currentPost: state.currentPost!.copyWith(isScraped: isScraped),
    );
  }

  void setCurrentBoard(BoardModel? board) {
    state = state.copyWith(
      currentBoard: board,
    );
  }
}
