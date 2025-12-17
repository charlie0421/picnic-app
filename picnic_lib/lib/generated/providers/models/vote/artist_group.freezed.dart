// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/vote/artist_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArtistGroupModel {

 int get id; Map<String, dynamic> get name; String? get image;
/// Create a copy of ArtistGroupModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistGroupModelCopyWith<ArtistGroupModel> get copyWith => _$ArtistGroupModelCopyWithImpl<ArtistGroupModel>(this as ArtistGroupModel, _$identity);

  /// Serializes this ArtistGroupModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistGroupModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.name, name)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(name),image);

@override
String toString() {
  return 'ArtistGroupModel(id: $id, name: $name, image: $image)';
}


}

/// @nodoc
abstract mixin class $ArtistGroupModelCopyWith<$Res>  {
  factory $ArtistGroupModelCopyWith(ArtistGroupModel value, $Res Function(ArtistGroupModel) _then) = _$ArtistGroupModelCopyWithImpl;
@useResult
$Res call({
 int id, Map<String, dynamic> name, String? image
});




}
/// @nodoc
class _$ArtistGroupModelCopyWithImpl<$Res>
    implements $ArtistGroupModelCopyWith<$Res> {
  _$ArtistGroupModelCopyWithImpl(this._self, this._then);

  final ArtistGroupModel _self;
  final $Res Function(ArtistGroupModel) _then;

/// Create a copy of ArtistGroupModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? image = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistGroupModel].
extension ArtistGroupModelPatterns on ArtistGroupModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistGroupModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistGroupModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistGroupModel value)  $default,){
final _that = this;
switch (_that) {
case _ArtistGroupModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistGroupModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistGroupModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  Map<String, dynamic> name,  String? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistGroupModel() when $default != null:
return $default(_that.id,_that.name,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  Map<String, dynamic> name,  String? image)  $default,) {final _that = this;
switch (_that) {
case _ArtistGroupModel():
return $default(_that.id,_that.name,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  Map<String, dynamic> name,  String? image)?  $default,) {final _that = this;
switch (_that) {
case _ArtistGroupModel() when $default != null:
return $default(_that.id,_that.name,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArtistGroupModel extends ArtistGroupModel {
  const _ArtistGroupModel({required this.id, required final  Map<String, dynamic> name, required this.image}): _name = name,super._();
  factory _ArtistGroupModel.fromJson(Map<String, dynamic> json) => _$ArtistGroupModelFromJson(json);

@override final  int id;
 final  Map<String, dynamic> _name;
@override Map<String, dynamic> get name {
  if (_name is EqualUnmodifiableMapView) return _name;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_name);
}

@override final  String? image;

/// Create a copy of ArtistGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistGroupModelCopyWith<_ArtistGroupModel> get copyWith => __$ArtistGroupModelCopyWithImpl<_ArtistGroupModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistGroupModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistGroupModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._name, _name)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_name),image);

@override
String toString() {
  return 'ArtistGroupModel(id: $id, name: $name, image: $image)';
}


}

/// @nodoc
abstract mixin class _$ArtistGroupModelCopyWith<$Res> implements $ArtistGroupModelCopyWith<$Res> {
  factory _$ArtistGroupModelCopyWith(_ArtistGroupModel value, $Res Function(_ArtistGroupModel) _then) = __$ArtistGroupModelCopyWithImpl;
@override @useResult
$Res call({
 int id, Map<String, dynamic> name, String? image
});




}
/// @nodoc
class __$ArtistGroupModelCopyWithImpl<$Res>
    implements _$ArtistGroupModelCopyWith<$Res> {
  __$ArtistGroupModelCopyWithImpl(this._self, this._then);

  final _ArtistGroupModel _self;
  final $Res Function(_ArtistGroupModel) _then;

/// Create a copy of ArtistGroupModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? image = freezed,}) {
  return _then(_ArtistGroupModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self._name : name // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
