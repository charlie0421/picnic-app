import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/pic/article_image.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';

part '../../../generated/models/pic/article.freezed.dart';
part '../../../generated/models/pic/article.g.dart';

@freezed
class ArticleModel with _$ArticleModel {
  const ArticleModel._();

  const factory ArticleModel({
    required int id,
    @JsonKey(name: 'title_ko') required String titleKo,
    @JsonKey(name: 'title_en') required String titleEn,
    required String content,
    required GalleryModel? gallery,
    @JsonKey(name: 'article_image')
    required List<ArticleImageModel>? articleImage,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'comment_count') required int? commentCount,
    required CommentModel? comment,
    @JsonKey(name: 'most_liked_comment')
    required CommentModel? mostLikedComment,
  }) = _ArticleModel;

  factory ArticleModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleModelFromJson(json);
}
