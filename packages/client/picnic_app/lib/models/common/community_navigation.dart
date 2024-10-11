import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/reflector.dart';

part 'community_navigation.freezed.dart';

@reflector
@freezed
class CommunityState with _$CommunityState {
  const CommunityState._();

  const factory CommunityState({
    @Default(0) int currentArtistId,
    @Default('') String currentArtistName,
    @Default('') String currentBoardId,
    @Default('') String currentBoardName,
    PostModel? currentPost,
  }) = Navigation;
}
