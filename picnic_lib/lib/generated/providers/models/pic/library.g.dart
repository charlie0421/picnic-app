// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/pic/library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LibraryModel _$LibraryModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_LibraryModel', json, ($checkedConvert) {
      final val = _LibraryModel(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
        images: $checkedConvert(
          'images',
          (v) => (v as List<dynamic>?)
              ?.map(
                (e) => ArticleImageModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LibraryModelToJson(_LibraryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'images': instance.images?.map((e) => e.toJson()).toList(),
    };
