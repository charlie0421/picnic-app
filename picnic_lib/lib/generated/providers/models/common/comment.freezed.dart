// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/common/comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentModel {

@JsonKey(name: 'comment_id') String get commentId;@JsonKey(name: 'user_id') String? get userId; List<CommentModel>? get children; UserCommentLikeModel? get myLike;@JsonKey(name: 'user_profiles') UserProfilesModel? get user; int get likes; int get replies; Map<String, dynamic>? get content; bool? get isLikedByMe; bool? get isReportedByMe; bool? get isBlindedByAdmin; bool? get isRepliedByMe; PostModel? get post; String? get locale;@JsonKey(name: 'parent_comment_id') String? get parentCommentId;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'deleted_at') DateTime? get deletedAt;
/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentModelCopyWith<CommentModel> get copyWith => _$CommentModelCopyWithImpl<CommentModel>(this as CommentModel, _$identity);

  /// Serializes this CommentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentModel&&(identical(other.commentId, commentId) || other.commentId == commentId)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other.children, children)&&(identical(other.myLike, myLike) || other.myLike == myLike)&&(identical(other.user, user) || other.user == user)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.replies, replies) || other.replies == replies)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.isLikedByMe, isLikedByMe) || other.isLikedByMe == isLikedByMe)&&(identical(other.isReportedByMe, isReportedByMe) || other.isReportedByMe == isReportedByMe)&&(identical(other.isBlindedByAdmin, isBlindedByAdmin) || other.isBlindedByAdmin == isBlindedByAdmin)&&(identical(other.isRepliedByMe, isRepliedByMe) || other.isRepliedByMe == isRepliedByMe)&&(identical(other.post, post) || other.post == post)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.parentCommentId, parentCommentId) || other.parentCommentId == parentCommentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,commentId,userId,const DeepCollectionEquality().hash(children),myLike,user,likes,replies,const DeepCollectionEquality().hash(content),isLikedByMe,isReportedByMe,isBlindedByAdmin,isRepliedByMe,post,locale,parentCommentId,createdAt,updatedAt,deletedAt);

@override
String toString() {
  return 'CommentModel(commentId: $commentId, userId: $userId, children: $children, myLike: $myLike, user: $user, likes: $likes, replies: $replies, content: $content, isLikedByMe: $isLikedByMe, isReportedByMe: $isReportedByMe, isBlindedByAdmin: $isBlindedByAdmin, isRepliedByMe: $isRepliedByMe, post: $post, locale: $locale, parentCommentId: $parentCommentId, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $CommentModelCopyWith<$Res>  {
  factory $CommentModelCopyWith(CommentModel value, $Res Function(CommentModel) _then) = _$CommentModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'comment_id') String commentId,@JsonKey(name: 'user_id') String? userId, List<CommentModel>? children, UserCommentLikeModel? myLike,@JsonKey(name: 'user_profiles') UserProfilesModel? user, int likes, int replies, Map<String, dynamic>? content, bool? isLikedByMe, bool? isReportedByMe, bool? isBlindedByAdmin, bool? isRepliedByMe, PostModel? post, String? locale,@JsonKey(name: 'parent_comment_id') String? parentCommentId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt
});


$UserCommentLikeModelCopyWith<$Res>? get myLike;$UserProfilesModelCopyWith<$Res>? get user;$PostModelCopyWith<$Res>? get post;

}
/// @nodoc
class _$CommentModelCopyWithImpl<$Res>
    implements $CommentModelCopyWith<$Res> {
  _$CommentModelCopyWithImpl(this._self, this._then);

  final CommentModel _self;
  final $Res Function(CommentModel) _then;

/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? commentId = null,Object? userId = freezed,Object? children = freezed,Object? myLike = freezed,Object? user = freezed,Object? likes = null,Object? replies = null,Object? content = freezed,Object? isLikedByMe = freezed,Object? isReportedByMe = freezed,Object? isBlindedByAdmin = freezed,Object? isRepliedByMe = freezed,Object? post = freezed,Object? locale = freezed,Object? parentCommentId = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
commentId: null == commentId ? _self.commentId : commentId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,children: freezed == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<CommentModel>?,myLike: freezed == myLike ? _self.myLike : myLike // ignore: cast_nullable_to_non_nullable
as UserCommentLikeModel?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserProfilesModel?,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as int,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as int,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isLikedByMe: freezed == isLikedByMe ? _self.isLikedByMe : isLikedByMe // ignore: cast_nullable_to_non_nullable
as bool?,isReportedByMe: freezed == isReportedByMe ? _self.isReportedByMe : isReportedByMe // ignore: cast_nullable_to_non_nullable
as bool?,isBlindedByAdmin: freezed == isBlindedByAdmin ? _self.isBlindedByAdmin : isBlindedByAdmin // ignore: cast_nullable_to_non_nullable
as bool?,isRepliedByMe: freezed == isRepliedByMe ? _self.isRepliedByMe : isRepliedByMe // ignore: cast_nullable_to_non_nullable
as bool?,post: freezed == post ? _self.post : post // ignore: cast_nullable_to_non_nullable
as PostModel?,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String?,parentCommentId: freezed == parentCommentId ? _self.parentCommentId : parentCommentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCommentLikeModelCopyWith<$Res>? get myLike {
    if (_self.myLike == null) {
    return null;
  }

  return $UserCommentLikeModelCopyWith<$Res>(_self.myLike!, (value) {
    return _then(_self.copyWith(myLike: value));
  });
}/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfilesModelCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserProfilesModelCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of CommentModel
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


/// Adds pattern-matching-related methods to [CommentModel].
extension CommentModelPatterns on CommentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentModel value)  $default,){
final _that = this;
switch (_that) {
case _CommentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentModel value)?  $default,){
final _that = this;
switch (_that) {
case _CommentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'comment_id')  String commentId, @JsonKey(name: 'user_id')  String? userId,  List<CommentModel>? children,  UserCommentLikeModel? myLike, @JsonKey(name: 'user_profiles')  UserProfilesModel? user,  int likes,  int replies,  Map<String, dynamic>? content,  bool? isLikedByMe,  bool? isReportedByMe,  bool? isBlindedByAdmin,  bool? isRepliedByMe,  PostModel? post,  String? locale, @JsonKey(name: 'parent_comment_id')  String? parentCommentId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentModel() when $default != null:
return $default(_that.commentId,_that.userId,_that.children,_that.myLike,_that.user,_that.likes,_that.replies,_that.content,_that.isLikedByMe,_that.isReportedByMe,_that.isBlindedByAdmin,_that.isRepliedByMe,_that.post,_that.locale,_that.parentCommentId,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'comment_id')  String commentId, @JsonKey(name: 'user_id')  String? userId,  List<CommentModel>? children,  UserCommentLikeModel? myLike, @JsonKey(name: 'user_profiles')  UserProfilesModel? user,  int likes,  int replies,  Map<String, dynamic>? content,  bool? isLikedByMe,  bool? isReportedByMe,  bool? isBlindedByAdmin,  bool? isRepliedByMe,  PostModel? post,  String? locale, @JsonKey(name: 'parent_comment_id')  String? parentCommentId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _CommentModel():
return $default(_that.commentId,_that.userId,_that.children,_that.myLike,_that.user,_that.likes,_that.replies,_that.content,_that.isLikedByMe,_that.isReportedByMe,_that.isBlindedByAdmin,_that.isRepliedByMe,_that.post,_that.locale,_that.parentCommentId,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'comment_id')  String commentId, @JsonKey(name: 'user_id')  String? userId,  List<CommentModel>? children,  UserCommentLikeModel? myLike, @JsonKey(name: 'user_profiles')  UserProfilesModel? user,  int likes,  int replies,  Map<String, dynamic>? content,  bool? isLikedByMe,  bool? isReportedByMe,  bool? isBlindedByAdmin,  bool? isRepliedByMe,  PostModel? post,  String? locale, @JsonKey(name: 'parent_comment_id')  String? parentCommentId, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _CommentModel() when $default != null:
return $default(_that.commentId,_that.userId,_that.children,_that.myLike,_that.user,_that.likes,_that.replies,_that.content,_that.isLikedByMe,_that.isReportedByMe,_that.isBlindedByAdmin,_that.isRepliedByMe,_that.post,_that.locale,_that.parentCommentId,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentModel extends CommentModel {
  const _CommentModel({@JsonKey(name: 'comment_id') required this.commentId, @JsonKey(name: 'user_id') this.userId, required final  List<CommentModel>? children, required this.myLike, @JsonKey(name: 'user_profiles') required this.user, required this.likes, required this.replies, required final  Map<String, dynamic>? content, required this.isLikedByMe, required this.isReportedByMe, required this.isBlindedByAdmin, required this.isRepliedByMe, required this.post, required this.locale, @JsonKey(name: 'parent_comment_id') required this.parentCommentId, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'deleted_at') this.deletedAt}): _children = children,_content = content,super._();
  factory _CommentModel.fromJson(Map<String, dynamic> json) => _$CommentModelFromJson(json);

@override@JsonKey(name: 'comment_id') final  String commentId;
@override@JsonKey(name: 'user_id') final  String? userId;
 final  List<CommentModel>? _children;
@override List<CommentModel>? get children {
  final value = _children;
  if (value == null) return null;
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  UserCommentLikeModel? myLike;
@override@JsonKey(name: 'user_profiles') final  UserProfilesModel? user;
@override final  int likes;
@override final  int replies;
 final  Map<String, dynamic>? _content;
@override Map<String, dynamic>? get content {
  final value = _content;
  if (value == null) return null;
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  bool? isLikedByMe;
@override final  bool? isReportedByMe;
@override final  bool? isBlindedByAdmin;
@override final  bool? isRepliedByMe;
@override final  PostModel? post;
@override final  String? locale;
@override@JsonKey(name: 'parent_comment_id') final  String? parentCommentId;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;

/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentModelCopyWith<_CommentModel> get copyWith => __$CommentModelCopyWithImpl<_CommentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentModel&&(identical(other.commentId, commentId) || other.commentId == commentId)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.myLike, myLike) || other.myLike == myLike)&&(identical(other.user, user) || other.user == user)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.replies, replies) || other.replies == replies)&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.isLikedByMe, isLikedByMe) || other.isLikedByMe == isLikedByMe)&&(identical(other.isReportedByMe, isReportedByMe) || other.isReportedByMe == isReportedByMe)&&(identical(other.isBlindedByAdmin, isBlindedByAdmin) || other.isBlindedByAdmin == isBlindedByAdmin)&&(identical(other.isRepliedByMe, isRepliedByMe) || other.isRepliedByMe == isRepliedByMe)&&(identical(other.post, post) || other.post == post)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.parentCommentId, parentCommentId) || other.parentCommentId == parentCommentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,commentId,userId,const DeepCollectionEquality().hash(_children),myLike,user,likes,replies,const DeepCollectionEquality().hash(_content),isLikedByMe,isReportedByMe,isBlindedByAdmin,isRepliedByMe,post,locale,parentCommentId,createdAt,updatedAt,deletedAt);

@override
String toString() {
  return 'CommentModel(commentId: $commentId, userId: $userId, children: $children, myLike: $myLike, user: $user, likes: $likes, replies: $replies, content: $content, isLikedByMe: $isLikedByMe, isReportedByMe: $isReportedByMe, isBlindedByAdmin: $isBlindedByAdmin, isRepliedByMe: $isRepliedByMe, post: $post, locale: $locale, parentCommentId: $parentCommentId, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$CommentModelCopyWith<$Res> implements $CommentModelCopyWith<$Res> {
  factory _$CommentModelCopyWith(_CommentModel value, $Res Function(_CommentModel) _then) = __$CommentModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'comment_id') String commentId,@JsonKey(name: 'user_id') String? userId, List<CommentModel>? children, UserCommentLikeModel? myLike,@JsonKey(name: 'user_profiles') UserProfilesModel? user, int likes, int replies, Map<String, dynamic>? content, bool? isLikedByMe, bool? isReportedByMe, bool? isBlindedByAdmin, bool? isRepliedByMe, PostModel? post, String? locale,@JsonKey(name: 'parent_comment_id') String? parentCommentId,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt
});


@override $UserCommentLikeModelCopyWith<$Res>? get myLike;@override $UserProfilesModelCopyWith<$Res>? get user;@override $PostModelCopyWith<$Res>? get post;

}
/// @nodoc
class __$CommentModelCopyWithImpl<$Res>
    implements _$CommentModelCopyWith<$Res> {
  __$CommentModelCopyWithImpl(this._self, this._then);

  final _CommentModel _self;
  final $Res Function(_CommentModel) _then;

/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? commentId = null,Object? userId = freezed,Object? children = freezed,Object? myLike = freezed,Object? user = freezed,Object? likes = null,Object? replies = null,Object? content = freezed,Object? isLikedByMe = freezed,Object? isReportedByMe = freezed,Object? isBlindedByAdmin = freezed,Object? isRepliedByMe = freezed,Object? post = freezed,Object? locale = freezed,Object? parentCommentId = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(_CommentModel(
commentId: null == commentId ? _self.commentId : commentId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,children: freezed == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<CommentModel>?,myLike: freezed == myLike ? _self.myLike : myLike // ignore: cast_nullable_to_non_nullable
as UserCommentLikeModel?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserProfilesModel?,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as int,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as int,content: freezed == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isLikedByMe: freezed == isLikedByMe ? _self.isLikedByMe : isLikedByMe // ignore: cast_nullable_to_non_nullable
as bool?,isReportedByMe: freezed == isReportedByMe ? _self.isReportedByMe : isReportedByMe // ignore: cast_nullable_to_non_nullable
as bool?,isBlindedByAdmin: freezed == isBlindedByAdmin ? _self.isBlindedByAdmin : isBlindedByAdmin // ignore: cast_nullable_to_non_nullable
as bool?,isRepliedByMe: freezed == isRepliedByMe ? _self.isRepliedByMe : isRepliedByMe // ignore: cast_nullable_to_non_nullable
as bool?,post: freezed == post ? _self.post : post // ignore: cast_nullable_to_non_nullable
as PostModel?,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String?,parentCommentId: freezed == parentCommentId ? _self.parentCommentId : parentCommentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCommentLikeModelCopyWith<$Res>? get myLike {
    if (_self.myLike == null) {
    return null;
  }

  return $UserCommentLikeModelCopyWith<$Res>(_self.myLike!, (value) {
    return _then(_self.copyWith(myLike: value));
  });
}/// Create a copy of CommentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserProfilesModelCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserProfilesModelCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of CommentModel
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
