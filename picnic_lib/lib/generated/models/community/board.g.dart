// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/community/board.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BoardModelImpl _$$BoardModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$BoardModelImpl',
      json,
      ($checkedConvert) {
        final val = _$BoardModelImpl(
          boardId: $checkedConvert('board_id', (v) => v as String),
          artistId: $checkedConvert('artist_id', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as Map<String, dynamic>),
          description: $checkedConvert(
              'description', (v) => const DescriptionConverter().fromJson(v)),
          isOfficial: $checkedConvert('is_official', (v) => v as bool?),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          updatedAt: $checkedConvert('updated_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          artist: $checkedConvert(
              'artist',
              (v) => v == null
                  ? null
                  : ArtistModel.fromJson(v as Map<String, dynamic>)),
          requestMessage:
              $checkedConvert('request_message', (v) => v as String?),
          status: $checkedConvert('status', (v) => v as String?),
          creatorId: $checkedConvert('creator_id', (v) => v as String?),
          features: $checkedConvert('features',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'boardId': 'board_id',
        'artistId': 'artist_id',
        'isOfficial': 'is_official',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
        'requestMessage': 'request_message',
        'creatorId': 'creator_id'
      },
    );

Map<String, dynamic> _$$BoardModelImplToJson(_$BoardModelImpl instance) =>
    <String, dynamic>{
      'board_id': instance.boardId,
      'artist_id': instance.artistId,
      'name': instance.name,
      'description': const DescriptionConverter().toJson(instance.description),
      'is_official': instance.isOfficial,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'artist': instance.artist?.toJson(),
      'request_message': instance.requestMessage,
      'status': instance.status,
      'creator_id': instance.creatorId,
      'features': instance.features,
    };
