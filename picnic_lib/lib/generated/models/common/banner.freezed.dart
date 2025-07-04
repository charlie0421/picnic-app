// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/common/banner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BannerModel _$BannerModelFromJson(Map<String, dynamic> json) {
  return _BannerModel.fromJson(json);
}

/// @nodoc
mixin _$BannerModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'title')
  Map<String, dynamic> get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail')
  String get thumbnail => throw _privateConstructorUsedError;
  @JsonKey(name: 'image')
  Map<String, dynamic> get image => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration', defaultValue: 3000)
  int get duration => throw _privateConstructorUsedError;
  @JsonKey(name: 'link')
  String? get link => throw _privateConstructorUsedError;

  /// Serializes this BannerModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BannerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BannerModelCopyWith<BannerModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BannerModelCopyWith<$Res> {
  factory $BannerModelCopyWith(
          BannerModel value, $Res Function(BannerModel) then) =
      _$BannerModelCopyWithImpl<$Res, BannerModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title') Map<String, dynamic> title,
      @JsonKey(name: 'thumbnail') String thumbnail,
      @JsonKey(name: 'image') Map<String, dynamic> image,
      @JsonKey(name: 'duration', defaultValue: 3000) int duration,
      @JsonKey(name: 'link') String? link});
}

/// @nodoc
class _$BannerModelCopyWithImpl<$Res, $Val extends BannerModel>
    implements $BannerModelCopyWith<$Res> {
  _$BannerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BannerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? thumbnail = null,
    Object? image = null,
    Object? duration = null,
    Object? link = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      thumbnail: null == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      link: freezed == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BannerModelImplCopyWith<$Res>
    implements $BannerModelCopyWith<$Res> {
  factory _$$BannerModelImplCopyWith(
          _$BannerModelImpl value, $Res Function(_$BannerModelImpl) then) =
      __$$BannerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title') Map<String, dynamic> title,
      @JsonKey(name: 'thumbnail') String thumbnail,
      @JsonKey(name: 'image') Map<String, dynamic> image,
      @JsonKey(name: 'duration', defaultValue: 3000) int duration,
      @JsonKey(name: 'link') String? link});
}

/// @nodoc
class __$$BannerModelImplCopyWithImpl<$Res>
    extends _$BannerModelCopyWithImpl<$Res, _$BannerModelImpl>
    implements _$$BannerModelImplCopyWith<$Res> {
  __$$BannerModelImplCopyWithImpl(
      _$BannerModelImpl _value, $Res Function(_$BannerModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of BannerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? thumbnail = null,
    Object? image = null,
    Object? duration = null,
    Object? link = freezed,
  }) {
    return _then(_$BannerModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value._title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      thumbnail: null == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value._image
          : image // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      link: freezed == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BannerModelImpl extends _BannerModel {
  const _$BannerModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'title') required final Map<String, dynamic> title,
      @JsonKey(name: 'thumbnail') required this.thumbnail,
      @JsonKey(name: 'image') required final Map<String, dynamic> image,
      @JsonKey(name: 'duration', defaultValue: 3000) required this.duration,
      @JsonKey(name: 'link') required this.link})
      : _title = title,
        _image = image,
        super._();

  factory _$BannerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BannerModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  final Map<String, dynamic> _title;
  @override
  @JsonKey(name: 'title')
  Map<String, dynamic> get title {
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_title);
  }

  @override
  @JsonKey(name: 'thumbnail')
  final String thumbnail;
  final Map<String, dynamic> _image;
  @override
  @JsonKey(name: 'image')
  Map<String, dynamic> get image {
    if (_image is EqualUnmodifiableMapView) return _image;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_image);
  }

  @override
  @JsonKey(name: 'duration', defaultValue: 3000)
  final int duration;
  @override
  @JsonKey(name: 'link')
  final String? link;

  @override
  String toString() {
    return 'BannerModel(id: $id, title: $title, thumbnail: $thumbnail, image: $image, duration: $duration, link: $link)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BannerModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            const DeepCollectionEquality().equals(other._image, _image) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.link, link) || other.link == link));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_title),
      thumbnail,
      const DeepCollectionEquality().hash(_image),
      duration,
      link);

  /// Create a copy of BannerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BannerModelImplCopyWith<_$BannerModelImpl> get copyWith =>
      __$$BannerModelImplCopyWithImpl<_$BannerModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BannerModelImplToJson(
      this,
    );
  }
}

abstract class _BannerModel extends BannerModel {
  const factory _BannerModel(
      {@JsonKey(name: 'id') required final int id,
      @JsonKey(name: 'title') required final Map<String, dynamic> title,
      @JsonKey(name: 'thumbnail') required final String thumbnail,
      @JsonKey(name: 'image') required final Map<String, dynamic> image,
      @JsonKey(name: 'duration', defaultValue: 3000)
      required final int duration,
      @JsonKey(name: 'link') required final String? link}) = _$BannerModelImpl;
  const _BannerModel._() : super._();

  factory _BannerModel.fromJson(Map<String, dynamic> json) =
      _$BannerModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'title')
  Map<String, dynamic> get title;
  @override
  @JsonKey(name: 'thumbnail')
  String get thumbnail;
  @override
  @JsonKey(name: 'image')
  Map<String, dynamic> get image;
  @override
  @JsonKey(name: 'duration', defaultValue: 3000)
  int get duration;
  @override
  @JsonKey(name: 'link')
  String? get link;

  /// Create a copy of BannerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BannerModelImplCopyWith<_$BannerModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
