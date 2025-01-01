import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/data/models/community/board.dart';
import 'package:picnic_app/data/models/community/post.dart';
import 'package:picnic_app/data/models/vote/artist.dart';
import 'package:picnic_app/reflector.dart';

part '../../../generated/models/common/community_navigation.freezed.dart';

@reflector
@freezed
class CommunityState with _$CommunityState {
  const CommunityState._();

  const factory CommunityState({
    ArtistModel? currentArtist,
    PostModel? currentPost,
    BoardModel? currentBoard,
  }) = Navigation;
}
