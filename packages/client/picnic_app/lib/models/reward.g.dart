// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RewardModelImpl _$$RewardModelImplFromJson(Map<String, dynamic> json) =>
    _$RewardModelImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as Map<String, dynamic>?,
      thumbnail: json['thumbnail'] as String?,
      overview_images: (json['overview_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      location: json['location'] as Map<String, dynamic>?,
      size_guide: json['size_guide'] as Map<String, dynamic>?,
      size_guide_images: (json['size_guide_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$RewardModelImplToJson(_$RewardModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'thumbnail': instance.thumbnail,
      'overview_images': instance.overview_images,
      'location': instance.location,
      'size_guide': instance.size_guide,
      'size_guide_images': instance.size_guide_images,
    };
