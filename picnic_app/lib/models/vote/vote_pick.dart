import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/vote/vote.dart';

part 'vote_pick.freezed.dart';
part 'vote_pick.g.dart';

@freezed
class VotePickListModel with _$VotePickListModel {
  const VotePickListModel._();

  const factory VotePickListModel({
    required List<VotePickModel> items,
    required MetaModel meta,
  }) = _VotePickListModel;

  factory VotePickListModel.fromJson(Map<String, dynamic> json) =>
      _$VotePickListModelFromJson(json);
}

@freezed
class VotePickModel with _$VotePickModel {
  const VotePickModel._();

  const factory VotePickModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'vote') required VoteModel vote,
    @JsonKey(name: 'vote_item') required VoteItemModel voteItem,
    @JsonKey(name: 'amount') required int? amount,
    @JsonKey(name: 'created_at') required DateTime? createdAt,
    @JsonKey(name: 'updated_at') required DateTime? updatedAt,
  }) = _VotePickModel;

  factory VotePickModel.fromJson(Map<String, dynamic> json) =>
      _$VotePickModelFromJson(json);
}
