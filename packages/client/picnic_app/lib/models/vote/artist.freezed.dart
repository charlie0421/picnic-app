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
  DateTime? get birth_date => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  ArtistGroupModel? get artist_group => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;
  DateTime? get updated_at => throw _privateConstructorUsedError;
  DateTime? get deleted_at => throw _privateConstructorUsedError;
  bool? get isBookmarked => throw _privateConstructorUsedError;

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
      DateTime? birth_date,
      String? gender,
      ArtistGroupModel? artist_group,
      String? image,
      DateTime? created_at,
      DateTime? updated_at,
      DateTime? deleted_at,
      bool? isBookmarked});

  $ArtistGroupModelCopyWith<$Res>? get artist_group;
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
    Object? birth_date = freezed,
    Object? gender = freezed,
    Object? artist_group = freezed,
    Object? image = freezed,
    Object? created_at = freezed,
    Object? updated_at = freezed,
    Object? deleted_at = freezed,
    Object? isBookmarked = freezed,
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
      birth_date: freezed == birth_date
          ? _value.birth_date
          : birth_date // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      artist_group: freezed == artist_group
          ? _value.artist_group
          : artist_group // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel?,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updated_at: freezed == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deleted_at: freezed == deleted_at
          ? _value.deleted_at
          : deleted_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isBookmarked: freezed == isBookmarked
          ? _value.isBookmarked
          : isBookmarked // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }

  /// Create a copy of ArtistModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistGroupModelCopyWith<$Res>? get artist_group {
    if (_value.artist_group == null) {
      return null;
    }

    return $ArtistGroupModelCopyWith<$Res>(_value.artist_group!, (value) {
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
      DateTime? birth_date,
      String? gender,
      ArtistGroupModel? artist_group,
      String? image,
      DateTime? created_at,
      DateTime? updated_at,
      DateTime? deleted_at,
      bool? isBookmarked});

  @override
  $ArtistGroupModelCopyWith<$Res>? get artist_group;
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
    Object? birth_date = freezed,
    Object? gender = freezed,
    Object? artist_group = freezed,
    Object? image = freezed,
    Object? created_at = freezed,
    Object? updated_at = freezed,
    Object? deleted_at = freezed,
    Object? isBookmarked = freezed,
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
      birth_date: freezed == birth_date
          ? _value.birth_date
          : birth_date // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      artist_group: freezed == artist_group
          ? _value.artist_group
          : artist_group // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel?,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updated_at: freezed == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deleted_at: freezed == deleted_at
          ? _value.deleted_at
          : deleted_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isBookmarked: freezed == isBookmarked
          ? _value.isBookmarked
          : isBookmarked // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistModelImpl extends _ArtistModel {
  const _$ArtistModelImpl(
      {required this.id,
      required final Map<String, dynamic> name,
      this.yy,
      this.mm,
      this.dd,
      this.birth_date,
      this.gender,
      this.artist_group,
      this.image,
      this.created_at,
      this.updated_at,
      this.deleted_at,
      this.isBookmarked})
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
  final DateTime? birth_date;
  @override
  final String? gender;
  @override
  final ArtistGroupModel? artist_group;
  @override
  final String? image;
  @override
  final DateTime? created_at;
  @override
  final DateTime? updated_at;
  @override
  final DateTime? deleted_at;
  @override
  final bool? isBookmarked;

  @override
  String toString() {
    return 'ArtistModel(id: $id, name: $name, yy: $yy, mm: $mm, dd: $dd, birth_date: $birth_date, gender: $gender, artist_group: $artist_group, image: $image, created_at: $created_at, updated_at: $updated_at, deleted_at: $deleted_at, isBookmarked: $isBookmarked)';
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
            (identical(other.birth_date, birth_date) ||
                other.birth_date == birth_date) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.artist_group, artist_group) ||
                other.artist_group == artist_group) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.updated_at, updated_at) ||
                other.updated_at == updated_at) &&
            (identical(other.deleted_at, deleted_at) ||
                other.deleted_at == deleted_at) &&
            (identical(other.isBookmarked, isBookmarked) ||
                other.isBookmarked == isBookmarked));
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
      birth_date,
      gender,
      artist_group,
      image,
      created_at,
      updated_at,
      deleted_at,
      isBookmarked);

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
      final int? yy,
      final int? mm,
      final int? dd,
      final DateTime? birth_date,
      final String? gender,
      final ArtistGroupModel? artist_group,
      final String? image,
      final DateTime? created_at,
      final DateTime? updated_at,
      final DateTime? deleted_at,
      final bool? isBookmarked}) = _$ArtistModelImpl;
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
  DateTime? get birth_date;
  @override
  String? get gender;
  @override
  ArtistGroupModel? get artist_group;
  @override
  String? get image;
  @override
  DateTime? get created_at;
  @override
  DateTime? get updated_at;
  @override
  DateTime? get deleted_at;
  @override
  bool? get isBookmarked;

  /// Create a copy of ArtistModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistModelImplCopyWith<_$ArtistModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
