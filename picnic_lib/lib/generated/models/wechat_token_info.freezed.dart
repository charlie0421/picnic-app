// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../data/models/wechat_token_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WeChatTokenInfo _$WeChatTokenInfoFromJson(Map<String, dynamic> json) {
  return _WeChatTokenInfo.fromJson(json);
}

/// @nodoc
mixin _$WeChatTokenInfo {
  String get accessToken => throw _privateConstructorUsedError;
  String get refreshToken => throw _privateConstructorUsedError;
  String get openId => throw _privateConstructorUsedError;
  String get unionId => throw _privateConstructorUsedError;
  String get scope => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get nickname => throw _privateConstructorUsedError;
  String? get headImgUrl => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get province => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;
  String? get language => throw _privateConstructorUsedError;
  int? get sex => throw _privateConstructorUsedError;

  /// Serializes this WeChatTokenInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WeChatTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WeChatTokenInfoCopyWith<WeChatTokenInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeChatTokenInfoCopyWith<$Res> {
  factory $WeChatTokenInfoCopyWith(
          WeChatTokenInfo value, $Res Function(WeChatTokenInfo) then) =
      _$WeChatTokenInfoCopyWithImpl<$Res, WeChatTokenInfo>;
  @useResult
  $Res call(
      {String accessToken,
      String refreshToken,
      String openId,
      String unionId,
      String scope,
      DateTime expiresAt,
      DateTime createdAt,
      String? nickname,
      String? headImgUrl,
      String? country,
      String? province,
      String? city,
      String? language,
      int? sex});
}

/// @nodoc
class _$WeChatTokenInfoCopyWithImpl<$Res, $Val extends WeChatTokenInfo>
    implements $WeChatTokenInfoCopyWith<$Res> {
  _$WeChatTokenInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WeChatTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? openId = null,
    Object? unionId = null,
    Object? scope = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? nickname = freezed,
    Object? headImgUrl = freezed,
    Object? country = freezed,
    Object? province = freezed,
    Object? city = freezed,
    Object? language = freezed,
    Object? sex = freezed,
  }) {
    return _then(_value.copyWith(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
      openId: null == openId
          ? _value.openId
          : openId // ignore: cast_nullable_to_non_nullable
              as String,
      unionId: null == unionId
          ? _value.unionId
          : unionId // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      headImgUrl: freezed == headImgUrl
          ? _value.headImgUrl
          : headImgUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      province: freezed == province
          ? _value.province
          : province // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      language: freezed == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      sex: freezed == sex
          ? _value.sex
          : sex // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WeChatTokenInfoImplCopyWith<$Res>
    implements $WeChatTokenInfoCopyWith<$Res> {
  factory _$$WeChatTokenInfoImplCopyWith(_$WeChatTokenInfoImpl value,
          $Res Function(_$WeChatTokenInfoImpl) then) =
      __$$WeChatTokenInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String accessToken,
      String refreshToken,
      String openId,
      String unionId,
      String scope,
      DateTime expiresAt,
      DateTime createdAt,
      String? nickname,
      String? headImgUrl,
      String? country,
      String? province,
      String? city,
      String? language,
      int? sex});
}

/// @nodoc
class __$$WeChatTokenInfoImplCopyWithImpl<$Res>
    extends _$WeChatTokenInfoCopyWithImpl<$Res, _$WeChatTokenInfoImpl>
    implements _$$WeChatTokenInfoImplCopyWith<$Res> {
  __$$WeChatTokenInfoImplCopyWithImpl(
      _$WeChatTokenInfoImpl _value, $Res Function(_$WeChatTokenInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of WeChatTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? openId = null,
    Object? unionId = null,
    Object? scope = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? nickname = freezed,
    Object? headImgUrl = freezed,
    Object? country = freezed,
    Object? province = freezed,
    Object? city = freezed,
    Object? language = freezed,
    Object? sex = freezed,
  }) {
    return _then(_$WeChatTokenInfoImpl(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
      openId: null == openId
          ? _value.openId
          : openId // ignore: cast_nullable_to_non_nullable
              as String,
      unionId: null == unionId
          ? _value.unionId
          : unionId // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      headImgUrl: freezed == headImgUrl
          ? _value.headImgUrl
          : headImgUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      province: freezed == province
          ? _value.province
          : province // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      language: freezed == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String?,
      sex: freezed == sex
          ? _value.sex
          : sex // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WeChatTokenInfoImpl extends _WeChatTokenInfo {
  const _$WeChatTokenInfoImpl(
      {required this.accessToken,
      required this.refreshToken,
      required this.openId,
      required this.unionId,
      required this.scope,
      required this.expiresAt,
      required this.createdAt,
      this.nickname,
      this.headImgUrl,
      this.country,
      this.province,
      this.city,
      this.language,
      this.sex})
      : super._();

  factory _$WeChatTokenInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeChatTokenInfoImplFromJson(json);

  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final String openId;
  @override
  final String unionId;
  @override
  final String scope;
  @override
  final DateTime expiresAt;
  @override
  final DateTime createdAt;
  @override
  final String? nickname;
  @override
  final String? headImgUrl;
  @override
  final String? country;
  @override
  final String? province;
  @override
  final String? city;
  @override
  final String? language;
  @override
  final int? sex;

  @override
  String toString() {
    return 'WeChatTokenInfo(accessToken: $accessToken, refreshToken: $refreshToken, openId: $openId, unionId: $unionId, scope: $scope, expiresAt: $expiresAt, createdAt: $createdAt, nickname: $nickname, headImgUrl: $headImgUrl, country: $country, province: $province, city: $city, language: $language, sex: $sex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeChatTokenInfoImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.openId, openId) || other.openId == openId) &&
            (identical(other.unionId, unionId) || other.unionId == unionId) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.headImgUrl, headImgUrl) ||
                other.headImgUrl == headImgUrl) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.province, province) ||
                other.province == province) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.sex, sex) || other.sex == sex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      accessToken,
      refreshToken,
      openId,
      unionId,
      scope,
      expiresAt,
      createdAt,
      nickname,
      headImgUrl,
      country,
      province,
      city,
      language,
      sex);

  /// Create a copy of WeChatTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeChatTokenInfoImplCopyWith<_$WeChatTokenInfoImpl> get copyWith =>
      __$$WeChatTokenInfoImplCopyWithImpl<_$WeChatTokenInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeChatTokenInfoImplToJson(
      this,
    );
  }
}

abstract class _WeChatTokenInfo extends WeChatTokenInfo {
  const factory _WeChatTokenInfo(
      {required final String accessToken,
      required final String refreshToken,
      required final String openId,
      required final String unionId,
      required final String scope,
      required final DateTime expiresAt,
      required final DateTime createdAt,
      final String? nickname,
      final String? headImgUrl,
      final String? country,
      final String? province,
      final String? city,
      final String? language,
      final int? sex}) = _$WeChatTokenInfoImpl;
  const _WeChatTokenInfo._() : super._();

  factory _WeChatTokenInfo.fromJson(Map<String, dynamic> json) =
      _$WeChatTokenInfoImpl.fromJson;

  @override
  String get accessToken;
  @override
  String get refreshToken;
  @override
  String get openId;
  @override
  String get unionId;
  @override
  String get scope;
  @override
  DateTime get expiresAt;
  @override
  DateTime get createdAt;
  @override
  String? get nickname;
  @override
  String? get headImgUrl;
  @override
  String? get country;
  @override
  String? get province;
  @override
  String? get city;
  @override
  String? get language;
  @override
  int? get sex;

  /// Create a copy of WeChatTokenInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeChatTokenInfoImplCopyWith<_$WeChatTokenInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
