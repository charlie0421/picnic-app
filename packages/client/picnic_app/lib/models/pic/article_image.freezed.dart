// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'article_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArticleImageListModel _$ArticleImageListModelFromJson(
    Map<String, dynamic> json) {
  return _ArticleImageListModel.fromJson(json);
}

/// @nodoc
mixin _$ArticleImageListModel {
  List<ArticleImageModel> get items => throw _privateConstructorUsedError;
  MetaModel get meta => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArticleImageListModelCopyWith<ArticleImageListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleImageListModelCopyWith<$Res> {
  factory $ArticleImageListModelCopyWith(ArticleImageListModel value,
          $Res Function(ArticleImageListModel) then) =
      _$ArticleImageListModelCopyWithImpl<$Res, ArticleImageListModel>;
  @useResult
  $Res call({List<ArticleImageModel> items, MetaModel meta});

  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class _$ArticleImageListModelCopyWithImpl<$Res,
        $Val extends ArticleImageListModel>
    implements $ArticleImageListModelCopyWith<$Res> {
  _$ArticleImageListModelCopyWithImpl(this._value, this._then);

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
              as List<ArticleImageModel>,
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
abstract class _$$ArticleImageListModelImplCopyWith<$Res>
    implements $ArticleImageListModelCopyWith<$Res> {
  factory _$$ArticleImageListModelImplCopyWith(
          _$ArticleImageListModelImpl value,
          $Res Function(_$ArticleImageListModelImpl) then) =
      __$$ArticleImageListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ArticleImageModel> items, MetaModel meta});

  @override
  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class __$$ArticleImageListModelImplCopyWithImpl<$Res>
    extends _$ArticleImageListModelCopyWithImpl<$Res,
        _$ArticleImageListModelImpl>
    implements _$$ArticleImageListModelImplCopyWith<$Res> {
  __$$ArticleImageListModelImplCopyWithImpl(_$ArticleImageListModelImpl _value,
      $Res Function(_$ArticleImageListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_$ArticleImageListModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ArticleImageModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleImageListModelImpl extends _ArticleImageListModel {
  const _$ArticleImageListModelImpl(
      {required final List<ArticleImageModel> items, required this.meta})
      : _items = items,
        super._();

  factory _$ArticleImageListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleImageListModelImplFromJson(json);

  final List<ArticleImageModel> _items;
  @override
  List<ArticleImageModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final MetaModel meta;

  @override
  String toString() {
    return 'ArticleImageListModel(items: $items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleImageListModelImpl &&
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
  _$$ArticleImageListModelImplCopyWith<_$ArticleImageListModelImpl>
      get copyWith => __$$ArticleImageListModelImplCopyWithImpl<
          _$ArticleImageListModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleImageListModelImplToJson(
      this,
    );
  }
}

abstract class _ArticleImageListModel extends ArticleImageListModel {
  const factory _ArticleImageListModel(
      {required final List<ArticleImageModel> items,
      required final MetaModel meta}) = _$ArticleImageListModelImpl;
  const _ArticleImageListModel._() : super._();

  factory _ArticleImageListModel.fromJson(Map<String, dynamic> json) =
      _$ArticleImageListModelImpl.fromJson;

  @override
  List<ArticleImageModel> get items;
  @override
  MetaModel get meta;
  @override
  @JsonKey(ignore: true)
  _$$ArticleImageListModelImplCopyWith<_$ArticleImageListModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ArticleImageModel _$ArticleImageModelFromJson(Map<String, dynamic> json) {
  return _ArticleImageModel.fromJson(json);
}

/// @nodoc
mixin _$ArticleImageModel {
  int get id => throw _privateConstructorUsedError;
  String get title_ko => throw _privateConstructorUsedError;
  String get title_en => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;
  List<UserProfilesModel>? get article_image_user =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArticleImageModelCopyWith<ArticleImageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleImageModelCopyWith<$Res> {
  factory $ArticleImageModelCopyWith(
          ArticleImageModel value, $Res Function(ArticleImageModel) then) =
      _$ArticleImageModelCopyWithImpl<$Res, ArticleImageModel>;
  @useResult
  $Res call(
      {int id,
      String title_ko,
      String title_en,
      String? image,
      List<UserProfilesModel>? article_image_user});
}

/// @nodoc
class _$ArticleImageModelCopyWithImpl<$Res, $Val extends ArticleImageModel>
    implements $ArticleImageModelCopyWith<$Res> {
  _$ArticleImageModelCopyWithImpl(this._value, this._then);

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
    Object? image = freezed,
    Object? article_image_user = freezed,
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
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      article_image_user: freezed == article_image_user
          ? _value.article_image_user
          : article_image_user // ignore: cast_nullable_to_non_nullable
              as List<UserProfilesModel>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArticleImageModelImplCopyWith<$Res>
    implements $ArticleImageModelCopyWith<$Res> {
  factory _$$ArticleImageModelImplCopyWith(_$ArticleImageModelImpl value,
          $Res Function(_$ArticleImageModelImpl) then) =
      __$$ArticleImageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title_ko,
      String title_en,
      String? image,
      List<UserProfilesModel>? article_image_user});
}

/// @nodoc
class __$$ArticleImageModelImplCopyWithImpl<$Res>
    extends _$ArticleImageModelCopyWithImpl<$Res, _$ArticleImageModelImpl>
    implements _$$ArticleImageModelImplCopyWith<$Res> {
  __$$ArticleImageModelImplCopyWithImpl(_$ArticleImageModelImpl _value,
      $Res Function(_$ArticleImageModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title_ko = null,
    Object? title_en = null,
    Object? image = freezed,
    Object? article_image_user = freezed,
  }) {
    return _then(_$ArticleImageModelImpl(
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
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      article_image_user: freezed == article_image_user
          ? _value._article_image_user
          : article_image_user // ignore: cast_nullable_to_non_nullable
              as List<UserProfilesModel>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleImageModelImpl extends _ArticleImageModel {
  const _$ArticleImageModelImpl(
      {required this.id,
      required this.title_ko,
      required this.title_en,
      this.image,
      required final List<UserProfilesModel>? article_image_user})
      : _article_image_user = article_image_user,
        super._();

  factory _$ArticleImageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleImageModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title_ko;
  @override
  final String title_en;
  @override
  final String? image;
  final List<UserProfilesModel>? _article_image_user;
  @override
  List<UserProfilesModel>? get article_image_user {
    final value = _article_image_user;
    if (value == null) return null;
    if (_article_image_user is EqualUnmodifiableListView)
      return _article_image_user;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ArticleImageModel(id: $id, title_ko: $title_ko, title_en: $title_en, image: $image, article_image_user: $article_image_user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleImageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title_ko, title_ko) ||
                other.title_ko == title_ko) &&
            (identical(other.title_en, title_en) ||
                other.title_en == title_en) &&
            (identical(other.image, image) || other.image == image) &&
            const DeepCollectionEquality()
                .equals(other._article_image_user, _article_image_user));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title_ko, title_en, image,
      const DeepCollectionEquality().hash(_article_image_user));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleImageModelImplCopyWith<_$ArticleImageModelImpl> get copyWith =>
      __$$ArticleImageModelImplCopyWithImpl<_$ArticleImageModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleImageModelImplToJson(
      this,
    );
  }
}

abstract class _ArticleImageModel extends ArticleImageModel {
  const factory _ArticleImageModel(
          {required final int id,
          required final String title_ko,
          required final String title_en,
          final String? image,
          required final List<UserProfilesModel>? article_image_user}) =
      _$ArticleImageModelImpl;
  const _ArticleImageModel._() : super._();

  factory _ArticleImageModel.fromJson(Map<String, dynamic> json) =
      _$ArticleImageModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title_ko;
  @override
  String get title_en;
  @override
  String? get image;
  @override
  List<UserProfilesModel>? get article_image_user;
  @override
  @JsonKey(ignore: true)
  _$$ArticleImageModelImplCopyWith<_$ArticleImageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
