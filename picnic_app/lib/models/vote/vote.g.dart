// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoteListModelImpl _$$VoteListModelImplFromJson(Map<String, dynamic> json) =>
    _$VoteListModelImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => VoteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VoteListModelImplToJson(_$VoteListModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

_$VoteModelImpl _$$VoteModelImplFromJson(Map<String, dynamic> json) =>
    _$VoteModelImpl(
      id: (json['id'] as num).toInt(),
      title_ko: json['title_ko'] as String,
      title_en: json['title_en'] as String,
      title_ja: json['title_ja'] as String,
      title_zh: json['title_zh'] as String,
      vote_category: json['vote_category'] as String,
      main_image: json['main_image'] as String,
      wait_image: json['wait_image'] as String,
      result_image: json['result_image'] as String,
      vote_content: json['vote_content'] as String,
      vote_item: (json['vote_item'] as List<dynamic>?)
          ?.map((e) => VoteItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      created_at: DateTime.parse(json['created_at'] as String),
      visible_at: DateTime.parse(json['visible_at'] as String),
      stop_at: DateTime.parse(json['stop_at'] as String),
      start_at: DateTime.parse(json['start_at'] as String),
      reward: (json['reward'] as List<dynamic>?)
          ?.map((e) => RewardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$VoteModelImplToJson(_$VoteModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'title_ja': instance.title_ja,
      'title_zh': instance.title_zh,
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
      'reward': instance.reward,
    };

_$VoteItemModelImpl _$$VoteItemModelImplFromJson(Map<String, dynamic> json) =>
    _$VoteItemModelImpl(
      id: (json['id'] as num).toInt(),
      vote_total: (json['vote_total'] as num).toInt(),
      vote_id: (json['vote_id'] as num).toInt(),
      mystar_member: MyStarMemberModel.fromJson(
          json['mystar_member'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VoteItemModelImplToJson(_$VoteItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_total': instance.vote_total,
      'vote_id': instance.vote_id,
      'mystar_member': instance.mystar_member,
    };

_$MyStarMemberModelImpl _$$MyStarMemberModelImplFromJson(
        Map<String, dynamic> json) =>
    _$MyStarMemberModelImpl(
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

Map<String, dynamic> _$$MyStarMemberModelImplToJson(
        _$MyStarMemberModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.name_ko,
      'name_en': instance.name_en,
      'gender': instance.gender,
      'image': instance.image,
      'mystar_group': instance.mystar_group,
    };

_$MyStarGroupModelImpl _$$MyStarGroupModelImplFromJson(
        Map<String, dynamic> json) =>
    _$MyStarGroupModelImpl(
      id: (json['id'] as num).toInt(),
      name_ko: json['name_ko'] as String,
      name_en: json['name_en'] as String,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$$MyStarGroupModelImplToJson(
        _$MyStarGroupModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.name_ko,
      'name_en': instance.name_en,
      'image': instance.image,
    };
