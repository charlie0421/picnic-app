// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArticleImageModelImpl _$$ArticleImageModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ArticleImageModelImpl(
      id: (json['id'] as num).toInt(),
      title_ko: json['title_ko'] as String,
      title_en: json['title_en'] as String,
      image: json['image'] as String?,
      article_image_user: (json['article_image_user'] as List<dynamic>?)
          ?.map((e) => UserProfilesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ArticleImageModelImplToJson(
        _$ArticleImageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'image': instance.image,
      'article_image_user': instance.article_image_user,
    };
