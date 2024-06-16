// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArticleListModelImpl _$$ArticleListModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ArticleListModelImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ArticleListModelImplToJson(
        _$ArticleListModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

_$ArticleModelImpl _$$ArticleModelImplFromJson(Map<String, dynamic> json) =>
    _$ArticleModelImpl(
      id: (json['id'] as num).toInt(),
      title_ko: json['title_ko'] as String,
      title_en: json['title_en'] as String,
      content: json['content'] as String,
      gallery: json['gallery'] == null
          ? null
          : GalleryModel.fromJson(json['gallery'] as Map<String, dynamic>),
      article_image: (json['article_image'] as List<dynamic>?)
          ?.map((e) => ArticleImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      created_at: DateTime.parse(json['created_at'] as String),
      comment_count: (json['comment_count'] as num?)?.toInt(),
      comment: json['comment'] == null
          ? null
          : CommentModel.fromJson(json['comment'] as Map<String, dynamic>),
      most_liked_comment: json['most_liked_comment'] == null
          ? null
          : CommentModel.fromJson(
              json['most_liked_comment'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ArticleModelImplToJson(_$ArticleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'content': instance.content,
      'gallery': instance.gallery,
      'article_image': instance.article_image,
      'created_at': instance.created_at.toIso8601String(),
      'comment_count': instance.comment_count,
      'comment': instance.comment,
      'most_liked_comment': instance.most_liked_comment,
    };
