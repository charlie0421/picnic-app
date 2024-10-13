// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_scrap.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PostScrapModel _$PostScrapModelFromJson(Map<String, dynamic> json) {
  return _PostScrapModel.fromJson(json);
}

/// @nodoc
mixin _$PostScrapModel {
  @JsonKey(name: 'post_id')
  String get postId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_profiles')
  UserProfilesModel? get userProfiles => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'board')
  BoardModel? get board => throw _privateConstructorUsedError;
  @JsonKey(name: 'post')
  PostModel? get post => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;

  /// Serializes this PostScrapModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostScrapModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostScrapModelCopyWith<PostScrapModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostScrapModelCopyWith<$Res> {
  factory $PostScrapModelCopyWith(
          PostScrapModel value, $Res Function(PostScrapModel) then) =
      _$PostScrapModelCopyWithImpl<$Res, PostScrapModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'post_id') String postId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'user_profiles') UserProfilesModel? userProfiles,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'board') BoardModel? board,
      @JsonKey(name: 'post') PostModel? post,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt});

  $UserProfilesModelCopyWith<$Res>? get userProfiles;
  $BoardModelCopyWith<$Res>? get board;
  $PostModelCopyWith<$Res>? get post;
}

/// @nodoc
class _$PostScrapModelCopyWithImpl<$Res, $Val extends PostScrapModel>
    implements $PostScrapModelCopyWith<$Res> {
  _$PostScrapModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PostScrapModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postId = null,
    Object? userId = null,
    Object? userProfiles = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? board = freezed,
    Object? post = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(_value.copyWith(
      postId: null == postId
          ? _value.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userProfiles: freezed == userProfiles
          ? _value.userProfiles
          : userProfiles // ignore: cast_nullable_to_non_nullable
              as UserProfilesModel?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      board: freezed == board
          ? _value.board
          : board // ignore: cast_nullable_to_non_nullable
              as BoardModel?,
      post: freezed == post
          ? _value.post
          : post // ignore: cast_nullable_to_non_nullable
              as PostModel?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of PostScrapModel
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

  /// Create a copy of PostScrapModel
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

  /// Create a copy of PostScrapModel
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
abstract class _$$PostScrapModelImplCopyWith<$Res>
    implements $PostScrapModelCopyWith<$Res> {
  factory _$$PostScrapModelImplCopyWith(_$PostScrapModelImpl value,
          $Res Function(_$PostScrapModelImpl) then) =
      __$$PostScrapModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'post_id') String postId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'user_profiles') UserProfilesModel? userProfiles,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'board') BoardModel? board,
      @JsonKey(name: 'post') PostModel? post,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt});

  @override
  $UserProfilesModelCopyWith<$Res>? get userProfiles;
  @override
  $BoardModelCopyWith<$Res>? get board;
  @override
  $PostModelCopyWith<$Res>? get post;
}

/// @nodoc
class __$$PostScrapModelImplCopyWithImpl<$Res>
    extends _$PostScrapModelCopyWithImpl<$Res, _$PostScrapModelImpl>
    implements _$$PostScrapModelImplCopyWith<$Res> {
  __$$PostScrapModelImplCopyWithImpl(
      _$PostScrapModelImpl _value, $Res Function(_$PostScrapModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PostScrapModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postId = null,
    Object? userId = null,
    Object? userProfiles = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? board = freezed,
    Object? post = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(_$PostScrapModelImpl(
      postId: null == postId
          ? _value.postId
          : postId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userProfiles: freezed == userProfiles
          ? _value.userProfiles
          : userProfiles // ignore: cast_nullable_to_non_nullable
              as UserProfilesModel?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      board: freezed == board
          ? _value.board
          : board // ignore: cast_nullable_to_non_nullable
              as BoardModel?,
      post: freezed == post
          ? _value.post
          : post // ignore: cast_nullable_to_non_nullable
              as PostModel?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostScrapModelImpl extends _PostScrapModel {
  const _$PostScrapModelImpl(
      {@JsonKey(name: 'post_id') required this.postId,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'user_profiles') required this.userProfiles,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'board') required this.board,
      @JsonKey(name: 'post') required this.post,
      @JsonKey(name: 'deleted_at') this.deletedAt})
      : super._();

  factory _$PostScrapModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostScrapModelImplFromJson(json);

  @override
  @JsonKey(name: 'post_id')
  final String postId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'user_profiles')
  final UserProfilesModel? userProfiles;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  @JsonKey(name: 'board')
  final BoardModel? board;
  @override
  @JsonKey(name: 'post')
  final PostModel? post;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'PostScrapModel(postId: $postId, userId: $userId, userProfiles: $userProfiles, createdAt: $createdAt, updatedAt: $updatedAt, board: $board, post: $post, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostScrapModelImpl &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userProfiles, userProfiles) ||
                other.userProfiles == userProfiles) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.board, board) || other.board == board) &&
            (identical(other.post, post) || other.post == post) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, postId, userId, userProfiles,
      createdAt, updatedAt, board, post, deletedAt);

  /// Create a copy of PostScrapModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostScrapModelImplCopyWith<_$PostScrapModelImpl> get copyWith =>
      __$$PostScrapModelImplCopyWithImpl<_$PostScrapModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostScrapModelImplToJson(
      this,
    );
  }
}

abstract class _PostScrapModel extends PostScrapModel {
  const factory _PostScrapModel(
          {@JsonKey(name: 'post_id') required final String postId,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'user_profiles')
          required final UserProfilesModel? userProfiles,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt,
          @JsonKey(name: 'board') required final BoardModel? board,
          @JsonKey(name: 'post') required final PostModel? post,
          @JsonKey(name: 'deleted_at') final DateTime? deletedAt}) =
      _$PostScrapModelImpl;
  const _PostScrapModel._() : super._();

  factory _PostScrapModel.fromJson(Map<String, dynamic> json) =
      _$PostScrapModelImpl.fromJson;

  @override
  @JsonKey(name: 'post_id')
  String get postId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'user_profiles')
  UserProfilesModel? get userProfiles;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  @JsonKey(name: 'board')
  BoardModel? get board;
  @override
  @JsonKey(name: 'post')
  PostModel? get post;
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;

  /// Create a copy of PostScrapModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostScrapModelImplCopyWith<_$PostScrapModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
