// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/common/popup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Popup {

 int get id; Map<String, String> get title; Map<String, String> get content; Map<String, String>? get image;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'deleted_at') DateTime? get deletedAt;@JsonKey(name: 'start_at') DateTime? get startAt;@JsonKey(name: 'stop_at') DateTime? get stopAt;
/// Create a copy of Popup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PopupCopyWith<Popup> get copyWith => _$PopupCopyWithImpl<Popup>(this as Popup, _$identity);

  /// Serializes this Popup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Popup&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.title, title)&&const DeepCollectionEquality().equals(other.content, content)&&const DeepCollectionEquality().equals(other.image, image)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.stopAt, stopAt) || other.stopAt == stopAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(title),const DeepCollectionEquality().hash(content),const DeepCollectionEquality().hash(image),createdAt,updatedAt,deletedAt,startAt,stopAt);

@override
String toString() {
  return 'Popup(id: $id, title: $title, content: $content, image: $image, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, startAt: $startAt, stopAt: $stopAt)';
}


}

/// @nodoc
abstract mixin class $PopupCopyWith<$Res>  {
  factory $PopupCopyWith(Popup value, $Res Function(Popup) _then) = _$PopupCopyWithImpl;
@useResult
$Res call({
 int id, Map<String, String> title, Map<String, String> content, Map<String, String>? image,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'start_at') DateTime? startAt,@JsonKey(name: 'stop_at') DateTime? stopAt
});




}
/// @nodoc
class _$PopupCopyWithImpl<$Res>
    implements $PopupCopyWith<$Res> {
  _$PopupCopyWithImpl(this._self, this._then);

  final Popup _self;
  final $Res Function(Popup) _then;

/// Create a copy of Popup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = null,Object? image = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? deletedAt = freezed,Object? startAt = freezed,Object? stopAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Map<String, String>,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, String>,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startAt: freezed == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stopAt: freezed == stopAt ? _self.stopAt : stopAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Popup].
extension PopupPatterns on Popup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Popup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Popup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Popup value)  $default,){
final _that = this;
switch (_that) {
case _Popup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Popup value)?  $default,){
final _that = this;
switch (_that) {
case _Popup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  Map<String, String> title,  Map<String, String> content,  Map<String, String>? image, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'start_at')  DateTime? startAt, @JsonKey(name: 'stop_at')  DateTime? stopAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Popup() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.image,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.startAt,_that.stopAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  Map<String, String> title,  Map<String, String> content,  Map<String, String>? image, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'start_at')  DateTime? startAt, @JsonKey(name: 'stop_at')  DateTime? stopAt)  $default,) {final _that = this;
switch (_that) {
case _Popup():
return $default(_that.id,_that.title,_that.content,_that.image,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.startAt,_that.stopAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  Map<String, String> title,  Map<String, String> content,  Map<String, String>? image, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'start_at')  DateTime? startAt, @JsonKey(name: 'stop_at')  DateTime? stopAt)?  $default,) {final _that = this;
switch (_that) {
case _Popup() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.image,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.startAt,_that.stopAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Popup implements Popup {
  const _Popup({required this.id, required final  Map<String, String> title, required final  Map<String, String> content, final  Map<String, String>? image, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'deleted_at') this.deletedAt, @JsonKey(name: 'start_at') this.startAt, @JsonKey(name: 'stop_at') this.stopAt}): _title = title,_content = content,_image = image;
  factory _Popup.fromJson(Map<String, dynamic> json) => _$PopupFromJson(json);

@override final  int id;
 final  Map<String, String> _title;
@override Map<String, String> get title {
  if (_title is EqualUnmodifiableMapView) return _title;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_title);
}

 final  Map<String, String> _content;
@override Map<String, String> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}

 final  Map<String, String>? _image;
@override Map<String, String>? get image {
  final value = _image;
  if (value == null) return null;
  if (_image is EqualUnmodifiableMapView) return _image;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;
@override@JsonKey(name: 'start_at') final  DateTime? startAt;
@override@JsonKey(name: 'stop_at') final  DateTime? stopAt;

/// Create a copy of Popup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PopupCopyWith<_Popup> get copyWith => __$PopupCopyWithImpl<_Popup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PopupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Popup&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._title, _title)&&const DeepCollectionEquality().equals(other._content, _content)&&const DeepCollectionEquality().equals(other._image, _image)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.stopAt, stopAt) || other.stopAt == stopAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_title),const DeepCollectionEquality().hash(_content),const DeepCollectionEquality().hash(_image),createdAt,updatedAt,deletedAt,startAt,stopAt);

@override
String toString() {
  return 'Popup(id: $id, title: $title, content: $content, image: $image, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, startAt: $startAt, stopAt: $stopAt)';
}


}

/// @nodoc
abstract mixin class _$PopupCopyWith<$Res> implements $PopupCopyWith<$Res> {
  factory _$PopupCopyWith(_Popup value, $Res Function(_Popup) _then) = __$PopupCopyWithImpl;
@override @useResult
$Res call({
 int id, Map<String, String> title, Map<String, String> content, Map<String, String>? image,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'start_at') DateTime? startAt,@JsonKey(name: 'stop_at') DateTime? stopAt
});




}
/// @nodoc
class __$PopupCopyWithImpl<$Res>
    implements _$PopupCopyWith<$Res> {
  __$PopupCopyWithImpl(this._self, this._then);

  final _Popup _self;
  final $Res Function(_Popup) _then;

/// Create a copy of Popup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? content = null,Object? image = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? deletedAt = freezed,Object? startAt = freezed,Object? stopAt = freezed,}) {
  return _then(_Popup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self._title : title // ignore: cast_nullable_to_non_nullable
as Map<String, String>,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, String>,image: freezed == image ? _self._image : image // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,startAt: freezed == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stopAt: freezed == stopAt ? _self.stopAt : stopAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
