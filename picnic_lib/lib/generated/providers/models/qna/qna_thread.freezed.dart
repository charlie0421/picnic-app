// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/qna/qna_thread.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QnaThread {

 int get id; String get userId; String get title; DateTime get createdAt; DateTime get updatedAt; String get status;
/// Create a copy of QnaThread
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QnaThreadCopyWith<QnaThread> get copyWith => _$QnaThreadCopyWithImpl<QnaThread>(this as QnaThread, _$identity);

  /// Serializes this QnaThread to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QnaThread&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,createdAt,updatedAt,status);

@override
String toString() {
  return 'QnaThread(id: $id, userId: $userId, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $QnaThreadCopyWith<$Res>  {
  factory $QnaThreadCopyWith(QnaThread value, $Res Function(QnaThread) _then) = _$QnaThreadCopyWithImpl;
@useResult
$Res call({
 int id, String userId, String title, DateTime createdAt, DateTime updatedAt, String status
});




}
/// @nodoc
class _$QnaThreadCopyWithImpl<$Res>
    implements $QnaThreadCopyWith<$Res> {
  _$QnaThreadCopyWithImpl(this._self, this._then);

  final QnaThread _self;
  final $Res Function(QnaThread) _then;

/// Create a copy of QnaThread
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QnaThread].
extension QnaThreadPatterns on QnaThread {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QnaThread value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QnaThread() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QnaThread value)  $default,){
final _that = this;
switch (_that) {
case _QnaThread():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QnaThread value)?  $default,){
final _that = this;
switch (_that) {
case _QnaThread() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String userId,  String title,  DateTime createdAt,  DateTime updatedAt,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QnaThread() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.createdAt,_that.updatedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String userId,  String title,  DateTime createdAt,  DateTime updatedAt,  String status)  $default,) {final _that = this;
switch (_that) {
case _QnaThread():
return $default(_that.id,_that.userId,_that.title,_that.createdAt,_that.updatedAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String userId,  String title,  DateTime createdAt,  DateTime updatedAt,  String status)?  $default,) {final _that = this;
switch (_that) {
case _QnaThread() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.createdAt,_that.updatedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QnaThread implements QnaThread {
  const _QnaThread({required this.id, required this.userId, required this.title, required this.createdAt, required this.updatedAt, required this.status});
  factory _QnaThread.fromJson(Map<String, dynamic> json) => _$QnaThreadFromJson(json);

@override final  int id;
@override final  String userId;
@override final  String title;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String status;

/// Create a copy of QnaThread
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QnaThreadCopyWith<_QnaThread> get copyWith => __$QnaThreadCopyWithImpl<_QnaThread>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QnaThreadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QnaThread&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,createdAt,updatedAt,status);

@override
String toString() {
  return 'QnaThread(id: $id, userId: $userId, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$QnaThreadCopyWith<$Res> implements $QnaThreadCopyWith<$Res> {
  factory _$QnaThreadCopyWith(_QnaThread value, $Res Function(_QnaThread) _then) = __$QnaThreadCopyWithImpl;
@override @useResult
$Res call({
 int id, String userId, String title, DateTime createdAt, DateTime updatedAt, String status
});




}
/// @nodoc
class __$QnaThreadCopyWithImpl<$Res>
    implements _$QnaThreadCopyWith<$Res> {
  __$QnaThreadCopyWithImpl(this._self, this._then);

  final _QnaThread _self;
  final $Res Function(_QnaThread) _then;

/// Create a copy of QnaThread
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,}) {
  return _then(_QnaThread(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
