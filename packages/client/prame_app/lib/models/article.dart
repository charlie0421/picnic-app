import 'package:json_annotation/json_annotation.dart';
import 'package:prame_app/models/article_image.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/models/gallery.dart';
import 'package:prame_app/models/meta.dart';
import 'package:prame_app/reflector.dart';

part 'article.g.dart';

@reflector
@JsonSerializable()
class ArticleListModel {
  final List<ArticleModel> items;
  final MetaModel meta;

  ArticleListModel({
    required this.items,
    required this.meta,
  });

  factory ArticleListModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleListModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleListModelToJson(this);
}

@reflector
@JsonSerializable()
class ArticleModel {
  final int id;
  final String titleKo;
  final String titleEn;
  final String content;
  final GalleryModel? gallery;
  final List<ArticleImageModel>? images;
  final DateTime createdAt;
  final int? commentCount;
  final CommentModel? comment;
  final CommentModel? mostLikedComment;

  ArticleModel({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.content,
    required this.gallery,
    required this.images,
    required this.createdAt,
    required this.commentCount,
    required this.comment,
    required this.mostLikedComment,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleModelToJson(this);
}
