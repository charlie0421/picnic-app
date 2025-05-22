// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/common/popup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Popup _$PopupFromJson(Map<String, dynamic> json) {
  return _Popup.fromJson(json);
}

/// @nodoc
mixin _$Popup {
  int get id => throw _privateConstructorUsedError;
  Map<String, String> get title => throw _privateConstructorUsedError;
  Map<String, String> get content => throw _privateConstructorUsedError;
  Map<String, String>? get image => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_at')
  DateTime? get startAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'stop_at')
  DateTime? get stopAt => throw _privateConstructorUsedError;

  /// Serializes this Popup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Popup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PopupCopyWith<Popup> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PopupCopyWith<$Res> {
  factory $PopupCopyWith(Popup value, $Res Function(Popup) then) =
      _$PopupCopyWithImpl<$Res, Popup>;
  @useResult
  $Res call(
      {int id,
      Map<String, String> title,
      Map<String, String> content,
      Map<String, String>? image,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'start_at') DateTime? startAt,
      @JsonKey(name: 'stop_at') DateTime? stopAt});
}

/// @nodoc
class _$PopupCopyWithImpl<$Res, $Val extends Popup>
    implements $PopupCopyWith<$Res> {
  _$PopupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Popup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? image = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
    Object? startAt = freezed,
    Object? stopAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startAt: freezed == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stopAt: freezed == stopAt
          ? _value.stopAt
          : stopAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PopupImplCopyWith<$Res> implements $PopupCopyWith<$Res> {
  factory _$$PopupImplCopyWith(
          _$PopupImpl value, $Res Function(_$PopupImpl) then) =
      __$$PopupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      Map<String, String> title,
      Map<String, String> content,
      Map<String, String>? image,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'start_at') DateTime? startAt,
      @JsonKey(name: 'stop_at') DateTime? stopAt});
}

/// @nodoc
class __$$PopupImplCopyWithImpl<$Res>
    extends _$PopupCopyWithImpl<$Res, _$PopupImpl>
    implements _$$PopupImplCopyWith<$Res> {
  __$$PopupImplCopyWithImpl(
      _$PopupImpl _value, $Res Function(_$PopupImpl) _then)
      : super(_value, _then);

  /// Create a copy of Popup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = null,
    Object? image = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
    Object? startAt = freezed,
    Object? stopAt = freezed,
  }) {
    return _then(_$PopupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value._title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      content: null == content
          ? _value._content
          : content // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      image: freezed == image
          ? _value._image
          : image // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startAt: freezed == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stopAt: freezed == stopAt
          ? _value.stopAt
          : stopAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PopupImpl implements _Popup {
  const _$PopupImpl(
      {required this.id,
      required final Map<String, String> title,
      required final Map<String, String> content,
      final Map<String, String>? image,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'deleted_at') this.deletedAt,
      @JsonKey(name: 'start_at') this.startAt,
      @JsonKey(name: 'stop_at') this.stopAt})
      : _title = title,
        _content = content,
        _image = image;

  factory _$PopupImpl.fromJson(Map<String, dynamic> json) =>
      _$$PopupImplFromJson(json);

  @override
  final int id;
  final Map<String, String> _title;
  @override
  Map<String, String> get title {
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_title);
  }

  final Map<String, String> _content;
  @override
  Map<String, String> get content {
    if (_content is EqualUnmodifiableMapView) return _content;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_content);
  }

  final Map<String, String>? _image;
  @override
  Map<String, String>? get image {
    final value = _image;
    if (value == null) return null;
    if (_image is EqualUnmodifiableMapView) return _image;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @override
  @JsonKey(name: 'start_at')
  final DateTime? startAt;
  @override
  @JsonKey(name: 'stop_at')
  final DateTime? stopAt;

  @override
  String toString() {
    return 'Popup(id: $id, title: $title, content: $content, image: $image, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, startAt: $startAt, stopAt: $stopAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PopupImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            const DeepCollectionEquality().equals(other._content, _content) &&
            const DeepCollectionEquality().equals(other._image, _image) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.startAt, startAt) || other.startAt == startAt) &&
            (identical(other.stopAt, stopAt) || other.stopAt == stopAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_title),
      const DeepCollectionEquality().hash(_content),
      const DeepCollectionEquality().hash(_image),
      createdAt,
      updatedAt,
      deletedAt,
      startAt,
      stopAt);

  /// Create a copy of Popup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PopupImplCopyWith<_$PopupImpl> get copyWith =>
      __$$PopupImplCopyWithImpl<_$PopupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PopupImplToJson(
      this,
    );
  }
}

abstract class _Popup implements Popup {
  const factory _Popup(
      {required final int id,
      required final Map<String, String> title,
      required final Map<String, String> content,
      final Map<String, String>? image,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt,
      @JsonKey(name: 'deleted_at') final DateTime? deletedAt,
      @JsonKey(name: 'start_at') final DateTime? startAt,
      @JsonKey(name: 'stop_at') final DateTime? stopAt}) = _$PopupImpl;

  factory _Popup.fromJson(Map<String, dynamic> json) = _$PopupImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, String> get title;
  @override
  Map<String, String> get content;
  @override
  Map<String, String>? get image;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;
  @override
  @JsonKey(name: 'start_at')
  DateTime? get startAt;
  @override
  @JsonKey(name: 'stop_at')
  DateTime? get stopAt;

  /// Create a copy of Popup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PopupImplCopyWith<_$PopupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
