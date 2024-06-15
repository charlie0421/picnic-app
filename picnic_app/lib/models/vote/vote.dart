import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/reward.dart';
import 'package:picnic_app/reflector.dart';

part 'vote.g.dart';

@reflector
@JsonSerializable()
class VoteListModel {
  final List<VoteModel> items;
  final MetaModel meta;

  VoteListModel({
    required this.items,
    required this.meta,
  });

  factory VoteListModel.fromJson(Map<String, dynamic> json) =>
      _$VoteListModelFromJson(json);

  Map<String, dynamic> toJson() => _$VoteListModelToJson(this);
}

@reflector
@JsonSerializable()
class VoteModel {
  final int id;
  final String title_ko;
  final String title_en;
  final String title_ja;
  final String title_zh;
  final String vote_category;
  final String main_image;
  final String wait_image;
  final String result_image;
  final String vote_content;
  final List<VoteItemModel> vote_item;
  final DateTime created_at;
  final DateTime visible_at;
  final DateTime stop_at;
  final DateTime start_at;
  final List<RewardModel>? reward;

  VoteModel({
    required this.id,
    required this.title_ko,
    required this.title_en,
    required this.title_ja,
    required this.title_zh,
    required this.vote_category,
    required this.main_image,
    required this.wait_image,
    required this.result_image,
    required this.vote_content,
    required this.vote_item,
    required this.visible_at,
    required this.stop_at,
    required this.start_at,
    required this.created_at,
    required this.reward,
  });

  copyWith({
    int? id,
    String? title_ko,
    String? title_en,
    String? title_ja,
    String? title_zh,
    String? vote_category,
    String? main_image,
    String? wait_image,
    String? result_image,
    String? vote_content,
    List<VoteItemModel>? vote_item,
    DateTime? created_at,
    DateTime? visible_at,
    DateTime? stop_at,
    DateTime? start_at,
    List<RewardModel>? reward,
  }) {
    return VoteModel(
      id: id ?? this.id,
      title_ko: title_ko ?? this.title_ko,
      title_en: title_en ?? this.title_en,
      title_ja: title_ja ?? this.title_ja,
      title_zh: title_zh ?? this.title_zh,
      vote_category: vote_category ?? this.vote_category,
      main_image: main_image ?? this.main_image,
      wait_image: wait_image ?? this.wait_image,
      result_image: result_image ?? this.result_image,
      vote_content: vote_content ?? this.vote_content,
      vote_item: vote_item ?? this.vote_item,
      created_at: created_at ?? this.created_at,
      visible_at: visible_at ?? this.visible_at,
      stop_at: stop_at ?? this.stop_at,
      start_at: start_at ?? this.start_at,
      reward: reward ?? this.reward,
    );
  }

  getTitle() {
    String title = '';
    if (Intl.getCurrentLocale() == 'ko') {
      title = title_ko;
    } else if (Intl.getCurrentLocale() == 'en') {
      title = title_en;
    } else if (Intl.getCurrentLocale() == 'ja') {
      title = title_ja;
    } else if (Intl.getCurrentLocale() == 'zh') {
      title = title_zh;
    }
    return title;
  }

  factory VoteModel.fromJson(Map<String, dynamic> json) {
    return _$VoteModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$VoteModelToJson(this);
}

@reflector
@JsonSerializable()
class VoteItemModel {
  final int id;
  final int vote_total;
  final int vote_id;
  final MyStarMemberModel mystar_member;

  VoteItemModel({
    required this.id,
    required this.vote_total,
    required this.vote_id,
    required this.mystar_member,
  });

  factory VoteItemModel.fromJson(Map<String, dynamic> json) =>
      _$VoteItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$VoteItemModelToJson(this);

  copyWith({
    int? id,
    int? vote_total,
    int? vote_id,
    MyStarMemberModel? mystar_member,
  }) {
    return VoteItemModel(
      id: id ?? this.id,
      vote_total: vote_total ?? this.vote_total,
      vote_id: vote_id ?? this.vote_id,
      mystar_member: mystar_member ?? this.mystar_member,
    );
  }

  toString() {
    return 'id: $id, vote_total: $vote_total, vote_id: $vote_id, mystar_member: $mystar_member';
  }
}

@reflector
@JsonSerializable()
class MyStarMemberModel {
  final int id;

  final String name_ko;
  final String name_en;
  final String gender;
  String? image;
  final MyStarGroupModel? mystar_group;

  MyStarMemberModel({
    required this.id,
    required this.name_ko,
    required this.name_en,
    required this.gender,
    this.image,
    required this.mystar_group,
  });

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

  Map<String, dynamic> toJson() => _$MyStarMemberModelToJson(this);
}

@reflector
@JsonSerializable()
class MyStarGroupModel {
  final int id;
  final String name_ko;
  final String name_en;
  String? image;

  MyStarGroupModel({
    required this.id,
    required this.name_ko,
    required this.name_en,
    this.image,
  });

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

  Map<String, dynamic> toJson() => _$MyStarGroupModelToJson(this);
}
