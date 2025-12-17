// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/reward.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RewardModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'title') Map<String, dynamic>? get title;@JsonKey(name: 'thumbnail') String? get thumbnail;@JsonKey(name: 'overview_images') List<String>? get overviewImages;@JsonKey(name: 'location') Map<String, dynamic>? get location;@JsonKey(name: 'size_guide') Map<String, dynamic>? get sizeGuide;@JsonKey(name: 'size_guide_images') List<String>? get sizeGuideImages;
/// Create a copy of RewardModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RewardModelCopyWith<RewardModel> get copyWith => _$RewardModelCopyWithImpl<RewardModel>(this as RewardModel, _$identity);

  /// Serializes this RewardModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RewardModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.title, title)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&const DeepCollectionEquality().equals(other.overviewImages, overviewImages)&&const DeepCollectionEquality().equals(other.location, location)&&const DeepCollectionEquality().equals(other.sizeGuide, sizeGuide)&&const DeepCollectionEquality().equals(other.sizeGuideImages, sizeGuideImages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(title),thumbnail,const DeepCollectionEquality().hash(overviewImages),const DeepCollectionEquality().hash(location),const DeepCollectionEquality().hash(sizeGuide),const DeepCollectionEquality().hash(sizeGuideImages));

@override
String toString() {
  return 'RewardModel(id: $id, title: $title, thumbnail: $thumbnail, overviewImages: $overviewImages, location: $location, sizeGuide: $sizeGuide, sizeGuideImages: $sizeGuideImages)';
}


}

/// @nodoc
abstract mixin class $RewardModelCopyWith<$Res>  {
  factory $RewardModelCopyWith(RewardModel value, $Res Function(RewardModel) _then) = _$RewardModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title') Map<String, dynamic>? title,@JsonKey(name: 'thumbnail') String? thumbnail,@JsonKey(name: 'overview_images') List<String>? overviewImages,@JsonKey(name: 'location') Map<String, dynamic>? location,@JsonKey(name: 'size_guide') Map<String, dynamic>? sizeGuide,@JsonKey(name: 'size_guide_images') List<String>? sizeGuideImages
});




}
/// @nodoc
class _$RewardModelCopyWithImpl<$Res>
    implements $RewardModelCopyWith<$Res> {
  _$RewardModelCopyWithImpl(this._self, this._then);

  final RewardModel _self;
  final $Res Function(RewardModel) _then;

/// Create a copy of RewardModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? thumbnail = freezed,Object? overviewImages = freezed,Object? location = freezed,Object? sizeGuide = freezed,Object? sizeGuideImages = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,overviewImages: freezed == overviewImages ? _self.overviewImages : overviewImages // ignore: cast_nullable_to_non_nullable
as List<String>?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,sizeGuide: freezed == sizeGuide ? _self.sizeGuide : sizeGuide // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,sizeGuideImages: freezed == sizeGuideImages ? _self.sizeGuideImages : sizeGuideImages // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [RewardModel].
extension RewardModelPatterns on RewardModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RewardModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RewardModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RewardModel value)  $default,){
final _that = this;
switch (_that) {
case _RewardModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RewardModel value)?  $default,){
final _that = this;
switch (_that) {
case _RewardModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title')  Map<String, dynamic>? title, @JsonKey(name: 'thumbnail')  String? thumbnail, @JsonKey(name: 'overview_images')  List<String>? overviewImages, @JsonKey(name: 'location')  Map<String, dynamic>? location, @JsonKey(name: 'size_guide')  Map<String, dynamic>? sizeGuide, @JsonKey(name: 'size_guide_images')  List<String>? sizeGuideImages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RewardModel() when $default != null:
return $default(_that.id,_that.title,_that.thumbnail,_that.overviewImages,_that.location,_that.sizeGuide,_that.sizeGuideImages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title')  Map<String, dynamic>? title, @JsonKey(name: 'thumbnail')  String? thumbnail, @JsonKey(name: 'overview_images')  List<String>? overviewImages, @JsonKey(name: 'location')  Map<String, dynamic>? location, @JsonKey(name: 'size_guide')  Map<String, dynamic>? sizeGuide, @JsonKey(name: 'size_guide_images')  List<String>? sizeGuideImages)  $default,) {final _that = this;
switch (_that) {
case _RewardModel():
return $default(_that.id,_that.title,_that.thumbnail,_that.overviewImages,_that.location,_that.sizeGuide,_that.sizeGuideImages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title')  Map<String, dynamic>? title, @JsonKey(name: 'thumbnail')  String? thumbnail, @JsonKey(name: 'overview_images')  List<String>? overviewImages, @JsonKey(name: 'location')  Map<String, dynamic>? location, @JsonKey(name: 'size_guide')  Map<String, dynamic>? sizeGuide, @JsonKey(name: 'size_guide_images')  List<String>? sizeGuideImages)?  $default,) {final _that = this;
switch (_that) {
case _RewardModel() when $default != null:
return $default(_that.id,_that.title,_that.thumbnail,_that.overviewImages,_that.location,_that.sizeGuide,_that.sizeGuideImages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RewardModel extends RewardModel {
  const _RewardModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'title') final  Map<String, dynamic>? title, @JsonKey(name: 'thumbnail') this.thumbnail, @JsonKey(name: 'overview_images') final  List<String>? overviewImages, @JsonKey(name: 'location') final  Map<String, dynamic>? location, @JsonKey(name: 'size_guide') final  Map<String, dynamic>? sizeGuide, @JsonKey(name: 'size_guide_images') final  List<String>? sizeGuideImages}): _title = title,_overviewImages = overviewImages,_location = location,_sizeGuide = sizeGuide,_sizeGuideImages = sizeGuideImages,super._();
  factory _RewardModel.fromJson(Map<String, dynamic> json) => _$RewardModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
 final  Map<String, dynamic>? _title;
@override@JsonKey(name: 'title') Map<String, dynamic>? get title {
  final value = _title;
  if (value == null) return null;
  if (_title is EqualUnmodifiableMapView) return _title;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'thumbnail') final  String? thumbnail;
 final  List<String>? _overviewImages;
@override@JsonKey(name: 'overview_images') List<String>? get overviewImages {
  final value = _overviewImages;
  if (value == null) return null;
  if (_overviewImages is EqualUnmodifiableListView) return _overviewImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Map<String, dynamic>? _location;
@override@JsonKey(name: 'location') Map<String, dynamic>? get location {
  final value = _location;
  if (value == null) return null;
  if (_location is EqualUnmodifiableMapView) return _location;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _sizeGuide;
@override@JsonKey(name: 'size_guide') Map<String, dynamic>? get sizeGuide {
  final value = _sizeGuide;
  if (value == null) return null;
  if (_sizeGuide is EqualUnmodifiableMapView) return _sizeGuide;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<String>? _sizeGuideImages;
@override@JsonKey(name: 'size_guide_images') List<String>? get sizeGuideImages {
  final value = _sizeGuideImages;
  if (value == null) return null;
  if (_sizeGuideImages is EqualUnmodifiableListView) return _sizeGuideImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of RewardModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RewardModelCopyWith<_RewardModel> get copyWith => __$RewardModelCopyWithImpl<_RewardModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RewardModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RewardModel&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._title, _title)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&const DeepCollectionEquality().equals(other._overviewImages, _overviewImages)&&const DeepCollectionEquality().equals(other._location, _location)&&const DeepCollectionEquality().equals(other._sizeGuide, _sizeGuide)&&const DeepCollectionEquality().equals(other._sizeGuideImages, _sizeGuideImages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_title),thumbnail,const DeepCollectionEquality().hash(_overviewImages),const DeepCollectionEquality().hash(_location),const DeepCollectionEquality().hash(_sizeGuide),const DeepCollectionEquality().hash(_sizeGuideImages));

@override
String toString() {
  return 'RewardModel(id: $id, title: $title, thumbnail: $thumbnail, overviewImages: $overviewImages, location: $location, sizeGuide: $sizeGuide, sizeGuideImages: $sizeGuideImages)';
}


}

/// @nodoc
abstract mixin class _$RewardModelCopyWith<$Res> implements $RewardModelCopyWith<$Res> {
  factory _$RewardModelCopyWith(_RewardModel value, $Res Function(_RewardModel) _then) = __$RewardModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title') Map<String, dynamic>? title,@JsonKey(name: 'thumbnail') String? thumbnail,@JsonKey(name: 'overview_images') List<String>? overviewImages,@JsonKey(name: 'location') Map<String, dynamic>? location,@JsonKey(name: 'size_guide') Map<String, dynamic>? sizeGuide,@JsonKey(name: 'size_guide_images') List<String>? sizeGuideImages
});




}
/// @nodoc
class __$RewardModelCopyWithImpl<$Res>
    implements _$RewardModelCopyWith<$Res> {
  __$RewardModelCopyWithImpl(this._self, this._then);

  final _RewardModel _self;
  final $Res Function(_RewardModel) _then;

/// Create a copy of RewardModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? thumbnail = freezed,Object? overviewImages = freezed,Object? location = freezed,Object? sizeGuide = freezed,Object? sizeGuideImages = freezed,}) {
  return _then(_RewardModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: freezed == title ? _self._title : title // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,overviewImages: freezed == overviewImages ? _self._overviewImages : overviewImages // ignore: cast_nullable_to_non_nullable
as List<String>?,location: freezed == location ? _self._location : location // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,sizeGuide: freezed == sizeGuide ? _self._sizeGuide : sizeGuide // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,sizeGuideImages: freezed == sizeGuideImages ? _self._sizeGuideImages : sizeGuideImages // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
