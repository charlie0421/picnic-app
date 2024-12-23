// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/pic/gallery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GalleryModelImpl _$$GalleryModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$GalleryModelImpl',
      json,
      ($checkedConvert) {
        final val = _$GalleryModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          titleKo: $checkedConvert('title_ko', (v) => v as String),
          titleEn: $checkedConvert('title_en', (v) => v as String),
          cover: $checkedConvert('cover', (v) => v as String?),
          celeb: $checkedConvert(
              'celeb',
              (v) => v == null
                  ? null
                  : CelebModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {'titleKo': 'title_ko', 'titleEn': 'title_en'},
    );

Map<String, dynamic> _$$GalleryModelImplToJson(_$GalleryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.titleKo,
      'title_en': instance.titleEn,
      'cover': instance.cover,
      'celeb': instance.celeb?.toJson(),
    };
