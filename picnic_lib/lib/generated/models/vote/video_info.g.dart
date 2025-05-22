// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/vote/video_info.dart';

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
          videoId: $checkedConvert('video_id', (v) => v as String),
          videoUrl: $checkedConvert('video_url', (v) => v as String),
          title: $checkedConvert(
              'title', (v) => Map<String, String>.from(v as Map)),
          thumbnailUrl: $checkedConvert('thumbnail_url', (v) => v as String),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          channelTitle: $checkedConvert('channel_title', (v) => v as String),
          channelId: $checkedConvert('channel_id', (v) => v as String),
          channelThumbnail:
              $checkedConvert('channel_thumbnail', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'videoId': 'video_id',
        'videoUrl': 'video_url',
        'thumbnailUrl': 'thumbnail_url',
        'createdAt': 'created_at',
        'channelTitle': 'channel_title',
        'channelId': 'channel_id',
        'channelThumbnail': 'channel_thumbnail'
      },
    );

Map<String, dynamic> _$$VideoInfoImplToJson(_$VideoInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'video_id': instance.videoId,
      'video_url': instance.videoUrl,
      'title': instance.title,
      'thumbnail_url': instance.thumbnailUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'channel_title': instance.channelTitle,
      'channel_id': instance.channelId,
      'channel_thumbnail': instance.channelThumbnail,
    };
