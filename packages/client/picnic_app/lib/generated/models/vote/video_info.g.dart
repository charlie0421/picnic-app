// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/vote/video_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoInfoImpl _$$VideoInfoImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$VideoInfoImpl',
      json,
      ($checkedConvert) {
        final val = _$VideoInfoImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          video_id: $checkedConvert('video_id', (v) => v as String),
          video_url: $checkedConvert('video_url', (v) => v as String),
          title: $checkedConvert(
              'title', (v) => Map<String, String>.from(v as Map)),
          thumbnail_url: $checkedConvert('thumbnail_url', (v) => v as String),
          created_at:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
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
