import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/reward.dart';
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
    required List<RewardModel>? reward,
  }) = _VoteModel;

  factory VoteModel.fromJson(Map<String, dynamic> json) =>
      _$VoteModelFromJson(json);
}

@reflector
@freezed
class VoteItemModel with _$VoteItemModel {
  const VoteItemModel._();

  const factory VoteItemModel({
    required int id,
    required int vote_total,
    required int vote_id,
    required MyStarMemberModel mystar_member,
  }) = _VoteItemModel;

  factory VoteItemModel.fromJson(Map<String, dynamic> json) =>
      _$VoteItemModelFromJson(json);
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
