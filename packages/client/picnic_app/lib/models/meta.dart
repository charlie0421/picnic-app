import 'package:freezed_annotation/freezed_annotation.dart';

part 'meta.freezed.dart';
part 'meta.g.dart';

@freezed
class MetaModel with _$MetaModel {
  const MetaModel._();

  const factory MetaModel({
    required int currentPage,
    required int itemCount,
    required int itemsPerPage,
    required int totalItems,
    required int totalPages,
  }) = _MetaModel;

  factory MetaModel.fromJson(Map<String, dynamic> json) =>
      _$MetaModelFromJson(json);
}
