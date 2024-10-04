import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/pic/article_image.dart';
import 'package:picnic_app/models/pic/gallery.dart';

part 'article.freezed.dart';
part 'article.g.dart';

@freezed
class ArticleListModel with _$ArticleListModel {
  const ArticleListModel._();

  const factory ArticleListModel({
    required List<ArticleModel> items,
    required MetaModel meta,
  }) = _ArticleListModel;

  factory ArticleListModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleListModelFromJson(json);
}

@freezed
class ArticleModel with _$ArticleModel {
  const ArticleModel._();

  const factory ArticleModel({
    required int id,
    required String title_ko,
    required String title_en,
    required String content,
    required GalleryModel? gallery,
    required List<ArticleImageModel>? article_image,
    required DateTime created_at,
    required int? comment_count,
    required CommentModel? comment,
    required CommentModel? most_liked_comment,
  }) = _ArticleModel;

  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleModelFromJson(json);
}
