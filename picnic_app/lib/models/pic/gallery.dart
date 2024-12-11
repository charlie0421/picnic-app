import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/models/pic/celeb.dart';
import 'package:picnic_app/util/i18n.dart';

part '../../generated/models/pic/gallery.freezed.dart';

part '../../generated/models/pic/gallery.g.dart';

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

  getTitle() {
    switch (getLocaleLanguage()) {
      case 'ko':
        return title_ko;
      case 'en':
        return title_en;
      default:
        return title_en;
    }
  }

  String getCdnUrl(String url) {
    return 'https://cdn-dev.picnic.fan/gallery/$id/$url';
  }

  factory GalleryModel.fromJson(Map<String, dynamic> json) =>
      _$GalleryModelFromJson(json);
}
