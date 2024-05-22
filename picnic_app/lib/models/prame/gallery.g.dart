// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryListModel _$GalleryListModelFromJson(Map<String, dynamic> json) =>
    GalleryListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => GalleryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GalleryListModelToJson(GalleryListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

GalleryModel _$GalleryModelFromJson(Map<String, dynamic> json) => GalleryModel(
      id: (json['id'] as num).toInt(),
      title_ko: json['title_ko'] as String,
      title_en: json['title_en'] as String,
      cover: json['cover'] as String?,
      celeb: json['celeb'] == null
          ? null
          : CelebModel.fromJson(json['celeb'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GalleryModelToJson(GalleryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'cover': instance.cover,
      'celeb': instance.celeb,
    };
