import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/reflector.dart';

part 'user.g.dart';

@reflector
@JsonSerializable()
class UserListModel {
  final List<UserModel> items;
  final MetaModel meta;

  UserListModel({
    required this.items,
    required this.meta,
  });

  factory UserListModel.fromJson(Map<String, dynamic> json) =>
      _$UserListModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserListModelToJson(this);
}

@reflector
@JsonSerializable()
class UserModel {
  final int id;
  final String nickname;
  final String? profileImage;
  final String? countryCode;

  UserModel({
    required this.id,
    required this.nickname,
    required this.profileImage,
    required this.countryCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
