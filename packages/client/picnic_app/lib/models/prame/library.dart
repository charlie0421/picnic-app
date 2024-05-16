import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/prame/article_image.dart';
import 'package:picnic_app/reflector.dart';

part 'library.g.dart';

@reflector
@JsonSerializable()
class LibraryListModel {
  final List<LibraryModel> items;
  final MetaModel meta;

  LibraryListModel({
    required this.items,
    required this.meta,
  });

  factory LibraryListModel.fromJson(Map<String, dynamic> json) =>
      _$LibraryListModelFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryListModelToJson(this);
}

@reflector
@JsonSerializable()
class LibraryModel {
  final int id;
  final String title;
  final List<ArticleImageModel>? images;

  LibraryModel({
    required this.id,
    required this.title,
    required this.images,
  });

  factory LibraryModel.fromJson(Map<String, dynamic> json) =>
      _$LibraryModelFromJson(json);

  Map<String, dynamic> toJson() => _$LibraryModelToJson(this);
}
