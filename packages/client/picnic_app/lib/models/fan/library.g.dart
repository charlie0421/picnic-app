// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LibraryListModel _$LibraryListModelFromJson(Map<String, dynamic> json) =>
    LibraryListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => LibraryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LibraryListModelToJson(LibraryListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

LibraryModel _$LibraryModelFromJson(Map<String, dynamic> json) => LibraryModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ArticleImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LibraryModelToJson(LibraryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'images': instance.images,
    };
