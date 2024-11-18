// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/pic/library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LibraryModelImpl _$$LibraryModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$LibraryModelImpl',
      json,
      ($checkedConvert) {
        final val = _$LibraryModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          title: $checkedConvert('title', (v) => v as String),
          images: $checkedConvert(
              'images',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      ArticleImageModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$LibraryModelImplToJson(_$LibraryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'images': instance.images?.map((e) => e.toJson()).toList(),
    };
