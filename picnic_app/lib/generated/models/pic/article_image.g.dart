// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/pic/article_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArticleImageModelImpl _$$ArticleImageModelImplFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$ArticleImageModelImpl',
      json,
      ($checkedConvert) {
        final val = _$ArticleImageModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          title_ko: $checkedConvert('title_ko', (v) => v as String),
          title_en: $checkedConvert('title_en', (v) => v as String),
          image: $checkedConvert('image', (v) => v as String?),
          article_image_user: $checkedConvert(
              'article_image_user',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      UserProfilesModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ArticleImageModelImplToJson(
        _$ArticleImageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'image': instance.image,
      'article_image_user':
          instance.article_image_user?.map((e) => e.toJson()).toList(),
    };
