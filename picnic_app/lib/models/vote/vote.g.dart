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
      title: json['title'] as Map<String, dynamic>,
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
      is_ended: json['is_ended'] as bool?,
      is_upcoming: json['is_upcoming'] as bool?,
      reward: (json['reward'] as List<dynamic>?)
          ?.map((e) => RewardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$VoteModelImplToJson(_$VoteModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
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
      'is_ended': instance.is_ended,
      'is_upcoming': instance.is_upcoming,
      'reward': instance.reward,
    };

_$VoteItemModelImpl _$$VoteItemModelImplFromJson(Map<String, dynamic> json) =>
    _$VoteItemModelImpl(
      id: (json['id'] as num).toInt(),
      vote_total: (json['vote_total'] as num).toInt(),
      vote_id: (json['vote_id'] as num).toInt(),
      artist: ArtistModel.fromJson(json['artist'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VoteItemModelImplToJson(_$VoteItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_total': instance.vote_total,
      'vote_id': instance.vote_id,
      'artist': instance.artist,
    };

_$ArtistModelImpl _$$ArtistModelImplFromJson(Map<String, dynamic> json) =>
    _$ArtistModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as Map<String, dynamic>,
      yy: (json['yy'] as num).toInt(),
      mm: (json['mm'] as num).toInt(),
      dd: (json['dd'] as num).toInt(),
      gender: json['gender'] as String,
      image: json['image'] as String,
      artist_group: ArtistGroupModel.fromJson(
          json['artist_group'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ArtistModelImplToJson(_$ArtistModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'yy': instance.yy,
      'mm': instance.mm,
      'dd': instance.dd,
      'gender': instance.gender,
      'image': instance.image,
      'artist_group': instance.artist_group,
    };

_$ArtistGroupModelImpl _$$ArtistGroupModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ArtistGroupModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$ArtistGroupModelImplToJson(
        _$ArtistGroupModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };
