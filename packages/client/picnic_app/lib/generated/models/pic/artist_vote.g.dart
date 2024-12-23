// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/pic/artist_vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistVoteModelImpl _$$ArtistVoteModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$ArtistVoteModelImpl',
      json,
      ($checkedConvert) {
        final val = _$ArtistVoteModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          title: $checkedConvert('title', (v) => v as Map<String, dynamic>),
          category: $checkedConvert('category', (v) => v as String),
          artistVoteItem: $checkedConvert(
              'artist_vote_item',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      ArtistVoteItemModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          visibleAt: $checkedConvert('visible_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          stopAt:
              $checkedConvert('stop_at', (v) => DateTime.parse(v as String)),
          startAt:
              $checkedConvert('start_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'artistVoteItem': 'artist_vote_item',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
        'visibleAt': 'visible_at',
        'stopAt': 'stop_at',
        'startAt': 'start_at'
      },
    );

Map<String, dynamic> _$$ArtistVoteModelImplToJson(
        _$ArtistVoteModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'artist_vote_item':
          instance.artistVoteItem?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'visible_at': instance.visibleAt?.toIso8601String(),
      'stop_at': instance.stopAt.toIso8601String(),
      'start_at': instance.startAt.toIso8601String(),
    };

_$ArtistVoteItemModelImpl _$$ArtistVoteItemModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$ArtistVoteItemModelImpl',
      json,
      ($checkedConvert) {
        final val = _$ArtistVoteItemModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          voteTotal: $checkedConvert('vote_total', (v) => (v as num).toInt()),
          artistVoteId:
              $checkedConvert('artist_vote_id', (v) => (v as num).toInt()),
          title: $checkedConvert('title', (v) => v as Map<String, dynamic>),
          description:
              $checkedConvert('description', (v) => v as Map<String, dynamic>),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteTotal': 'vote_total',
        'artistVoteId': 'artist_vote_id'
      },
    );

Map<String, dynamic> _$$ArtistVoteItemModelImplToJson(
        _$ArtistVoteItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote_total': instance.voteTotal,
      'artist_vote_id': instance.artistVoteId,
      'title': instance.title,
      'description': instance.description,
    };

_$MyStarMemberModelImpl _$$MyStarMemberModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$MyStarMemberModelImpl',
      json,
      ($checkedConvert) {
        final val = _$MyStarMemberModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          nameKo: $checkedConvert('name_ko', (v) => v as String),
          nameEn: $checkedConvert('name_en', (v) => v as String),
          gender: $checkedConvert('gender', (v) => v as String),
          image: $checkedConvert('image', (v) => v as String?),
          mystarGroup: $checkedConvert(
              'mystar_group',
              (v) => v == null
                  ? null
                  : MyStarGroupModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'nameKo': 'name_ko',
        'nameEn': 'name_en',
        'mystarGroup': 'mystar_group'
      },
    );

Map<String, dynamic> _$$MyStarMemberModelImplToJson(
        _$MyStarMemberModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.nameKo,
      'name_en': instance.nameEn,
      'gender': instance.gender,
      'image': instance.image,
      'mystar_group': instance.mystarGroup?.toJson(),
    };

_$MyStarGroupModelImpl _$$MyStarGroupModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$MyStarGroupModelImpl',
      json,
      ($checkedConvert) {
        final val = _$MyStarGroupModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          nameKo: $checkedConvert('name_ko', (v) => v as String),
          nameEn: $checkedConvert('name_en', (v) => v as String),
          image: $checkedConvert('image', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'nameKo': 'name_ko', 'nameEn': 'name_en'},
    );

Map<String, dynamic> _$$MyStarGroupModelImplToJson(
        _$MyStarGroupModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.nameKo,
      'name_en': instance.nameEn,
      'image': instance.image,
    };

_$ArtistMemberModelImpl _$$ArtistMemberModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$ArtistMemberModelImpl',
      json,
      ($checkedConvert) {
        final val = _$ArtistMemberModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          name: $checkedConvert(
              'name', (v) => Map<String, String>.from(v as Map)),
          gender: $checkedConvert('gender', (v) => v as String),
          image: $checkedConvert('image', (v) => v as String?),
          artistGroup: $checkedConvert(
              'artist_group',
              (v) => v == null
                  ? null
                  : ArtistGroupModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {'artistGroup': 'artist_group'},
    );

Map<String, dynamic> _$$ArtistMemberModelImplToJson(
        _$ArtistMemberModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'gender': instance.gender,
      'image': instance.image,
      'artist_group': instance.artistGroup?.toJson(),
    };

_$ArtistGroupModelImpl _$$ArtistGroupModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$ArtistGroupModelImpl',
      json,
      ($checkedConvert) {
        final val = _$ArtistGroupModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as Map<String, dynamic>),
          image: $checkedConvert('image', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ArtistGroupModelImplToJson(
        _$ArtistGroupModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
    };
