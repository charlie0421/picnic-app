// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryImageListModel _$GalleryImageListModelFromJson(
        Map<String, dynamic> json) =>
    GalleryImageListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => GalleryImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GalleryImageListModelToJson(
        GalleryImageListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

GalleryImageModel _$GalleryImageModelFromJson(Map<String, dynamic> json) =>
    GalleryImageModel(
      id: json['id'] as int,
      titleKo: json['titleKo'] as String,
      titleEn: json['titleEn'] as String,
      thumbnail: json['thumbnail'] as String,
    );

Map<String, dynamic> _$GalleryImageModelToJson(GalleryImageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titleKo': instance.titleKo,
      'titleEn': instance.titleEn,
      'thumbnail': instance.thumbnail,
    };
