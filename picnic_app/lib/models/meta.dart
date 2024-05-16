import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'meta.g.dart';

@reflector
@JsonSerializable()
class MetaModel {
  final int currentPage;
  final int itemCount;
  final int itemsPerPage;
  final int totalItems;
  final int totalPages;

  MetaModel({
    required this.currentPage,
    required this.itemCount,
    required this.itemsPerPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory MetaModel.fromJson(Map<String, dynamic> json) =>
      _$MetaModelFromJson(json);

  Map<String, dynamic> toJson() => _$MetaModelToJson(this);
}
