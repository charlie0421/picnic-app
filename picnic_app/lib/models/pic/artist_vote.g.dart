// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistVoteListModelImpl _$$ArtistVoteListModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ArtistVoteListModelImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => ArtistVoteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ArtistVoteListModelImplToJson(
        _$ArtistVoteListModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

_$ArtistVoteModelImpl _$$ArtistVoteModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ArtistVoteModelImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as Map<String, dynamic>,
      category: json['category'] as String,
      artist_vote_item: (json['artist_vote_item'] as List<dynamic>?)
          ?.map((e) => ArtistVoteItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      visible_at: json['visible_at'] == null
          ? null
          : DateTime.parse(json['visible_at'] as String),
      stop_at: DateTime.parse(json['stop_at'] as String),
      start_at: DateTime.parse(json['start_at'] as String),
    );

Map<String, dynamic> _$$ArtistVoteModelImplToJson(
        _$ArtistVoteModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'artist_vote_item': instance.artist_vote_item,
      'created_at': instance.created_at.toIso8601String(),
      'updated_at': instance.updated_at?.toIso8601String(),
      'visible_at': instance.visible_at?.toIso8601String(),
      'stop_at': instance.stop_at.toIso8601String(),
      'start_at': instance.start_at.toIso8601String(),
    };

_$ArtistVoteItemModelImpl _$$ArtistVoteItemModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ArtistVoteItemModelImpl(
      id: (json['id'] as num).toInt(),
      vote_total: (json['vote_total'] as num).toInt(),
      artist_vote_id: (json['artist_vote_id'] as num).toInt(),
      title: json['title'] as Map<String, dynamic>,
      description: json['description'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$ArtistVoteItemModelImplToJson(
        _$ArtistVoteItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_total': instance.vote_total,
      'artist_vote_id': instance.artist_vote_id,
      'title': instance.title,
      'description': instance.description,
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

_$ArtistMemberModelImpl _$$ArtistMemberModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ArtistMemberModelImpl(
      id: (json['id'] as num).toInt(),
      name: Map<String, String>.from(json['name'] as Map),
      gender: json['gender'] as String,
      image: json['image'] as String?,
      mystar_group: json['mystar_group'] == null
          ? null
          : ArtistGroupModel.fromJson(
              json['mystar_group'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ArtistMemberModelImplToJson(
        _$ArtistMemberModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'gender': instance.gender,
      'image': instance.image,
      'mystar_group': instance.mystar_group,
    };

_$ArtistGroupModelImpl _$$ArtistGroupModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ArtistGroupModelImpl(
      id: (json['id'] as num).toInt(),
      name: Map<String, String>.from(json['name'] as Map),
      image: json['image'] as String?,
    );

Map<String, dynamic> _$$ArtistGroupModelImplToJson(
        _$ArtistGroupModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
    };
