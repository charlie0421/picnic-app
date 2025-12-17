// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/community/post_scrap.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PostScrapModel {

@JsonKey(name: 'post_id') String get postId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'user_profiles') UserProfilesModel? get userProfiles;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'board') BoardModel? get board;@JsonKey(name: 'post') PostModel? get post;@JsonKey(name: 'deleted_at') DateTime? get deletedAt;
/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostScrapModelCopyWith<PostScrapModel> get copyWith => _$PostScrapModelCopyWithImpl<PostScrapModel>(this as PostScrapModel, _$identity);

  /// Serializes this PostScrapModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostScrapModel&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userProfiles, userProfiles) || other.userProfiles == userProfiles)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.board, board) || other.board == board)&&(identical(other.post, post) || other.post == post)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,postId,userId,userProfiles,createdAt,updatedAt,board,post,deletedAt);

@override
String toString() {
  return 'PostScrapModel(postId: $postId, userId: $userId, userProfiles: $userProfiles, createdAt: $createdAt, updatedAt: $updatedAt, board: $board, post: $post, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $PostScrapModelCopyWith<$Res>  {
  factory $PostScrapModelCopyWith(PostScrapModel value, $Res Function(PostScrapModel) _then) = _$PostScrapModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'post_id') String postId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'user_profiles') UserProfilesModel? userProfiles,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'board') BoardModel? board,@JsonKey(name: 'post') PostModel? post,@JsonKey(name: 'deleted_at') DateTime? deletedAt
});


$UserProfilesModelCopyWith<$Res>? get userProfiles;$BoardModelCopyWith<$Res>? get board;$PostModelCopyWith<$Res>? get post;

}
/// @nodoc
class _$PostScrapModelCopyWithImpl<$Res>
    implements $PostScrapModelCopyWith<$Res> {
  _$PostScrapModelCopyWithImpl(this._self, this._then);

  final PostScrapModel _self;
  final $Res Function(PostScrapModel) _then;

/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? postId = null,Object? userId = null,Object? userProfiles = freezed,Object? createdAt = null,Object? updatedAt = null,Object? board = freezed,Object? post = freezed,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userProfiles: freezed == userProfiles ? _self.userProfiles : userProfiles // ignore: cast_nullable_to_non_nullable
as UserProfilesModel?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,board: freezed == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardModel?,post: freezed == post ? _self.post : post // ignore: cast_nullable_to_non_nullable
as PostModel?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfilesModelCopyWith<$Res>? get userProfiles {
    if (_self.userProfiles == null) {
    return null;
  }

  return $UserProfilesModelCopyWith<$Res>(_self.userProfiles!, (value) {
    return _then(_self.copyWith(userProfiles: value));
  });
}/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoardModelCopyWith<$Res>? get board {
    if (_self.board == null) {
    return null;
  }

  return $BoardModelCopyWith<$Res>(_self.board!, (value) {
    return _then(_self.copyWith(board: value));
  });
}/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostModelCopyWith<$Res>? get post {
    if (_self.post == null) {
    return null;
  }

  return $PostModelCopyWith<$Res>(_self.post!, (value) {
    return _then(_self.copyWith(post: value));
  });
}
}


/// Adds pattern-matching-related methods to [PostScrapModel].
extension PostScrapModelPatterns on PostScrapModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostScrapModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostScrapModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostScrapModel value)  $default,){
final _that = this;
switch (_that) {
case _PostScrapModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostScrapModel value)?  $default,){
final _that = this;
switch (_that) {
case _PostScrapModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'user_profiles')  UserProfilesModel? userProfiles, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'board')  BoardModel? board, @JsonKey(name: 'post')  PostModel? post, @JsonKey(name: 'deleted_at')  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostScrapModel() when $default != null:
return $default(_that.postId,_that.userId,_that.userProfiles,_that.createdAt,_that.updatedAt,_that.board,_that.post,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'user_profiles')  UserProfilesModel? userProfiles, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'board')  BoardModel? board, @JsonKey(name: 'post')  PostModel? post, @JsonKey(name: 'deleted_at')  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _PostScrapModel():
return $default(_that.postId,_that.userId,_that.userProfiles,_that.createdAt,_that.updatedAt,_that.board,_that.post,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'user_profiles')  UserProfilesModel? userProfiles, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'board')  BoardModel? board, @JsonKey(name: 'post')  PostModel? post, @JsonKey(name: 'deleted_at')  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _PostScrapModel() when $default != null:
return $default(_that.postId,_that.userId,_that.userProfiles,_that.createdAt,_that.updatedAt,_that.board,_that.post,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostScrapModel extends PostScrapModel {
  const _PostScrapModel({@JsonKey(name: 'post_id') required this.postId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'user_profiles') required this.userProfiles, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'board') required this.board, @JsonKey(name: 'post') required this.post, @JsonKey(name: 'deleted_at') this.deletedAt}): super._();
  factory _PostScrapModel.fromJson(Map<String, dynamic> json) => _$PostScrapModelFromJson(json);

@override@JsonKey(name: 'post_id') final  String postId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'user_profiles') final  UserProfilesModel? userProfiles;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'board') final  BoardModel? board;
@override@JsonKey(name: 'post') final  PostModel? post;
@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;

/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostScrapModelCopyWith<_PostScrapModel> get copyWith => __$PostScrapModelCopyWithImpl<_PostScrapModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostScrapModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostScrapModel&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userProfiles, userProfiles) || other.userProfiles == userProfiles)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.board, board) || other.board == board)&&(identical(other.post, post) || other.post == post)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,postId,userId,userProfiles,createdAt,updatedAt,board,post,deletedAt);

@override
String toString() {
  return 'PostScrapModel(postId: $postId, userId: $userId, userProfiles: $userProfiles, createdAt: $createdAt, updatedAt: $updatedAt, board: $board, post: $post, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$PostScrapModelCopyWith<$Res> implements $PostScrapModelCopyWith<$Res> {
  factory _$PostScrapModelCopyWith(_PostScrapModel value, $Res Function(_PostScrapModel) _then) = __$PostScrapModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'post_id') String postId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'user_profiles') UserProfilesModel? userProfiles,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'board') BoardModel? board,@JsonKey(name: 'post') PostModel? post,@JsonKey(name: 'deleted_at') DateTime? deletedAt
});


@override $UserProfilesModelCopyWith<$Res>? get userProfiles;@override $BoardModelCopyWith<$Res>? get board;@override $PostModelCopyWith<$Res>? get post;

}
/// @nodoc
class __$PostScrapModelCopyWithImpl<$Res>
    implements _$PostScrapModelCopyWith<$Res> {
  __$PostScrapModelCopyWithImpl(this._self, this._then);

  final _PostScrapModel _self;
  final $Res Function(_PostScrapModel) _then;

/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? postId = null,Object? userId = null,Object? userProfiles = freezed,Object? createdAt = null,Object? updatedAt = null,Object? board = freezed,Object? post = freezed,Object? deletedAt = freezed,}) {
  return _then(_PostScrapModel(
postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userProfiles: freezed == userProfiles ? _self.userProfiles : userProfiles // ignore: cast_nullable_to_non_nullable
as UserProfilesModel?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,board: freezed == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardModel?,post: freezed == post ? _self.post : post // ignore: cast_nullable_to_non_nullable
as PostModel?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfilesModelCopyWith<$Res>? get userProfiles {
    if (_self.userProfiles == null) {
    return null;
  }

  return $UserProfilesModelCopyWith<$Res>(_self.userProfiles!, (value) {
    return _then(_self.copyWith(userProfiles: value));
  });
}/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BoardModelCopyWith<$Res>? get board {
    if (_self.board == null) {
    return null;
  }

  return $BoardModelCopyWith<$Res>(_self.board!, (value) {
    return _then(_self.copyWith(board: value));
  });
}/// Create a copy of PostScrapModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PostModelCopyWith<$Res>? get post {
    if (_self.post == null) {
    return null;
  }

  return $PostModelCopyWith<$Res>(_self.post!, (value) {
    return _then(_self.copyWith(post: value));
  });
}
}

// dart format on
