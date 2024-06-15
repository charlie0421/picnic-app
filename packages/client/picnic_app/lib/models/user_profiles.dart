import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/reflector.dart';

part 'user_profiles.g.dart';

@reflector
@JsonSerializable()
class UserProfilesListModel {
  final List<UserProfilesModel> items;
  final MetaModel meta;

  UserProfilesListModel({
    required this.items,
    required this.meta,
  });

  factory UserProfilesListModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfilesListModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfilesListModelToJson(this);
}

@reflector
@JsonSerializable()
class UserProfilesModel {
  final String? id;
  final String? nickname;
  final String? avatar_url;
  final String? country_code;
  final int star_candy;

  UserProfilesModel(
      {this.id,
      this.nickname,
      this.country_code,
      required this.star_candy,
      this.avatar_url});

  copyWithStarCandy(int starCandy) {
    return UserProfilesModel(
        id: id,
        nickname: nickname,
        country_code: country_code,
        star_candy: starCandy,
        avatar_url: avatar_url);
  }

  factory UserProfilesModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfilesModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfilesModelToJson(this);
}
