// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VideoInfo _$VideoInfoFromJson(Map<String, dynamic> json) {
  return _VideoInfo.fromJson(json);
}

/// @nodoc
mixin _$VideoInfo {
  int get id => throw _privateConstructorUsedError;
  String get video_id => throw _privateConstructorUsedError;
  Map<String, String> get title => throw _privateConstructorUsedError;
  String get thumbnail_url => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VideoInfoCopyWith<VideoInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoInfoCopyWith<$Res> {
  factory $VideoInfoCopyWith(VideoInfo value, $Res Function(VideoInfo) then) =
      _$VideoInfoCopyWithImpl<$Res, VideoInfo>;
  @useResult
  $Res call(
      {int id,
      String video_id,
      Map<String, String> title,
      String thumbnail_url});
}

/// @nodoc
class _$VideoInfoCopyWithImpl<$Res, $Val extends VideoInfo>
    implements $VideoInfoCopyWith<$Res> {
  _$VideoInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? video_id = null,
    Object? title = null,
    Object? thumbnail_url = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      video_id: null == video_id
          ? _value.video_id
          : video_id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      thumbnail_url: null == thumbnail_url
          ? _value.thumbnail_url
          : thumbnail_url // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VideoInfoImplCopyWith<$Res>
    implements $VideoInfoCopyWith<$Res> {
  factory _$$VideoInfoImplCopyWith(
          _$VideoInfoImpl value, $Res Function(_$VideoInfoImpl) then) =
      __$$VideoInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String video_id,
      Map<String, String> title,
      String thumbnail_url});
}

/// @nodoc
class __$$VideoInfoImplCopyWithImpl<$Res>
    extends _$VideoInfoCopyWithImpl<$Res, _$VideoInfoImpl>
    implements _$$VideoInfoImplCopyWith<$Res> {
  __$$VideoInfoImplCopyWithImpl(
      _$VideoInfoImpl _value, $Res Function(_$VideoInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? video_id = null,
    Object? title = null,
    Object? thumbnail_url = null,
  }) {
    return _then(_$VideoInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      video_id: null == video_id
          ? _value.video_id
          : video_id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value._title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      thumbnail_url: null == thumbnail_url
          ? _value.thumbnail_url
          : thumbnail_url // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoInfoImpl implements _VideoInfo {
  const _$VideoInfoImpl(
      {required this.id,
      required this.video_id,
      required final Map<String, String> title,
      required this.thumbnail_url})
      : _title = title;

  factory _$VideoInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoInfoImplFromJson(json);

  @override
  final int id;
  @override
  final String video_id;
  final Map<String, String> _title;
  @override
  Map<String, String> get title {
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_title);
  }

  @override
  final String thumbnail_url;

  @override
  String toString() {
    return 'VideoInfo(id: $id, video_id: $video_id, title: $title, thumbnail_url: $thumbnail_url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.video_id, video_id) ||
                other.video_id == video_id) &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            (identical(other.thumbnail_url, thumbnail_url) ||
                other.thumbnail_url == thumbnail_url));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, video_id,
      const DeepCollectionEquality().hash(_title), thumbnail_url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoInfoImplCopyWith<_$VideoInfoImpl> get copyWith =>
      __$$VideoInfoImplCopyWithImpl<_$VideoInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoInfoImplToJson(
      this,
    );
  }
}

abstract class _VideoInfo implements VideoInfo {
  const factory _VideoInfo(
      {required final int id,
      required final String video_id,
      required final Map<String, String> title,
      required final String thumbnail_url}) = _$VideoInfoImpl;

  factory _VideoInfo.fromJson(Map<String, dynamic> json) =
      _$VideoInfoImpl.fromJson;

  @override
  int get id;
  @override
  String get video_id;
  @override
  Map<String, String> get title;
  @override
  String get thumbnail_url;
  @override
  @JsonKey(ignore: true)
  _$$VideoInfoImplCopyWith<_$VideoInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
