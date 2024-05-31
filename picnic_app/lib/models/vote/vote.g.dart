// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoteListModel _$VoteListModelFromJson(Map<String, dynamic> json) =>
    VoteListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => VoteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VoteListModelToJson(VoteListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

VoteModel _$VoteModelFromJson(Map<String, dynamic> json) => VoteModel(
      id: (json['id'] as num).toInt(),
      vote_title: json['vote_title'] as String,
      vote_category: json['vote_category'] as String,
      main_image: json['main_image'] as String,
      wait_image: json['wait_image'] as String,
      result_image: json['result_image'] as String,
      vote_content: json['vote_content'] as String,
      vote_item: (json['vote_item'] as List<dynamic>)
          .map((e) => VoteItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      visible_at: DateTime.parse(json['visible_at'] as String),
      stop_at: DateTime.parse(json['stop_at'] as String),
      start_at: DateTime.parse(json['start_at'] as String),
      created_at: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$VoteModelToJson(VoteModel instance) => <String, dynamic>{
      'id': instance.id,
      'vote_title': instance.vote_title,
      'vote_category': instance.vote_category,
      'main_image': instance.main_image,
      'wait_image': instance.wait_image,
      'result_image': instance.result_image,
      'vote_content': instance.vote_content,
      'vote_item': instance.vote_item,
      'created_at': instance.created_at.toIso8601String(),
      'visible_at': instance.visible_at.toIso8601String(),
      'stop_at': instance.stop_at.toIso8601String(),
      'start_at': instance.start_at.toIso8601String(),
    };

VoteItemModel _$VoteItemFromJson(Map<String, dynamic> json) => VoteItemModel(
      id: (json['id'] as num).toInt(),
      vote_total: (json['vote_total'] as num).toInt(),
      vote_id: (json['vote_id'] as num).toInt(),
      mystar_member: MyStarMemberModel.fromJson(
          json['mystar_member'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VoteItemToJson(VoteItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_total': instance.vote_total,
      'vote_id': instance.vote_id,
      'mystar_member': instance.mystar_member,
    };

MyStarMemberModel _$MyStarMemberModelFromJson(Map<String, dynamic> json) =>
    MyStarMemberModel(
      id: (json['id'] as num).toInt(),
      name_ko: json['name_ko'] as String,
      name_en: json['name_en'] as String,
      gender: json['gender'] as String,
      image: json['image'] as String?,
      mystar_group: json['mystar_group'] == null
          ? null
          : MyStarGroupModel.fromJson(
              json['mystar_group'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MyStarMemberModelToJson(MyStarMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.name_ko,
      'name_en': instance.name_en,
      'gender': instance.gender,
      'image': instance.image,
      'mystar_group': instance.mystar_group,
    };

MyStarGroupModel _$MyStarGroupModelFromJson(Map<String, dynamic> json) =>
    MyStarGroupModel(
      id: (json['id'] as num).toInt(),
      name_ko: json['name_ko'] as String,
      name_en: json['name_en'] as String,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$MyStarGroupModelToJson(MyStarGroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.name_ko,
      'name_en': instance.name_en,
      'image': instance.image,
    };
