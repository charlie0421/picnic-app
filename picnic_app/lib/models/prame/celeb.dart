import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/user.dart';
import 'package:picnic_app/reflector.dart';

part 'celeb.g.dart';

@reflector
@JsonSerializable()
class CelebListModel {
  final List<CelebModel> items;
  final MetaModel meta;

  CelebListModel({
    required this.items,
    required this.meta,
  });

  factory CelebListModel.fromJson(Map<String, dynamic> json) =>
      _$CelebListModelFromJson(json);

  Map<String, dynamic> toJson() => _$CelebListModelToJson(this);
}

@reflector
@JsonSerializable()
class CelebModel {
  final int id;
  final String nameKo;
  final String nameEn;
  final String thumbnail;
  final List<UserModel>? users;

  CelebModel({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.thumbnail,
    required this.users,
  });

  factory CelebModel.fromJson(Map<String, dynamic> json) =>
      _$CelebModelFromJson(json);

  Map<String, dynamic> toJson() => _$CelebModelToJson(this);
}
