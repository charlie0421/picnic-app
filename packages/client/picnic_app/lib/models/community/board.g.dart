// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BoardModelImpl _$$BoardModelImplFromJson(Map<String, dynamic> json) =>
    _$BoardModelImpl(
      board_id: json['board_id'] as String,
      artist_id: (json['artist_id'] as num).toInt(),
      name: json['name'] as Map<String, dynamic>,
      description: const DescriptionConverter().fromJson(json['description']),
      is_official: json['is_official'] as bool,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
      artist: json['artist'] == null
          ? null
          : ArtistModel.fromJson(json['artist'] as Map<String, dynamic>),
      requestMessage: json['request_message'] as String?,
    );

Map<String, dynamic> _$$BoardModelImplToJson(_$BoardModelImpl instance) =>
    <String, dynamic>{
      'board_id': instance.board_id,
      'artist_id': instance.artist_id,
      'name': instance.name,
      'description': const DescriptionConverter().toJson(instance.description),
      'is_official': instance.is_official,
      'created_at': instance.created_at.toIso8601String(),
      'updated_at': instance.updated_at.toIso8601String(),
      'artist': instance.artist,
      'request_message': instance.requestMessage,
    };
