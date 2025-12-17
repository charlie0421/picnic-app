// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/common/social_login_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SocialLoginResult {

 String? get idToken; String? get accessToken; Map<String, dynamic>? get userData;
/// Create a copy of SocialLoginResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialLoginResultCopyWith<SocialLoginResult> get copyWith => _$SocialLoginResultCopyWithImpl<SocialLoginResult>(this as SocialLoginResult, _$identity);

  /// Serializes this SocialLoginResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialLoginResult&&(identical(other.idToken, idToken) || other.idToken == idToken)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&const DeepCollectionEquality().equals(other.userData, userData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idToken,accessToken,const DeepCollectionEquality().hash(userData));

@override
String toString() {
  return 'SocialLoginResult(idToken: $idToken, accessToken: $accessToken, userData: $userData)';
}


}

/// @nodoc
abstract mixin class $SocialLoginResultCopyWith<$Res>  {
  factory $SocialLoginResultCopyWith(SocialLoginResult value, $Res Function(SocialLoginResult) _then) = _$SocialLoginResultCopyWithImpl;
@useResult
$Res call({
 String? idToken, String? accessToken, Map<String, dynamic>? userData
});




}
/// @nodoc
class _$SocialLoginResultCopyWithImpl<$Res>
    implements $SocialLoginResultCopyWith<$Res> {
  _$SocialLoginResultCopyWithImpl(this._self, this._then);

  final SocialLoginResult _self;
  final $Res Function(SocialLoginResult) _then;

/// Create a copy of SocialLoginResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idToken = freezed,Object? accessToken = freezed,Object? userData = freezed,}) {
  return _then(_self.copyWith(
idToken: freezed == idToken ? _self.idToken : idToken // ignore: cast_nullable_to_non_nullable
as String?,accessToken: freezed == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String?,userData: freezed == userData ? _self.userData : userData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [SocialLoginResult].
extension SocialLoginResultPatterns on SocialLoginResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocialLoginResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocialLoginResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocialLoginResult value)  $default,){
final _that = this;
switch (_that) {
case _SocialLoginResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocialLoginResult value)?  $default,){
final _that = this;
switch (_that) {
case _SocialLoginResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? idToken,  String? accessToken,  Map<String, dynamic>? userData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocialLoginResult() when $default != null:
return $default(_that.idToken,_that.accessToken,_that.userData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? idToken,  String? accessToken,  Map<String, dynamic>? userData)  $default,) {final _that = this;
switch (_that) {
case _SocialLoginResult():
return $default(_that.idToken,_that.accessToken,_that.userData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? idToken,  String? accessToken,  Map<String, dynamic>? userData)?  $default,) {final _that = this;
switch (_that) {
case _SocialLoginResult() when $default != null:
return $default(_that.idToken,_that.accessToken,_that.userData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SocialLoginResult implements SocialLoginResult {
  const _SocialLoginResult({this.idToken, this.accessToken, final  Map<String, dynamic>? userData}): _userData = userData;
  factory _SocialLoginResult.fromJson(Map<String, dynamic> json) => _$SocialLoginResultFromJson(json);

@override final  String? idToken;
@override final  String? accessToken;
 final  Map<String, dynamic>? _userData;
@override Map<String, dynamic>? get userData {
  final value = _userData;
  if (value == null) return null;
  if (_userData is EqualUnmodifiableMapView) return _userData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SocialLoginResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocialLoginResultCopyWith<_SocialLoginResult> get copyWith => __$SocialLoginResultCopyWithImpl<_SocialLoginResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocialLoginResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocialLoginResult&&(identical(other.idToken, idToken) || other.idToken == idToken)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&const DeepCollectionEquality().equals(other._userData, _userData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,idToken,accessToken,const DeepCollectionEquality().hash(_userData));

@override
String toString() {
  return 'SocialLoginResult(idToken: $idToken, accessToken: $accessToken, userData: $userData)';
}


}

/// @nodoc
abstract mixin class _$SocialLoginResultCopyWith<$Res> implements $SocialLoginResultCopyWith<$Res> {
  factory _$SocialLoginResultCopyWith(_SocialLoginResult value, $Res Function(_SocialLoginResult) _then) = __$SocialLoginResultCopyWithImpl;
@override @useResult
$Res call({
 String? idToken, String? accessToken, Map<String, dynamic>? userData
});




}
/// @nodoc
class __$SocialLoginResultCopyWithImpl<$Res>
    implements _$SocialLoginResultCopyWith<$Res> {
  __$SocialLoginResultCopyWithImpl(this._self, this._then);

  final _SocialLoginResult _self;
  final $Res Function(_SocialLoginResult) _then;

/// Create a copy of SocialLoginResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idToken = freezed,Object? accessToken = freezed,Object? userData = freezed,}) {
  return _then(_SocialLoginResult(
idToken: freezed == idToken ? _self.idToken : idToken // ignore: cast_nullable_to_non_nullable
as String?,accessToken: freezed == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String?,userData: freezed == userData ? _self._userData : userData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
