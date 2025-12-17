// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/community/post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PostModel {

@JsonKey(name: 'post_id') String get postId;@JsonKey(name: 'user_id') String? get userId;@JsonKey(name: 'user_profiles') UserProfilesModel? get userProfiles;@JsonKey(name: 'board_id') String? get boardId;@JsonKey(name: 'title') String? get title;@JsonKey(name: 'content') List<dynamic>? get content;@JsonKey(name: 'view_count') int? get viewCount;@JsonKey(name: 'reply_count') int? get replyCount;@JsonKey(name: 'is_hidden') bool? get isHidden;@JsonKey(name: 'boards') BoardModel? get board;@JsonKey(name: 'is_anonymous') bool? get isAnonymous;@JsonKey(name: 'is_scraped') bool? get isScraped;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'deleted_at') DateTime? get deletedAt;
/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostModelCopyWith<PostModel> get copyWith => _$PostModelCopyWithImpl<PostModel>(this as PostModel, _$identity);

  /// Serializes this PostModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostModel&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userProfiles, userProfiles) || other.userProfiles == userProfiles)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.board, board) || other.board == board)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isScraped, isScraped) || other.isScraped == isScraped)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,postId,userId,userProfiles,boardId,title,const DeepCollectionEquality().hash(content),viewCount,replyCount,isHidden,board,isAnonymous,isScraped,createdAt,updatedAt,deletedAt);

@override
String toString() {
  return 'PostModel(postId: $postId, userId: $userId, userProfiles: $userProfiles, boardId: $boardId, title: $title, content: $content, viewCount: $viewCount, replyCount: $replyCount, isHidden: $isHidden, board: $board, isAnonymous: $isAnonymous, isScraped: $isScraped, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $PostModelCopyWith<$Res>  {
  factory $PostModelCopyWith(PostModel value, $Res Function(PostModel) _then) = _$PostModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'post_id') String postId,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'user_profiles') UserProfilesModel? userProfiles,@JsonKey(name: 'board_id') String? boardId,@JsonKey(name: 'title') String? title,@JsonKey(name: 'content') List<dynamic>? content,@JsonKey(name: 'view_count') int? viewCount,@JsonKey(name: 'reply_count') int? replyCount,@JsonKey(name: 'is_hidden') bool? isHidden,@JsonKey(name: 'boards') BoardModel? board,@JsonKey(name: 'is_anonymous') bool? isAnonymous,@JsonKey(name: 'is_scraped') bool? isScraped,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt
});


$UserProfilesModelCopyWith<$Res>? get userProfiles;$BoardModelCopyWith<$Res>? get board;

}
/// @nodoc
class _$PostModelCopyWithImpl<$Res>
    implements $PostModelCopyWith<$Res> {
  _$PostModelCopyWithImpl(this._self, this._then);

  final PostModel _self;
  final $Res Function(PostModel) _then;

/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? postId = null,Object? userId = freezed,Object? userProfiles = freezed,Object? boardId = freezed,Object? title = freezed,Object? content = freezed,Object? viewCount = freezed,Object? replyCount = freezed,Object? isHidden = freezed,Object? board = freezed,Object? isAnonymous = freezed,Object? isScraped = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,userProfiles: freezed == userProfiles ? _self.userProfiles : userProfiles // ignore: cast_nullable_to_non_nullable
as UserProfilesModel?,boardId: freezed == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,replyCount: freezed == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int?,isHidden: freezed == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool?,board: freezed == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardModel?,isAnonymous: freezed == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool?,isScraped: freezed == isScraped ? _self.isScraped : isScraped // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of PostModel
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
}/// Create a copy of PostModel
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
}
}


/// Adds pattern-matching-related methods to [PostModel].
extension PostModelPatterns on PostModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostModel value)  $default,){
final _that = this;
switch (_that) {
case _PostModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostModel value)?  $default,){
final _that = this;
switch (_that) {
case _PostModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'user_profiles')  UserProfilesModel? userProfiles, @JsonKey(name: 'board_id')  String? boardId, @JsonKey(name: 'title')  String? title, @JsonKey(name: 'content')  List<dynamic>? content, @JsonKey(name: 'view_count')  int? viewCount, @JsonKey(name: 'reply_count')  int? replyCount, @JsonKey(name: 'is_hidden')  bool? isHidden, @JsonKey(name: 'boards')  BoardModel? board, @JsonKey(name: 'is_anonymous')  bool? isAnonymous, @JsonKey(name: 'is_scraped')  bool? isScraped, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostModel() when $default != null:
return $default(_that.postId,_that.userId,_that.userProfiles,_that.boardId,_that.title,_that.content,_that.viewCount,_that.replyCount,_that.isHidden,_that.board,_that.isAnonymous,_that.isScraped,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'user_profiles')  UserProfilesModel? userProfiles, @JsonKey(name: 'board_id')  String? boardId, @JsonKey(name: 'title')  String? title, @JsonKey(name: 'content')  List<dynamic>? content, @JsonKey(name: 'view_count')  int? viewCount, @JsonKey(name: 'reply_count')  int? replyCount, @JsonKey(name: 'is_hidden')  bool? isHidden, @JsonKey(name: 'boards')  BoardModel? board, @JsonKey(name: 'is_anonymous')  bool? isAnonymous, @JsonKey(name: 'is_scraped')  bool? isScraped, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _PostModel():
return $default(_that.postId,_that.userId,_that.userProfiles,_that.boardId,_that.title,_that.content,_that.viewCount,_that.replyCount,_that.isHidden,_that.board,_that.isAnonymous,_that.isScraped,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'post_id')  String postId, @JsonKey(name: 'user_id')  String? userId, @JsonKey(name: 'user_profiles')  UserProfilesModel? userProfiles, @JsonKey(name: 'board_id')  String? boardId, @JsonKey(name: 'title')  String? title, @JsonKey(name: 'content')  List<dynamic>? content, @JsonKey(name: 'view_count')  int? viewCount, @JsonKey(name: 'reply_count')  int? replyCount, @JsonKey(name: 'is_hidden')  bool? isHidden, @JsonKey(name: 'boards')  BoardModel? board, @JsonKey(name: 'is_anonymous')  bool? isAnonymous, @JsonKey(name: 'is_scraped')  bool? isScraped, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _PostModel() when $default != null:
return $default(_that.postId,_that.userId,_that.userProfiles,_that.boardId,_that.title,_that.content,_that.viewCount,_that.replyCount,_that.isHidden,_that.board,_that.isAnonymous,_that.isScraped,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostModel extends PostModel {
  const _PostModel({@JsonKey(name: 'post_id') required this.postId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'user_profiles') required this.userProfiles, @JsonKey(name: 'board_id') required this.boardId, @JsonKey(name: 'title') required this.title, @JsonKey(name: 'content') required final  List<dynamic>? content, @JsonKey(name: 'view_count') required this.viewCount, @JsonKey(name: 'reply_count') required this.replyCount, @JsonKey(name: 'is_hidden') required this.isHidden, @JsonKey(name: 'boards') required this.board, @JsonKey(name: 'is_anonymous') required this.isAnonymous, @JsonKey(name: 'is_scraped') required this.isScraped, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'deleted_at') this.deletedAt}): _content = content,super._();
  factory _PostModel.fromJson(Map<String, dynamic> json) => _$PostModelFromJson(json);

@override@JsonKey(name: 'post_id') final  String postId;
@override@JsonKey(name: 'user_id') final  String? userId;
@override@JsonKey(name: 'user_profiles') final  UserProfilesModel? userProfiles;
@override@JsonKey(name: 'board_id') final  String? boardId;
@override@JsonKey(name: 'title') final  String? title;
 final  List<dynamic>? _content;
@override@JsonKey(name: 'content') List<dynamic>? get content {
  final value = _content;
  if (value == null) return null;
  if (_content is EqualUnmodifiableListView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'view_count') final  int? viewCount;
@override@JsonKey(name: 'reply_count') final  int? replyCount;
@override@JsonKey(name: 'is_hidden') final  bool? isHidden;
@override@JsonKey(name: 'boards') final  BoardModel? board;
@override@JsonKey(name: 'is_anonymous') final  bool? isAnonymous;
@override@JsonKey(name: 'is_scraped') final  bool? isScraped;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;

/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostModelCopyWith<_PostModel> get copyWith => __$PostModelCopyWithImpl<_PostModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostModel&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userProfiles, userProfiles) || other.userProfiles == userProfiles)&&(identical(other.boardId, boardId) || other.boardId == boardId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.board, board) || other.board == board)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isScraped, isScraped) || other.isScraped == isScraped)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,postId,userId,userProfiles,boardId,title,const DeepCollectionEquality().hash(_content),viewCount,replyCount,isHidden,board,isAnonymous,isScraped,createdAt,updatedAt,deletedAt);

@override
String toString() {
  return 'PostModel(postId: $postId, userId: $userId, userProfiles: $userProfiles, boardId: $boardId, title: $title, content: $content, viewCount: $viewCount, replyCount: $replyCount, isHidden: $isHidden, board: $board, isAnonymous: $isAnonymous, isScraped: $isScraped, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$PostModelCopyWith<$Res> implements $PostModelCopyWith<$Res> {
  factory _$PostModelCopyWith(_PostModel value, $Res Function(_PostModel) _then) = __$PostModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'post_id') String postId,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'user_profiles') UserProfilesModel? userProfiles,@JsonKey(name: 'board_id') String? boardId,@JsonKey(name: 'title') String? title,@JsonKey(name: 'content') List<dynamic>? content,@JsonKey(name: 'view_count') int? viewCount,@JsonKey(name: 'reply_count') int? replyCount,@JsonKey(name: 'is_hidden') bool? isHidden,@JsonKey(name: 'boards') BoardModel? board,@JsonKey(name: 'is_anonymous') bool? isAnonymous,@JsonKey(name: 'is_scraped') bool? isScraped,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt
});


@override $UserProfilesModelCopyWith<$Res>? get userProfiles;@override $BoardModelCopyWith<$Res>? get board;

}
/// @nodoc
class __$PostModelCopyWithImpl<$Res>
    implements _$PostModelCopyWith<$Res> {
  __$PostModelCopyWithImpl(this._self, this._then);

  final _PostModel _self;
  final $Res Function(_PostModel) _then;

/// Create a copy of PostModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? postId = null,Object? userId = freezed,Object? userProfiles = freezed,Object? boardId = freezed,Object? title = freezed,Object? content = freezed,Object? viewCount = freezed,Object? replyCount = freezed,Object? isHidden = freezed,Object? board = freezed,Object? isAnonymous = freezed,Object? isScraped = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? deletedAt = freezed,}) {
  return _then(_PostModel(
postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,userProfiles: freezed == userProfiles ? _self.userProfiles : userProfiles // ignore: cast_nullable_to_non_nullable
as UserProfilesModel?,boardId: freezed == boardId ? _self.boardId : boardId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,replyCount: freezed == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int?,isHidden: freezed == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool?,board: freezed == board ? _self.board : board // ignore: cast_nullable_to_non_nullable
as BoardModel?,isAnonymous: freezed == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool?,isScraped: freezed == isScraped ? _self.isScraped : isScraped // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of PostModel
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
}/// Create a copy of PostModel
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
}
}

// dart format on
