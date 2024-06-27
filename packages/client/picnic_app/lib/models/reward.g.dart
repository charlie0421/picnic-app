// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RewardModelImpl _$$RewardModelImplFromJson(Map<String, dynamic> json) =>
    _$RewardModelImpl(
      id: (json['id'] as num).toInt(),
      title_ko: json['title_ko'] as String,
      title_en: json['title_en'] as String,
      title_ja: json['title_ja'] as String,
      title_zh: json['title_zh'] as String,
      thumbnail: json['thumbnail'] as String?,
      overview_images: (json['overview_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      location_images: (json['location_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      location_desc: (json['location_desc'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      size_guide_images: (json['size_guide_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$RewardModelImplToJson(_$RewardModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'title_ja': instance.title_ja,
      'title_zh': instance.title_zh,
      'thumbnail': instance.thumbnail,
      'overview_images': instance.overview_images,
      'location_images': instance.location_images,
      'location_desc': instance.location_desc,
      'size_guide_images': instance.size_guide_images,
    };
