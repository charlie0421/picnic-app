// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PostModel _$PostModelFromJson(Map<String, dynamic> json) {
  return _PostModel.fromJson(json);
}

/// @nodoc
mixin _$PostModel {
  @JsonKey(name: 'post_id')
  String get postId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_profiles')
  UserProfilesModel? get userProfiles => throw _privateConstructorUsedError;
  @JsonKey(name: 'board_id')
  String? get boardId => throw _privateConstructorUsedError;
  @JsonKey(name: 'title')
  String? get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'content')
  List<dynamic>? get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'view_count')
  int? get viewCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'reply_count')
  int? get replyCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_hidden')
  bool? get isHidden => throw _privateConstructorUsedError;
  @JsonKey(name: 'board')
  BoardModel? get board => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_anonymous')
  bool? get isAnonymous => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_scraped')
  bool? get isScraped => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  /// Serializes this PostModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostModelCopyWith<PostModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostModelCopyWith<$Res> {
  factory $PostModelCopyWith(PostModel value, $Res Function(PostModel) then) =
      _$PostModelCopyWithImpl<$Res, PostModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'post_id') String postId,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'user_profiles') UserProfilesModel? userProfiles,
      @JsonKey(name: 'board_id') String? boardId,
      @JsonKey(name: 'title') String? title,
      @JsonKey(name: 'content') List<dynamic>? content,
      @JsonKey(name: 'view_count') int? viewCount,
      @JsonKey(name: 'reply_count') int? replyCount,
      @JsonKey(name: 'is_hidden') bool? isHidden,
      @JsonKey(name: 'board') BoardModel? board,
      @JsonKey(name: 'is_anonymous') bool? isAnonymous,
      @JsonKey(name: 'is_scraped') bool? isScraped,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt});

  $UserProfilesModelCopyWith<$Res>? get userProfiles;
  $BoardModelCopyWith<$Res>? get board;
}

/// @nodoc
class _$PostModelCopyWithImpl<$Res, $Val extends PostModel>
    implements $PostModelCopyWith<$Res> {
  _$PostModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postId = null,
    Object? userId = freezed,
    Object? userProfiles = freezed,
    Object? boardId = freezed,
    Object? title = freezed,
    Object? content = freezed,
    Object? viewCount = freezed,
    Object? replyCount = freezed,
    Object? isHidden = freezed,
    Object? board = freezed,
    Object? isAnonymous = freezed,
    Object? isScraped = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_value.copyWith(
      postId: null == postId
          ? _value.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      userProfiles: freezed == userProfiles
          ? _value.userProfiles
          : userProfiles // ignore: cast_nullable_to_non_nullable
              as UserProfilesModel?,
      boardId: freezed == boardId
          ? _value.boardId
          : boardId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      viewCount: freezed == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int?,
      replyCount: freezed == replyCount
          ? _value.replyCount
          : replyCount // ignore: cast_nullable_to_non_nullable
              as int?,
      isHidden: freezed == isHidden
          ? _value.isHidden
          : isHidden // ignore: cast_nullable_to_non_nullable
              as bool?,
      board: freezed == board
          ? _value.board
          : board // ignore: cast_nullable_to_non_nullable
              as BoardModel?,
      isAnonymous: freezed == isAnonymous
          ? _value.isAnonymous
          : isAnonymous // ignore: cast_nullable_to_non_nullable
              as bool?,
      isScraped: freezed == isScraped
          ? _value.isScraped
          : isScraped // ignore: cast_nullable_to_non_nullable
              as bool?,
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

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserProfilesModelCopyWith<$Res>? get userProfiles {
    if (_value.userProfiles == null) {
      return null;
    }

    return $UserProfilesModelCopyWith<$Res>(_value.userProfiles!, (value) {
      return _then(_value.copyWith(userProfiles: value) as $Val);
    });
  }

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BoardModelCopyWith<$Res>? get board {
    if (_value.board == null) {
      return null;
    }

    return $BoardModelCopyWith<$Res>(_value.board!, (value) {
      return _then(_value.copyWith(board: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PostModelImplCopyWith<$Res>
    implements $PostModelCopyWith<$Res> {
  factory _$$PostModelImplCopyWith(
          _$PostModelImpl value, $Res Function(_$PostModelImpl) then) =
      __$$PostModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'post_id') String postId,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'user_profiles') UserProfilesModel? userProfiles,
      @JsonKey(name: 'board_id') String? boardId,
      @JsonKey(name: 'title') String? title,
      @JsonKey(name: 'content') List<dynamic>? content,
      @JsonKey(name: 'view_count') int? viewCount,
      @JsonKey(name: 'reply_count') int? replyCount,
      @JsonKey(name: 'is_hidden') bool? isHidden,
      @JsonKey(name: 'board') BoardModel? board,
      @JsonKey(name: 'is_anonymous') bool? isAnonymous,
      @JsonKey(name: 'is_scraped') bool? isScraped,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt});

  @override
  $UserProfilesModelCopyWith<$Res>? get userProfiles;
  @override
  $BoardModelCopyWith<$Res>? get board;
}

/// @nodoc
class __$$PostModelImplCopyWithImpl<$Res>
    extends _$PostModelCopyWithImpl<$Res, _$PostModelImpl>
    implements _$$PostModelImplCopyWith<$Res> {
  __$$PostModelImplCopyWithImpl(
      _$PostModelImpl _value, $Res Function(_$PostModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postId = null,
    Object? userId = freezed,
    Object? userProfiles = freezed,
    Object? boardId = freezed,
    Object? title = freezed,
    Object? content = freezed,
    Object? viewCount = freezed,
    Object? replyCount = freezed,
    Object? isHidden = freezed,
    Object? board = freezed,
    Object? isAnonymous = freezed,
    Object? isScraped = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_$PostModelImpl(
      postId: null == postId
          ? _value.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      userProfiles: freezed == userProfiles
          ? _value.userProfiles
          : userProfiles // ignore: cast_nullable_to_non_nullable
              as UserProfilesModel?,
      boardId: freezed == boardId
          ? _value.boardId
          : boardId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      content: freezed == content
          ? _value._content
          : content // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      viewCount: freezed == viewCount
          ? _value.viewCount
          : viewCount // ignore: cast_nullable_to_non_nullable
              as int?,
      replyCount: freezed == replyCount
          ? _value.replyCount
          : replyCount // ignore: cast_nullable_to_non_nullable
              as int?,
      isHidden: freezed == isHidden
          ? _value.isHidden
          : isHidden // ignore: cast_nullable_to_non_nullable
              as bool?,
      board: freezed == board
          ? _value.board
          : board // ignore: cast_nullable_to_non_nullable
              as BoardModel?,
      isAnonymous: freezed == isAnonymous
          ? _value.isAnonymous
          : isAnonymous // ignore: cast_nullable_to_non_nullable
              as bool?,
      isScraped: freezed == isScraped
          ? _value.isScraped
          : isScraped // ignore: cast_nullable_to_non_nullable
              as bool?,
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
class _$PostModelImpl extends _PostModel {
  const _$PostModelImpl(
      {@JsonKey(name: 'post_id') required this.postId,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'user_profiles') required this.userProfiles,
      @JsonKey(name: 'board_id') required this.boardId,
      @JsonKey(name: 'title') required this.title,
      @JsonKey(name: 'content') required final List<dynamic>? content,
      @JsonKey(name: 'view_count') required this.viewCount,
      @JsonKey(name: 'reply_count') required this.replyCount,
      @JsonKey(name: 'is_hidden') required this.isHidden,
      @JsonKey(name: 'board') required this.board,
      @JsonKey(name: 'is_anonymous') required this.isAnonymous,
      @JsonKey(name: 'is_scraped') required this.isScraped,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'deleted_at') this.deletedAt})
      : _content = content,
        super._();

  factory _$PostModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostModelImplFromJson(json);

  @override
  @JsonKey(name: 'post_id')
  final String postId;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
  @override
  @JsonKey(name: 'user_profiles')
  final UserProfilesModel? userProfiles;
  @override
  @JsonKey(name: 'board_id')
  final String? boardId;
  @override
  @JsonKey(name: 'title')
  final String? title;
  final List<dynamic>? _content;
  @override
  @JsonKey(name: 'content')
  List<dynamic>? get content {
    final value = _content;
    if (value == null) return null;
    if (_content is EqualUnmodifiableListView) return _content;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'view_count')
  final int? viewCount;
  @override
  @JsonKey(name: 'reply_count')
  final int? replyCount;
  @override
  @JsonKey(name: 'is_hidden')
  final bool? isHidden;
  @override
  @JsonKey(name: 'board')
  final BoardModel? board;
  @override
  @JsonKey(name: 'is_anonymous')
  final bool? isAnonymous;
  @override
  @JsonKey(name: 'is_scraped')
  final bool? isScraped;
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
    return 'PostModel(postId: $postId, userId: $userId, userProfiles: $userProfiles, boardId: $boardId, title: $title, content: $content, viewCount: $viewCount, replyCount: $replyCount, isHidden: $isHidden, board: $board, isAnonymous: $isAnonymous, isScraped: $isScraped, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostModelImpl &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userProfiles, userProfiles) ||
                other.userProfiles == userProfiles) &&
            (identical(other.boardId, boardId) || other.boardId == boardId) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._content, _content) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.replyCount, replyCount) ||
                other.replyCount == replyCount) &&
            (identical(other.isHidden, isHidden) ||
                other.isHidden == isHidden) &&
            (identical(other.board, board) || other.board == board) &&
            (identical(other.isAnonymous, isAnonymous) ||
                other.isAnonymous == isAnonymous) &&
            (identical(other.isScraped, isScraped) ||
                other.isScraped == isScraped) &&
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
      postId,
      userId,
      userProfiles,
      boardId,
      title,
      const DeepCollectionEquality().hash(_content),
      viewCount,
      replyCount,
      isHidden,
      board,
      isAnonymous,
      isScraped,
      createdAt,
      updatedAt,
      deletedAt);

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostModelImplCopyWith<_$PostModelImpl> get copyWith =>
      __$$PostModelImplCopyWithImpl<_$PostModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostModelImplToJson(
      this,
    );
  }
}

abstract class _PostModel extends PostModel {
  const factory _PostModel(
          {@JsonKey(name: 'post_id') required final String postId,
          @JsonKey(name: 'user_id') required final String? userId,
          @JsonKey(name: 'user_profiles')
          required final UserProfilesModel? userProfiles,
          @JsonKey(name: 'board_id') required final String? boardId,
          @JsonKey(name: 'title') required final String? title,
          @JsonKey(name: 'content') required final List<dynamic>? content,
          @JsonKey(name: 'view_count') required final int? viewCount,
          @JsonKey(name: 'reply_count') required final int? replyCount,
          @JsonKey(name: 'is_hidden') required final bool? isHidden,
          @JsonKey(name: 'board') required final BoardModel? board,
          @JsonKey(name: 'is_anonymous') required final bool? isAnonymous,
          @JsonKey(name: 'is_scraped') required final bool? isScraped,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt,
          @JsonKey(name: 'deleted_at') final DateTime? deletedAt}) =
      _$PostModelImpl;
  const _PostModel._() : super._();

  factory _PostModel.fromJson(Map<String, dynamic> json) =
      _$PostModelImpl.fromJson;

  @override
  @JsonKey(name: 'post_id')
  String get postId;
  @override
  @JsonKey(name: 'user_id')
  String? get userId;
  @override
  @JsonKey(name: 'user_profiles')
  UserProfilesModel? get userProfiles;
  @override
  @JsonKey(name: 'board_id')
  String? get boardId;
  @override
  @JsonKey(name: 'title')
  String? get title;
  @override
  @JsonKey(name: 'content')
  List<dynamic>? get content;
  @override
  @JsonKey(name: 'view_count')
  int? get viewCount;
  @override
  @JsonKey(name: 'reply_count')
  int? get replyCount;
  @override
  @JsonKey(name: 'is_hidden')
  bool? get isHidden;
  @override
  @JsonKey(name: 'board')
  BoardModel? get board;
  @override
  @JsonKey(name: 'is_anonymous')
  bool? get isAnonymous;
  @override
  @JsonKey(name: 'is_scraped')
  bool? get isScraped;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostModelImplCopyWith<_$PostModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
