import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/reward.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/models/vote/artist_group.dart';
import 'package:picnic_app/reflector.dart';

part 'vote.freezed.dart';
part 'vote.g.dart';

@reflector
@freezed
class VoteListModel with _$VoteListModel {
  const VoteListModel._();

  const factory VoteListModel({
    required List<VoteModel> items,
    required MetaModel meta,
  }) = _VoteListModel;

  factory VoteListModel.fromJson(Map<String, dynamic> json) =>
      _$VoteListModelFromJson(json);
}

@reflector
@freezed
class VoteModel with _$VoteModel {
  const VoteModel._();

  const factory VoteModel({
    required int id,
    required Map<String, dynamic> title,
    required String vote_category,
    required String main_image,
    required String wait_image,
    required String result_image,
    required String vote_content,
    required List<VoteItemModel>? vote_item,
    required DateTime created_at,
    required DateTime visible_at,
    required DateTime stop_at,
    required DateTime start_at,
    required bool? is_ended,
    required bool? is_upcoming,
    required List<RewardModel>? reward,
  }) = _VoteModel;

  factory VoteModel.fromJson(Map<String, dynamic> json) =>
      _$VoteModelFromJson(json);
}

@reflector
@freezed
class VoteItemModel with _$VoteItemModel {
  const VoteItemModel._();

  const factory VoteItemModel(
      {required int id,
      required int vote_total,
      required int vote_id,
      required ArtistModel artist,
      required ArtistGroupModel artist_group}) = _VoteItemModel;

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
