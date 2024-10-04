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
mixin _$CommunityNavigation {
  int get currentArtistId => throw _privateConstructorUsedError;
  String get currentArtistName => throw _privateConstructorUsedError;
  String get currentBoardId => throw _privateConstructorUsedError;
  String get currentBoardName => throw _privateConstructorUsedError;
  NavigationStack? get communityNavigationStack =>
      throw _privateConstructorUsedError;

  /// Create a copy of CommunityNavigation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommunityNavigationCopyWith<CommunityNavigation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunityNavigationCopyWith<$Res> {
  factory $CommunityNavigationCopyWith(
          CommunityNavigation value, $Res Function(CommunityNavigation) then) =
      _$CommunityNavigationCopyWithImpl<$Res, CommunityNavigation>;
  @useResult
  $Res call(
      {int currentArtistId,
      String currentArtistName,
      String currentBoardId,
      String currentBoardName,
      NavigationStack? communityNavigationStack});
}

/// @nodoc
class _$CommunityNavigationCopyWithImpl<$Res, $Val extends CommunityNavigation>
    implements $CommunityNavigationCopyWith<$Res> {
  _$CommunityNavigationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommunityNavigation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentArtistId = null,
    Object? currentArtistName = null,
    Object? currentBoardId = null,
    Object? currentBoardName = null,
    Object? communityNavigationStack = freezed,
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
      communityNavigationStack: freezed == communityNavigationStack
          ? _value.communityNavigationStack
          : communityNavigationStack // ignore: cast_nullable_to_non_nullable
              as NavigationStack?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NavigationImplCopyWith<$Res>
    implements $CommunityNavigationCopyWith<$Res> {
  factory _$$NavigationImplCopyWith(
          _$NavigationImpl value, $Res Function(_$NavigationImpl) then) =
      __$$NavigationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int currentArtistId,
      String currentArtistName,
      String currentBoardId,
      String currentBoardName,
      NavigationStack? communityNavigationStack});
}

/// @nodoc
class __$$NavigationImplCopyWithImpl<$Res>
    extends _$CommunityNavigationCopyWithImpl<$Res, _$NavigationImpl>
    implements _$$NavigationImplCopyWith<$Res> {
  __$$NavigationImplCopyWithImpl(
      _$NavigationImpl _value, $Res Function(_$NavigationImpl) _then)
      : super(_value, _then);

  /// Create a copy of CommunityNavigation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentArtistId = null,
    Object? currentArtistName = null,
    Object? currentBoardId = null,
    Object? currentBoardName = null,
    Object? communityNavigationStack = freezed,
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
      communityNavigationStack: freezed == communityNavigationStack
          ? _value.communityNavigationStack
          : communityNavigationStack // ignore: cast_nullable_to_non_nullable
              as NavigationStack?,
    ));
  }
}

/// @nodoc

class _$NavigationImpl extends _Navigation {
  const _$NavigationImpl(
      {this.currentArtistId = 0,
      this.currentArtistName = '',
      this.currentBoardId = '',
      this.currentBoardName = '',
      this.communityNavigationStack})
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
  final NavigationStack? communityNavigationStack;

  @override
  String toString() {
    return 'CommunityNavigation(currentArtistId: $currentArtistId, currentArtistName: $currentArtistName, currentBoardId: $currentBoardId, currentBoardName: $currentBoardName, communityNavigationStack: $communityNavigationStack)';
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
                other.currentBoardName == currentBoardName) &&
            (identical(
                    other.communityNavigationStack, communityNavigationStack) ||
                other.communityNavigationStack == communityNavigationStack));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentArtistId,
      currentArtistName,
      currentBoardId,
      currentBoardName,
      communityNavigationStack);

  /// Create a copy of CommunityNavigation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NavigationImplCopyWith<_$NavigationImpl> get copyWith =>
      __$$NavigationImplCopyWithImpl<_$NavigationImpl>(this, _$identity);
}

abstract class _Navigation extends CommunityNavigation {
  const factory _Navigation(
      {final int currentArtistId,
      final String currentArtistName,
      final String currentBoardId,
      final String currentBoardName,
      final NavigationStack? communityNavigationStack}) = _$NavigationImpl;
  const _Navigation._() : super._();

  @override
  int get currentArtistId;
  @override
  String get currentArtistName;
  @override
  String get currentBoardId;
  @override
  String get currentBoardName;
  @override
  NavigationStack? get communityNavigationStack;

  /// Create a copy of CommunityNavigation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NavigationImplCopyWith<_$NavigationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
