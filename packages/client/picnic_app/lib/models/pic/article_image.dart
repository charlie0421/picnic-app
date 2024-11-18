import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/user_profiles.dart';

part '../../generated/models/pic/article_image.freezed.dart';

part '../../generated/models/pic/article_image.g.dart';

@freezed
class ArticleImageModel with _$ArticleImageModel {
  const ArticleImageModel._();

  const factory ArticleImageModel({
    required int id,
    required String title_ko,
    required String title_en,
    String? image,
    required List<UserProfilesModel>? article_image_user,
  }) = _ArticleImageModel;

  factory ArticleImageModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleImageModelFromJson(json);
}
