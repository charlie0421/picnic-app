// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GalleryModelImpl _$$GalleryModelImplFromJson(Map<String, dynamic> json) =>
    _$GalleryModelImpl(
      id: (json['id'] as num).toInt(),
      title_ko: json['title_ko'] as String,
      title_en: json['title_en'] as String,
      cover: json['cover'] as String?,
      celeb: json['celeb'] == null
          ? null
          : CelebModel.fromJson(json['celeb'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$GalleryModelImplToJson(_$GalleryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'cover': instance.cover,
      'celeb': instance.celeb,
    };
