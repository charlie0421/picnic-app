// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/common/community_navigation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CommunityState {
  ArtistModel? get currentArtist => throw _privateConstructorUsedError;
  PostModel? get currentPost => throw _privateConstructorUsedError;
  BoardModel? get currentBoard => throw _privateConstructorUsedError;

  /// Create a copy of CommunityState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunityStateCopyWith<CommunityState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunityStateCopyWith<$Res> {
  factory $CommunityStateCopyWith(
          CommunityState value, $Res Function(CommunityState) then) =
      _$CommunityStateCopyWithImpl<$Res, CommunityState>;
  @useResult
  $Res call(
      {ArtistModel? currentArtist,
      PostModel? currentPost,
      BoardModel? currentBoard});

  $ArtistModelCopyWith<$Res>? get currentArtist;
  $PostModelCopyWith<$Res>? get currentPost;
  $BoardModelCopyWith<$Res>? get currentBoard;
}

/// @nodoc
class _$CommunityStateCopyWithImpl<$Res, $Val extends CommunityState>
    implements $CommunityStateCopyWith<$Res> {
  _$CommunityStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunityState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentArtist = freezed,
    Object? currentPost = freezed,
    Object? currentBoard = freezed,
  }) {
    return _then(_value.copyWith(
      currentArtist: freezed == currentArtist
          ? _value.currentArtist
          : currentArtist // ignore: cast_nullable_to_non_nullable
              as ArtistModel?,
      currentPost: freezed == currentPost
          ? _value.currentPost
          : currentPost // ignore: cast_nullable_to_non_nullable
              as PostModel?,
      currentBoard: freezed == currentBoard
          ? _value.currentBoard
          : currentBoard // ignore: cast_nullable_to_non_nullable
              as BoardModel?,
    ) as $Val);
  }

  /// Create a copy of CommunityState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistModelCopyWith<$Res>? get currentArtist {
    if (_value.currentArtist == null) {
      return null;
    }

    return $ArtistModelCopyWith<$Res>(_value.currentArtist!, (value) {
      return _then(_value.copyWith(currentArtist: value) as $Val);
    });
  }

  /// Create a copy of CommunityState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PostModelCopyWith<$Res>? get currentPost {
    if (_value.currentPost == null) {
      return null;
    }

    return $PostModelCopyWith<$Res>(_value.currentPost!, (value) {
      return _then(_value.copyWith(currentPost: value) as $Val);
    });
  }

  /// Create a copy of CommunityState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BoardModelCopyWith<$Res>? get currentBoard {
    if (_value.currentBoard == null) {
      return null;
    }

    return $BoardModelCopyWith<$Res>(_value.currentBoard!, (value) {
      return _then(_value.copyWith(currentBoard: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NavigationImplCopyWith<$Res>
    implements $CommunityStateCopyWith<$Res> {
  factory _$$NavigationImplCopyWith(
          _$NavigationImpl value, $Res Function(_$NavigationImpl) then) =
      __$$NavigationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ArtistModel? currentArtist,
      PostModel? currentPost,
      BoardModel? currentBoard});

  @override
  $ArtistModelCopyWith<$Res>? get currentArtist;
  @override
  $PostModelCopyWith<$Res>? get currentPost;
  @override
  $BoardModelCopyWith<$Res>? get currentBoard;
}

/// @nodoc
class __$$NavigationImplCopyWithImpl<$Res>
    extends _$CommunityStateCopyWithImpl<$Res, _$NavigationImpl>
    implements _$$NavigationImplCopyWith<$Res> {
  __$$NavigationImplCopyWithImpl(
      _$NavigationImpl _value, $Res Function(_$NavigationImpl) _then)
      : super(_value, _then);

  /// Create a copy of CommunityState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentArtist = freezed,
    Object? currentPost = freezed,
    Object? currentBoard = freezed,
  }) {
    return _then(_$NavigationImpl(
      currentArtist: freezed == currentArtist
          ? _value.currentArtist
          : currentArtist // ignore: cast_nullable_to_non_nullable
              as ArtistModel?,
      currentPost: freezed == currentPost
          ? _value.currentPost
          : currentPost // ignore: cast_nullable_to_non_nullable
              as PostModel?,
      currentBoard: freezed == currentBoard
          ? _value.currentBoard
          : currentBoard // ignore: cast_nullable_to_non_nullable
              as BoardModel?,
    ));
  }
}

/// @nodoc

class _$NavigationImpl extends Navigation {
  const _$NavigationImpl(
      {this.currentArtist, this.currentPost, this.currentBoard})
      : super._();

  @override
  final ArtistModel? currentArtist;
  @override
  final PostModel? currentPost;
  @override
  final BoardModel? currentBoard;

  @override
  String toString() {
    return 'CommunityState(currentArtist: $currentArtist, currentPost: $currentPost, currentBoard: $currentBoard)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NavigationImpl &&
            (identical(other.currentArtist, currentArtist) ||
                other.currentArtist == currentArtist) &&
            (identical(other.currentPost, currentPost) ||
                other.currentPost == currentPost) &&
            (identical(other.currentBoard, currentBoard) ||
                other.currentBoard == currentBoard));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, currentArtist, currentPost, currentBoard);

  /// Create a copy of CommunityState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NavigationImplCopyWith<_$NavigationImpl> get copyWith =>
      __$$NavigationImplCopyWithImpl<_$NavigationImpl>(this, _$identity);
}

abstract class Navigation extends CommunityState {
  const factory Navigation(
      {final ArtistModel? currentArtist,
      final PostModel? currentPost,
      final BoardModel? currentBoard}) = _$NavigationImpl;
  const Navigation._() : super._();

  @override
  ArtistModel? get currentArtist;
  @override
  PostModel? get currentPost;
  @override
  BoardModel? get currentBoard;

  /// Create a copy of CommunityState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NavigationImplCopyWith<_$NavigationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
