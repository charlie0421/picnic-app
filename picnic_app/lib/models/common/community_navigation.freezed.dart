// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_navigation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CommunityState {
  int get currentArtistId => throw _privateConstructorUsedError;
  String get currentArtistName => throw _privateConstructorUsedError;
  String get currentBoardId => throw _privateConstructorUsedError;
  String get currentBoardName => throw _privateConstructorUsedError;

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
      {int currentArtistId,
      String currentArtistName,
      String currentBoardId,
      String currentBoardName});
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
    Object? currentArtistId = null,
    Object? currentArtistName = null,
    Object? currentBoardId = null,
    Object? currentBoardName = null,
  }) {
    return _then(_value.copyWith(
      currentArtistId: null == currentArtistId
          ? _value.currentArtistId
          : currentArtistId // ignore: cast_nullable_to_non_nullable
              as int,
      currentArtistName: null == currentArtistName
          ? _value.currentArtistName
          : currentArtistName // ignore: cast_nullable_to_non_nullable
              as String,
      currentBoardId: null == currentBoardId
          ? _value.currentBoardId
          : currentBoardId // ignore: cast_nullable_to_non_nullable
              as String,
      currentBoardName: null == currentBoardName
          ? _value.currentBoardName
          : currentBoardName // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
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
      {int currentArtistId,
      String currentArtistName,
      String currentBoardId,
      String currentBoardName});
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
    Object? currentArtistId = null,
    Object? currentArtistName = null,
    Object? currentBoardId = null,
    Object? currentBoardName = null,
  }) {
    return _then(_$NavigationImpl(
      currentArtistId: null == currentArtistId
          ? _value.currentArtistId
          : currentArtistId // ignore: cast_nullable_to_non_nullable
              as int,
      currentArtistName: null == currentArtistName
          ? _value.currentArtistName
          : currentArtistName // ignore: cast_nullable_to_non_nullable
              as String,
      currentBoardId: null == currentBoardId
          ? _value.currentBoardId
          : currentBoardId // ignore: cast_nullable_to_non_nullable
              as String,
      currentBoardName: null == currentBoardName
          ? _value.currentBoardName
          : currentBoardName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$NavigationImpl extends Navigation {
  const _$NavigationImpl(
      {this.currentArtistId = 0,
      this.currentArtistName = '',
      this.currentBoardId = '',
      this.currentBoardName = ''})
      : super._();

  @override
  @JsonKey()
  final int currentArtistId;
  @override
  @JsonKey()
  final String currentArtistName;
  @override
  @JsonKey()
  final String currentBoardId;
  @override
  @JsonKey()
  final String currentBoardName;

  @override
  String toString() {
    return 'CommunityState(currentArtistId: $currentArtistId, currentArtistName: $currentArtistName, currentBoardId: $currentBoardId, currentBoardName: $currentBoardName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NavigationImpl &&
            (identical(other.currentArtistId, currentArtistId) ||
                other.currentArtistId == currentArtistId) &&
            (identical(other.currentArtistName, currentArtistName) ||
                other.currentArtistName == currentArtistName) &&
            (identical(other.currentBoardId, currentBoardId) ||
                other.currentBoardId == currentBoardId) &&
            (identical(other.currentBoardName, currentBoardName) ||
                other.currentBoardName == currentBoardName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentArtistId,
      currentArtistName, currentBoardId, currentBoardName);

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
      {final int currentArtistId,
      final String currentArtistName,
      final String currentBoardId,
      final String currentBoardName}) = _$NavigationImpl;
  const Navigation._() : super._();

  @override
  int get currentArtistId;
  @override
  String get currentArtistName;
  @override
  String get currentBoardId;
  @override
  String get currentBoardName;

  /// Create a copy of CommunityState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NavigationImplCopyWith<_$NavigationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
