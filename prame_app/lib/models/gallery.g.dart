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
      id: json['id'] as int,
      titleKo: json['titleKo'] as String,
      titleEn: json['titleEn'] as String,
      cover: json['cover'] as String,
      celeb: CelebModel.fromJson(json['celeb'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GalleryModelToJson(GalleryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titleKo': instance.titleKo,
      'titleEn': instance.titleEn,
      'cover': instance.cover,
      'celeb': instance.celeb,
    };
