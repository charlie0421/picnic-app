// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoInfoImpl _$$VideoInfoImplFromJson(Map<String, dynamic> json) =>
    _$VideoInfoImpl(
      id: (json['id'] as num).toInt(),
      video_id: json['video_id'] as String,
      video_url: json['video_url'] as String,
      title: Map<String, String>.from(json['title'] as Map),
      thumbnail_url: json['thumbnail_url'] as String,
      created_at: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$VideoInfoImplToJson(_$VideoInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'video_id': instance.video_id,
      'video_url': instance.video_url,
      'title': instance.title,
      'thumbnail_url': instance.thumbnail_url,
      'created_at': instance.created_at.toIso8601String(),
    };
