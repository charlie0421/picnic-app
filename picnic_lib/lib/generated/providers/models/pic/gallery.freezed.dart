// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/pic/gallery.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GalleryModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'title_ko') String get titleKo;@JsonKey(name: 'title_en') String get titleEn;@JsonKey(name: 'cover') String? get cover;@JsonKey(name: 'celeb') CelebModel? get celeb;
/// Create a copy of GalleryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryModelCopyWith<GalleryModel> get copyWith => _$GalleryModelCopyWithImpl<GalleryModel>(this as GalleryModel, _$identity);

  /// Serializes this GalleryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.titleKo, titleKo) || other.titleKo == titleKo)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.celeb, celeb) || other.celeb == celeb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleKo,titleEn,cover,celeb);

@override
String toString() {
  return 'GalleryModel(id: $id, titleKo: $titleKo, titleEn: $titleEn, cover: $cover, celeb: $celeb)';
}


}

/// @nodoc
abstract mixin class $GalleryModelCopyWith<$Res>  {
  factory $GalleryModelCopyWith(GalleryModel value, $Res Function(GalleryModel) _then) = _$GalleryModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title_ko') String titleKo,@JsonKey(name: 'title_en') String titleEn,@JsonKey(name: 'cover') String? cover,@JsonKey(name: 'celeb') CelebModel? celeb
});


$CelebModelCopyWith<$Res>? get celeb;

}
/// @nodoc
class _$GalleryModelCopyWithImpl<$Res>
    implements $GalleryModelCopyWith<$Res> {
  _$GalleryModelCopyWithImpl(this._self, this._then);

  final GalleryModel _self;
  final $Res Function(GalleryModel) _then;

/// Create a copy of GalleryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titleKo = null,Object? titleEn = null,Object? cover = freezed,Object? celeb = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titleKo: null == titleKo ? _self.titleKo : titleKo // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,celeb: freezed == celeb ? _self.celeb : celeb // ignore: cast_nullable_to_non_nullable
as CelebModel?,
  ));
}
/// Create a copy of GalleryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CelebModelCopyWith<$Res>? get celeb {
    if (_self.celeb == null) {
    return null;
  }

  return $CelebModelCopyWith<$Res>(_self.celeb!, (value) {
    return _then(_self.copyWith(celeb: value));
  });
}
}


/// Adds pattern-matching-related methods to [GalleryModel].
extension GalleryModelPatterns on GalleryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GalleryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GalleryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GalleryModel value)  $default,){
final _that = this;
switch (_that) {
case _GalleryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GalleryModel value)?  $default,){
final _that = this;
switch (_that) {
case _GalleryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title_ko')  String titleKo, @JsonKey(name: 'title_en')  String titleEn, @JsonKey(name: 'cover')  String? cover, @JsonKey(name: 'celeb')  CelebModel? celeb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GalleryModel() when $default != null:
return $default(_that.id,_that.titleKo,_that.titleEn,_that.cover,_that.celeb);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title_ko')  String titleKo, @JsonKey(name: 'title_en')  String titleEn, @JsonKey(name: 'cover')  String? cover, @JsonKey(name: 'celeb')  CelebModel? celeb)  $default,) {final _that = this;
switch (_that) {
case _GalleryModel():
return $default(_that.id,_that.titleKo,_that.titleEn,_that.cover,_that.celeb);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title_ko')  String titleKo, @JsonKey(name: 'title_en')  String titleEn, @JsonKey(name: 'cover')  String? cover, @JsonKey(name: 'celeb')  CelebModel? celeb)?  $default,) {final _that = this;
switch (_that) {
case _GalleryModel() when $default != null:
return $default(_that.id,_that.titleKo,_that.titleEn,_that.cover,_that.celeb);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GalleryModel extends GalleryModel {
  const _GalleryModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'title_ko') required this.titleKo, @JsonKey(name: 'title_en') required this.titleEn, @JsonKey(name: 'cover') this.cover, @JsonKey(name: 'celeb') required this.celeb}): super._();
  factory _GalleryModel.fromJson(Map<String, dynamic> json) => _$GalleryModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'title_ko') final  String titleKo;
@override@JsonKey(name: 'title_en') final  String titleEn;
@override@JsonKey(name: 'cover') final  String? cover;
@override@JsonKey(name: 'celeb') final  CelebModel? celeb;

/// Create a copy of GalleryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GalleryModelCopyWith<_GalleryModel> get copyWith => __$GalleryModelCopyWithImpl<_GalleryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GalleryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GalleryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.titleKo, titleKo) || other.titleKo == titleKo)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.celeb, celeb) || other.celeb == celeb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleKo,titleEn,cover,celeb);

@override
String toString() {
  return 'GalleryModel(id: $id, titleKo: $titleKo, titleEn: $titleEn, cover: $cover, celeb: $celeb)';
}


}

/// @nodoc
abstract mixin class _$GalleryModelCopyWith<$Res> implements $GalleryModelCopyWith<$Res> {
  factory _$GalleryModelCopyWith(_GalleryModel value, $Res Function(_GalleryModel) _then) = __$GalleryModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title_ko') String titleKo,@JsonKey(name: 'title_en') String titleEn,@JsonKey(name: 'cover') String? cover,@JsonKey(name: 'celeb') CelebModel? celeb
});


@override $CelebModelCopyWith<$Res>? get celeb;

}
/// @nodoc
class __$GalleryModelCopyWithImpl<$Res>
    implements _$GalleryModelCopyWith<$Res> {
  __$GalleryModelCopyWithImpl(this._self, this._then);

  final _GalleryModel _self;
  final $Res Function(_GalleryModel) _then;

/// Create a copy of GalleryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titleKo = null,Object? titleEn = null,Object? cover = freezed,Object? celeb = freezed,}) {
  return _then(_GalleryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titleKo: null == titleKo ? _self.titleKo : titleKo // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String?,celeb: freezed == celeb ? _self.celeb : celeb // ignore: cast_nullable_to_non_nullable
as CelebModel?,
  ));
}

/// Create a copy of GalleryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CelebModelCopyWith<$Res>? get celeb {
    if (_self.celeb == null) {
    return null;
  }

  return $CelebModelCopyWith<$Res>(_self.celeb!, (value) {
    return _then(_self.copyWith(celeb: value));
  });
}
}

// dart format on
