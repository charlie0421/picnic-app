// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../models/common/app_version.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppVersionModel _$AppVersionModelFromJson(Map<String, dynamic> json) {
  return _AppVersionModel.fromJson(json);
}

/// @nodoc
mixin _$AppVersionModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'ios')
  Map<String, dynamic> get ios => throw _privateConstructorUsedError;
  @JsonKey(name: 'android')
  Map<String, dynamic> get android => throw _privateConstructorUsedError;
  @JsonKey(name: 'macos')
  Map<String, dynamic> get macos => throw _privateConstructorUsedError;
  @JsonKey(name: 'windows')
  Map<String, dynamic> get windows => throw _privateConstructorUsedError;
  @JsonKey(name: 'linux')
  Map<String, dynamic> get linux => throw _privateConstructorUsedError;

  /// Serializes this AppVersionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppVersionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppVersionModelCopyWith<AppVersionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppVersionModelCopyWith<$Res> {
  factory $AppVersionModelCopyWith(
          AppVersionModel value, $Res Function(AppVersionModel) then) =
      _$AppVersionModelCopyWithImpl<$Res, AppVersionModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'ios') Map<String, dynamic> ios,
      @JsonKey(name: 'android') Map<String, dynamic> android,
      @JsonKey(name: 'macos') Map<String, dynamic> macos,
      @JsonKey(name: 'windows') Map<String, dynamic> windows,
      @JsonKey(name: 'linux') Map<String, dynamic> linux});
}

/// @nodoc
class _$AppVersionModelCopyWithImpl<$Res, $Val extends AppVersionModel>
    implements $AppVersionModelCopyWith<$Res> {
  _$AppVersionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppVersionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ios = null,
    Object? android = null,
    Object? macos = null,
    Object? windows = null,
    Object? linux = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      ios: null == ios
          ? _value.ios
          : ios // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      android: null == android
          ? _value.android
          : android // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      macos: null == macos
          ? _value.macos
          : macos // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      windows: null == windows
          ? _value.windows
          : windows // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      linux: null == linux
          ? _value.linux
          : linux // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppVersionModelImplCopyWith<$Res>
    implements $AppVersionModelCopyWith<$Res> {
  factory _$$AppVersionModelImplCopyWith(_$AppVersionModelImpl value,
          $Res Function(_$AppVersionModelImpl) then) =
      __$$AppVersionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'ios') Map<String, dynamic> ios,
      @JsonKey(name: 'android') Map<String, dynamic> android,
      @JsonKey(name: 'macos') Map<String, dynamic> macos,
      @JsonKey(name: 'windows') Map<String, dynamic> windows,
      @JsonKey(name: 'linux') Map<String, dynamic> linux});
}

/// @nodoc
class __$$AppVersionModelImplCopyWithImpl<$Res>
    extends _$AppVersionModelCopyWithImpl<$Res, _$AppVersionModelImpl>
    implements _$$AppVersionModelImplCopyWith<$Res> {
  __$$AppVersionModelImplCopyWithImpl(
      _$AppVersionModelImpl _value, $Res Function(_$AppVersionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppVersionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ios = null,
    Object? android = null,
    Object? macos = null,
    Object? windows = null,
    Object? linux = null,
  }) {
    return _then(_$AppVersionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      ios: null == ios
          ? _value._ios
          : ios // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      android: null == android
          ? _value._android
          : android // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      macos: null == macos
          ? _value._macos
          : macos // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      windows: null == windows
          ? _value._windows
          : windows // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      linux: null == linux
          ? _value._linux
          : linux // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppVersionModelImpl implements _AppVersionModel {
  const _$AppVersionModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'ios') required final Map<String, dynamic> ios,
      @JsonKey(name: 'android') required final Map<String, dynamic> android,
      @JsonKey(name: 'macos') required final Map<String, dynamic> macos,
      @JsonKey(name: 'windows') required final Map<String, dynamic> windows,
      @JsonKey(name: 'linux') required final Map<String, dynamic> linux})
      : _ios = ios,
        _android = android,
        _macos = macos,
        _windows = windows,
        _linux = linux;

  factory _$AppVersionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppVersionModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  final Map<String, dynamic> _ios;
  @override
  @JsonKey(name: 'ios')
  Map<String, dynamic> get ios {
    if (_ios is EqualUnmodifiableMapView) return _ios;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_ios);
  }

  final Map<String, dynamic> _android;
  @override
  @JsonKey(name: 'android')
  Map<String, dynamic> get android {
    if (_android is EqualUnmodifiableMapView) return _android;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_android);
  }

  final Map<String, dynamic> _macos;
  @override
  @JsonKey(name: 'macos')
  Map<String, dynamic> get macos {
    if (_macos is EqualUnmodifiableMapView) return _macos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_macos);
  }

  final Map<String, dynamic> _windows;
  @override
  @JsonKey(name: 'windows')
  Map<String, dynamic> get windows {
    if (_windows is EqualUnmodifiableMapView) return _windows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_windows);
  }

  final Map<String, dynamic> _linux;
  @override
  @JsonKey(name: 'linux')
  Map<String, dynamic> get linux {
    if (_linux is EqualUnmodifiableMapView) return _linux;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_linux);
  }

  @override
  String toString() {
    return 'AppVersionModel(id: $id, ios: $ios, android: $android, macos: $macos, windows: $windows, linux: $linux)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppVersionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._ios, _ios) &&
            const DeepCollectionEquality().equals(other._android, _android) &&
            const DeepCollectionEquality().equals(other._macos, _macos) &&
            const DeepCollectionEquality().equals(other._windows, _windows) &&
            const DeepCollectionEquality().equals(other._linux, _linux));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_ios),
      const DeepCollectionEquality().hash(_android),
      const DeepCollectionEquality().hash(_macos),
      const DeepCollectionEquality().hash(_windows),
      const DeepCollectionEquality().hash(_linux));

  /// Create a copy of AppVersionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppVersionModelImplCopyWith<_$AppVersionModelImpl> get copyWith =>
      __$$AppVersionModelImplCopyWithImpl<_$AppVersionModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppVersionModelImplToJson(
      this,
    );
  }
}

abstract class _AppVersionModel implements AppVersionModel {
  const factory _AppVersionModel(
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'ios') required final Map<String, dynamic> ios,
          @JsonKey(name: 'android') required final Map<String, dynamic> android,
          @JsonKey(name: 'macos') required final Map<String, dynamic> macos,
          @JsonKey(name: 'windows') required final Map<String, dynamic> windows,
          @JsonKey(name: 'linux') required final Map<String, dynamic> linux}) =
      _$AppVersionModelImpl;

  factory _AppVersionModel.fromJson(Map<String, dynamic> json) =
      _$AppVersionModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'ios')
  Map<String, dynamic> get ios;
  @override
  @JsonKey(name: 'android')
  Map<String, dynamic> get android;
  @override
  @JsonKey(name: 'macos')
  Map<String, dynamic> get macos;
  @override
  @JsonKey(name: 'windows')
  Map<String, dynamic> get windows;
  @override
  @JsonKey(name: 'linux')
  Map<String, dynamic> get linux;

  /// Create a copy of AppVersionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppVersionModelImplCopyWith<_$AppVersionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
