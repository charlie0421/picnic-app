import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/reward.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/models/vote/artist_group.dart';

part 'vote.freezed.dart';
part 'vote.g.dart';

@freezed
class VoteModel with _$VoteModel {
  const VoteModel._();

  const factory VoteModel(
          {@JsonKey(name: 'id') required int id,
          @JsonKey(name: 'title') required Map<String, dynamic> title,
          @JsonKey(name: 'vote_category') required String? voteCategory,
          @JsonKey(name: 'main_image') required String? mainImage,
          @JsonKey(name: 'wait_image') required String? waitImage,
          @JsonKey(name: 'result_image') required String? resultImage,
          @JsonKey(name: 'vote_content') required String? voteContent,
          @JsonKey(name: 'vote_item') required List<VoteItemModel>? voteItem,
          @JsonKey(name: 'created_at') required DateTime? createdAt,
          @JsonKey(name: 'visible_at') required DateTime visibleAt,
          @JsonKey(name: 'stop_at') required DateTime stopAt,
          @JsonKey(name: 'start_at') required DateTime startAt,
          @JsonKey(name: 'is_ended') required bool? isEnded,
          @JsonKey(name: 'is_upcoming') required bool? isUpcoming,
          @JsonKey(name: 'reward') required List<RewardModel>? reward}) =
      _VoteModel;

  factory VoteModel.fromJson(Map<String, dynamic> json) =>
      _$VoteModelFromJson(json);
}

@freezed
class VoteItemModel with _$VoteItemModel {
  const VoteItemModel._();

  const factory VoteItemModel(
      {@JsonKey(name: 'id') required int id,
      @JsonKey(name: 'vote_total') required int voteTotal,
      @JsonKey(name: 'vote_id') required int voteId,
      @JsonKey(name: 'artist') required ArtistModel artist,
      @JsonKey(name: 'artist_group')
      required ArtistGroupModel artistGroup}) = _VoteItemModel;

  factory VoteItemModel.fromJson(Map<String, dynamic> json) =>
      _$VoteItemModelFromJson(json);
}

// 새로 추가된 ArtistModelWithHighlight 클래스
class ArtistModelWithHighlight {
  final ArtistModel artist;
  final String highlightedName;
  final String highlightedGroupName;

  ArtistModelWithHighlight({
    required this.artist,
    required this.highlightedName,
    required this.highlightedGroupName,
  });
}
