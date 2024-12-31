// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../providers/app_initialization_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppInitializationState {
  bool get hasNetwork => throw _privateConstructorUsedError;
  bool get isBanned => throw _privateConstructorUsedError;
  bool get isInitialized => throw _privateConstructorUsedError;
  bool get isUpdateRequired => throw _privateConstructorUsedError;
  UpdateInfo? get updateInfo => throw _privateConstructorUsedError;

  /// Create a copy of AppInitializationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppInitializationStateCopyWith<AppInitializationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppInitializationStateCopyWith<$Res> {
  factory $AppInitializationStateCopyWith(AppInitializationState value,
          $Res Function(AppInitializationState) then) =
      _$AppInitializationStateCopyWithImpl<$Res, AppInitializationState>;
  @useResult
  $Res call(
      {bool hasNetwork,
      bool isBanned,
      bool isInitialized,
      bool isUpdateRequired,
      UpdateInfo? updateInfo});

  $UpdateInfoCopyWith<$Res>? get updateInfo;
}

/// @nodoc
class _$AppInitializationStateCopyWithImpl<$Res,
        $Val extends AppInitializationState>
    implements $AppInitializationStateCopyWith<$Res> {
  _$AppInitializationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppInitializationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasNetwork = null,
    Object? isBanned = null,
    Object? isInitialized = null,
    Object? isUpdateRequired = null,
    Object? updateInfo = freezed,
  }) {
    return _then(_value.copyWith(
      hasNetwork: null == hasNetwork
          ? _value.hasNetwork
          : hasNetwork // ignore: cast_nullable_to_non_nullable
              as bool,
      isBanned: null == isBanned
          ? _value.isBanned
          : isBanned // ignore: cast_nullable_to_non_nullable
              as bool,
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isUpdateRequired: null == isUpdateRequired
          ? _value.isUpdateRequired
          : isUpdateRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      updateInfo: freezed == updateInfo
          ? _value.updateInfo
          : updateInfo // ignore: cast_nullable_to_non_nullable
              as UpdateInfo?,
    ) as $Val);
  }

  /// Create a copy of AppInitializationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UpdateInfoCopyWith<$Res>? get updateInfo {
    if (_value.updateInfo == null) {
      return null;
    }

    return $UpdateInfoCopyWith<$Res>(_value.updateInfo!, (value) {
      return _then(_value.copyWith(updateInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AppInitializationStateImplCopyWith<$Res>
    implements $AppInitializationStateCopyWith<$Res> {
  factory _$$AppInitializationStateImplCopyWith(
          _$AppInitializationStateImpl value,
          $Res Function(_$AppInitializationStateImpl) then) =
      __$$AppInitializationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool hasNetwork,
      bool isBanned,
      bool isInitialized,
      bool isUpdateRequired,
      UpdateInfo? updateInfo});

  @override
  $UpdateInfoCopyWith<$Res>? get updateInfo;
}

/// @nodoc
class __$$AppInitializationStateImplCopyWithImpl<$Res>
    extends _$AppInitializationStateCopyWithImpl<$Res,
        _$AppInitializationStateImpl>
    implements _$$AppInitializationStateImplCopyWith<$Res> {
  __$$AppInitializationStateImplCopyWithImpl(
      _$AppInitializationStateImpl _value,
      $Res Function(_$AppInitializationStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppInitializationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hasNetwork = null,
    Object? isBanned = null,
    Object? isInitialized = null,
    Object? isUpdateRequired = null,
    Object? updateInfo = freezed,
  }) {
    return _then(_$AppInitializationStateImpl(
      hasNetwork: null == hasNetwork
          ? _value.hasNetwork
          : hasNetwork // ignore: cast_nullable_to_non_nullable
              as bool,
      isBanned: null == isBanned
          ? _value.isBanned
          : isBanned // ignore: cast_nullable_to_non_nullable
              as bool,
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isUpdateRequired: null == isUpdateRequired
          ? _value.isUpdateRequired
          : isUpdateRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      updateInfo: freezed == updateInfo
          ? _value.updateInfo
          : updateInfo // ignore: cast_nullable_to_non_nullable
              as UpdateInfo?,
    ));
  }
}

/// @nodoc

class _$AppInitializationStateImpl implements _AppInitializationState {
  const _$AppInitializationStateImpl(
      {this.hasNetwork = true,
      this.isBanned = false,
      this.isInitialized = false,
      this.isUpdateRequired = false,
      this.updateInfo});

  @override
  @JsonKey()
  final bool hasNetwork;
  @override
  @JsonKey()
  final bool isBanned;
  @override
  @JsonKey()
  final bool isInitialized;
  @override
  @JsonKey()
  final bool isUpdateRequired;
  @override
  final UpdateInfo? updateInfo;

  @override
  String toString() {
    return 'AppInitializationState(hasNetwork: $hasNetwork, isBanned: $isBanned, isInitialized: $isInitialized, isUpdateRequired: $isUpdateRequired, updateInfo: $updateInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppInitializationStateImpl &&
            (identical(other.hasNetwork, hasNetwork) ||
                other.hasNetwork == hasNetwork) &&
            (identical(other.isBanned, isBanned) ||
                other.isBanned == isBanned) &&
            (identical(other.isInitialized, isInitialized) ||
                other.isInitialized == isInitialized) &&
            (identical(other.isUpdateRequired, isUpdateRequired) ||
                other.isUpdateRequired == isUpdateRequired) &&
            (identical(other.updateInfo, updateInfo) ||
                other.updateInfo == updateInfo));
  }

  @override
  int get hashCode => Object.hash(runtimeType, hasNetwork, isBanned,
      isInitialized, isUpdateRequired, updateInfo);

  /// Create a copy of AppInitializationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppInitializationStateImplCopyWith<_$AppInitializationStateImpl>
      get copyWith => __$$AppInitializationStateImplCopyWithImpl<
          _$AppInitializationStateImpl>(this, _$identity);
}

abstract class _AppInitializationState implements AppInitializationState {
  const factory _AppInitializationState(
      {final bool hasNetwork,
      final bool isBanned,
      final bool isInitialized,
      final bool isUpdateRequired,
      final UpdateInfo? updateInfo}) = _$AppInitializationStateImpl;

  @override
  bool get hasNetwork;
  @override
  bool get isBanned;
  @override
  bool get isInitialized;
  @override
  bool get isUpdateRequired;
  @override
  UpdateInfo? get updateInfo;

  /// Create a copy of AppInitializationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppInitializationStateImplCopyWith<_$AppInitializationStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
