// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArtistModel _$ArtistModelFromJson(Map<String, dynamic> json) {
  return _ArtistModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistModel {
  int get id => throw _privateConstructorUsedError;
  Map<String, dynamic> get name => throw _privateConstructorUsedError;
  int? get yy => throw _privateConstructorUsedError;
  int? get mm => throw _privateConstructorUsedError;
  int? get dd => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  String get image => throw _privateConstructorUsedError;
  ArtistGroupModel get artist_group => throw _privateConstructorUsedError;
  bool? get isBookmarked => throw _privateConstructorUsedError;
  int? get originalIndex => throw _privateConstructorUsedError;

  /// Serializes this ArtistModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArtistModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArtistModelCopyWith<ArtistModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistModelCopyWith<$Res> {
  factory $ArtistModelCopyWith(
          ArtistModel value, $Res Function(ArtistModel) then) =
      _$ArtistModelCopyWithImpl<$Res, ArtistModel>;
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic> name,
      int? yy,
      int? mm,
      int? dd,
      String gender,
      String image,
      ArtistGroupModel artist_group,
      bool? isBookmarked,
      int? originalIndex});

  $ArtistGroupModelCopyWith<$Res> get artist_group;
}

/// @nodoc
class _$ArtistModelCopyWithImpl<$Res, $Val extends ArtistModel>
    implements $ArtistModelCopyWith<$Res> {
  _$ArtistModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArtistModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? yy = freezed,
    Object? mm = freezed,
    Object? dd = freezed,
    Object? gender = null,
    Object? image = null,
    Object? artist_group = null,
    Object? isBookmarked = freezed,
    Object? originalIndex = freezed,
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
      yy: freezed == yy
          ? _value.yy
          : yy // ignore: cast_nullable_to_non_nullable
              as int?,
      mm: freezed == mm
          ? _value.mm
          : mm // ignore: cast_nullable_to_non_nullable
              as int?,
      dd: freezed == dd
          ? _value.dd
          : dd // ignore: cast_nullable_to_non_nullable
              as int?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      artist_group: null == artist_group
          ? _value.artist_group
          : artist_group // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel,
      isBookmarked: freezed == isBookmarked
          ? _value.isBookmarked
          : isBookmarked // ignore: cast_nullable_to_non_nullable
              as bool?,
      originalIndex: freezed == originalIndex
          ? _value.originalIndex
          : originalIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  /// Create a copy of ArtistModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistGroupModelCopyWith<$Res> get artist_group {
    return $ArtistGroupModelCopyWith<$Res>(_value.artist_group, (value) {
      return _then(_value.copyWith(artist_group: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArtistModelImplCopyWith<$Res>
    implements $ArtistModelCopyWith<$Res> {
  factory _$$ArtistModelImplCopyWith(
          _$ArtistModelImpl value, $Res Function(_$ArtistModelImpl) then) =
      __$$ArtistModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic> name,
      int? yy,
      int? mm,
      int? dd,
      String gender,
      String image,
      ArtistGroupModel artist_group,
      bool? isBookmarked,
      int? originalIndex});

  @override
  $ArtistGroupModelCopyWith<$Res> get artist_group;
}

/// @nodoc
class __$$ArtistModelImplCopyWithImpl<$Res>
    extends _$ArtistModelCopyWithImpl<$Res, _$ArtistModelImpl>
    implements _$$ArtistModelImplCopyWith<$Res> {
  __$$ArtistModelImplCopyWithImpl(
      _$ArtistModelImpl _value, $Res Function(_$ArtistModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArtistModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? yy = freezed,
    Object? mm = freezed,
    Object? dd = freezed,
    Object? gender = null,
    Object? image = null,
    Object? artist_group = null,
    Object? isBookmarked = freezed,
    Object? originalIndex = freezed,
  }) {
    return _then(_$ArtistModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value._name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      yy: freezed == yy
          ? _value.yy
          : yy // ignore: cast_nullable_to_non_nullable
              as int?,
      mm: freezed == mm
          ? _value.mm
          : mm // ignore: cast_nullable_to_non_nullable
              as int?,
      dd: freezed == dd
          ? _value.dd
          : dd // ignore: cast_nullable_to_non_nullable
              as int?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      artist_group: null == artist_group
          ? _value.artist_group
          : artist_group // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel,
      isBookmarked: freezed == isBookmarked
          ? _value.isBookmarked
          : isBookmarked // ignore: cast_nullable_to_non_nullable
              as bool?,
      originalIndex: freezed == originalIndex
          ? _value.originalIndex
          : originalIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistModelImpl extends _ArtistModel {
  const _$ArtistModelImpl(
      {required this.id,
      required final Map<String, dynamic> name,
      required this.yy,
      required this.mm,
      required this.dd,
      required this.gender,
      required this.image,
      required this.artist_group,
      required this.isBookmarked,
      this.originalIndex})
      : _name = name,
        super._();

  factory _$ArtistModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistModelImplFromJson(json);

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
  final int? yy;
  @override
  final int? mm;
  @override
  final int? dd;
  @override
  final String gender;
  @override
  final String image;
  @override
  final ArtistGroupModel artist_group;
  @override
  final bool? isBookmarked;
  @override
  final int? originalIndex;

  @override
  String toString() {
    return 'ArtistModel(id: $id, name: $name, yy: $yy, mm: $mm, dd: $dd, gender: $gender, image: $image, artist_group: $artist_group, isBookmarked: $isBookmarked, originalIndex: $originalIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._name, _name) &&
            (identical(other.yy, yy) || other.yy == yy) &&
            (identical(other.mm, mm) || other.mm == mm) &&
            (identical(other.dd, dd) || other.dd == dd) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.artist_group, artist_group) ||
                other.artist_group == artist_group) &&
            (identical(other.isBookmarked, isBookmarked) ||
                other.isBookmarked == isBookmarked) &&
            (identical(other.originalIndex, originalIndex) ||
                other.originalIndex == originalIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_name),
      yy,
      mm,
      dd,
      gender,
      image,
      artist_group,
      isBookmarked,
      originalIndex);

  /// Create a copy of ArtistModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistModelImplCopyWith<_$ArtistModelImpl> get copyWith =>
      __$$ArtistModelImplCopyWithImpl<_$ArtistModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistModelImplToJson(
      this,
    );
  }
}

abstract class _ArtistModel extends ArtistModel {
  const factory _ArtistModel(
      {required final int id,
      required final Map<String, dynamic> name,
      required final int? yy,
      required final int? mm,
      required final int? dd,
      required final String gender,
      required final String image,
      required final ArtistGroupModel artist_group,
      required final bool? isBookmarked,
      final int? originalIndex}) = _$ArtistModelImpl;
  const _ArtistModel._() : super._();

  factory _ArtistModel.fromJson(Map<String, dynamic> json) =
      _$ArtistModelImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, dynamic> get name;
  @override
  int? get yy;
  @override
  int? get mm;
  @override
  int? get dd;
  @override
  String get gender;
  @override
  String get image;
  @override
  ArtistGroupModel get artist_group;
  @override
  bool? get isBookmarked;
  @override
  int? get originalIndex;

  /// Create a copy of ArtistModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistModelImplCopyWith<_$ArtistModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
