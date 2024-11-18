// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
