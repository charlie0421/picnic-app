// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/pic/library.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LibraryModel {

 int get id; String get title; List<ArticleImageModel>? get images;
/// Create a copy of LibraryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryModelCopyWith<LibraryModel> get copyWith => _$LibraryModelCopyWithImpl<LibraryModel>(this as LibraryModel, _$identity);

  /// Serializes this LibraryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.images, images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(images));

@override
String toString() {
  return 'LibraryModel(id: $id, title: $title, images: $images)';
}


}

/// @nodoc
abstract mixin class $LibraryModelCopyWith<$Res>  {
  factory $LibraryModelCopyWith(LibraryModel value, $Res Function(LibraryModel) _then) = _$LibraryModelCopyWithImpl;
@useResult
$Res call({
 int id, String title, List<ArticleImageModel>? images
});




}
/// @nodoc
class _$LibraryModelCopyWithImpl<$Res>
    implements $LibraryModelCopyWith<$Res> {
  _$LibraryModelCopyWithImpl(this._self, this._then);

  final LibraryModel _self;
  final $Res Function(LibraryModel) _then;

/// Create a copy of LibraryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? images = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,images: freezed == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ArticleImageModel>?,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryModel].
extension LibraryModelPatterns on LibraryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryModel value)  $default,){
final _that = this;
switch (_that) {
case _LibraryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryModel value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  List<ArticleImageModel>? images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryModel() when $default != null:
return $default(_that.id,_that.title,_that.images);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  List<ArticleImageModel>? images)  $default,) {final _that = this;
switch (_that) {
case _LibraryModel():
return $default(_that.id,_that.title,_that.images);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  List<ArticleImageModel>? images)?  $default,) {final _that = this;
switch (_that) {
case _LibraryModel() when $default != null:
return $default(_that.id,_that.title,_that.images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibraryModel extends LibraryModel {
  const _LibraryModel({required this.id, required this.title, required final  List<ArticleImageModel>? images}): _images = images,super._();
  factory _LibraryModel.fromJson(Map<String, dynamic> json) => _$LibraryModelFromJson(json);

@override final  int id;
@override final  String title;
 final  List<ArticleImageModel>? _images;
@override List<ArticleImageModel>? get images {
  final value = _images;
  if (value == null) return null;
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of LibraryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryModelCopyWith<_LibraryModel> get copyWith => __$LibraryModelCopyWithImpl<_LibraryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibraryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._images, _images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_images));

@override
String toString() {
  return 'LibraryModel(id: $id, title: $title, images: $images)';
}


}

/// @nodoc
abstract mixin class _$LibraryModelCopyWith<$Res> implements $LibraryModelCopyWith<$Res> {
  factory _$LibraryModelCopyWith(_LibraryModel value, $Res Function(_LibraryModel) _then) = __$LibraryModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, List<ArticleImageModel>? images
});




}
/// @nodoc
class __$LibraryModelCopyWithImpl<$Res>
    implements _$LibraryModelCopyWith<$Res> {
  __$LibraryModelCopyWithImpl(this._self, this._then);

  final _LibraryModel _self;
  final $Res Function(_LibraryModel) _then;

/// Create a copy of LibraryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? images = freezed,}) {
  return _then(_LibraryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,images: freezed == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ArticleImageModel>?,
  ));
}


}

// dart format on
