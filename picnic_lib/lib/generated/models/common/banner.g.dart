// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/common/banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BannerModelImpl _$$BannerModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$BannerModelImpl',
      json,
      ($checkedConvert) {
        final val = _$BannerModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          title: $checkedConvert('title', (v) => v as Map<String, dynamic>),
          thumbnail: $checkedConvert('thumbnail', (v) => v as String),
          image: $checkedConvert('image', (v) => v as Map<String, dynamic>),
          duration:
              $checkedConvert('duration', (v) => (v as num?)?.toInt() ?? 3000),
          link: $checkedConvert('link', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$$BannerModelImplToJson(_$BannerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'thumbnail': instance.thumbnail,
      'image': instance.image,
      'duration': instance.duration,
      'link': instance.link,
    };
