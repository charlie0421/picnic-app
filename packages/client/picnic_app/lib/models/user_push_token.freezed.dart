// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_push_token.dart';

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
  int get id => throw _privateConstructorUsedError;
  int get user_id => throw _privateConstructorUsedError;
  String get token_ios => throw _privateConstructorUsedError;
  String get token_android => throw _privateConstructorUsedError;
  String get token_web => throw _privateConstructorUsedError;
  String get token_macos => throw _privateConstructorUsedError;
  String get token_windows => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      {int id,
      int user_id,
      String token_ios,
      String token_android,
      String token_web,
      String token_macos,
      String token_windows});
}

/// @nodoc
class _$UserPushTokenCopyWithImpl<$Res, $Val extends UserPushToken>
    implements $UserPushTokenCopyWith<$Res> {
  _$UserPushTokenCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user_id = null,
    Object? token_ios = null,
    Object? token_android = null,
    Object? token_web = null,
    Object? token_macos = null,
    Object? token_windows = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      user_id: null == user_id
          ? _value.user_id
          : user_id // ignore: cast_nullable_to_non_nullable
              as int,
      token_ios: null == token_ios
          ? _value.token_ios
          : token_ios // ignore: cast_nullable_to_non_nullable
              as String,
      token_android: null == token_android
          ? _value.token_android
          : token_android // ignore: cast_nullable_to_non_nullable
              as String,
      token_web: null == token_web
          ? _value.token_web
          : token_web // ignore: cast_nullable_to_non_nullable
              as String,
      token_macos: null == token_macos
          ? _value.token_macos
          : token_macos // ignore: cast_nullable_to_non_nullable
              as String,
      token_windows: null == token_windows
          ? _value.token_windows
          : token_windows // ignore: cast_nullable_to_non_nullable
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
      {int id,
      int user_id,
      String token_ios,
      String token_android,
      String token_web,
      String token_macos,
      String token_windows});
}

/// @nodoc
class __$$UserPushTokenImplCopyWithImpl<$Res>
    extends _$UserPushTokenCopyWithImpl<$Res, _$UserPushTokenImpl>
    implements _$$UserPushTokenImplCopyWith<$Res> {
  __$$UserPushTokenImplCopyWithImpl(
      _$UserPushTokenImpl _value, $Res Function(_$UserPushTokenImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user_id = null,
    Object? token_ios = null,
    Object? token_android = null,
    Object? token_web = null,
    Object? token_macos = null,
    Object? token_windows = null,
  }) {
    return _then(_$UserPushTokenImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      user_id: null == user_id
          ? _value.user_id
          : user_id // ignore: cast_nullable_to_non_nullable
              as int,
      token_ios: null == token_ios
          ? _value.token_ios
          : token_ios // ignore: cast_nullable_to_non_nullable
              as String,
      token_android: null == token_android
          ? _value.token_android
          : token_android // ignore: cast_nullable_to_non_nullable
              as String,
      token_web: null == token_web
          ? _value.token_web
          : token_web // ignore: cast_nullable_to_non_nullable
              as String,
      token_macos: null == token_macos
          ? _value.token_macos
          : token_macos // ignore: cast_nullable_to_non_nullable
              as String,
      token_windows: null == token_windows
          ? _value.token_windows
          : token_windows // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserPushTokenImpl extends _UserPushToken {
  const _$UserPushTokenImpl(
      {required this.id,
      required this.user_id,
      required this.token_ios,
      required this.token_android,
      required this.token_web,
      required this.token_macos,
      required this.token_windows})
      : super._();

  factory _$UserPushTokenImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserPushTokenImplFromJson(json);

  @override
  final int id;
  @override
  final int user_id;
  @override
  final String token_ios;
  @override
  final String token_android;
  @override
  final String token_web;
  @override
  final String token_macos;
  @override
  final String token_windows;

  @override
  String toString() {
    return 'UserPushToken(id: $id, user_id: $user_id, token_ios: $token_ios, token_android: $token_android, token_web: $token_web, token_macos: $token_macos, token_windows: $token_windows)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserPushTokenImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.user_id, user_id) || other.user_id == user_id) &&
            (identical(other.token_ios, token_ios) ||
                other.token_ios == token_ios) &&
            (identical(other.token_android, token_android) ||
                other.token_android == token_android) &&
            (identical(other.token_web, token_web) ||
                other.token_web == token_web) &&
            (identical(other.token_macos, token_macos) ||
                other.token_macos == token_macos) &&
            (identical(other.token_windows, token_windows) ||
                other.token_windows == token_windows));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, user_id, token_ios,
      token_android, token_web, token_macos, token_windows);

  @JsonKey(ignore: true)
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
      {required final int id,
      required final int user_id,
      required final String token_ios,
      required final String token_android,
      required final String token_web,
      required final String token_macos,
      required final String token_windows}) = _$UserPushTokenImpl;
  const _UserPushToken._() : super._();

  factory _UserPushToken.fromJson(Map<String, dynamic> json) =
      _$UserPushTokenImpl.fromJson;

  @override
  int get id;
  @override
  int get user_id;
  @override
  String get token_ios;
  @override
  String get token_android;
  @override
  String get token_web;
  @override
  String get token_macos;
  @override
  String get token_windows;
  @override
  @JsonKey(ignore: true)
  _$$UserPushTokenImplCopyWith<_$UserPushTokenImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
