import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/data/models/user_profiles.dart';

part '../../../generated/models/pic/article_image.freezed.dart';
part '../../../generated/models/pic/article_image.g.dart';

@freezed
class ArticleImageModel with _$ArticleImageModel {
  const ArticleImageModel._();

  const factory ArticleImageModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'title_ko') required String titleKo,
    @JsonKey(name: 'title_en') required String titleEn,
    @JsonKey(name: 'image') String? image,
    @JsonKey(name: 'article_image_user')
    required List<UserProfilesModel>? articleImageUser,
  }) = _ArticleImageModel;

  factory ArticleImageModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleImageModelFromJson(json);
}
