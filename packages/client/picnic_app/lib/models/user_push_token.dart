import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'user_push_token.freezed.dart';
part 'user_push_token.g.dart';

@reflector
@freezed
class UserPushToken with _$UserPushToken {
  const UserPushToken._();

  const factory UserPushToken({
    required int id,
    required int user_id,
    required String token_ios,
    required String token_android,
    required String token_web,
    required String token_macos,
    required String token_windows,
  }) = _UserPushToken;

  factory UserPushToken.fromJson(Map<String, dynamic> json) =>
      _$UserPushTokenFromJson(json);
}
