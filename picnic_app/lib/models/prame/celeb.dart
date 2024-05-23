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
  final String name_ko;
  final String name_en;
  String? thumbnail;
  final List<UserModel>? users;

  CelebModel({
    required this.id,
    required this.name_ko,
    required this.name_en,
    this.thumbnail,
    this.users,
  });

  factory CelebModel.fromJson(Map<String, dynamic> json) =>
      _$CelebModelFromJson(json);

  Map<String, dynamic> toJson() => _$CelebModelToJson(this);
}
