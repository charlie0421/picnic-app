import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/pic/article_image.dart';

part '../../generated/models/pic/library.freezed.dart';
part '../../generated/models/pic/library.g.dart';

@freezed
class LibraryModel with _$LibraryModel {
  const LibraryModel._();

  const factory LibraryModel({
    required int id,
    required String title,
    required List<ArticleImageModel>? images,
  }) = _LibraryModel;

  factory LibraryModel.fromJson(Map<String, dynamic> json) =>
      _$LibraryModelFromJson(json);
}
