// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RewardModel _$RewardModelFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_RewardModel',
  json,
  ($checkedConvert) {
    final val = _RewardModel(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      title: $checkedConvert('title', (v) => v as Map<String, dynamic>?),
      thumbnail: $checkedConvert('thumbnail', (v) => v as String?),
      overviewImages: $checkedConvert(
        'overview_images',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      location: $checkedConvert('location', (v) => v as Map<String, dynamic>?),
      sizeGuide: $checkedConvert(
        'size_guide',
        (v) => v as Map<String, dynamic>?,
      ),
      sizeGuideImages: $checkedConvert(
        'size_guide_images',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'overviewImages': 'overview_images',
    'sizeGuide': 'size_guide',
    'sizeGuideImages': 'size_guide_images',
  },
);

Map<String, dynamic> _$RewardModelToJson(_RewardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'thumbnail': instance.thumbnail,
      'overview_images': instance.overviewImages,
      'location': instance.location,
      'size_guide': instance.sizeGuide,
      'size_guide_images': instance.sizeGuideImages,
    };
