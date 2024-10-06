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

CommentListModel _$CommentListModelFromJson(Map<String, dynamic> json) {
  return _CommentListModel.fromJson(json);
}

/// @nodoc
mixin _$CommentListModel {
  List<CommentModel> get items => throw _privateConstructorUsedError;
  MetaModel get meta => throw _privateConstructorUsedError;

  /// Serializes this CommentListModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentListModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentListModelCopyWith<CommentListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentListModelCopyWith<$Res> {
  factory $CommentListModelCopyWith(
          CommentListModel value, $Res Function(CommentListModel) then) =
      _$CommentListModelCopyWithImpl<$Res, CommentListModel>;
  @useResult
  $Res call({List<CommentModel> items, MetaModel meta});

  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class _$CommentListModelCopyWithImpl<$Res, $Val extends CommentListModel>
    implements $CommentListModelCopyWith<$Res> {
  _$CommentListModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentListModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ) as $Val);
  }

  /// Create a copy of CommentListModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MetaModelCopyWith<$Res> get meta {
    return $MetaModelCopyWith<$Res>(_value.meta, (value) {
      return _then(_value.copyWith(meta: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommentListModelImplCopyWith<$Res>
    implements $CommentListModelCopyWith<$Res> {
  factory _$$CommentListModelImplCopyWith(_$CommentListModelImpl value,
          $Res Function(_$CommentListModelImpl) then) =
      __$$CommentListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<CommentModel> items, MetaModel meta});

  @override
  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class __$$CommentListModelImplCopyWithImpl<$Res>
    extends _$CommentListModelCopyWithImpl<$Res, _$CommentListModelImpl>
    implements _$$CommentListModelImplCopyWith<$Res> {
  __$$CommentListModelImplCopyWithImpl(_$CommentListModelImpl _value,
      $Res Function(_$CommentListModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of CommentListModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_$CommentListModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentListModelImpl extends _CommentListModel {
  const _$CommentListModelImpl(
      {required final List<CommentModel> items, required this.meta})
      : _items = items,
        super._();

  factory _$CommentListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentListModelImplFromJson(json);

  final List<CommentModel> _items;
  @override
  List<CommentModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final MetaModel meta;

  @override
  String toString() {
    return 'CommentListModel(items: $items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentListModelImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.meta, meta) || other.meta == meta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_items), meta);

  /// Create a copy of CommentListModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentListModelImplCopyWith<_$CommentListModelImpl> get copyWith =>
      __$$CommentListModelImplCopyWithImpl<_$CommentListModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentListModelImplToJson(
      this,
    );
  }
}

abstract class _CommentListModel extends CommentListModel {
  const factory _CommentListModel(
      {required final List<CommentModel> items,
      required final MetaModel meta}) = _$CommentListModelImpl;
  const _CommentListModel._() : super._();

  factory _CommentListModel.fromJson(Map<String, dynamic> json) =
      _$CommentListModelImpl.fromJson;

  @override
  List<CommentModel> get items;
  @override
  MetaModel get meta;

  /// Create a copy of CommentListModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentListModelImplCopyWith<_$CommentListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

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
  UserProfilesModel? get user => throw _privateConstructorUsedError;
  int get likes => throw _privateConstructorUsedError;
  int get replies => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  bool? get isLiked => throw _privateConstructorUsedError;
  bool? get isReplied => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_comment_id')
  String? get parentCommentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

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
      UserProfilesModel? user,
      int likes,
      int replies,
      String content,
      bool? isLiked,
      bool? isReplied,
      @JsonKey(name: 'parent_comment_id') String? parentCommentId,
      @JsonKey(name: 'created_at') DateTime createdAt});

  $UserCommentLikeModelCopyWith<$Res>? get myLike;
  $UserProfilesModelCopyWith<$Res>? get user;
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
    Object? content = null,
    Object? isLiked = freezed,
    Object? isReplied = freezed,
    Object? parentCommentId = freezed,
    Object? createdAt = null,
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      isLiked: freezed == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool?,
      isReplied: freezed == isReplied
          ? _value.isReplied
          : isReplied // ignore: cast_nullable_to_non_nullable
              as bool?,
      parentCommentId: freezed == parentCommentId
          ? _value.parentCommentId
          : parentCommentId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
      UserProfilesModel? user,
      int likes,
      int replies,
      String content,
      bool? isLiked,
      bool? isReplied,
      @JsonKey(name: 'parent_comment_id') String? parentCommentId,
      @JsonKey(name: 'created_at') DateTime createdAt});

  @override
  $UserCommentLikeModelCopyWith<$Res>? get myLike;
  @override
  $UserProfilesModelCopyWith<$Res>? get user;
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
    Object? content = null,
    Object? isLiked = freezed,
    Object? isReplied = freezed,
    Object? parentCommentId = freezed,
    Object? createdAt = null,
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      isLiked: freezed == isLiked
          ? _value.isLiked
          : isLiked // ignore: cast_nullable_to_non_nullable
              as bool?,
      isReplied: freezed == isReplied
          ? _value.isReplied
          : isReplied // ignore: cast_nullable_to_non_nullable
              as bool?,
      parentCommentId: freezed == parentCommentId
          ? _value.parentCommentId
          : parentCommentId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
      required this.user,
      required this.likes,
      required this.replies,
      required this.content,
      required this.isLiked,
      required this.isReplied,
      @JsonKey(name: 'parent_comment_id') required this.parentCommentId,
      @JsonKey(name: 'created_at') required this.createdAt})
      : _children = children,
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
  final UserProfilesModel? user;
  @override
  final int likes;
  @override
  final int replies;
  @override
  final String content;
  @override
  final bool? isLiked;
  @override
  final bool? isReplied;
  @override
  @JsonKey(name: 'parent_comment_id')
  final String? parentCommentId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'CommentModel(commentId: $commentId, userId: $userId, children: $children, myLike: $myLike, user: $user, likes: $likes, replies: $replies, content: $content, isLiked: $isLiked, isReplied: $isReplied, parentCommentId: $parentCommentId, createdAt: $createdAt)';
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
            (identical(other.content, content) || other.content == content) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked) &&
            (identical(other.isReplied, isReplied) ||
                other.isReplied == isReplied) &&
            (identical(other.parentCommentId, parentCommentId) ||
                other.parentCommentId == parentCommentId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
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
      content,
      isLiked,
      isReplied,
      parentCommentId,
      createdAt);

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
          required final UserProfilesModel? user,
          required final int likes,
          required final int replies,
          required final String content,
          required final bool? isLiked,
          required final bool? isReplied,
          @JsonKey(name: 'parent_comment_id')
          required final String? parentCommentId,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$CommentModelImpl;
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
  UserProfilesModel? get user;
  @override
  int get likes;
  @override
  int get replies;
  @override
  String get content;
  @override
  bool? get isLiked;
  @override
  bool? get isReplied;
  @override
  @JsonKey(name: 'parent_comment_id')
  String? get parentCommentId;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of CommentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentModelImplCopyWith<_$CommentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
