import 'package:freezed_annotation/freezed_annotation.dart';

part '../../generated/models/common/social_login_result.freezed.dart';

part '../../generated/models/common/social_login_result.g.dart';

@freezed
class SocialLoginResult with _$SocialLoginResult {
  const factory SocialLoginResult({
    String? idToken,
    String? accessToken,
    Map<String, dynamic>? userData,
  }) = _SocialLoginResult;

  factory SocialLoginResult.fromJson(Map<String, dynamic> json) =>
      _$SocialLoginResultFromJson(json);
}
