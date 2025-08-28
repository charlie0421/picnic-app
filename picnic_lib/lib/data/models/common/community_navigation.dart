import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

part '../../../generated/models/common/community_navigation.freezed.dart';

@freezed
class CommunityState with _$CommunityState {
  const CommunityState._();

  const factory CommunityState({
    ArtistModel? currentArtist,
    PostModel? currentPost,
    BoardModel? currentBoard,
  }) = Navigation;
}
