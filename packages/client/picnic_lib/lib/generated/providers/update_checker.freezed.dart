// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../presentation/providers/update_checker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UpdateInfo {
  UpdateStatus get status => throw _privateConstructorUsedError;
  String get currentVersion => throw _privateConstructorUsedError;
  String get latestVersion => throw _privateConstructorUsedError;
  String get forceVersion => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;

  /// Create a copy of UpdateInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateInfoCopyWith<UpdateInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateInfoCopyWith<$Res> {
  factory $UpdateInfoCopyWith(
          UpdateInfo value, $Res Function(UpdateInfo) then) =
      _$UpdateInfoCopyWithImpl<$Res, UpdateInfo>;
  @useResult
  $Res call(
      {UpdateStatus status,
      String currentVersion,
      String latestVersion,
      String forceVersion,
      String? url});
}

/// @nodoc
class _$UpdateInfoCopyWithImpl<$Res, $Val extends UpdateInfo>
    implements $UpdateInfoCopyWith<$Res> {
  _$UpdateInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? currentVersion = null,
    Object? latestVersion = null,
    Object? forceVersion = null,
    Object? url = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as UpdateStatus,
      currentVersion: null == currentVersion
          ? _value.currentVersion
          : currentVersion // ignore: cast_nullable_to_non_nullable
              as String,
      latestVersion: null == latestVersion
          ? _value.latestVersion
          : latestVersion // ignore: cast_nullable_to_non_nullable
              as String,
      forceVersion: null == forceVersion
          ? _value.forceVersion
          : forceVersion // ignore: cast_nullable_to_non_nullable
              as String,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateInfoImplCopyWith<$Res>
    implements $UpdateInfoCopyWith<$Res> {
  factory _$$UpdateInfoImplCopyWith(
          _$UpdateInfoImpl value, $Res Function(_$UpdateInfoImpl) then) =
      __$$UpdateInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {UpdateStatus status,
      String currentVersion,
      String latestVersion,
      String forceVersion,
      String? url});
}

/// @nodoc
class __$$UpdateInfoImplCopyWithImpl<$Res>
    extends _$UpdateInfoCopyWithImpl<$Res, _$UpdateInfoImpl>
    implements _$$UpdateInfoImplCopyWith<$Res> {
  __$$UpdateInfoImplCopyWithImpl(
      _$UpdateInfoImpl _value, $Res Function(_$UpdateInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of UpdateInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? currentVersion = null,
    Object? latestVersion = null,
    Object? forceVersion = null,
    Object? url = freezed,
  }) {
    return _then(_$UpdateInfoImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as UpdateStatus,
      currentVersion: null == currentVersion
          ? _value.currentVersion
          : currentVersion // ignore: cast_nullable_to_non_nullable
              as String,
      latestVersion: null == latestVersion
          ? _value.latestVersion
          : latestVersion // ignore: cast_nullable_to_non_nullable
              as String,
      forceVersion: null == forceVersion
          ? _value.forceVersion
          : forceVersion // ignore: cast_nullable_to_non_nullable
              as String,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UpdateInfoImpl extends _UpdateInfo {
  const _$UpdateInfoImpl(
      {required this.status,
      required this.currentVersion,
      required this.latestVersion,
      required this.forceVersion,
      this.url})
      : super._();

  @override
  final UpdateStatus status;
  @override
  final String currentVersion;
  @override
  final String latestVersion;
  @override
  final String forceVersion;
  @override
  final String? url;

  @override
  String toString() {
    return 'UpdateInfo(status: $status, currentVersion: $currentVersion, latestVersion: $latestVersion, forceVersion: $forceVersion, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateInfoImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentVersion, currentVersion) ||
                other.currentVersion == currentVersion) &&
            (identical(other.latestVersion, latestVersion) ||
                other.latestVersion == latestVersion) &&
            (identical(other.forceVersion, forceVersion) ||
                other.forceVersion == forceVersion) &&
            (identical(other.url, url) || other.url == url));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, status, currentVersion, latestVersion, forceVersion, url);

  /// Create a copy of UpdateInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateInfoImplCopyWith<_$UpdateInfoImpl> get copyWith =>
      __$$UpdateInfoImplCopyWithImpl<_$UpdateInfoImpl>(this, _$identity);
}

abstract class _UpdateInfo extends UpdateInfo {
  const factory _UpdateInfo(
      {required final UpdateStatus status,
      required final String currentVersion,
      required final String latestVersion,
      required final String forceVersion,
      final String? url}) = _$UpdateInfoImpl;
  const _UpdateInfo._() : super._();

  @override
  UpdateStatus get status;
  @override
  String get currentVersion;
  @override
  String get latestVersion;
  @override
  String get forceVersion;
  @override
  String? get url;

  /// Create a copy of UpdateInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateInfoImplCopyWith<_$UpdateInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
