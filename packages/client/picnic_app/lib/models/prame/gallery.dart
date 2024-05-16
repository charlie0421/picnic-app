import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/prame/celeb.dart';
import 'package:picnic_app/reflector.dart';

part 'gallery.g.dart';

@reflector
@JsonSerializable()
class GalleryListModel {
  final List<GalleryModel> items;
  final MetaModel meta;

  GalleryListModel({
    required this.items,
    required this.meta,
  });

  factory GalleryListModel.fromJson(Map<String, dynamic> json) =>
      _$GalleryListModelFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryListModelToJson(this);
}

@reflector
@JsonSerializable()
class GalleryModel {
  final int id;
  final String titleKo;
  final String titleEn;
  final String cover;
  final CelebModel? celeb;

  GalleryModel({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.cover,
    required this.celeb,
  });

  factory GalleryModel.fromJson(Map<String, dynamic> json) =>
      _$GalleryModelFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryModelToJson(this);
}
