// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/ad_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdInfo {

 RewardedAd? get ad; bool get isShowing; bool get isLoading;
/// Create a copy of AdInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdInfoCopyWith<AdInfo> get copyWith => _$AdInfoCopyWithImpl<AdInfo>(this as AdInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdInfo&&(identical(other.ad, ad) || other.ad == ad)&&(identical(other.isShowing, isShowing) || other.isShowing == isShowing)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,ad,isShowing,isLoading);

@override
String toString() {
  return 'AdInfo(ad: $ad, isShowing: $isShowing, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $AdInfoCopyWith<$Res>  {
  factory $AdInfoCopyWith(AdInfo value, $Res Function(AdInfo) _then) = _$AdInfoCopyWithImpl;
@useResult
$Res call({
 RewardedAd? ad, bool isShowing, bool isLoading
});




}
/// @nodoc
class _$AdInfoCopyWithImpl<$Res>
    implements $AdInfoCopyWith<$Res> {
  _$AdInfoCopyWithImpl(this._self, this._then);

  final AdInfo _self;
  final $Res Function(AdInfo) _then;

/// Create a copy of AdInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ad = freezed,Object? isShowing = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
ad: freezed == ad ? _self.ad : ad // ignore: cast_nullable_to_non_nullable
as RewardedAd?,isShowing: null == isShowing ? _self.isShowing : isShowing // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AdInfo].
extension AdInfoPatterns on AdInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdInfo value)  $default,){
final _that = this;
switch (_that) {
case _AdInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AdInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RewardedAd? ad,  bool isShowing,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdInfo() when $default != null:
return $default(_that.ad,_that.isShowing,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RewardedAd? ad,  bool isShowing,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _AdInfo():
return $default(_that.ad,_that.isShowing,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RewardedAd? ad,  bool isShowing,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _AdInfo() when $default != null:
return $default(_that.ad,_that.isShowing,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _AdInfo implements AdInfo {
  const _AdInfo({this.ad, this.isShowing = false, this.isLoading = false});
  

@override final  RewardedAd? ad;
@override@JsonKey() final  bool isShowing;
@override@JsonKey() final  bool isLoading;

/// Create a copy of AdInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdInfoCopyWith<_AdInfo> get copyWith => __$AdInfoCopyWithImpl<_AdInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdInfo&&(identical(other.ad, ad) || other.ad == ad)&&(identical(other.isShowing, isShowing) || other.isShowing == isShowing)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,ad,isShowing,isLoading);

@override
String toString() {
  return 'AdInfo(ad: $ad, isShowing: $isShowing, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$AdInfoCopyWith<$Res> implements $AdInfoCopyWith<$Res> {
  factory _$AdInfoCopyWith(_AdInfo value, $Res Function(_AdInfo) _then) = __$AdInfoCopyWithImpl;
@override @useResult
$Res call({
 RewardedAd? ad, bool isShowing, bool isLoading
});




}
/// @nodoc
class __$AdInfoCopyWithImpl<$Res>
    implements _$AdInfoCopyWith<$Res> {
  __$AdInfoCopyWithImpl(this._self, this._then);

  final _AdInfo _self;
  final $Res Function(_AdInfo) _then;

/// Create a copy of AdInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ad = freezed,Object? isShowing = null,Object? isLoading = null,}) {
  return _then(_AdInfo(
ad: freezed == ad ? _self.ad : ad // ignore: cast_nullable_to_non_nullable
as RewardedAd?,isShowing: null == isShowing ? _self.isShowing : isShowing // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$AdState {

 List<AdInfo> get ads;
/// Create a copy of AdState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdStateCopyWith<AdState> get copyWith => _$AdStateCopyWithImpl<AdState>(this as AdState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdState&&const DeepCollectionEquality().equals(other.ads, ads));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(ads));

@override
String toString() {
  return 'AdState(ads: $ads)';
}


}

/// @nodoc
abstract mixin class $AdStateCopyWith<$Res>  {
  factory $AdStateCopyWith(AdState value, $Res Function(AdState) _then) = _$AdStateCopyWithImpl;
@useResult
$Res call({
 List<AdInfo> ads
});




}
/// @nodoc
class _$AdStateCopyWithImpl<$Res>
    implements $AdStateCopyWith<$Res> {
  _$AdStateCopyWithImpl(this._self, this._then);

  final AdState _self;
  final $Res Function(AdState) _then;

/// Create a copy of AdState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ads = null,}) {
  return _then(_self.copyWith(
ads: null == ads ? _self.ads : ads // ignore: cast_nullable_to_non_nullable
as List<AdInfo>,
  ));
}

}


/// Adds pattern-matching-related methods to [AdState].
extension AdStatePatterns on AdState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdState value)  $default,){
final _that = this;
switch (_that) {
case _AdState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdState value)?  $default,){
final _that = this;
switch (_that) {
case _AdState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdInfo> ads)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdState() when $default != null:
return $default(_that.ads);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdInfo> ads)  $default,) {final _that = this;
switch (_that) {
case _AdState():
return $default(_that.ads);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdInfo> ads)?  $default,) {final _that = this;
switch (_that) {
case _AdState() when $default != null:
return $default(_that.ads);case _:
  return null;

}
}

}

/// @nodoc


class _AdState implements AdState {
  const _AdState({required final  List<AdInfo> ads}): _ads = ads;
  

 final  List<AdInfo> _ads;
@override List<AdInfo> get ads {
  if (_ads is EqualUnmodifiableListView) return _ads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ads);
}


/// Create a copy of AdState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdStateCopyWith<_AdState> get copyWith => __$AdStateCopyWithImpl<_AdState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdState&&const DeepCollectionEquality().equals(other._ads, _ads));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_ads));

@override
String toString() {
  return 'AdState(ads: $ads)';
}


}

/// @nodoc
abstract mixin class _$AdStateCopyWith<$Res> implements $AdStateCopyWith<$Res> {
  factory _$AdStateCopyWith(_AdState value, $Res Function(_AdState) _then) = __$AdStateCopyWithImpl;
@override @useResult
$Res call({
 List<AdInfo> ads
});




}
/// @nodoc
class __$AdStateCopyWithImpl<$Res>
    implements _$AdStateCopyWith<$Res> {
  __$AdStateCopyWithImpl(this._self, this._then);

  final _AdState _self;
  final $Res Function(_AdState) _then;

/// Create a copy of AdState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ads = null,}) {
  return _then(_AdState(
ads: null == ads ? _self._ads : ads // ignore: cast_nullable_to_non_nullable
as List<AdInfo>,
  ));
}


}

// dart format on
