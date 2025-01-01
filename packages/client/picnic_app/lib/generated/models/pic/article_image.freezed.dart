// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/pic/article_image.dart';

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
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'title_ko')
  String get titleKo => throw _privateConstructorUsedError;
  @JsonKey(name: 'title_en')
  String get titleEn => throw _privateConstructorUsedError;
  @JsonKey(name: 'image')
  String? get image => throw _privateConstructorUsedError;
  @JsonKey(name: 'article_image_user')
  List<UserProfilesModel>? get articleImageUser =>
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title_ko') String titleKo,
      @JsonKey(name: 'title_en') String titleEn,
      @JsonKey(name: 'image') String? image,
      @JsonKey(name: 'article_image_user')
      List<UserProfilesModel>? articleImageUser});
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
    Object? titleKo = null,
    Object? titleEn = null,
    Object? image = freezed,
    Object? articleImageUser = freezed,
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
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      articleImageUser: freezed == articleImageUser
          ? _value.articleImageUser
          : articleImageUser // ignore: cast_nullable_to_non_nullable
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title_ko') String titleKo,
      @JsonKey(name: 'title_en') String titleEn,
      @JsonKey(name: 'image') String? image,
      @JsonKey(name: 'article_image_user')
      List<UserProfilesModel>? articleImageUser});
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
    Object? titleKo = null,
    Object? titleEn = null,
    Object? image = freezed,
    Object? articleImageUser = freezed,
  }) {
    return _then(_$ArticleImageModelImpl(
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
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      articleImageUser: freezed == articleImageUser
          ? _value._articleImageUser
          : articleImageUser // ignore: cast_nullable_to_non_nullable
              as List<UserProfilesModel>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleImageModelImpl extends _ArticleImageModel {
  const _$ArticleImageModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'title_ko') required this.titleKo,
      @JsonKey(name: 'title_en') required this.titleEn,
      @JsonKey(name: 'image') this.image,
      @JsonKey(name: 'article_image_user')
      required final List<UserProfilesModel>? articleImageUser})
      : _articleImageUser = articleImageUser,
        super._();

  factory _$ArticleImageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleImageModelImplFromJson(json);

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
  @JsonKey(name: 'image')
  final String? image;
  final List<UserProfilesModel>? _articleImageUser;
  @override
  @JsonKey(name: 'article_image_user')
  List<UserProfilesModel>? get articleImageUser {
    final value = _articleImageUser;
    if (value == null) return null;
    if (_articleImageUser is EqualUnmodifiableListView)
      return _articleImageUser;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ArticleImageModel(id: $id, titleKo: $titleKo, titleEn: $titleEn, image: $image, articleImageUser: $articleImageUser)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleImageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.titleKo, titleKo) || other.titleKo == titleKo) &&
            (identical(other.titleEn, titleEn) || other.titleEn == titleEn) &&
            (identical(other.image, image) || other.image == image) &&
            const DeepCollectionEquality()
                .equals(other._articleImageUser, _articleImageUser));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, titleKo, titleEn, image,
      const DeepCollectionEquality().hash(_articleImageUser));

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
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'title_ko') required final String titleKo,
          @JsonKey(name: 'title_en') required final String titleEn,
          @JsonKey(name: 'image') final String? image,
          @JsonKey(name: 'article_image_user')
          required final List<UserProfilesModel>? articleImageUser}) =
      _$ArticleImageModelImpl;
  const _ArticleImageModel._() : super._();

  factory _ArticleImageModel.fromJson(Map<String, dynamic> json) =
      _$ArticleImageModelImpl.fromJson;

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
  @JsonKey(name: 'image')
  String? get image;
  @override
  @JsonKey(name: 'article_image_user')
  List<UserProfilesModel>? get articleImageUser;

  /// Create a copy of ArticleImageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleImageModelImplCopyWith<_$ArticleImageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
