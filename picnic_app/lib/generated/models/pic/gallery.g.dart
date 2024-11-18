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
          title_ko: $checkedConvert('title_ko', (v) => v as String),
          title_en: $checkedConvert('title_en', (v) => v as String),
          cover: $checkedConvert('cover', (v) => v as String?),
          celeb: $checkedConvert(
              'celeb',
              (v) => v == null
                  ? null
                  : CelebModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$GalleryModelImplToJson(_$GalleryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'cover': instance.cover,
      'celeb': instance.celeb?.toJson(),
    };
