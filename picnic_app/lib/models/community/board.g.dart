// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BoardModelImpl _$$BoardModelImplFromJson(Map<String, dynamic> json) =>
    _$BoardModelImpl(
      boardId: json['board_id'] as String,
      artistId: (json['artist_id'] as num).toInt(),
      name: json['name'] as Map<String, dynamic>,
      description: const DescriptionConverter().fromJson(json['description']),
      isOfficial: json['is_official'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      artist: json['artist'] == null
          ? null
          : ArtistModel.fromJson(json['artist'] as Map<String, dynamic>),
      requestMessage: json['request_message'] as String?,
      status: json['status'] as String?,
      creatorId: json['creator_id'] as String?,
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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
      'artist': instance.artist,
      'request_message': instance.requestMessage,
      'status': instance.status,
      'creator_id': instance.creatorId,
      'features': instance.features,
    };
