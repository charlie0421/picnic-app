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
          titleKo: $checkedConvert('title_ko', (v) => v as String),
          titleEn: $checkedConvert('title_en', (v) => v as String),
          image: $checkedConvert('image', (v) => v as String?),
          articleImageUser: $checkedConvert(
              'article_image_user',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      UserProfilesModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'titleKo': 'title_ko',
        'titleEn': 'title_en',
        'articleImageUser': 'article_image_user'
      },
    );

Map<String, dynamic> _$$ArticleImageModelImplToJson(
        _$ArticleImageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.titleKo,
      'title_en': instance.titleEn,
      'image': instance.image,
      'article_image_user':
          instance.articleImageUser?.map((e) => e.toJson()).toList(),
    };
