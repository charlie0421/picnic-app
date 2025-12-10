import 'package:json_annotation/json_annotation.dart';

part '../../generated/models/user_push_token.g.dart';

@JsonSerializable()
class UserPushToken {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'token_ios')
  final String? tokenIos;

  @JsonKey(name: 'token_android')
  final String? tokenAndroid;

  @JsonKey(name: 'token_web')
  final String? tokenWeb;

  @JsonKey(name: 'token_macos')
  final String? tokenMacos;

  @JsonKey(name: 'token_windows')
  final String? tokenWindows;

  const UserPushToken({
    required this.id,
    required this.userId,
    this.tokenIos,
    this.tokenAndroid,
    this.tokenWeb,
    this.tokenMacos,
    this.tokenWindows,
  });

  factory UserPushToken.fromJson(Map<String, dynamic> json) =>
      _$UserPushTokenFromJson(json);

  Map<String, dynamic> toJson() => _$UserPushTokenToJson(this);

  UserPushToken copyWith({
    int? id,
    String? userId,
    String? tokenIos,
    String? tokenAndroid,
    String? tokenWeb,
    String? tokenMacos,
    String? tokenWindows,
  }) {
    return UserPushToken(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tokenIos: tokenIos ?? this.tokenIos,
      tokenAndroid: tokenAndroid ?? this.tokenAndroid,
      tokenWeb: tokenWeb ?? this.tokenWeb,
      tokenMacos: tokenMacos ?? this.tokenMacos,
      tokenWindows: tokenWindows ?? this.tokenWindows,
    );
  }
}
