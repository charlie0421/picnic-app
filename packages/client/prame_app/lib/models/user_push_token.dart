import 'package:json_annotation/json_annotation.dart';
import 'package:prame_app/reflector.dart';

part 'user_push_token.g.dart';

@reflector
@JsonSerializable()
class UserPushToken {
  final int id;
  final int user_id;
  final String token_ios;
  final String token_android;
  final String token_web;
  final String token_macos;
  final String token_windows;

  UserPushToken({
    required this.id,
    required this.user_id,
    required this.token_ios,
    required this.token_android,
    required this.token_web,
    required this.token_macos,
    required this.token_windows,
  });

  factory UserPushToken.fromJson(Map<String, dynamic> json) =>
      _$UserPushTokenFromJson(json);

  Map<String, dynamic> toJson() => _$UserPushTokenToJson(this);
}
