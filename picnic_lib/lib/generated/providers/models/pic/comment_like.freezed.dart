// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/pic/comment_like.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserCommentLikeModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'user_id') int get userId;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of UserCommentLikeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCommentLikeModelCopyWith<UserCommentLikeModel> get copyWith => _$UserCommentLikeModelCopyWithImpl<UserCommentLikeModel>(this as UserCommentLikeModel, _$identity);

  /// Serializes this UserCommentLikeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCommentLikeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,createdAt);

@override
String toString() {
  return 'UserCommentLikeModel(id: $id, userId: $userId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserCommentLikeModelCopyWith<$Res>  {
  factory $UserCommentLikeModelCopyWith(UserCommentLikeModel value, $Res Function(UserCommentLikeModel) _then) = _$UserCommentLikeModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'user_id') int userId,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$UserCommentLikeModelCopyWithImpl<$Res>
    implements $UserCommentLikeModelCopyWith<$Res> {
  _$UserCommentLikeModelCopyWithImpl(this._self, this._then);

  final UserCommentLikeModel _self;
  final $Res Function(UserCommentLikeModel) _then;

/// Create a copy of UserCommentLikeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserCommentLikeModel].
extension UserCommentLikeModelPatterns on UserCommentLikeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserCommentLikeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserCommentLikeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserCommentLikeModel value)  $default,){
final _that = this;
switch (_that) {
case _UserCommentLikeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserCommentLikeModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserCommentLikeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'user_id')  int userId, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserCommentLikeModel() when $default != null:
return $default(_that.id,_that.userId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'user_id')  int userId, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _UserCommentLikeModel():
return $default(_that.id,_that.userId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'user_id')  int userId, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UserCommentLikeModel() when $default != null:
return $default(_that.id,_that.userId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserCommentLikeModel extends UserCommentLikeModel {
  const _UserCommentLikeModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'created_at') required this.createdAt}): super._();
  factory _UserCommentLikeModel.fromJson(Map<String, dynamic> json) => _$UserCommentLikeModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'user_id') final  int userId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of UserCommentLikeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCommentLikeModelCopyWith<_UserCommentLikeModel> get copyWith => __$UserCommentLikeModelCopyWithImpl<_UserCommentLikeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserCommentLikeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCommentLikeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,createdAt);

@override
String toString() {
  return 'UserCommentLikeModel(id: $id, userId: $userId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserCommentLikeModelCopyWith<$Res> implements $UserCommentLikeModelCopyWith<$Res> {
  factory _$UserCommentLikeModelCopyWith(_UserCommentLikeModel value, $Res Function(_UserCommentLikeModel) _then) = __$UserCommentLikeModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'user_id') int userId,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$UserCommentLikeModelCopyWithImpl<$Res>
    implements _$UserCommentLikeModelCopyWith<$Res> {
  __$UserCommentLikeModelCopyWithImpl(this._self, this._then);

  final _UserCommentLikeModel _self;
  final $Res Function(_UserCommentLikeModel) _then;

/// Create a copy of UserCommentLikeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? createdAt = null,}) {
  return _then(_UserCommentLikeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
