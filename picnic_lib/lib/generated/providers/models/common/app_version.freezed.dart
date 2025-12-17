// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/common/app_version.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppVersionModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'ios') Map<String, dynamic> get ios;@JsonKey(name: 'android') Map<String, dynamic> get android;@JsonKey(name: 'macos') Map<String, dynamic> get macos;@JsonKey(name: 'windows') Map<String, dynamic> get windows;@JsonKey(name: 'linux') Map<String, dynamic> get linux;
/// Create a copy of AppVersionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppVersionModelCopyWith<AppVersionModel> get copyWith => _$AppVersionModelCopyWithImpl<AppVersionModel>(this as AppVersionModel, _$identity);

  /// Serializes this AppVersionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppVersionModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.ios, ios)&&const DeepCollectionEquality().equals(other.android, android)&&const DeepCollectionEquality().equals(other.macos, macos)&&const DeepCollectionEquality().equals(other.windows, windows)&&const DeepCollectionEquality().equals(other.linux, linux));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(ios),const DeepCollectionEquality().hash(android),const DeepCollectionEquality().hash(macos),const DeepCollectionEquality().hash(windows),const DeepCollectionEquality().hash(linux));

@override
String toString() {
  return 'AppVersionModel(id: $id, ios: $ios, android: $android, macos: $macos, windows: $windows, linux: $linux)';
}


}

/// @nodoc
abstract mixin class $AppVersionModelCopyWith<$Res>  {
  factory $AppVersionModelCopyWith(AppVersionModel value, $Res Function(AppVersionModel) _then) = _$AppVersionModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'ios') Map<String, dynamic> ios,@JsonKey(name: 'android') Map<String, dynamic> android,@JsonKey(name: 'macos') Map<String, dynamic> macos,@JsonKey(name: 'windows') Map<String, dynamic> windows,@JsonKey(name: 'linux') Map<String, dynamic> linux
});




}
/// @nodoc
class _$AppVersionModelCopyWithImpl<$Res>
    implements $AppVersionModelCopyWith<$Res> {
  _$AppVersionModelCopyWithImpl(this._self, this._then);

  final AppVersionModel _self;
  final $Res Function(AppVersionModel) _then;

/// Create a copy of AppVersionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ios = null,Object? android = null,Object? macos = null,Object? windows = null,Object? linux = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ios: null == ios ? _self.ios : ios // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,android: null == android ? _self.android : android // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,macos: null == macos ? _self.macos : macos // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,windows: null == windows ? _self.windows : windows // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,linux: null == linux ? _self.linux : linux // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppVersionModel].
extension AppVersionModelPatterns on AppVersionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppVersionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppVersionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppVersionModel value)  $default,){
final _that = this;
switch (_that) {
case _AppVersionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppVersionModel value)?  $default,){
final _that = this;
switch (_that) {
case _AppVersionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'ios')  Map<String, dynamic> ios, @JsonKey(name: 'android')  Map<String, dynamic> android, @JsonKey(name: 'macos')  Map<String, dynamic> macos, @JsonKey(name: 'windows')  Map<String, dynamic> windows, @JsonKey(name: 'linux')  Map<String, dynamic> linux)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppVersionModel() when $default != null:
return $default(_that.id,_that.ios,_that.android,_that.macos,_that.windows,_that.linux);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'ios')  Map<String, dynamic> ios, @JsonKey(name: 'android')  Map<String, dynamic> android, @JsonKey(name: 'macos')  Map<String, dynamic> macos, @JsonKey(name: 'windows')  Map<String, dynamic> windows, @JsonKey(name: 'linux')  Map<String, dynamic> linux)  $default,) {final _that = this;
switch (_that) {
case _AppVersionModel():
return $default(_that.id,_that.ios,_that.android,_that.macos,_that.windows,_that.linux);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'ios')  Map<String, dynamic> ios, @JsonKey(name: 'android')  Map<String, dynamic> android, @JsonKey(name: 'macos')  Map<String, dynamic> macos, @JsonKey(name: 'windows')  Map<String, dynamic> windows, @JsonKey(name: 'linux')  Map<String, dynamic> linux)?  $default,) {final _that = this;
switch (_that) {
case _AppVersionModel() when $default != null:
return $default(_that.id,_that.ios,_that.android,_that.macos,_that.windows,_that.linux);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppVersionModel implements AppVersionModel {
  const _AppVersionModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'ios') required final  Map<String, dynamic> ios, @JsonKey(name: 'android') required final  Map<String, dynamic> android, @JsonKey(name: 'macos') required final  Map<String, dynamic> macos, @JsonKey(name: 'windows') required final  Map<String, dynamic> windows, @JsonKey(name: 'linux') required final  Map<String, dynamic> linux}): _ios = ios,_android = android,_macos = macos,_windows = windows,_linux = linux;
  factory _AppVersionModel.fromJson(Map<String, dynamic> json) => _$AppVersionModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
 final  Map<String, dynamic> _ios;
@override@JsonKey(name: 'ios') Map<String, dynamic> get ios {
  if (_ios is EqualUnmodifiableMapView) return _ios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ios);
}

 final  Map<String, dynamic> _android;
@override@JsonKey(name: 'android') Map<String, dynamic> get android {
  if (_android is EqualUnmodifiableMapView) return _android;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_android);
}

 final  Map<String, dynamic> _macos;
@override@JsonKey(name: 'macos') Map<String, dynamic> get macos {
  if (_macos is EqualUnmodifiableMapView) return _macos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_macos);
}

 final  Map<String, dynamic> _windows;
@override@JsonKey(name: 'windows') Map<String, dynamic> get windows {
  if (_windows is EqualUnmodifiableMapView) return _windows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_windows);
}

 final  Map<String, dynamic> _linux;
@override@JsonKey(name: 'linux') Map<String, dynamic> get linux {
  if (_linux is EqualUnmodifiableMapView) return _linux;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_linux);
}


/// Create a copy of AppVersionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppVersionModelCopyWith<_AppVersionModel> get copyWith => __$AppVersionModelCopyWithImpl<_AppVersionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppVersionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppVersionModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._ios, _ios)&&const DeepCollectionEquality().equals(other._android, _android)&&const DeepCollectionEquality().equals(other._macos, _macos)&&const DeepCollectionEquality().equals(other._windows, _windows)&&const DeepCollectionEquality().equals(other._linux, _linux));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_ios),const DeepCollectionEquality().hash(_android),const DeepCollectionEquality().hash(_macos),const DeepCollectionEquality().hash(_windows),const DeepCollectionEquality().hash(_linux));

@override
String toString() {
  return 'AppVersionModel(id: $id, ios: $ios, android: $android, macos: $macos, windows: $windows, linux: $linux)';
}


}

/// @nodoc
abstract mixin class _$AppVersionModelCopyWith<$Res> implements $AppVersionModelCopyWith<$Res> {
  factory _$AppVersionModelCopyWith(_AppVersionModel value, $Res Function(_AppVersionModel) _then) = __$AppVersionModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'ios') Map<String, dynamic> ios,@JsonKey(name: 'android') Map<String, dynamic> android,@JsonKey(name: 'macos') Map<String, dynamic> macos,@JsonKey(name: 'windows') Map<String, dynamic> windows,@JsonKey(name: 'linux') Map<String, dynamic> linux
});




}
/// @nodoc
class __$AppVersionModelCopyWithImpl<$Res>
    implements _$AppVersionModelCopyWith<$Res> {
  __$AppVersionModelCopyWithImpl(this._self, this._then);

  final _AppVersionModel _self;
  final $Res Function(_AppVersionModel) _then;

/// Create a copy of AppVersionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ios = null,Object? android = null,Object? macos = null,Object? windows = null,Object? linux = null,}) {
  return _then(_AppVersionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ios: null == ios ? _self._ios : ios // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,android: null == android ? _self._android : android // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,macos: null == macos ? _self._macos : macos // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,windows: null == windows ? _self._windows : windows // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,linux: null == linux ? _self._linux : linux // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
