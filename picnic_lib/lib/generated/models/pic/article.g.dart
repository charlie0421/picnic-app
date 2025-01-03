// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../data/models/pic/article.dart';

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
          titleKo: $checkedConvert('title_ko', (v) => v as String),
          titleEn: $checkedConvert('title_en', (v) => v as String),
          content: $checkedConvert('content', (v) => v as String),
          gallery: $checkedConvert(
              'gallery',
              (v) => v == null
                  ? null
                  : GalleryModel.fromJson(v as Map<String, dynamic>)),
          articleImage: $checkedConvert(
              'article_image',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      ArticleImageModel.fromJson(e as Map<String, dynamic>))
                  .toList()),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          commentCount:
              $checkedConvert('comment_count', (v) => (v as num?)?.toInt()),
          comment: $checkedConvert(
              'comment',
              (v) => v == null
                  ? null
                  : CommentModel.fromJson(v as Map<String, dynamic>)),
          mostLikedComment: $checkedConvert(
              'most_liked_comment',
              (v) => v == null
                  ? null
                  : CommentModel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'titleKo': 'title_ko',
        'titleEn': 'title_en',
        'articleImage': 'article_image',
        'createdAt': 'created_at',
        'commentCount': 'comment_count',
        'mostLikedComment': 'most_liked_comment'
      },
    );

Map<String, dynamic> _$$ArticleModelImplToJson(_$ArticleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_ko': instance.titleKo,
      'title_en': instance.titleEn,
      'content': instance.content,
      'gallery': instance.gallery?.toJson(),
      'article_image': instance.articleImage?.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt.toIso8601String(),
      'comment_count': instance.commentCount,
      'comment': instance.comment?.toJson(),
      'most_liked_comment': instance.mostLikedComment?.toJson(),
    };
