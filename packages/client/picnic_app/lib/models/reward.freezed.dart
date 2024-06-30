// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reward.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RewardModel _$RewardModelFromJson(Map<String, dynamic> json) {
  return _RewardModel.fromJson(json);
}

/// @nodoc
mixin _$RewardModel {
  int get id => throw _privateConstructorUsedError;
  Map<String, dynamic>? get title => throw _privateConstructorUsedError;
  String? get thumbnail => throw _privateConstructorUsedError;
  List<String>? get overview_images => throw _privateConstructorUsedError;
  Map<String, dynamic>? get location => throw _privateConstructorUsedError;
  Map<String, dynamic>? get size_guide => throw _privateConstructorUsedError;
  List<String>? get size_guide_images => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RewardModelCopyWith<RewardModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RewardModelCopyWith<$Res> {
  factory $RewardModelCopyWith(
          RewardModel value, $Res Function(RewardModel) then) =
      _$RewardModelCopyWithImpl<$Res, RewardModel>;
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic>? title,
      String? thumbnail,
      List<String>? overview_images,
      Map<String, dynamic>? location,
      Map<String, dynamic>? size_guide,
      List<String>? size_guide_images});
}

/// @nodoc
class _$RewardModelCopyWithImpl<$Res, $Val extends RewardModel>
    implements $RewardModelCopyWith<$Res> {
  _$RewardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? thumbnail = freezed,
    Object? overview_images = freezed,
    Object? location = freezed,
    Object? size_guide = freezed,
    Object? size_guide_images = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
      overview_images: freezed == overview_images
          ? _value.overview_images
          : overview_images // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      size_guide: freezed == size_guide
          ? _value.size_guide
          : size_guide // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      size_guide_images: freezed == size_guide_images
          ? _value.size_guide_images
          : size_guide_images // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RewardModelImplCopyWith<$Res>
    implements $RewardModelCopyWith<$Res> {
  factory _$$RewardModelImplCopyWith(
          _$RewardModelImpl value, $Res Function(_$RewardModelImpl) then) =
      __$$RewardModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic>? title,
      String? thumbnail,
      List<String>? overview_images,
      Map<String, dynamic>? location,
      Map<String, dynamic>? size_guide,
      List<String>? size_guide_images});
}

/// @nodoc
class __$$RewardModelImplCopyWithImpl<$Res>
    extends _$RewardModelCopyWithImpl<$Res, _$RewardModelImpl>
    implements _$$RewardModelImplCopyWith<$Res> {
  __$$RewardModelImplCopyWithImpl(
      _$RewardModelImpl _value, $Res Function(_$RewardModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? thumbnail = freezed,
    Object? overview_images = freezed,
    Object? location = freezed,
    Object? size_guide = freezed,
    Object? size_guide_images = freezed,
  }) {
    return _then(_$RewardModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: freezed == title
          ? _value._title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
      overview_images: freezed == overview_images
          ? _value._overview_images
          : overview_images // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      location: freezed == location
          ? _value._location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      size_guide: freezed == size_guide
          ? _value._size_guide
          : size_guide // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      size_guide_images: freezed == size_guide_images
          ? _value._size_guide_images
          : size_guide_images // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RewardModelImpl extends _RewardModel {
  const _$RewardModelImpl(
      {required this.id,
      final Map<String, dynamic>? title,
      this.thumbnail,
      final List<String>? overview_images,
      final Map<String, dynamic>? location,
      final Map<String, dynamic>? size_guide,
      final List<String>? size_guide_images})
      : _title = title,
        _overview_images = overview_images,
        _location = location,
        _size_guide = size_guide,
        _size_guide_images = size_guide_images,
        super._();

  factory _$RewardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RewardModelImplFromJson(json);

  @override
  final int id;
  final Map<String, dynamic>? _title;
  @override
  Map<String, dynamic>? get title {
    final value = _title;
    if (value == null) return null;
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? thumbnail;
  final List<String>? _overview_images;
  @override
  List<String>? get overview_images {
    final value = _overview_images;
    if (value == null) return null;
    if (_overview_images is EqualUnmodifiableListView) return _overview_images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _location;
  @override
  Map<String, dynamic>? get location {
    final value = _location;
    if (value == null) return null;
    if (_location is EqualUnmodifiableMapView) return _location;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _size_guide;
  @override
  Map<String, dynamic>? get size_guide {
    final value = _size_guide;
    if (value == null) return null;
    if (_size_guide is EqualUnmodifiableMapView) return _size_guide;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<String>? _size_guide_images;
  @override
  List<String>? get size_guide_images {
    final value = _size_guide_images;
    if (value == null) return null;
    if (_size_guide_images is EqualUnmodifiableListView)
      return _size_guide_images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'RewardModel(id: $id, title: $title, thumbnail: $thumbnail, overview_images: $overview_images, location: $location, size_guide: $size_guide, size_guide_images: $size_guide_images)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RewardModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            const DeepCollectionEquality()
                .equals(other._overview_images, _overview_images) &&
            const DeepCollectionEquality().equals(other._location, _location) &&
            const DeepCollectionEquality()
                .equals(other._size_guide, _size_guide) &&
            const DeepCollectionEquality()
                .equals(other._size_guide_images, _size_guide_images));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_title),
      thumbnail,
      const DeepCollectionEquality().hash(_overview_images),
      const DeepCollectionEquality().hash(_location),
      const DeepCollectionEquality().hash(_size_guide),
      const DeepCollectionEquality().hash(_size_guide_images));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RewardModelImplCopyWith<_$RewardModelImpl> get copyWith =>
      __$$RewardModelImplCopyWithImpl<_$RewardModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RewardModelImplToJson(
      this,
    );
  }
}

abstract class _RewardModel extends RewardModel {
  const factory _RewardModel(
      {required final int id,
      final Map<String, dynamic>? title,
      final String? thumbnail,
      final List<String>? overview_images,
      final Map<String, dynamic>? location,
      final Map<String, dynamic>? size_guide,
      final List<String>? size_guide_images}) = _$RewardModelImpl;
  const _RewardModel._() : super._();

  factory _RewardModel.fromJson(Map<String, dynamic> json) =
      _$RewardModelImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, dynamic>? get title;
  @override
  String? get thumbnail;
  @override
  List<String>? get overview_images;
  @override
  Map<String, dynamic>? get location;
  @override
  Map<String, dynamic>? get size_guide;
  @override
  List<String>? get size_guide_images;
  @override
  @JsonKey(ignore: true)
  _$$RewardModelImplCopyWith<_$RewardModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
