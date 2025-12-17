// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/common/banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BannerModel _$BannerModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_BannerModel', json, ($checkedConvert) {
      final val = _BannerModel(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as Map<String, dynamic>),
        thumbnail: $checkedConvert('thumbnail', (v) => v as String),
        image: $checkedConvert('image', (v) => v as Map<String, dynamic>),
        duration: $checkedConvert(
          'duration',
          (v) => (v as num?)?.toInt() ?? 3000,
        ),
        link: $checkedConvert('link', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$BannerModelToJson(_BannerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'thumbnail': instance.thumbnail,
      'image': instance.image,
      'duration': instance.duration,
      'link': instance.link,
    };
