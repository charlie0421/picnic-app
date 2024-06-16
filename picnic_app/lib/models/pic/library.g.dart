// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LibraryListModelImpl _$$LibraryListModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LibraryListModelImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => LibraryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LibraryListModelImplToJson(
        _$LibraryListModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

_$LibraryModelImpl _$$LibraryModelImplFromJson(Map<String, dynamic> json) =>
    _$LibraryModelImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ArticleImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$LibraryModelImplToJson(_$LibraryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'images': instance.images,
    };
