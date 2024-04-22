import 'package:json_annotation/json_annotation.dart';
import 'package:prame_app/models/meta.dart';
import 'package:prame_app/models/user.dart';
import 'package:prame_app/reflector.dart';

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
  final String titleKo;
  final String titleEn;
  final String image;
  final List<UserModel>? bookmarkUsers;

  ArticleImageModel({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.image,
    required this.bookmarkUsers,
  });

  factory ArticleImageModel.fromJson(Map<String, dynamic> json) =>
      _$ArticleImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleImageModelToJson(this);
}
