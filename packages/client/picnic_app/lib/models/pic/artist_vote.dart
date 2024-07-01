import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/reflector.dart';

part 'artist_vote.freezed.dart';
part 'artist_vote.g.dart';

@reflector
@freezed
class ArtistVoteListModel with _$ArtistVoteListModel {
  const ArtistVoteListModel._();

  const factory ArtistVoteListModel({
    required List<ArtistVoteModel> items,
    required MetaModel meta,
  }) = _ArtistVoteListModel;

  factory ArtistVoteListModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistVoteListModelFromJson(json);
}

@reflector
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

@reflector
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

@reflector
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

@reflector
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
