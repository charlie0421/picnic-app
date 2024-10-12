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
  String get post_id => throw _privateConstructorUsedError;
  String get user_id => throw _privateConstructorUsedError;
  UserProfilesModel? get user_profiles => throw _privateConstructorUsedError;
  DateTime get created_at => throw _privateConstructorUsedError;
  DateTime get updated_at => throw _privateConstructorUsedError;
  BoardModel? get board => throw _privateConstructorUsedError;
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
      {String post_id,
      String user_id,
      UserProfilesModel? user_profiles,
      DateTime created_at,
      DateTime updated_at,
      BoardModel? board,
      PostModel? post,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt});

  $UserProfilesModelCopyWith<$Res>? get user_profiles;
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
    Object? post_id = null,
    Object? user_id = null,
    Object? user_profiles = freezed,
    Object? created_at = null,
    Object? updated_at = null,
    Object? board = freezed,
    Object? post = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(_value.copyWith(
      post_id: null == post_id
          ? _value.post_id
          : post_id // ignore: cast_nullable_to_non_nullable
              as String,
      user_id: null == user_id
          ? _value.user_id
          : user_id // ignore: cast_nullable_to_non_nullable
              as String,
      user_profiles: freezed == user_profiles
          ? _value.user_profiles
          : user_profiles // ignore: cast_nullable_to_non_nullable
              as UserProfilesModel?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated_at: null == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
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
  $UserProfilesModelCopyWith<$Res>? get user_profiles {
    if (_value.user_profiles == null) {
      return null;
    }

    return $UserProfilesModelCopyWith<$Res>(_value.user_profiles!, (value) {
      return _then(_value.copyWith(user_profiles: value) as $Val);
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
      {String post_id,
      String user_id,
      UserProfilesModel? user_profiles,
      DateTime created_at,
      DateTime updated_at,
      BoardModel? board,
      PostModel? post,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt});

  @override
  $UserProfilesModelCopyWith<$Res>? get user_profiles;
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
    Object? post_id = null,
    Object? user_id = null,
    Object? user_profiles = freezed,
    Object? created_at = null,
    Object? updated_at = null,
    Object? board = freezed,
    Object? post = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(_$PostScrapModelImpl(
      post_id: null == post_id
          ? _value.post_id
          : post_id // ignore: cast_nullable_to_non_nullable
              as String,
      user_id: null == user_id
          ? _value.user_id
          : user_id // ignore: cast_nullable_to_non_nullable
              as String,
      user_profiles: freezed == user_profiles
          ? _value.user_profiles
          : user_profiles // ignore: cast_nullable_to_non_nullable
              as UserProfilesModel?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated_at: null == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
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
      {required this.post_id,
      required this.user_id,
      required this.user_profiles,
      required this.created_at,
      required this.updated_at,
      required this.board,
      required this.post,
      @JsonKey(name: 'deleted_at') this.deletedAt})
      : super._();

  factory _$PostScrapModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostScrapModelImplFromJson(json);

  @override
  final String post_id;
  @override
  final String user_id;
  @override
  final UserProfilesModel? user_profiles;
  @override
  final DateTime created_at;
  @override
  final DateTime updated_at;
  @override
  final BoardModel? board;
  @override
  final PostModel? post;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  @override
  String toString() {
    return 'PostScrapModel(post_id: $post_id, user_id: $user_id, user_profiles: $user_profiles, created_at: $created_at, updated_at: $updated_at, board: $board, post: $post, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostScrapModelImpl &&
            (identical(other.post_id, post_id) || other.post_id == post_id) &&
            (identical(other.user_id, user_id) || other.user_id == user_id) &&
            (identical(other.user_profiles, user_profiles) ||
                other.user_profiles == user_profiles) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.updated_at, updated_at) ||
                other.updated_at == updated_at) &&
            (identical(other.board, board) || other.board == board) &&
            (identical(other.post, post) || other.post == post) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, post_id, user_id, user_profiles,
      created_at, updated_at, board, post, deletedAt);

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
          {required final String post_id,
          required final String user_id,
          required final UserProfilesModel? user_profiles,
          required final DateTime created_at,
          required final DateTime updated_at,
          required final BoardModel? board,
          required final PostModel? post,
          @JsonKey(name: 'deleted_at') final DateTime? deletedAt}) =
      _$PostScrapModelImpl;
  const _PostScrapModel._() : super._();

  factory _PostScrapModel.fromJson(Map<String, dynamic> json) =
      _$PostScrapModelImpl.fromJson;

  @override
  String get post_id;
  @override
  String get user_id;
  @override
  UserProfilesModel? get user_profiles;
  @override
  DateTime get created_at;
  @override
  DateTime get updated_at;
  @override
  BoardModel? get board;
  @override
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
