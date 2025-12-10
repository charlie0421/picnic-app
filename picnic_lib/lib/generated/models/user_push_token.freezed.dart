// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../data/models/user_push_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPushToken {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'token_ios') String? get tokenIos;@JsonKey(name: 'token_android') String? get tokenAndroid;@JsonKey(name: 'token_web') String? get tokenWeb;@JsonKey(name: 'token_macos') String? get tokenMacos;@JsonKey(name: 'token_windows') String? get tokenWindows;
/// Create a copy of UserPushToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPushTokenCopyWith<UserPushToken> get copyWith => _$UserPushTokenCopyWithImpl<UserPushToken>(this as UserPushToken, _$identity);

  /// Serializes this UserPushToken to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPushToken&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.tokenIos, tokenIos) || other.tokenIos == tokenIos)&&(identical(other.tokenAndroid, tokenAndroid) || other.tokenAndroid == tokenAndroid)&&(identical(other.tokenWeb, tokenWeb) || other.tokenWeb == tokenWeb)&&(identical(other.tokenMacos, tokenMacos) || other.tokenMacos == tokenMacos)&&(identical(other.tokenWindows, tokenWindows) || other.tokenWindows == tokenWindows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,tokenIos,tokenAndroid,tokenWeb,tokenMacos,tokenWindows);

@override
String toString() {
  return 'UserPushToken(id: $id, userId: $userId, tokenIos: $tokenIos, tokenAndroid: $tokenAndroid, tokenWeb: $tokenWeb, tokenMacos: $tokenMacos, tokenWindows: $tokenWindows)';
}


}

/// @nodoc
abstract mixin class $UserPushTokenCopyWith<$Res>  {
  factory $UserPushTokenCopyWith(UserPushToken value, $Res Function(UserPushToken) _then) = _$UserPushTokenCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'token_ios') String? tokenIos,@JsonKey(name: 'token_android') String? tokenAndroid,@JsonKey(name: 'token_web') String? tokenWeb,@JsonKey(name: 'token_macos') String? tokenMacos,@JsonKey(name: 'token_windows') String? tokenWindows
});




}
/// @nodoc
class _$UserPushTokenCopyWithImpl<$Res>
    implements $UserPushTokenCopyWith<$Res> {
  _$UserPushTokenCopyWithImpl(this._self, this._then);

  final UserPushToken _self;
  final $Res Function(UserPushToken) _then;

/// Create a copy of UserPushToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? tokenIos = freezed,Object? tokenAndroid = freezed,Object? tokenWeb = freezed,Object? tokenMacos = freezed,Object? tokenWindows = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,tokenIos: freezed == tokenIos ? _self.tokenIos : tokenIos // ignore: cast_nullable_to_non_nullable
as String?,tokenAndroid: freezed == tokenAndroid ? _self.tokenAndroid : tokenAndroid // ignore: cast_nullable_to_non_nullable
as String?,tokenWeb: freezed == tokenWeb ? _self.tokenWeb : tokenWeb // ignore: cast_nullable_to_non_nullable
as String?,tokenMacos: freezed == tokenMacos ? _self.tokenMacos : tokenMacos // ignore: cast_nullable_to_non_nullable
as String?,tokenWindows: freezed == tokenWindows ? _self.tokenWindows : tokenWindows // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPushToken].
extension UserPushTokenPatterns on UserPushToken {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPushToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPushToken() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPushToken value)  $default,){
final _that = this;
switch (_that) {
case _UserPushToken():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPushToken value)?  $default,){
final _that = this;
switch (_that) {
case _UserPushToken() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'token_ios')  String? tokenIos, @JsonKey(name: 'token_android')  String? tokenAndroid, @JsonKey(name: 'token_web')  String? tokenWeb, @JsonKey(name: 'token_macos')  String? tokenMacos, @JsonKey(name: 'token_windows')  String? tokenWindows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPushToken() when $default != null:
return $default(_that.id,_that.userId,_that.tokenIos,_that.tokenAndroid,_that.tokenWeb,_that.tokenMacos,_that.tokenWindows);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'token_ios')  String? tokenIos, @JsonKey(name: 'token_android')  String? tokenAndroid, @JsonKey(name: 'token_web')  String? tokenWeb, @JsonKey(name: 'token_macos')  String? tokenMacos, @JsonKey(name: 'token_windows')  String? tokenWindows)  $default,) {final _that = this;
switch (_that) {
case _UserPushToken():
return $default(_that.id,_that.userId,_that.tokenIos,_that.tokenAndroid,_that.tokenWeb,_that.tokenMacos,_that.tokenWindows);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'token_ios')  String? tokenIos, @JsonKey(name: 'token_android')  String? tokenAndroid, @JsonKey(name: 'token_web')  String? tokenWeb, @JsonKey(name: 'token_macos')  String? tokenMacos, @JsonKey(name: 'token_windows')  String? tokenWindows)?  $default,) {final _that = this;
switch (_that) {
case _UserPushToken() when $default != null:
return $default(_that.id,_that.userId,_that.tokenIos,_that.tokenAndroid,_that.tokenWeb,_that.tokenMacos,_that.tokenWindows);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPushToken extends UserPushToken {
  const _UserPushToken({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'token_ios') this.tokenIos, @JsonKey(name: 'token_android') this.tokenAndroid, @JsonKey(name: 'token_web') this.tokenWeb, @JsonKey(name: 'token_macos') this.tokenMacos, @JsonKey(name: 'token_windows') this.tokenWindows}): super._();
  factory _UserPushToken.fromJson(Map<String, dynamic> json) => _$UserPushTokenFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'token_ios') final  String? tokenIos;
@override@JsonKey(name: 'token_android') final  String? tokenAndroid;
@override@JsonKey(name: 'token_web') final  String? tokenWeb;
@override@JsonKey(name: 'token_macos') final  String? tokenMacos;
@override@JsonKey(name: 'token_windows') final  String? tokenWindows;

/// Create a copy of UserPushToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPushTokenCopyWith<_UserPushToken> get copyWith => __$UserPushTokenCopyWithImpl<_UserPushToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPushTokenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPushToken&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.tokenIos, tokenIos) || other.tokenIos == tokenIos)&&(identical(other.tokenAndroid, tokenAndroid) || other.tokenAndroid == tokenAndroid)&&(identical(other.tokenWeb, tokenWeb) || other.tokenWeb == tokenWeb)&&(identical(other.tokenMacos, tokenMacos) || other.tokenMacos == tokenMacos)&&(identical(other.tokenWindows, tokenWindows) || other.tokenWindows == tokenWindows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,tokenIos,tokenAndroid,tokenWeb,tokenMacos,tokenWindows);

@override
String toString() {
  return 'UserPushToken(id: $id, userId: $userId, tokenIos: $tokenIos, tokenAndroid: $tokenAndroid, tokenWeb: $tokenWeb, tokenMacos: $tokenMacos, tokenWindows: $tokenWindows)';
}


}

/// @nodoc
abstract mixin class _$UserPushTokenCopyWith<$Res> implements $UserPushTokenCopyWith<$Res> {
  factory _$UserPushTokenCopyWith(_UserPushToken value, $Res Function(_UserPushToken) _then) = __$UserPushTokenCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'token_ios') String? tokenIos,@JsonKey(name: 'token_android') String? tokenAndroid,@JsonKey(name: 'token_web') String? tokenWeb,@JsonKey(name: 'token_macos') String? tokenMacos,@JsonKey(name: 'token_windows') String? tokenWindows
});




}
/// @nodoc
class __$UserPushTokenCopyWithImpl<$Res>
    implements _$UserPushTokenCopyWith<$Res> {
  __$UserPushTokenCopyWithImpl(this._self, this._then);

  final _UserPushToken _self;
  final $Res Function(_UserPushToken) _then;

/// Create a copy of UserPushToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? tokenIos = freezed,Object? tokenAndroid = freezed,Object? tokenWeb = freezed,Object? tokenMacos = freezed,Object? tokenWindows = freezed,}) {
  return _then(_UserPushToken(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,tokenIos: freezed == tokenIos ? _self.tokenIos : tokenIos // ignore: cast_nullable_to_non_nullable
as String?,tokenAndroid: freezed == tokenAndroid ? _self.tokenAndroid : tokenAndroid // ignore: cast_nullable_to_non_nullable
as String?,tokenWeb: freezed == tokenWeb ? _self.tokenWeb : tokenWeb // ignore: cast_nullable_to_non_nullable
as String?,tokenMacos: freezed == tokenMacos ? _self.tokenMacos : tokenMacos // ignore: cast_nullable_to_non_nullable
as String?,tokenWindows: freezed == tokenWindows ? _self.tokenWindows : tokenWindows // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
