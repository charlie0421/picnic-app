import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/pic/celeb.dart';
import 'package:picnic_app/reflector.dart';

part 'gallery.freezed.dart';
part 'gallery.g.dart';

@reflector
@freezed
class GalleryListModel with _$GalleryListModel {
  const GalleryListModel._();

  const factory GalleryListModel({
    required List<GalleryModel> items,
    required MetaModel meta,
  }) = _GalleryListModel;

  factory GalleryListModel.fromJson(Map<String, dynamic> json) =>
      _$GalleryListModelFromJson(json);
}

@reflector
@freezed
class GalleryModel with _$GalleryModel {
  const GalleryModel._();

  const factory GalleryModel({
    required int id,
    required String title_ko,
    required String title_en,
    String? cover,
    required CelebModel? celeb,
  }) = _GalleryModel;

  factory GalleryModel.fromJson(Map<String, dynamic> json) =>
      _$GalleryModelFromJson(json);
}
