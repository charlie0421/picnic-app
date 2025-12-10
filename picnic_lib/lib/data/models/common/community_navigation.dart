import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

class CommunityState {
  final ArtistModel? currentArtist;
  final PostModel? currentPost;
  final BoardModel? currentBoard;

  const CommunityState({
    this.currentArtist,
    this.currentPost,
    this.currentBoard,
  });

  CommunityState copyWith({
    ArtistModel? currentArtist,
    PostModel? currentPost,
    BoardModel? currentBoard,
  }) {
    return CommunityState(
      currentArtist: currentArtist ?? this.currentArtist,
      currentPost: currentPost ?? this.currentPost,
      currentBoard: currentBoard ?? this.currentBoard,
    );
  }
}
