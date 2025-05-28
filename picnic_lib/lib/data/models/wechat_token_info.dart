import 'package:freezed_annotation/freezed_annotation.dart';

part '../../generated/models/wechat_token_info.freezed.dart';
part '../../generated/models/wechat_token_info.g.dart';

@freezed
class WeChatTokenInfo with _$WeChatTokenInfo {
  const WeChatTokenInfo._();

  const factory WeChatTokenInfo({
    required String accessToken,
    required String refreshToken,
    required String openId,
    required String unionId,
    required String scope,
    required DateTime expiresAt,
    required DateTime createdAt,
    String? nickname,
    String? headImgUrl,
    String? country,
    String? province,
    String? city,
    String? language,
    int? sex,
  }) = _WeChatTokenInfo;

  factory WeChatTokenInfo.fromJson(Map<String, dynamic> json) =>
      _$WeChatTokenInfoFromJson(json);

  /// Check if the access token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if the token will expire within the given duration
  bool willExpireWithin(Duration duration) =>
      DateTime.now().add(duration).isAfter(expiresAt);

  /// Create a new instance with updated token information
  WeChatTokenInfo copyWithTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) =>
      copyWith(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

  /// Create from WeChat API response
  factory WeChatTokenInfo.fromWeChatResponse({
    required Map<String, dynamic> tokenResponse,
    required Map<String, dynamic>? userInfo,
  }) {
    final now = DateTime.now();
    final expiresIn = tokenResponse['expires_in'] as int? ?? 7200;

    return WeChatTokenInfo(
      accessToken: tokenResponse['access_token'] as String,
      refreshToken: tokenResponse['refresh_token'] as String,
      openId: tokenResponse['openid'] as String,
      unionId: tokenResponse['unionid'] as String? ?? '',
      scope: tokenResponse['scope'] as String? ?? 'snsapi_userinfo',
      expiresAt: now.add(Duration(seconds: expiresIn)),
      createdAt: now,
      nickname: userInfo?['nickname'] as String?,
      headImgUrl: userInfo?['headimgurl'] as String?,
      country: userInfo?['country'] as String?,
      province: userInfo?['province'] as String?,
      city: userInfo?['city'] as String?,
      language: userInfo?['language'] as String?,
      sex: userInfo?['sex'] as int?,
    );
  }
}
