// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) {
  return _CommentModel.fromJson(json);
}

/// @nodoc
mixin _$CommentModel {
  @JsonKey(name: 'comment_id')
  String get commentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError;
  List<CommentModel>? get children => throw _privateConstructorUsedError;
  UserCommentLikeModel? get myLike => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_profiles')
  UserProfilesModel? get user => throw _privateConstructorUsedError;
  int get likes => throw _privateConstructorUsedError;
  int get replies => throw _privateConstructorUsedError;
  Map<String, dynamic>? get content => throw _privateConstructorUsedError;
  bool? get isLikedByMe => throw _privateConstructorUsedError;
  bool? get isReportedByMe => throw _privateConstructorUsedError;
  bool? get isBlindedByAdmin => throw _privateConstructorUsedError;
  bool? get isRepliedByMe => throw _privateConstructorUsedError;
  PostModel? get post => throw _privateConstructorUsedError;
  String? get locale => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_comment_id')
  String? get parentCommentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  /// Serializes this CommentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentModelCopyWith<CommentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentModelCopyWith<$Res> {
  factory $CommentModelCopyWith(
          CommentModel value, $Res Function(CommentModel) then) =
      _$CommentModelCopyWithImpl<$Res, CommentModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'comment_id') String commentId,
      @JsonKey(name: 'user_id') String? userId,
      List<CommentModel>? children,
      UserCommentLikeModel? myLike,
      @JsonKey(name: 'user_profiles') UserProfilesModel? user,
      int likes,
      int replies,
      Map<String, dynamic>? content,
      bool? isLikedByMe,
      bool? isReportedByMe,
      bool? isBlindedByAdmin,
      bool? isRepliedByMe,
      PostModel? post,
      String? locale,
      @JsonKey(name: 'parent_comment_id') String? parentCommentId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt});

  $UserCommentLikeModelCopyWith<$Res>? get myLike;
  $UserProfilesModelCopyWith<$Res>? get user;
  $PostModelCopyWith<$Res>? get post;
}

/// @nodoc
class _$CommentModelCopyWithImpl<$Res, $Val extends CommentModel>
    implements $CommentModelCopyWith<$Res> {
  _$CommentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commentId = null,
    Object? userId = freezed,
    Object? children = freezed,
    Object? myLike = freezed,
    Object? user = freezed,
    Object? likes = null,
    Object? replies = null,
    Object? content = freezed,
    Object? isLikedByMe = freezed,
    Object? isReportedByMe = freezed,
    Object? isBlindedByAdmin = freezed,
    Object? isRepliedByMe = freezed,
    Object? post = freezed,
    Object? locale = freezed,
    Object? parentCommentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_value.copyWith(
      commentId: null == commentId
          ? _value.commentId
          : commentId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      children: freezed == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>?,
      myLike: freezed == myLike
          ? _value.myLike
          : myLike // ignore: cast_nullable_to_non_nullable
              as UserCommentLikeModel?,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserProfilesModel?,
      likes: null == likes
          ? _value.likes
          : likes // ignore: cast_nullable_to_non_nullable
              as int,
      replies: null == replies
          ? _value.replies
          : replies // ignore: cast_nullable_to_non_nullable
              as int,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      isLikedByMe: freezed == isLikedByMe
          ? _value.isLikedByMe
          : isLikedByMe // ignore: cast_nullable_to_non_nullable
              as bool?,
      isReportedByMe: freezed == isReportedByMe
          ? _value.isReportedByMe
          : isReportedByMe // ignore: cast_nullable_to_non_nullable
              as bool?,
      isBlindedByAdmin: freezed == isBlindedByAdmin
          ? _value.isBlindedByAdmin
          : isBlindedByAdmin // ignore: cast_nullable_to_non_nullable
              as bool?,
      isRepliedByMe: freezed == isRepliedByMe
          ? _value.isRepliedByMe
          : isRepliedByMe // ignore: cast_nullable_to_non_nullable
              as bool?,
      post: freezed == post
          ? _value.post
          : post // ignore: cast_nullable_to_non_nullable
              as PostModel?,
      locale: freezed == locale
          ? _value.locale
          : locale // ignore: cast_nullable_to_non_nullable
              as String?,
      parentCommentId: freezed == parentCommentId
          ? _value.parentCommentId
          : parentCommentId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCommentLikeModelCopyWith<$Res>? get myLike {
    if (_value.myLike == null) {
      return null;
    }

    return $UserCommentLikeModelCopyWith<$Res>(_value.myLike!, (value) {
      return _then(_value.copyWith(myLike: value) as $Val);
    });
  }

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserProfilesModelCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $UserProfilesModelCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PostModelCopyWith<$Res>? get post {
    if (_value.post == null) {
      return null;
    }

    return $PostModelCopyWith<$Res>(_value.post!, (value) {
      return _then(_value.copyWith(post: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommentModelImplCopyWith<$Res>
    implements $CommentModelCopyWith<$Res> {
  factory _$$CommentModelImplCopyWith(
          _$CommentModelImpl value, $Res Function(_$CommentModelImpl) then) =
      __$$CommentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'comment_id') String commentId,
      @JsonKey(name: 'user_id') String? userId,
      List<CommentModel>? children,
      UserCommentLikeModel? myLike,
      @JsonKey(name: 'user_profiles') UserProfilesModel? user,
      int likes,
      int replies,
      Map<String, dynamic>? content,
      bool? isLikedByMe,
      bool? isReportedByMe,
      bool? isBlindedByAdmin,
      bool? isRepliedByMe,
      PostModel? post,
      String? locale,
      @JsonKey(name: 'parent_comment_id') String? parentCommentId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt});

  @override
  $UserCommentLikeModelCopyWith<$Res>? get myLike;
  @override
  $UserProfilesModelCopyWith<$Res>? get user;
  @override
  $PostModelCopyWith<$Res>? get post;
}

/// @nodoc
class __$$CommentModelImplCopyWithImpl<$Res>
    extends _$CommentModelCopyWithImpl<$Res, _$CommentModelImpl>
    implements _$$CommentModelImplCopyWith<$Res> {
  __$$CommentModelImplCopyWithImpl(
      _$CommentModelImpl _value, $Res Function(_$CommentModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commentId = null,
    Object? userId = freezed,
    Object? children = freezed,
    Object? myLike = freezed,
    Object? user = freezed,
    Object? likes = null,
    Object? replies = null,
    Object? content = freezed,
    Object? isLikedByMe = freezed,
    Object? isReportedByMe = freezed,
    Object? isBlindedByAdmin = freezed,
    Object? isRepliedByMe = freezed,
    Object? post = freezed,
    Object? locale = freezed,
    Object? parentCommentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_$CommentModelImpl(
      commentId: null == commentId
          ? _value.commentId
          : commentId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      children: freezed == children
          ? _value._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>?,
      myLike: freezed == myLike
          ? _value.myLike
          : myLike // ignore: cast_nullable_to_non_nullable
              as UserCommentLikeModel?,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserProfilesModel?,
      likes: null == likes
          ? _value.likes
          : likes // ignore: cast_nullable_to_non_nullable
              as int,
      replies: null == replies
          ? _value.replies
          : replies // ignore: cast_nullable_to_non_nullable
              as int,
      content: freezed == content
          ? _value._content
          : content // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      isLikedByMe: freezed == isLikedByMe
          ? _value.isLikedByMe
          : isLikedByMe // ignore: cast_nullable_to_non_nullable
              as bool?,
      isReportedByMe: freezed == isReportedByMe
          ? _value.isReportedByMe
          : isReportedByMe // ignore: cast_nullable_to_non_nullable
              as bool?,
      isBlindedByAdmin: freezed == isBlindedByAdmin
          ? _value.isBlindedByAdmin
          : isBlindedByAdmin // ignore: cast_nullable_to_non_nullable
              as bool?,
      isRepliedByMe: freezed == isRepliedByMe
          ? _value.isRepliedByMe
          : isRepliedByMe // ignore: cast_nullable_to_non_nullable
              as bool?,
      post: freezed == post
          ? _value.post
          : post // ignore: cast_nullable_to_non_nullable
              as PostModel?,
      locale: freezed == locale
          ? _value.locale
          : locale // ignore: cast_nullable_to_non_nullable
              as String?,
      parentCommentId: freezed == parentCommentId
          ? _value.parentCommentId
          : parentCommentId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentModelImpl extends _CommentModel {
  const _$CommentModelImpl(
      {@JsonKey(name: 'comment_id') required this.commentId,
      @JsonKey(name: 'user_id') this.userId,
      required final List<CommentModel>? children,
      required this.myLike,
      @JsonKey(name: 'user_profiles') required this.user,
      required this.likes,
      required this.replies,
      required final Map<String, dynamic>? content,
      required this.isLikedByMe,
      required this.isReportedByMe,
      required this.isBlindedByAdmin,
      required this.isRepliedByMe,
      required this.post,
      required this.locale,
      @JsonKey(name: 'parent_comment_id') required this.parentCommentId,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'deleted_at') this.deletedAt})
      : _children = children,
        _content = content,
        super._();

  factory _$CommentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentModelImplFromJson(json);

  @override
  @JsonKey(name: 'comment_id')
  final String commentId;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
  final List<CommentModel>? _children;
  @override
  List<CommentModel>? get children {
    final value = _children;
    if (value == null) return null;
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final UserCommentLikeModel? myLike;
  @override
  @JsonKey(name: 'user_profiles')
  final UserProfilesModel? user;
  @override
  final int likes;
  @override
  final int replies;
  final Map<String, dynamic>? _content;
  @override
  Map<String, dynamic>? get content {
    final value = _content;
    if (value == null) return null;
    if (_content is EqualUnmodifiableMapView) return _content;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final bool? isLikedByMe;
  @override
  final bool? isReportedByMe;
  @override
  final bool? isBlindedByAdmin;
  @override
  final bool? isRepliedByMe;
  @override
  final PostModel? post;
  @override
  final String? locale;
  @override
  @JsonKey(name: 'parent_comment_id')
  final String? parentCommentId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'CommentModel(commentId: $commentId, userId: $userId, children: $children, myLike: $myLike, user: $user, likes: $likes, replies: $replies, content: $content, isLikedByMe: $isLikedByMe, isReportedByMe: $isReportedByMe, isBlindedByAdmin: $isBlindedByAdmin, isRepliedByMe: $isRepliedByMe, post: $post, locale: $locale, parentCommentId: $parentCommentId, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentModelImpl &&
            (identical(other.commentId, commentId) ||
                other.commentId == commentId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            (identical(other.myLike, myLike) || other.myLike == myLike) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.likes, likes) || other.likes == likes) &&
            (identical(other.replies, replies) || other.replies == replies) &&
            const DeepCollectionEquality().equals(other._content, _content) &&
            (identical(other.isLikedByMe, isLikedByMe) ||
                other.isLikedByMe == isLikedByMe) &&
            (identical(other.isReportedByMe, isReportedByMe) ||
                other.isReportedByMe == isReportedByMe) &&
            (identical(other.isBlindedByAdmin, isBlindedByAdmin) ||
                other.isBlindedByAdmin == isBlindedByAdmin) &&
            (identical(other.isRepliedByMe, isRepliedByMe) ||
                other.isRepliedByMe == isRepliedByMe) &&
            (identical(other.post, post) || other.post == post) &&
            (identical(other.locale, locale) || other.locale == locale) &&
            (identical(other.parentCommentId, parentCommentId) ||
                other.parentCommentId == parentCommentId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      commentId,
      userId,
      const DeepCollectionEquality().hash(_children),
      myLike,
      user,
      likes,
      replies,
      const DeepCollectionEquality().hash(_content),
      isLikedByMe,
      isReportedByMe,
      isBlindedByAdmin,
      isRepliedByMe,
      post,
      locale,
      parentCommentId,
      createdAt,
      updatedAt,
      deletedAt);

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentModelImplCopyWith<_$CommentModelImpl> get copyWith =>
      __$$CommentModelImplCopyWithImpl<_$CommentModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentModelImplToJson(
      this,
    );
  }
}

abstract class _CommentModel extends CommentModel {
  const factory _CommentModel(
      {@JsonKey(name: 'comment_id') required final String commentId,
      @JsonKey(name: 'user_id') final String? userId,
      required final List<CommentModel>? children,
      required final UserCommentLikeModel? myLike,
      @JsonKey(name: 'user_profiles') required final UserProfilesModel? user,
      required final int likes,
      required final int replies,
      required final Map<String, dynamic>? content,
      required final bool? isLikedByMe,
      required final bool? isReportedByMe,
      required final bool? isBlindedByAdmin,
      required final bool? isRepliedByMe,
      required final PostModel? post,
      required final String? locale,
      @JsonKey(name: 'parent_comment_id')
      required final String? parentCommentId,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'updated_at') required final DateTime updatedAt,
      @JsonKey(name: 'deleted_at')
      final DateTime? deletedAt}) = _$CommentModelImpl;
  const _CommentModel._() : super._();

  factory _CommentModel.fromJson(Map<String, dynamic> json) =
      _$CommentModelImpl.fromJson;

  @override
  @JsonKey(name: 'comment_id')
  String get commentId;
  @override
  @JsonKey(name: 'user_id')
  String? get userId;
  @override
  List<CommentModel>? get children;
  @override
  UserCommentLikeModel? get myLike;
  @override
  @JsonKey(name: 'user_profiles')
  UserProfilesModel? get user;
  @override
  int get likes;
  @override
  int get replies;
  @override
  Map<String, dynamic>? get content;
  @override
  bool? get isLikedByMe;
  @override
  bool? get isReportedByMe;
  @override
  bool? get isBlindedByAdmin;
  @override
  bool? get isRepliedByMe;
  @override
  PostModel? get post;
  @override
  String? get locale;
  @override
  @JsonKey(name: 'parent_comment_id')
  String? get parentCommentId;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentModelImplCopyWith<_$CommentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
