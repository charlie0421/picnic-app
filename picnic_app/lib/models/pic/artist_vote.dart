import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part '../../generated/models/pic/artist_vote.freezed.dart';

part '../../generated/models/pic/artist_vote.g.dart';

@freezed
class ArtistVoteModel with _$ArtistVoteModel {
  const ArtistVoteModel._();

  const factory ArtistVoteModel({
    required int id,
    required Map<String, dynamic> title,
    required String category,
    required List<ArtistVoteItemModel>? artist_vote_item,
    required DateTime created_at,
    required DateTime? updated_at,
    required DateTime? visible_at,
    required DateTime stop_at,
    required DateTime start_at,
  }) = _ArtistVoteModel;

  factory ArtistVoteModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistVoteModelFromJson(json);
}

@freezed
class ArtistVoteItemModel with _$ArtistVoteItemModel {
  const ArtistVoteItemModel._();

  const factory ArtistVoteItemModel({
    required int id,
    required int vote_total,
    required int artist_vote_id,
    required Map<String, dynamic> title,
    required Map<String, dynamic> description,
  }) = _ArtistVoteItemModel;

  factory ArtistVoteItemModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistVoteItemModelFromJson(json);
}

@freezed
class MyStarMemberModel with _$MyStarMemberModel {
  const MyStarMemberModel._();

  const factory MyStarMemberModel({
    required int id,
    required String name_ko,
    required String name_en,
    required String gender,
    required String? image,
    MyStarGroupModel? mystar_group,
  }) = _MyStarMemberModel;

  getTitle() {
    String title = '';
    if (Intl.getCurrentLocale() == 'ko') {
      title = name_ko;
    } else {
      title = name_en;
    }
    return title;
  }

  getGroupTitle() {
    return mystar_group?.getTitle() ?? '';
  }

  factory MyStarMemberModel.fromJson(Map<String, dynamic> json) =>
      _$MyStarMemberModelFromJson(json);
}

@freezed
class MyStarGroupModel with _$MyStarGroupModel {
  const MyStarGroupModel._();

  const factory MyStarGroupModel({
    required int id,
    required String name_ko,
    required String name_en,
    String? image,
  }) = _MyStarGroupModel;

  String getTitle() {
    String title = '';
    if (Intl.getCurrentLocale() == 'ko') {
      title = name_ko;
    } else {
      title = name_en;
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
    required int id,
    required Map<String, String> name,
    required String gender,
    required String? image,
    ArtistGroupModel? artist_group,
  }) = _ArtistMemberModel;

  factory ArtistMemberModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistMemberModelFromJson(json);
}

@freezed
class ArtistGroupModel with _$ArtistGroupModel {
  const ArtistGroupModel._();

  const factory ArtistGroupModel({
    required int id,
    required Map<String, dynamic> name,
    String? image,
  }) = _ArtistGroupModel;

  factory ArtistGroupModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistGroupModelFromJson(json);
}
