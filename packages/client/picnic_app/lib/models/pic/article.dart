import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/pic/article_image.dart';
import 'package:picnic_app/models/pic/gallery.dart';

part '../../generated/models/pic/article.freezed.dart';

part '../../generated/models/pic/article.g.dart';

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
