import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/reflector.dart';

part 'article_image.g.dart';

@reflector
@JsonSerializable()
class ArticleImageListModel {
  final List<ArticleImageModel> items;
  final MetaModel meta;

  ArticleImageListModel({
    required this.items,
    required this.meta,
  });

  factory ArticleImageListModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleImageListModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleImageListModelToJson(this);
}

@reflector
@JsonSerializable()
class ArticleImageModel {
  final int id;
  final String title_ko;
  final String title_en;
  String? image;
  final List<UserProfilesModel>? article_image_user;

  ArticleImageModel({
    required this.id,
    required this.title_ko,
    required this.title_en,
    this.image,
    required this.article_image_user,
  });

  factory ArticleImageModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleImageModelToJson(this);
}
