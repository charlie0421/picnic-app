// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_login_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SocialLoginResult _$SocialLoginResultFromJson(Map<String, dynamic> json) {
  return _SocialLoginResult.fromJson(json);
}

/// @nodoc
mixin _$SocialLoginResult {
  String? get idToken => throw _privateConstructorUsedError;
  String? get accessToken => throw _privateConstructorUsedError;
  Map<String, dynamic>? get userData => throw _privateConstructorUsedError;

  /// Serializes this SocialLoginResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SocialLoginResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SocialLoginResultCopyWith<SocialLoginResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SocialLoginResultCopyWith<$Res> {
  factory $SocialLoginResultCopyWith(
          SocialLoginResult value, $Res Function(SocialLoginResult) then) =
      _$SocialLoginResultCopyWithImpl<$Res, SocialLoginResult>;
  @useResult
  $Res call(
      {String? idToken, String? accessToken, Map<String, dynamic>? userData});
}

/// @nodoc
class _$SocialLoginResultCopyWithImpl<$Res, $Val extends SocialLoginResult>
    implements $SocialLoginResultCopyWith<$Res> {
  _$SocialLoginResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SocialLoginResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idToken = freezed,
    Object? accessToken = freezed,
    Object? userData = freezed,
  }) {
    return _then(_value.copyWith(
      idToken: freezed == idToken
          ? _value.idToken
          : idToken // ignore: cast_nullable_to_non_nullable
              as String?,
      accessToken: freezed == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String?,
      userData: freezed == userData
          ? _value.userData
          : userData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SocialLoginResultImplCopyWith<$Res>
    implements $SocialLoginResultCopyWith<$Res> {
  factory _$$SocialLoginResultImplCopyWith(_$SocialLoginResultImpl value,
          $Res Function(_$SocialLoginResultImpl) then) =
      __$$SocialLoginResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? idToken, String? accessToken, Map<String, dynamic>? userData});
}

/// @nodoc
class __$$SocialLoginResultImplCopyWithImpl<$Res>
    extends _$SocialLoginResultCopyWithImpl<$Res, _$SocialLoginResultImpl>
    implements _$$SocialLoginResultImplCopyWith<$Res> {
  __$$SocialLoginResultImplCopyWithImpl(_$SocialLoginResultImpl _value,
      $Res Function(_$SocialLoginResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of SocialLoginResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idToken = freezed,
    Object? accessToken = freezed,
    Object? userData = freezed,
  }) {
    return _then(_$SocialLoginResultImpl(
      idToken: freezed == idToken
          ? _value.idToken
          : idToken // ignore: cast_nullable_to_non_nullable
              as String?,
      accessToken: freezed == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String?,
      userData: freezed == userData
          ? _value._userData
          : userData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SocialLoginResultImpl implements _SocialLoginResult {
  const _$SocialLoginResultImpl(
      {this.idToken, this.accessToken, final Map<String, dynamic>? userData})
      : _userData = userData;

  factory _$SocialLoginResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SocialLoginResultImplFromJson(json);

  @override
  final String? idToken;
  @override
  final String? accessToken;
  final Map<String, dynamic>? _userData;
  @override
  Map<String, dynamic>? get userData {
    final value = _userData;
    if (value == null) return null;
    if (_userData is EqualUnmodifiableMapView) return _userData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'SocialLoginResult(idToken: $idToken, accessToken: $accessToken, userData: $userData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SocialLoginResultImpl &&
            (identical(other.idToken, idToken) || other.idToken == idToken) &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            const DeepCollectionEquality().equals(other._userData, _userData));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, idToken, accessToken,
      const DeepCollectionEquality().hash(_userData));

  /// Create a copy of SocialLoginResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SocialLoginResultImplCopyWith<_$SocialLoginResultImpl> get copyWith =>
      __$$SocialLoginResultImplCopyWithImpl<_$SocialLoginResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SocialLoginResultImplToJson(
      this,
    );
  }
}

abstract class _SocialLoginResult implements SocialLoginResult {
  const factory _SocialLoginResult(
      {final String? idToken,
      final String? accessToken,
      final Map<String, dynamic>? userData}) = _$SocialLoginResultImpl;

  factory _SocialLoginResult.fromJson(Map<String, dynamic> json) =
      _$SocialLoginResultImpl.fromJson;

  @override
  String? get idToken;
  @override
  String? get accessToken;
  @override
  Map<String, dynamic>? get userData;

  /// Create a copy of SocialLoginResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SocialLoginResultImplCopyWith<_$SocialLoginResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
