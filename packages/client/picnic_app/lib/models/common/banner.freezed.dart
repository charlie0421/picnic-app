// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'banner.dart';

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
  int get id => throw _privateConstructorUsedError;
  String get title_ko => throw _privateConstructorUsedError;
  String get title_en => throw _privateConstructorUsedError;
  String get title_ja => throw _privateConstructorUsedError;
  String get title_zh => throw _privateConstructorUsedError;
  String? get thumbnail => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      {int id,
      String title_ko,
      String title_en,
      String title_ja,
      String title_zh,
      String? thumbnail});
}

/// @nodoc
class _$BannerModelCopyWithImpl<$Res, $Val extends BannerModel>
    implements $BannerModelCopyWith<$Res> {
  _$BannerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title_ko = null,
    Object? title_en = null,
    Object? title_ja = null,
    Object? title_zh = null,
    Object? thumbnail = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title_ko: null == title_ko
          ? _value.title_ko
          : title_ko // ignore: cast_nullable_to_non_nullable
              as String,
      title_en: null == title_en
          ? _value.title_en
          : title_en // ignore: cast_nullable_to_non_nullable
              as String,
      title_ja: null == title_ja
          ? _value.title_ja
          : title_ja // ignore: cast_nullable_to_non_nullable
              as String,
      title_zh: null == title_zh
          ? _value.title_zh
          : title_zh // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
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
      {int id,
      String title_ko,
      String title_en,
      String title_ja,
      String title_zh,
      String? thumbnail});
}

/// @nodoc
class __$$BannerModelImplCopyWithImpl<$Res>
    extends _$BannerModelCopyWithImpl<$Res, _$BannerModelImpl>
    implements _$$BannerModelImplCopyWith<$Res> {
  __$$BannerModelImplCopyWithImpl(
      _$BannerModelImpl _value, $Res Function(_$BannerModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title_ko = null,
    Object? title_en = null,
    Object? title_ja = null,
    Object? title_zh = null,
    Object? thumbnail = freezed,
  }) {
    return _then(_$BannerModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title_ko: null == title_ko
          ? _value.title_ko
          : title_ko // ignore: cast_nullable_to_non_nullable
              as String,
      title_en: null == title_en
          ? _value.title_en
          : title_en // ignore: cast_nullable_to_non_nullable
              as String,
      title_ja: null == title_ja
          ? _value.title_ja
          : title_ja // ignore: cast_nullable_to_non_nullable
              as String,
      title_zh: null == title_zh
          ? _value.title_zh
          : title_zh // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BannerModelImpl extends _BannerModel {
  const _$BannerModelImpl(
      {required this.id,
      required this.title_ko,
      required this.title_en,
      required this.title_ja,
      required this.title_zh,
      this.thumbnail})
      : super._();

  factory _$BannerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BannerModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title_ko;
  @override
  final String title_en;
  @override
  final String title_ja;
  @override
  final String title_zh;
  @override
  final String? thumbnail;

  @override
  String toString() {
    return 'BannerModel(id: $id, title_ko: $title_ko, title_en: $title_en, title_ja: $title_ja, title_zh: $title_zh, thumbnail: $thumbnail)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BannerModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title_ko, title_ko) ||
                other.title_ko == title_ko) &&
            (identical(other.title_en, title_en) ||
                other.title_en == title_en) &&
            (identical(other.title_ja, title_ja) ||
                other.title_ja == title_ja) &&
            (identical(other.title_zh, title_zh) ||
                other.title_zh == title_zh) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, title_ko, title_en, title_ja, title_zh, thumbnail);

  @JsonKey(ignore: true)
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
      {required final int id,
      required final String title_ko,
      required final String title_en,
      required final String title_ja,
      required final String title_zh,
      final String? thumbnail}) = _$BannerModelImpl;
  const _BannerModel._() : super._();

  factory _BannerModel.fromJson(Map<String, dynamic> json) =
      _$BannerModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title_ko;
  @override
  String get title_en;
  @override
  String get title_ja;
  @override
  String get title_zh;
  @override
  String? get thumbnail;
  @override
  @JsonKey(ignore: true)
  _$$BannerModelImplCopyWith<_$BannerModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
