import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/pic/article_image.dart';
import 'package:picnic_app/reflector.dart';

part 'library.freezed.dart';
part 'library.g.dart';

@reflector
@freezed
class LibraryListModel with _$LibraryListModel {
  const LibraryListModel._();

  const factory LibraryListModel({
    required List<LibraryModel> items,
    required MetaModel meta,
  }) = _LibraryListModel;

  factory LibraryListModel.fromJson(Map<String, dynamic> json) =>
      _$LibraryListModelFromJson(json);
}

@reflector
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
