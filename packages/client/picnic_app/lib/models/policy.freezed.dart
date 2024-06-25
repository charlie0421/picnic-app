// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PolicyItemModel _$PolicyItemModelFromJson(Map<String, dynamic> json) {
  return _PolicyItemModel.fromJson(json);
}

/// @nodoc
mixin _$PolicyItemModel {
  String get content => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PolicyItemModelCopyWith<PolicyItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PolicyItemModelCopyWith<$Res> {
  factory $PolicyItemModelCopyWith(
          PolicyItemModel value, $Res Function(PolicyItemModel) then) =
      _$PolicyItemModelCopyWithImpl<$Res, PolicyItemModel>;
  @useResult
  $Res call({String content, String version});
}

/// @nodoc
class _$PolicyItemModelCopyWithImpl<$Res, $Val extends PolicyItemModel>
    implements $PolicyItemModelCopyWith<$Res> {
  _$PolicyItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PolicyItemModelImplCopyWith<$Res>
    implements $PolicyItemModelCopyWith<$Res> {
  factory _$$PolicyItemModelImplCopyWith(_$PolicyItemModelImpl value,
          $Res Function(_$PolicyItemModelImpl) then) =
      __$$PolicyItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String content, String version});
}

/// @nodoc
class __$$PolicyItemModelImplCopyWithImpl<$Res>
    extends _$PolicyItemModelCopyWithImpl<$Res, _$PolicyItemModelImpl>
    implements _$$PolicyItemModelImplCopyWith<$Res> {
  __$$PolicyItemModelImplCopyWithImpl(
      _$PolicyItemModelImpl _value, $Res Function(_$PolicyItemModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? version = null,
  }) {
    return _then(_$PolicyItemModelImpl(
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PolicyItemModelImpl implements _PolicyItemModel {
  _$PolicyItemModelImpl({required this.content, required this.version});

  factory _$PolicyItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PolicyItemModelImplFromJson(json);

  @override
  final String content;
  @override
  final String version;

  @override
  String toString() {
    return 'PolicyItemModel(content: $content, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PolicyItemModelImpl &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, content, version);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PolicyItemModelImplCopyWith<_$PolicyItemModelImpl> get copyWith =>
      __$$PolicyItemModelImplCopyWithImpl<_$PolicyItemModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PolicyItemModelImplToJson(
      this,
    );
  }
}

abstract class _PolicyItemModel implements PolicyItemModel {
  factory _PolicyItemModel(
      {required final String content,
      required final String version}) = _$PolicyItemModelImpl;

  factory _PolicyItemModel.fromJson(Map<String, dynamic> json) =
      _$PolicyItemModelImpl.fromJson;

  @override
  String get content;
  @override
  String get version;
  @override
  @JsonKey(ignore: true)
  _$$PolicyItemModelImplCopyWith<_$PolicyItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
