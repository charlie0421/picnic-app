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
  String get post_id => throw _privateConstructorUsedError;
  String get user_id => throw _privateConstructorUsedError;
  UserProfilesModel? get user_profiles => throw _privateConstructorUsedError;
  String get board_id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<dynamic> get content => throw _privateConstructorUsedError;
  int get view_count => throw _privateConstructorUsedError;
  int get reply_count => throw _privateConstructorUsedError;
  bool get is_hidden => throw _privateConstructorUsedError;
  DateTime get created_at => throw _privateConstructorUsedError;
  DateTime get updated_at => throw _privateConstructorUsedError;
  BoardModel get boards => throw _privateConstructorUsedError;

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
      {String post_id,
      String user_id,
      UserProfilesModel? user_profiles,
      String board_id,
      String title,
      List<dynamic> content,
      int view_count,
      int reply_count,
      bool is_hidden,
      DateTime created_at,
      DateTime updated_at,
      BoardModel boards});

  $UserProfilesModelCopyWith<$Res>? get user_profiles;
  $BoardModelCopyWith<$Res> get boards;
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
    Object? post_id = null,
    Object? user_id = null,
    Object? user_profiles = freezed,
    Object? board_id = null,
    Object? title = null,
    Object? content = null,
    Object? view_count = null,
    Object? reply_count = null,
    Object? is_hidden = null,
    Object? created_at = null,
    Object? updated_at = null,
    Object? boards = null,
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
      board_id: null == board_id
          ? _value.board_id
          : board_id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      view_count: null == view_count
          ? _value.view_count
          : view_count // ignore: cast_nullable_to_non_nullable
              as int,
      reply_count: null == reply_count
          ? _value.reply_count
          : reply_count // ignore: cast_nullable_to_non_nullable
              as int,
      is_hidden: null == is_hidden
          ? _value.is_hidden
          : is_hidden // ignore: cast_nullable_to_non_nullable
              as bool,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated_at: null == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      boards: null == boards
          ? _value.boards
          : boards // ignore: cast_nullable_to_non_nullable
              as BoardModel,
    ) as $Val);
  }

  /// Create a copy of PostModel
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

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BoardModelCopyWith<$Res> get boards {
    return $BoardModelCopyWith<$Res>(_value.boards, (value) {
      return _then(_value.copyWith(boards: value) as $Val);
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
      {String post_id,
      String user_id,
      UserProfilesModel? user_profiles,
      String board_id,
      String title,
      List<dynamic> content,
      int view_count,
      int reply_count,
      bool is_hidden,
      DateTime created_at,
      DateTime updated_at,
      BoardModel boards});

  @override
  $UserProfilesModelCopyWith<$Res>? get user_profiles;
  @override
  $BoardModelCopyWith<$Res> get boards;
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
    Object? post_id = null,
    Object? user_id = null,
    Object? user_profiles = freezed,
    Object? board_id = null,
    Object? title = null,
    Object? content = null,
    Object? view_count = null,
    Object? reply_count = null,
    Object? is_hidden = null,
    Object? created_at = null,
    Object? updated_at = null,
    Object? boards = null,
  }) {
    return _then(_$PostModelImpl(
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
      board_id: null == board_id
          ? _value.board_id
          : board_id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value._content
          : content // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      view_count: null == view_count
          ? _value.view_count
          : view_count // ignore: cast_nullable_to_non_nullable
              as int,
      reply_count: null == reply_count
          ? _value.reply_count
          : reply_count // ignore: cast_nullable_to_non_nullable
              as int,
      is_hidden: null == is_hidden
          ? _value.is_hidden
          : is_hidden // ignore: cast_nullable_to_non_nullable
              as bool,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated_at: null == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      boards: null == boards
          ? _value.boards
          : boards // ignore: cast_nullable_to_non_nullable
              as BoardModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostModelImpl extends _PostModel {
  const _$PostModelImpl(
      {required this.post_id,
      required this.user_id,
      required this.user_profiles,
      required this.board_id,
      required this.title,
      required final List<dynamic> content,
      required this.view_count,
      required this.reply_count,
      required this.is_hidden,
      required this.created_at,
      required this.updated_at,
      required this.boards})
      : _content = content,
        super._();

  factory _$PostModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostModelImplFromJson(json);

  @override
  final String post_id;
  @override
  final String user_id;
  @override
  final UserProfilesModel? user_profiles;
  @override
  final String board_id;
  @override
  final String title;
  final List<dynamic> _content;
  @override
  List<dynamic> get content {
    if (_content is EqualUnmodifiableListView) return _content;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_content);
  }

  @override
  final int view_count;
  @override
  final int reply_count;
  @override
  final bool is_hidden;
  @override
  final DateTime created_at;
  @override
  final DateTime updated_at;
  @override
  final BoardModel boards;

  @override
  String toString() {
    return 'PostModel(post_id: $post_id, user_id: $user_id, user_profiles: $user_profiles, board_id: $board_id, title: $title, content: $content, view_count: $view_count, reply_count: $reply_count, is_hidden: $is_hidden, created_at: $created_at, updated_at: $updated_at, boards: $boards)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostModelImpl &&
            (identical(other.post_id, post_id) || other.post_id == post_id) &&
            (identical(other.user_id, user_id) || other.user_id == user_id) &&
            (identical(other.user_profiles, user_profiles) ||
                other.user_profiles == user_profiles) &&
            (identical(other.board_id, board_id) ||
                other.board_id == board_id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._content, _content) &&
            (identical(other.view_count, view_count) ||
                other.view_count == view_count) &&
            (identical(other.reply_count, reply_count) ||
                other.reply_count == reply_count) &&
            (identical(other.is_hidden, is_hidden) ||
                other.is_hidden == is_hidden) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.updated_at, updated_at) ||
                other.updated_at == updated_at) &&
            (identical(other.boards, boards) || other.boards == boards));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      post_id,
      user_id,
      user_profiles,
      board_id,
      title,
      const DeepCollectionEquality().hash(_content),
      view_count,
      reply_count,
      is_hidden,
      created_at,
      updated_at,
      boards);

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
      {required final String post_id,
      required final String user_id,
      required final UserProfilesModel? user_profiles,
      required final String board_id,
      required final String title,
      required final List<dynamic> content,
      required final int view_count,
      required final int reply_count,
      required final bool is_hidden,
      required final DateTime created_at,
      required final DateTime updated_at,
      required final BoardModel boards}) = _$PostModelImpl;
  const _PostModel._() : super._();

  factory _PostModel.fromJson(Map<String, dynamic> json) =
      _$PostModelImpl.fromJson;

  @override
  String get post_id;
  @override
  String get user_id;
  @override
  UserProfilesModel? get user_profiles;
  @override
  String get board_id;
  @override
  String get title;
  @override
  List<dynamic> get content;
  @override
  int get view_count;
  @override
  int get reply_count;
  @override
  bool get is_hidden;
  @override
  DateTime get created_at;
  @override
  DateTime get updated_at;
  @override
  BoardModel get boards;

  /// Create a copy of PostModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostModelImplCopyWith<_$PostModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
