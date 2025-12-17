// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/pic/gallery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GalleryModel _$GalleryModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_GalleryModel',
      json,
      ($checkedConvert) {
        final val = _GalleryModel(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          titleKo: $checkedConvert('title_ko', (v) => v as String),
          titleEn: $checkedConvert('title_en', (v) => v as String),
          cover: $checkedConvert('cover', (v) => v as String?),
          celeb: $checkedConvert(
            'celeb',
            (v) => v == null
                ? null
                : CelebModel.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {'titleKo': 'title_ko', 'titleEn': 'title_en'},
    );

Map<String, dynamic> _$GalleryModelToJson(_GalleryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.titleKo,
      'title_en': instance.titleEn,
      'cover': instance.cover,
      'celeb': instance.celeb?.toJson(),
    };
