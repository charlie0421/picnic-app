// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/user_push_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserPushToken _$UserPushTokenFromJson(Map<String, dynamic> json) {
  return _UserPushToken.fromJson(json);
}

/// @nodoc
mixin _$UserPushToken {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'token_ios')
  String get tokenIos => throw _privateConstructorUsedError;
  @JsonKey(name: 'token_android')
  String get tokenAndroid => throw _privateConstructorUsedError;
  @JsonKey(name: 'token_web')
  String get tokenWeb => throw _privateConstructorUsedError;
  @JsonKey(name: 'token_macos')
  String get tokenMacos => throw _privateConstructorUsedError;
  @JsonKey(name: 'token_windows')
  String get tokenWindows => throw _privateConstructorUsedError;

  /// Serializes this UserPushToken to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserPushToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserPushTokenCopyWith<UserPushToken> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserPushTokenCopyWith<$Res> {
  factory $UserPushTokenCopyWith(
          UserPushToken value, $Res Function(UserPushToken) then) =
      _$UserPushTokenCopyWithImpl<$Res, UserPushToken>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'user_id') int userId,
      @JsonKey(name: 'token_ios') String tokenIos,
      @JsonKey(name: 'token_android') String tokenAndroid,
      @JsonKey(name: 'token_web') String tokenWeb,
      @JsonKey(name: 'token_macos') String tokenMacos,
      @JsonKey(name: 'token_windows') String tokenWindows});
}

/// @nodoc
class _$UserPushTokenCopyWithImpl<$Res, $Val extends UserPushToken>
    implements $UserPushTokenCopyWith<$Res> {
  _$UserPushTokenCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserPushToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? tokenIos = null,
    Object? tokenAndroid = null,
    Object? tokenWeb = null,
    Object? tokenMacos = null,
    Object? tokenWindows = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      tokenIos: null == tokenIos
          ? _value.tokenIos
          : tokenIos // ignore: cast_nullable_to_non_nullable
              as String,
      tokenAndroid: null == tokenAndroid
          ? _value.tokenAndroid
          : tokenAndroid // ignore: cast_nullable_to_non_nullable
              as String,
      tokenWeb: null == tokenWeb
          ? _value.tokenWeb
          : tokenWeb // ignore: cast_nullable_to_non_nullable
              as String,
      tokenMacos: null == tokenMacos
          ? _value.tokenMacos
          : tokenMacos // ignore: cast_nullable_to_non_nullable
              as String,
      tokenWindows: null == tokenWindows
          ? _value.tokenWindows
          : tokenWindows // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserPushTokenImplCopyWith<$Res>
    implements $UserPushTokenCopyWith<$Res> {
  factory _$$UserPushTokenImplCopyWith(
          _$UserPushTokenImpl value, $Res Function(_$UserPushTokenImpl) then) =
      __$$UserPushTokenImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'user_id') int userId,
      @JsonKey(name: 'token_ios') String tokenIos,
      @JsonKey(name: 'token_android') String tokenAndroid,
      @JsonKey(name: 'token_web') String tokenWeb,
      @JsonKey(name: 'token_macos') String tokenMacos,
      @JsonKey(name: 'token_windows') String tokenWindows});
}

/// @nodoc
class __$$UserPushTokenImplCopyWithImpl<$Res>
    extends _$UserPushTokenCopyWithImpl<$Res, _$UserPushTokenImpl>
    implements _$$UserPushTokenImplCopyWith<$Res> {
  __$$UserPushTokenImplCopyWithImpl(
      _$UserPushTokenImpl _value, $Res Function(_$UserPushTokenImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserPushToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? tokenIos = null,
    Object? tokenAndroid = null,
    Object? tokenWeb = null,
    Object? tokenMacos = null,
    Object? tokenWindows = null,
  }) {
    return _then(_$UserPushTokenImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      tokenIos: null == tokenIos
          ? _value.tokenIos
          : tokenIos // ignore: cast_nullable_to_non_nullable
              as String,
      tokenAndroid: null == tokenAndroid
          ? _value.tokenAndroid
          : tokenAndroid // ignore: cast_nullable_to_non_nullable
              as String,
      tokenWeb: null == tokenWeb
          ? _value.tokenWeb
          : tokenWeb // ignore: cast_nullable_to_non_nullable
              as String,
      tokenMacos: null == tokenMacos
          ? _value.tokenMacos
          : tokenMacos // ignore: cast_nullable_to_non_nullable
              as String,
      tokenWindows: null == tokenWindows
          ? _value.tokenWindows
          : tokenWindows // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserPushTokenImpl extends _UserPushToken {
  const _$UserPushTokenImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'token_ios') required this.tokenIos,
      @JsonKey(name: 'token_android') required this.tokenAndroid,
      @JsonKey(name: 'token_web') required this.tokenWeb,
      @JsonKey(name: 'token_macos') required this.tokenMacos,
      @JsonKey(name: 'token_windows') required this.tokenWindows})
      : super._();

  factory _$UserPushTokenImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserPushTokenImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  @JsonKey(name: 'token_ios')
  final String tokenIos;
  @override
  @JsonKey(name: 'token_android')
  final String tokenAndroid;
  @override
  @JsonKey(name: 'token_web')
  final String tokenWeb;
  @override
  @JsonKey(name: 'token_macos')
  final String tokenMacos;
  @override
  @JsonKey(name: 'token_windows')
  final String tokenWindows;

  @override
  String toString() {
    return 'UserPushToken(id: $id, userId: $userId, tokenIos: $tokenIos, tokenAndroid: $tokenAndroid, tokenWeb: $tokenWeb, tokenMacos: $tokenMacos, tokenWindows: $tokenWindows)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserPushTokenImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.tokenIos, tokenIos) ||
                other.tokenIos == tokenIos) &&
            (identical(other.tokenAndroid, tokenAndroid) ||
                other.tokenAndroid == tokenAndroid) &&
            (identical(other.tokenWeb, tokenWeb) ||
                other.tokenWeb == tokenWeb) &&
            (identical(other.tokenMacos, tokenMacos) ||
                other.tokenMacos == tokenMacos) &&
            (identical(other.tokenWindows, tokenWindows) ||
                other.tokenWindows == tokenWindows));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, tokenIos,
      tokenAndroid, tokenWeb, tokenMacos, tokenWindows);

  /// Create a copy of UserPushToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserPushTokenImplCopyWith<_$UserPushTokenImpl> get copyWith =>
      __$$UserPushTokenImplCopyWithImpl<_$UserPushTokenImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserPushTokenImplToJson(
      this,
    );
  }
}

abstract class _UserPushToken extends UserPushToken {
  const factory _UserPushToken(
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'user_id') required final int userId,
          @JsonKey(name: 'token_ios') required final String tokenIos,
          @JsonKey(name: 'token_android') required final String tokenAndroid,
          @JsonKey(name: 'token_web') required final String tokenWeb,
          @JsonKey(name: 'token_macos') required final String tokenMacos,
          @JsonKey(name: 'token_windows') required final String tokenWindows}) =
      _$UserPushTokenImpl;
  const _UserPushToken._() : super._();

  factory _UserPushToken.fromJson(Map<String, dynamic> json) =
      _$UserPushTokenImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  @JsonKey(name: 'token_ios')
  String get tokenIos;
  @override
  @JsonKey(name: 'token_android')
  String get tokenAndroid;
  @override
  @JsonKey(name: 'token_web')
  String get tokenWeb;
  @override
  @JsonKey(name: 'token_macos')
  String get tokenMacos;
  @override
  @JsonKey(name: 'token_windows')
  String get tokenWindows;

  /// Create a copy of UserPushToken
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserPushTokenImplCopyWith<_$UserPushTokenImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
