// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../models/vote/artist_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArtistGroupModel _$ArtistGroupModelFromJson(Map<String, dynamic> json) {
  return _ArtistGroupModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistGroupModel {
  int get id => throw _privateConstructorUsedError;
  Map<String, dynamic> get name => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;

  /// Serializes this ArtistGroupModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArtistGroupModelCopyWith<ArtistGroupModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistGroupModelCopyWith<$Res> {
  factory $ArtistGroupModelCopyWith(
          ArtistGroupModel value, $Res Function(ArtistGroupModel) then) =
      _$ArtistGroupModelCopyWithImpl<$Res, ArtistGroupModel>;
  @useResult
  $Res call({int id, Map<String, dynamic> name, String? image});
}

/// @nodoc
class _$ArtistGroupModelCopyWithImpl<$Res, $Val extends ArtistGroupModel>
    implements $ArtistGroupModelCopyWith<$Res> {
  _$ArtistGroupModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? image = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistGroupModelImplCopyWith<$Res>
    implements $ArtistGroupModelCopyWith<$Res> {
  factory _$$ArtistGroupModelImplCopyWith(_$ArtistGroupModelImpl value,
          $Res Function(_$ArtistGroupModelImpl) then) =
      __$$ArtistGroupModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, Map<String, dynamic> name, String? image});
}

/// @nodoc
class __$$ArtistGroupModelImplCopyWithImpl<$Res>
    extends _$ArtistGroupModelCopyWithImpl<$Res, _$ArtistGroupModelImpl>
    implements _$$ArtistGroupModelImplCopyWith<$Res> {
  __$$ArtistGroupModelImplCopyWithImpl(_$ArtistGroupModelImpl _value,
      $Res Function(_$ArtistGroupModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? image = freezed,
  }) {
    return _then(_$ArtistGroupModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value._name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistGroupModelImpl extends _ArtistGroupModel {
  const _$ArtistGroupModelImpl(
      {required this.id,
      required final Map<String, dynamic> name,
      required this.image})
      : _name = name,
        super._();

  factory _$ArtistGroupModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistGroupModelImplFromJson(json);

  @override
  final int id;
  final Map<String, dynamic> _name;
  @override
  Map<String, dynamic> get name {
    if (_name is EqualUnmodifiableMapView) return _name;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_name);
  }

  @override
  final String? image;

  @override
  String toString() {
    return 'ArtistGroupModel(id: $id, name: $name, image: $image)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistGroupModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._name, _name) &&
            (identical(other.image, image) || other.image == image));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, const DeepCollectionEquality().hash(_name), image);

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistGroupModelImplCopyWith<_$ArtistGroupModelImpl> get copyWith =>
      __$$ArtistGroupModelImplCopyWithImpl<_$ArtistGroupModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistGroupModelImplToJson(
      this,
    );
  }
}

abstract class _ArtistGroupModel extends ArtistGroupModel {
  const factory _ArtistGroupModel(
      {required final int id,
      required final Map<String, dynamic> name,
      required final String? image}) = _$ArtistGroupModelImpl;
  const _ArtistGroupModel._() : super._();

  factory _ArtistGroupModel.fromJson(Map<String, dynamic> json) =
      _$ArtistGroupModelImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, dynamic> get name;
  @override
  String? get image;

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistGroupModelImplCopyWith<_$ArtistGroupModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
