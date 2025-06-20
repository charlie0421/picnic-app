import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/l10n.dart';

part '../../../generated/models/pic/artist_vote.freezed.dart';
part '../../../generated/models/pic/artist_vote.g.dart';

@freezed
class ArtistVoteModel with _$ArtistVoteModel {
  const ArtistVoteModel._();

  const factory ArtistVoteModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'title') required Map<String, dynamic> title,
    @JsonKey(name: 'category') required String category,
    @JsonKey(name: 'artist_vote_item')
    required List<ArtistVoteItemModel>? artistVoteItem,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime? updatedAt,
    @JsonKey(name: 'visible_at') required DateTime? visibleAt,
    @JsonKey(name: 'stop_at') required DateTime stopAt,
    @JsonKey(name: 'start_at') required DateTime startAt,
  }) = _ArtistVoteModel;

  factory ArtistVoteModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistVoteModelFromJson(json);
}

@freezed
class ArtistVoteItemModel with _$ArtistVoteItemModel {
  const ArtistVoteItemModel._();

  const factory ArtistVoteItemModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'vote_total') required int voteTotal,
    @JsonKey(name: 'artist_vote_id') required int artistVoteId,
    @JsonKey(name: 'title') required Map<String, dynamic> title,
    @JsonKey(name: 'description') required Map<String, dynamic> description,
  }) = _ArtistVoteItemModel;

  factory ArtistVoteItemModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistVoteItemModelFromJson(json);
}

@freezed
class MyStarMemberModel with _$MyStarMemberModel {
  const MyStarMemberModel._();

  const factory MyStarMemberModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'name_ko') required String nameKo,
    @JsonKey(name: 'name_en') required String nameEn,
    @JsonKey(name: 'gender') required String gender,
    @JsonKey(name: 'image') required String? image,
    @JsonKey(name: 'mystar_group') MyStarGroupModel? mystarGroup,
  }) = _MyStarMemberModel;

  String getTitle() {
    String title = '';
    if (getLocaleLanguage() == 'ko') {
      title = nameKo;
    } else {
      title = nameEn;
    }
    return title;
  }

  String getGroupTitle() {
    return mystarGroup?.getTitle() ?? '';
  }

  factory MyStarMemberModel.fromJson(Map<String, dynamic> json) =>
      _$MyStarMemberModelFromJson(json);
}

@freezed
class MyStarGroupModel with _$MyStarGroupModel {
  const MyStarGroupModel._();

  const factory MyStarGroupModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'name_ko') required String nameKo,
    @JsonKey(name: 'name_en') required String nameEn,
    String? image,
  }) = _MyStarGroupModel;

  String getTitle() {
    String title = '';
    if (getLocaleLanguage() == 'ko') {
      title = nameKo;
    } else {
      title = nameEn;
    }
    return title;
  }

  factory MyStarGroupModel.fromJson(Map<String, dynamic> json) =>
      _$MyStarGroupModelFromJson(json);
}

@freezed
class ArtistMemberModel with _$ArtistMemberModel {
  const ArtistMemberModel._();

  const factory ArtistMemberModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'name') required Map<String, String> name,
    @JsonKey(name: 'gender') required String gender,
    @JsonKey(name: 'image') required String? image,
    @JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup,
  }) = _ArtistMemberModel;

  factory ArtistMemberModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistMemberModelFromJson(json);
}

@freezed
class ArtistGroupModel with _$ArtistGroupModel {
  const ArtistGroupModel._();

  const factory ArtistGroupModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'name') required Map<String, dynamic> name,
    @JsonKey(name: 'image') String? image,
  }) = _ArtistGroupModel;

  factory ArtistGroupModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistGroupModelFromJson(json);
}
