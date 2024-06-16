// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gallery.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GalleryListModel _$GalleryListModelFromJson(Map<String, dynamic> json) {
  return _GalleryListModel.fromJson(json);
}

/// @nodoc
mixin _$GalleryListModel {
  List<GalleryModel> get items => throw _privateConstructorUsedError;
  MetaModel get meta => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GalleryListModelCopyWith<GalleryListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GalleryListModelCopyWith<$Res> {
  factory $GalleryListModelCopyWith(
          GalleryListModel value, $Res Function(GalleryListModel) then) =
      _$GalleryListModelCopyWithImpl<$Res, GalleryListModel>;
  @useResult
  $Res call({List<GalleryModel> items, MetaModel meta});

  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class _$GalleryListModelCopyWithImpl<$Res, $Val extends GalleryListModel>
    implements $GalleryListModelCopyWith<$Res> {
  _$GalleryListModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<GalleryModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MetaModelCopyWith<$Res> get meta {
    return $MetaModelCopyWith<$Res>(_value.meta, (value) {
      return _then(_value.copyWith(meta: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GalleryListModelImplCopyWith<$Res>
    implements $GalleryListModelCopyWith<$Res> {
  factory _$$GalleryListModelImplCopyWith(_$GalleryListModelImpl value,
          $Res Function(_$GalleryListModelImpl) then) =
      __$$GalleryListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<GalleryModel> items, MetaModel meta});

  @override
  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class __$$GalleryListModelImplCopyWithImpl<$Res>
    extends _$GalleryListModelCopyWithImpl<$Res, _$GalleryListModelImpl>
    implements _$$GalleryListModelImplCopyWith<$Res> {
  __$$GalleryListModelImplCopyWithImpl(_$GalleryListModelImpl _value,
      $Res Function(_$GalleryListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_$GalleryListModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<GalleryModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GalleryListModelImpl extends _GalleryListModel {
  const _$GalleryListModelImpl(
      {required final List<GalleryModel> items, required this.meta})
      : _items = items,
        super._();

  factory _$GalleryListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GalleryListModelImplFromJson(json);

  final List<GalleryModel> _items;
  @override
  List<GalleryModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final MetaModel meta;

  @override
  String toString() {
    return 'GalleryListModel(items: $items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GalleryListModelImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.meta, meta) || other.meta == meta));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_items), meta);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GalleryListModelImplCopyWith<_$GalleryListModelImpl> get copyWith =>
      __$$GalleryListModelImplCopyWithImpl<_$GalleryListModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GalleryListModelImplToJson(
      this,
    );
  }
}

abstract class _GalleryListModel extends GalleryListModel {
  const factory _GalleryListModel(
      {required final List<GalleryModel> items,
      required final MetaModel meta}) = _$GalleryListModelImpl;
  const _GalleryListModel._() : super._();

  factory _GalleryListModel.fromJson(Map<String, dynamic> json) =
      _$GalleryListModelImpl.fromJson;

  @override
  List<GalleryModel> get items;
  @override
  MetaModel get meta;
  @override
  @JsonKey(ignore: true)
  _$$GalleryListModelImplCopyWith<_$GalleryListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GalleryModel _$GalleryModelFromJson(Map<String, dynamic> json) {
  return _GalleryModel.fromJson(json);
}

/// @nodoc
mixin _$GalleryModel {
  int get id => throw _privateConstructorUsedError;
  String get title_ko => throw _privateConstructorUsedError;
  String get title_en => throw _privateConstructorUsedError;
  String? get cover => throw _privateConstructorUsedError;
  CelebModel? get celeb => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      {int id,
      String title_ko,
      String title_en,
      String? cover,
      CelebModel? celeb});

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

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title_ko = null,
    Object? title_en = null,
    Object? cover = freezed,
    Object? celeb = freezed,
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
      {int id,
      String title_ko,
      String title_en,
      String? cover,
      CelebModel? celeb});

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

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title_ko = null,
    Object? title_en = null,
    Object? cover = freezed,
    Object? celeb = freezed,
  }) {
    return _then(_$GalleryModelImpl(
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
      {required this.id,
      required this.title_ko,
      required this.title_en,
      this.cover,
      required this.celeb})
      : super._();

  factory _$GalleryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GalleryModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title_ko;
  @override
  final String title_en;
  @override
  final String? cover;
  @override
  final CelebModel? celeb;

  @override
  String toString() {
    return 'GalleryModel(id: $id, title_ko: $title_ko, title_en: $title_en, cover: $cover, celeb: $celeb)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GalleryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title_ko, title_ko) ||
                other.title_ko == title_ko) &&
            (identical(other.title_en, title_en) ||
                other.title_en == title_en) &&
            (identical(other.cover, cover) || other.cover == cover) &&
            (identical(other.celeb, celeb) || other.celeb == celeb));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title_ko, title_en, cover, celeb);

  @JsonKey(ignore: true)
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
      {required final int id,
      required final String title_ko,
      required final String title_en,
      final String? cover,
      required final CelebModel? celeb}) = _$GalleryModelImpl;
  const _GalleryModel._() : super._();

  factory _GalleryModel.fromJson(Map<String, dynamic> json) =
      _$GalleryModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title_ko;
  @override
  String get title_en;
  @override
  String? get cover;
  @override
  CelebModel? get celeb;
  @override
  @JsonKey(ignore: true)
  _$$GalleryModelImplCopyWith<_$GalleryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
