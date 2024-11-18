// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../models/pic/article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArticleModelImpl _$$ArticleModelImplFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      r'_$ArticleModelImpl',
      json,
      ($checkedConvert) {
        final val = _$ArticleModelImpl(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          title_ko: $checkedConvert('title_ko', (v) => v as String),
          title_en: $checkedConvert('title_en', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          gallery: $checkedConvert(
              'gallery',
              (v) => v == null
                  ? null
                  : GalleryModel.fromJson(v as Map<String, dynamic>)),
          article_image: $checkedConvert(
              'article_image',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      ArticleImageModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
          created_at:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          comment_count:
              $checkedConvert('comment_count', (v) => (v as num?)?.toInt()),
          comment: $checkedConvert(
              'comment',
              (v) => v == null
                  ? null
                  : CommentModel.fromJson(v as Map<String, dynamic>)),
          most_liked_comment: $checkedConvert(
              'most_liked_comment',
              (v) => v == null
                  ? null
                  : CommentModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$$ArticleModelImplToJson(_$ArticleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.title_ko,
      'title_en': instance.title_en,
      'content': instance.content,
      'gallery': instance.gallery?.toJson(),
      'article_image': instance.article_image?.map((e) => e.toJson()).toList(),
      'created_at': instance.created_at.toIso8601String(),
      'comment_count': instance.comment_count,
      'comment': instance.comment?.toJson(),
      'most_liked_comment': instance.most_liked_comment?.toJson(),
    };
