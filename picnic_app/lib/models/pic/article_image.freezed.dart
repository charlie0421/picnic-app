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

  /// Serializes this ArticleImageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArticleImageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of ArticleImageModel
  /// with the given fields replaced by the non-null parameter values.
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

  /// Create a copy of ArticleImageModel
  /// with the given fields replaced by the non-null parameter values.
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title_ko, title_en, image,
      const DeepCollectionEquality().hash(_article_image_user));

  /// Create a copy of ArticleImageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of ArticleImageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleImageModelImplCopyWith<_$ArticleImageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
