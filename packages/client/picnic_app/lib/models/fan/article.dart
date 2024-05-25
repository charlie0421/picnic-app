import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/fan/article_image.dart';
import 'package:picnic_app/models/fan/comment.dart';
import 'package:picnic_app/models/fan/gallery.dart';
import 'package:picnic_app/reflector.dart';

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
  final String title_ko;
  final String title_en;
  final String content;
  final GalleryModel? gallery;
  final List<ArticleImageModel>? article_image;
  final DateTime created_at;
  final int? comment_count;
  final CommentModel? comment;
  final CommentModel? most_liked_comment;

  ArticleModel({
    required this.id,
    required this.title_ko,
    required this.title_en,
    required this.content,
    required this.gallery,
    required this.article_image,
    required this.created_at,
    required this.comment_count,
    required this.comment,
    required this.most_liked_comment,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleModelToJson(this);
}
