// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/pic/gallery.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GalleryModel _$GalleryModelFromJson(Map<String, dynamic> json) {
  return _GalleryModel.fromJson(json);
}

/// @nodoc
mixin _$GalleryModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'title_ko')
  String get titleKo => throw _privateConstructorUsedError;
  @JsonKey(name: 'title_en')
  String get titleEn => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover')
  String? get cover => throw _privateConstructorUsedError;
  @JsonKey(name: 'celeb')
  CelebModel? get celeb => throw _privateConstructorUsedError;

  /// Serializes this GalleryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GalleryModelCopyWith<GalleryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GalleryModelCopyWith<$Res> {
  factory $GalleryModelCopyWith(
          GalleryModel value, $Res Function(GalleryModel) then) =
      _$GalleryModelCopyWithImpl<$Res, GalleryModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title_ko') String titleKo,
      @JsonKey(name: 'title_en') String titleEn,
      @JsonKey(name: 'cover') String? cover,
      @JsonKey(name: 'celeb') CelebModel? celeb});

  $CelebModelCopyWith<$Res>? get celeb;
}

/// @nodoc
class _$GalleryModelCopyWithImpl<$Res, $Val extends GalleryModel>
    implements $GalleryModelCopyWith<$Res> {
  _$GalleryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? titleKo = null,
    Object? titleEn = null,
    Object? cover = freezed,
    Object? celeb = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      titleKo: null == titleKo
          ? _value.titleKo
          : titleKo // ignore: cast_nullable_to_non_nullable
              as String,
      titleEn: null == titleEn
          ? _value.titleEn
          : titleEn // ignore: cast_nullable_to_non_nullable
              as String,
      cover: freezed == cover
          ? _value.cover
          : cover // ignore: cast_nullable_to_non_nullable
              as String?,
      celeb: freezed == celeb
          ? _value.celeb
          : celeb // ignore: cast_nullable_to_non_nullable
              as CelebModel?,
    ) as $Val);
  }

  /// Create a copy of GalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CelebModelCopyWith<$Res>? get celeb {
    if (_value.celeb == null) {
      return null;
    }

    return $CelebModelCopyWith<$Res>(_value.celeb!, (value) {
      return _then(_value.copyWith(celeb: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GalleryModelImplCopyWith<$Res>
    implements $GalleryModelCopyWith<$Res> {
  factory _$$GalleryModelImplCopyWith(
          _$GalleryModelImpl value, $Res Function(_$GalleryModelImpl) then) =
      __$$GalleryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title_ko') String titleKo,
      @JsonKey(name: 'title_en') String titleEn,
      @JsonKey(name: 'cover') String? cover,
      @JsonKey(name: 'celeb') CelebModel? celeb});

  @override
  $CelebModelCopyWith<$Res>? get celeb;
}

/// @nodoc
class __$$GalleryModelImplCopyWithImpl<$Res>
    extends _$GalleryModelCopyWithImpl<$Res, _$GalleryModelImpl>
    implements _$$GalleryModelImplCopyWith<$Res> {
  __$$GalleryModelImplCopyWithImpl(
      _$GalleryModelImpl _value, $Res Function(_$GalleryModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of GalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? titleKo = null,
    Object? titleEn = null,
    Object? cover = freezed,
    Object? celeb = freezed,
  }) {
    return _then(_$GalleryModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      titleKo: null == titleKo
          ? _value.titleKo
          : titleKo // ignore: cast_nullable_to_non_nullable
              as String,
      titleEn: null == titleEn
          ? _value.titleEn
          : titleEn // ignore: cast_nullable_to_non_nullable
              as String,
      cover: freezed == cover
          ? _value.cover
          : cover // ignore: cast_nullable_to_non_nullable
              as String?,
      celeb: freezed == celeb
          ? _value.celeb
          : celeb // ignore: cast_nullable_to_non_nullable
              as CelebModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GalleryModelImpl extends _GalleryModel {
  const _$GalleryModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'title_ko') required this.titleKo,
      @JsonKey(name: 'title_en') required this.titleEn,
      @JsonKey(name: 'cover') this.cover,
      @JsonKey(name: 'celeb') required this.celeb})
      : super._();

  factory _$GalleryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GalleryModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'title_ko')
  final String titleKo;
  @override
  @JsonKey(name: 'title_en')
  final String titleEn;
  @override
  @JsonKey(name: 'cover')
  final String? cover;
  @override
  @JsonKey(name: 'celeb')
  final CelebModel? celeb;

  @override
  String toString() {
    return 'GalleryModel(id: $id, titleKo: $titleKo, titleEn: $titleEn, cover: $cover, celeb: $celeb)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GalleryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.titleKo, titleKo) || other.titleKo == titleKo) &&
            (identical(other.titleEn, titleEn) || other.titleEn == titleEn) &&
            (identical(other.cover, cover) || other.cover == cover) &&
            (identical(other.celeb, celeb) || other.celeb == celeb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, titleKo, titleEn, cover, celeb);

  /// Create a copy of GalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GalleryModelImplCopyWith<_$GalleryModelImpl> get copyWith =>
      __$$GalleryModelImplCopyWithImpl<_$GalleryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GalleryModelImplToJson(
      this,
    );
  }
}

abstract class _GalleryModel extends GalleryModel {
  const factory _GalleryModel(
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'title_ko') required final String titleKo,
          @JsonKey(name: 'title_en') required final String titleEn,
          @JsonKey(name: 'cover') final String? cover,
          @JsonKey(name: 'celeb') required final CelebModel? celeb}) =
      _$GalleryModelImpl;
  const _GalleryModel._() : super._();

  factory _GalleryModel.fromJson(Map<String, dynamic> json) =
      _$GalleryModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'title_ko')
  String get titleKo;
  @override
  @JsonKey(name: 'title_en')
  String get titleEn;
  @override
  @JsonKey(name: 'cover')
  String? get cover;
  @override
  @JsonKey(name: 'celeb')
  CelebModel? get celeb;

  /// Create a copy of GalleryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GalleryModelImplCopyWith<_$GalleryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
