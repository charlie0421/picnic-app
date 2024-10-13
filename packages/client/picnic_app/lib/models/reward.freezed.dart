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
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'title')
  Map<String, dynamic>? get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail')
  String? get thumbnail => throw _privateConstructorUsedError;
  @JsonKey(name: 'overview_images')
  List<String>? get overviewImages => throw _privateConstructorUsedError;
  @JsonKey(name: 'location')
  Map<String, dynamic>? get location => throw _privateConstructorUsedError;
  @JsonKey(name: 'size_guide')
  Map<String, dynamic>? get sizeGuide => throw _privateConstructorUsedError;
  @JsonKey(name: 'size_guide_images')
  List<String>? get size_guide_images => throw _privateConstructorUsedError;

  /// Serializes this RewardModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RewardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title') Map<String, dynamic>? title,
      @JsonKey(name: 'thumbnail') String? thumbnail,
      @JsonKey(name: 'overview_images') List<String>? overviewImages,
      @JsonKey(name: 'location') Map<String, dynamic>? location,
      @JsonKey(name: 'size_guide') Map<String, dynamic>? sizeGuide,
      @JsonKey(name: 'size_guide_images') List<String>? size_guide_images});
}

/// @nodoc
class _$RewardModelCopyWithImpl<$Res, $Val extends RewardModel>
    implements $RewardModelCopyWith<$Res> {
  _$RewardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RewardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? thumbnail = freezed,
    Object? overviewImages = freezed,
    Object? location = freezed,
    Object? sizeGuide = freezed,
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
      overviewImages: freezed == overviewImages
          ? _value.overviewImages
          : overviewImages // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      sizeGuide: freezed == sizeGuide
          ? _value.sizeGuide
          : sizeGuide // ignore: cast_nullable_to_non_nullable
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title') Map<String, dynamic>? title,
      @JsonKey(name: 'thumbnail') String? thumbnail,
      @JsonKey(name: 'overview_images') List<String>? overviewImages,
      @JsonKey(name: 'location') Map<String, dynamic>? location,
      @JsonKey(name: 'size_guide') Map<String, dynamic>? sizeGuide,
      @JsonKey(name: 'size_guide_images') List<String>? size_guide_images});
}

/// @nodoc
class __$$RewardModelImplCopyWithImpl<$Res>
    extends _$RewardModelCopyWithImpl<$Res, _$RewardModelImpl>
    implements _$$RewardModelImplCopyWith<$Res> {
  __$$RewardModelImplCopyWithImpl(
      _$RewardModelImpl _value, $Res Function(_$RewardModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of RewardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? thumbnail = freezed,
    Object? overviewImages = freezed,
    Object? location = freezed,
    Object? sizeGuide = freezed,
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
      overviewImages: freezed == overviewImages
          ? _value._overviewImages
          : overviewImages // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      location: freezed == location
          ? _value._location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      sizeGuide: freezed == sizeGuide
          ? _value._sizeGuide
          : sizeGuide // ignore: cast_nullable_to_non_nullable
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
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'title') final Map<String, dynamic>? title,
      @JsonKey(name: 'thumbnail') this.thumbnail,
      @JsonKey(name: 'overview_images') final List<String>? overviewImages,
      @JsonKey(name: 'location') final Map<String, dynamic>? location,
      @JsonKey(name: 'size_guide') final Map<String, dynamic>? sizeGuide,
      @JsonKey(name: 'size_guide_images')
      final List<String>? size_guide_images})
      : _title = title,
        _overviewImages = overviewImages,
        _location = location,
        _sizeGuide = sizeGuide,
        _size_guide_images = size_guide_images,
        super._();

  factory _$RewardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RewardModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  final Map<String, dynamic>? _title;
  @override
  @JsonKey(name: 'title')
  Map<String, dynamic>? get title {
    final value = _title;
    if (value == null) return null;
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'thumbnail')
  final String? thumbnail;
  final List<String>? _overviewImages;
  @override
  @JsonKey(name: 'overview_images')
  List<String>? get overviewImages {
    final value = _overviewImages;
    if (value == null) return null;
    if (_overviewImages is EqualUnmodifiableListView) return _overviewImages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _location;
  @override
  @JsonKey(name: 'location')
  Map<String, dynamic>? get location {
    final value = _location;
    if (value == null) return null;
    if (_location is EqualUnmodifiableMapView) return _location;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _sizeGuide;
  @override
  @JsonKey(name: 'size_guide')
  Map<String, dynamic>? get sizeGuide {
    final value = _sizeGuide;
    if (value == null) return null;
    if (_sizeGuide is EqualUnmodifiableMapView) return _sizeGuide;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<String>? _size_guide_images;
  @override
  @JsonKey(name: 'size_guide_images')
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
    return 'RewardModel(id: $id, title: $title, thumbnail: $thumbnail, overviewImages: $overviewImages, location: $location, sizeGuide: $sizeGuide, size_guide_images: $size_guide_images)';
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
                .equals(other._overviewImages, _overviewImages) &&
            const DeepCollectionEquality().equals(other._location, _location) &&
            const DeepCollectionEquality()
                .equals(other._sizeGuide, _sizeGuide) &&
            const DeepCollectionEquality()
                .equals(other._size_guide_images, _size_guide_images));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_title),
      thumbnail,
      const DeepCollectionEquality().hash(_overviewImages),
      const DeepCollectionEquality().hash(_location),
      const DeepCollectionEquality().hash(_sizeGuide),
      const DeepCollectionEquality().hash(_size_guide_images));

  /// Create a copy of RewardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') required final int id,
      @JsonKey(name: 'title') final Map<String, dynamic>? title,
      @JsonKey(name: 'thumbnail') final String? thumbnail,
      @JsonKey(name: 'overview_images') final List<String>? overviewImages,
      @JsonKey(name: 'location') final Map<String, dynamic>? location,
      @JsonKey(name: 'size_guide') final Map<String, dynamic>? sizeGuide,
      @JsonKey(name: 'size_guide_images')
      final List<String>? size_guide_images}) = _$RewardModelImpl;
  const _RewardModel._() : super._();

  factory _RewardModel.fromJson(Map<String, dynamic> json) =
      _$RewardModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'title')
  Map<String, dynamic>? get title;
  @override
  @JsonKey(name: 'thumbnail')
  String? get thumbnail;
  @override
  @JsonKey(name: 'overview_images')
  List<String>? get overviewImages;
  @override
  @JsonKey(name: 'location')
  Map<String, dynamic>? get location;
  @override
  @JsonKey(name: 'size_guide')
  Map<String, dynamic>? get sizeGuide;
  @override
  @JsonKey(name: 'size_guide_images')
  List<String>? get size_guide_images;

  /// Create a copy of RewardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RewardModelImplCopyWith<_$RewardModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
