import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'social_login_result.freezed.dart';
part 'social_login_result.g.dart';

@freezed
@reflector
class SocialLoginResult with _$SocialLoginResult {
  const factory SocialLoginResult({
    String? idToken,
    String? accessToken,
    Map<String, dynamic>? userData,
  }) = _SocialLoginResult;

  factory SocialLoginResult.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginResultFromJson(json);
}
