// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LibraryListModel _$LibraryListModelFromJson(Map<String, dynamic> json) {
  return _LibraryListModel.fromJson(json);
}

/// @nodoc
mixin _$LibraryListModel {
  List<LibraryModel> get items => throw _privateConstructorUsedError;
  MetaModel get meta => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LibraryListModelCopyWith<LibraryListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryListModelCopyWith<$Res> {
  factory $LibraryListModelCopyWith(
          LibraryListModel value, $Res Function(LibraryListModel) then) =
      _$LibraryListModelCopyWithImpl<$Res, LibraryListModel>;
  @useResult
  $Res call({List<LibraryModel> items, MetaModel meta});

  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class _$LibraryListModelCopyWithImpl<$Res, $Val extends LibraryListModel>
    implements $LibraryListModelCopyWith<$Res> {
  _$LibraryListModelCopyWithImpl(this._value, this._then);

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
              as List<LibraryModel>,
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
abstract class _$$LibraryListModelImplCopyWith<$Res>
    implements $LibraryListModelCopyWith<$Res> {
  factory _$$LibraryListModelImplCopyWith(_$LibraryListModelImpl value,
          $Res Function(_$LibraryListModelImpl) then) =
      __$$LibraryListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<LibraryModel> items, MetaModel meta});

  @override
  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class __$$LibraryListModelImplCopyWithImpl<$Res>
    extends _$LibraryListModelCopyWithImpl<$Res, _$LibraryListModelImpl>
    implements _$$LibraryListModelImplCopyWith<$Res> {
  __$$LibraryListModelImplCopyWithImpl(_$LibraryListModelImpl _value,
      $Res Function(_$LibraryListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_$LibraryListModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<LibraryModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LibraryListModelImpl extends _LibraryListModel {
  const _$LibraryListModelImpl(
      {required final List<LibraryModel> items, required this.meta})
      : _items = items,
        super._();

  factory _$LibraryListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LibraryListModelImplFromJson(json);

  final List<LibraryModel> _items;
  @override
  List<LibraryModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final MetaModel meta;

  @override
  String toString() {
    return 'LibraryListModel(items: $items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryListModelImpl &&
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
  _$$LibraryListModelImplCopyWith<_$LibraryListModelImpl> get copyWith =>
      __$$LibraryListModelImplCopyWithImpl<_$LibraryListModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LibraryListModelImplToJson(
      this,
    );
  }
}

abstract class _LibraryListModel extends LibraryListModel {
  const factory _LibraryListModel(
      {required final List<LibraryModel> items,
      required final MetaModel meta}) = _$LibraryListModelImpl;
  const _LibraryListModel._() : super._();

  factory _LibraryListModel.fromJson(Map<String, dynamic> json) =
      _$LibraryListModelImpl.fromJson;

  @override
  List<LibraryModel> get items;
  @override
  MetaModel get meta;
  @override
  @JsonKey(ignore: true)
  _$$LibraryListModelImplCopyWith<_$LibraryListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LibraryModel _$LibraryModelFromJson(Map<String, dynamic> json) {
  return _LibraryModel.fromJson(json);
}

/// @nodoc
mixin _$LibraryModel {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<ArticleImageModel>? get images => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LibraryModelCopyWith<LibraryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryModelCopyWith<$Res> {
  factory $LibraryModelCopyWith(
          LibraryModel value, $Res Function(LibraryModel) then) =
      _$LibraryModelCopyWithImpl<$Res, LibraryModel>;
  @useResult
  $Res call({int id, String title, List<ArticleImageModel>? images});
}

/// @nodoc
class _$LibraryModelCopyWithImpl<$Res, $Val extends LibraryModel>
    implements $LibraryModelCopyWith<$Res> {
  _$LibraryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? images = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      images: freezed == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<ArticleImageModel>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LibraryModelImplCopyWith<$Res>
    implements $LibraryModelCopyWith<$Res> {
  factory _$$LibraryModelImplCopyWith(
          _$LibraryModelImpl value, $Res Function(_$LibraryModelImpl) then) =
      __$$LibraryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String title, List<ArticleImageModel>? images});
}

/// @nodoc
class __$$LibraryModelImplCopyWithImpl<$Res>
    extends _$LibraryModelCopyWithImpl<$Res, _$LibraryModelImpl>
    implements _$$LibraryModelImplCopyWith<$Res> {
  __$$LibraryModelImplCopyWithImpl(
      _$LibraryModelImpl _value, $Res Function(_$LibraryModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? images = freezed,
  }) {
    return _then(_$LibraryModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      images: freezed == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<ArticleImageModel>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LibraryModelImpl extends _LibraryModel {
  const _$LibraryModelImpl(
      {required this.id,
      required this.title,
      required final List<ArticleImageModel>? images})
      : _images = images,
        super._();

  factory _$LibraryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LibraryModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  final List<ArticleImageModel>? _images;
  @override
  List<ArticleImageModel>? get images {
    final value = _images;
    if (value == null) return null;
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'LibraryModel(id: $id, title: $title, images: $images)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._images, _images));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, title, const DeepCollectionEquality().hash(_images));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LibraryModelImplCopyWith<_$LibraryModelImpl> get copyWith =>
      __$$LibraryModelImplCopyWithImpl<_$LibraryModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LibraryModelImplToJson(
      this,
    );
  }
}

abstract class _LibraryModel extends LibraryModel {
  const factory _LibraryModel(
      {required final int id,
      required final String title,
      required final List<ArticleImageModel>? images}) = _$LibraryModelImpl;
  const _LibraryModel._() : super._();

  factory _LibraryModel.fromJson(Map<String, dynamic> json) =
      _$LibraryModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  List<ArticleImageModel>? get images;
  @override
  @JsonKey(ignore: true)
  _$$LibraryModelImplCopyWith<_$LibraryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
