import 'package:freezed_annotation/freezed_annotation.dart';

part '../generated/models/user_push_token.freezed.dart';
part '../generated/models/user_push_token.g.dart';

@freezed
class UserPushToken with _$UserPushToken {
  const UserPushToken._();

  const factory UserPushToken({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'token_ios') required String tokenIos,
    @JsonKey(name: 'token_android') required String tokenAndroid,
    @JsonKey(name: 'token_web') required String tokenWeb,
    @JsonKey(name: 'token_macos') required String tokenMacos,
    @JsonKey(name: 'token_windows') required String tokenWindows,
  }) = _UserPushToken;

  factory UserPushToken.fromJson(Map<String, dynamic> json) =>
      _$UserPushTokenFromJson(json);
}
