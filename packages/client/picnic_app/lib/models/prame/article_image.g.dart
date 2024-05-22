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
      id: (json['id'] as num).toInt(),
      title_ko: json['title_ko'] as String,
      title_en: json['title_en'] as String,
      image: json['image'] as String?,
      bookmark_users: (json['bookmark_users'] as List<dynamic>?)
          ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ArticleImageModelToJson(ArticleImageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'image': instance.image,
      'bookmark_users': instance.bookmark_users,
    };
