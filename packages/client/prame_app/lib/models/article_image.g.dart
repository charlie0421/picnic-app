// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArticleImageListModel _$ArticleImageListModelFromJson(
        Map<String, dynamic> json) =>
    ArticleImageListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => ArticleImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ArticleImageListModelToJson(
        ArticleImageListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

ArticleImageModel _$ArticleImageModelFromJson(Map<String, dynamic> json) =>
    ArticleImageModel(
      id: json['id'] as int,
      titleKo: json['titleKo'] as String,
      titleEn: json['titleEn'] as String,
      image: json['image'] as String,
    );

Map<String, dynamic> _$ArticleImageModelToJson(ArticleImageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titleKo': instance.titleKo,
      'titleEn': instance.titleEn,
      'image': instance.image,
    };
