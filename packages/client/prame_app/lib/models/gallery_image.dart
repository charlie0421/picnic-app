import 'package:json_annotation/json_annotation.dart';
import 'package:prame_app/models/meta.dart';
import 'package:prame_app/reflector.dart';

part 'gallery_image.g.dart';

@reflector
@JsonSerializable()
class GalleryImageListModel {
  final List<GalleryImageModel> items;
  final MetaModel meta;

  GalleryImageListModel({
    required this.items,
    required this.meta,
  });

  factory GalleryImageListModel.fromJson(Map<String, dynamic> json) =>
      _$GalleryImageListModelFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryImageListModelToJson(this);
}

@reflector
@JsonSerializable()
class GalleryImageModel {
  final int id;
  final String titleKo;
  final String titleEn;
  final String thumbnail;

  GalleryImageModel({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.thumbnail,
  });

  factory GalleryImageModel.fromJson(Map<String, dynamic> json) =>
      _$GalleryImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryImageModelToJson(this);
}
