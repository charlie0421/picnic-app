import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/pic/celeb.dart';
import 'package:picnic_app/util/i18n.dart';

part '../../generated/models/pic/gallery.freezed.dart';

part '../../generated/models/pic/gallery.g.dart';

@freezed
class GalleryModel with _$GalleryModel {
  const GalleryModel._();

  const factory GalleryModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'title_ko') required String titleKo,
    @JsonKey(name: 'title_en') required String titleEn,
    @JsonKey(name: 'cover') String? cover,
    @JsonKey(name: 'celeb') required CelebModel? celeb,
  }) = _GalleryModel;

  getTitle() {
    switch (getLocaleLanguage()) {
      case 'ko':
        return titleKo;
      case 'en':
        return titleEn;
      default:
        return titleEn;
    }
  }

  String getCdnUrl(String url) {
    return 'https://cdn-dev.picnic.fan/gallery/$id/$url';
  }

  factory GalleryModel.fromJson(Map<String, dynamic> json) =>
      _$GalleryModelFromJson(json);
}
