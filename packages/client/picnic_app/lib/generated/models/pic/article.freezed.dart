// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../models/pic/article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArticleModel _$ArticleModelFromJson(Map<String, dynamic> json) {
  return _ArticleModel.fromJson(json);
}

/// @nodoc
mixin _$ArticleModel {
  int get id => throw _privateConstructorUsedError;
  String get title_ko => throw _privateConstructorUsedError;
  String get title_en => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  GalleryModel? get gallery => throw _privateConstructorUsedError;
  List<ArticleImageModel>? get article_image =>
      throw _privateConstructorUsedError;
  DateTime get created_at => throw _privateConstructorUsedError;
  int? get comment_count => throw _privateConstructorUsedError;
  CommentModel? get comment => throw _privateConstructorUsedError;
  CommentModel? get most_liked_comment => throw _privateConstructorUsedError;

  /// Serializes this ArticleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArticleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArticleModelCopyWith<ArticleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArticleModelCopyWith<$Res> {
  factory $ArticleModelCopyWith(
          ArticleModel value, $Res Function(ArticleModel) then) =
      _$ArticleModelCopyWithImpl<$Res, ArticleModel>;
  @useResult
  $Res call(
      {int id,
      String title_ko,
      String title_en,
      String content,
      GalleryModel? gallery,
      List<ArticleImageModel>? article_image,
      DateTime created_at,
      int? comment_count,
      CommentModel? comment,
      CommentModel? most_liked_comment});

  $GalleryModelCopyWith<$Res>? get gallery;
  $CommentModelCopyWith<$Res>? get comment;
  $CommentModelCopyWith<$Res>? get most_liked_comment;
}

/// @nodoc
class _$ArticleModelCopyWithImpl<$Res, $Val extends ArticleModel>
    implements $ArticleModelCopyWith<$Res> {
  _$ArticleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArticleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title_ko = null,
    Object? title_en = null,
    Object? content = null,
    Object? gallery = freezed,
    Object? article_image = freezed,
    Object? created_at = null,
    Object? comment_count = freezed,
    Object? comment = freezed,
    Object? most_liked_comment = freezed,
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      gallery: freezed == gallery
          ? _value.gallery
          : gallery // ignore: cast_nullable_to_non_nullable
              as GalleryModel?,
      article_image: freezed == article_image
          ? _value.article_image
          : article_image // ignore: cast_nullable_to_non_nullable
              as List<ArticleImageModel>?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      comment_count: freezed == comment_count
          ? _value.comment_count
          : comment_count // ignore: cast_nullable_to_non_nullable
              as int?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as CommentModel?,
      most_liked_comment: freezed == most_liked_comment
          ? _value.most_liked_comment
          : most_liked_comment // ignore: cast_nullable_to_non_nullable
              as CommentModel?,
    ) as $Val);
  }

  /// Create a copy of ArticleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GalleryModelCopyWith<$Res>? get gallery {
    if (_value.gallery == null) {
      return null;
    }

    return $GalleryModelCopyWith<$Res>(_value.gallery!, (value) {
      return _then(_value.copyWith(gallery: value) as $Val);
    });
  }

  /// Create a copy of ArticleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CommentModelCopyWith<$Res>? get comment {
    if (_value.comment == null) {
      return null;
    }

    return $CommentModelCopyWith<$Res>(_value.comment!, (value) {
      return _then(_value.copyWith(comment: value) as $Val);
    });
  }

  /// Create a copy of ArticleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CommentModelCopyWith<$Res>? get most_liked_comment {
    if (_value.most_liked_comment == null) {
      return null;
    }

    return $CommentModelCopyWith<$Res>(_value.most_liked_comment!, (value) {
      return _then(_value.copyWith(most_liked_comment: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArticleModelImplCopyWith<$Res>
    implements $ArticleModelCopyWith<$Res> {
  factory _$$ArticleModelImplCopyWith(
          _$ArticleModelImpl value, $Res Function(_$ArticleModelImpl) then) =
      __$$ArticleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title_ko,
      String title_en,
      String content,
      GalleryModel? gallery,
      List<ArticleImageModel>? article_image,
      DateTime created_at,
      int? comment_count,
      CommentModel? comment,
      CommentModel? most_liked_comment});

  @override
  $GalleryModelCopyWith<$Res>? get gallery;
  @override
  $CommentModelCopyWith<$Res>? get comment;
  @override
  $CommentModelCopyWith<$Res>? get most_liked_comment;
}

/// @nodoc
class __$$ArticleModelImplCopyWithImpl<$Res>
    extends _$ArticleModelCopyWithImpl<$Res, _$ArticleModelImpl>
    implements _$$ArticleModelImplCopyWith<$Res> {
  __$$ArticleModelImplCopyWithImpl(
      _$ArticleModelImpl _value, $Res Function(_$ArticleModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArticleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title_ko = null,
    Object? title_en = null,
    Object? content = null,
    Object? gallery = freezed,
    Object? article_image = freezed,
    Object? created_at = null,
    Object? comment_count = freezed,
    Object? comment = freezed,
    Object? most_liked_comment = freezed,
  }) {
    return _then(_$ArticleModelImpl(
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      gallery: freezed == gallery
          ? _value.gallery
          : gallery // ignore: cast_nullable_to_non_nullable
              as GalleryModel?,
      article_image: freezed == article_image
          ? _value._article_image
          : article_image // ignore: cast_nullable_to_non_nullable
              as List<ArticleImageModel>?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      comment_count: freezed == comment_count
          ? _value.comment_count
          : comment_count // ignore: cast_nullable_to_non_nullable
              as int?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as CommentModel?,
      most_liked_comment: freezed == most_liked_comment
          ? _value.most_liked_comment
          : most_liked_comment // ignore: cast_nullable_to_non_nullable
              as CommentModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleModelImpl extends _ArticleModel {
  const _$ArticleModelImpl(
      {required this.id,
      required this.title_ko,
      required this.title_en,
      required this.content,
      required this.gallery,
      required final List<ArticleImageModel>? article_image,
      required this.created_at,
      required this.comment_count,
      required this.comment,
      required this.most_liked_comment})
      : _article_image = article_image,
        super._();

  factory _$ArticleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title_ko;
  @override
  final String title_en;
  @override
  final String content;
  @override
  final GalleryModel? gallery;
  final List<ArticleImageModel>? _article_image;
  @override
  List<ArticleImageModel>? get article_image {
    final value = _article_image;
    if (value == null) return null;
    if (_article_image is EqualUnmodifiableListView) return _article_image;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime created_at;
  @override
  final int? comment_count;
  @override
  final CommentModel? comment;
  @override
  final CommentModel? most_liked_comment;

  @override
  String toString() {
    return 'ArticleModel(id: $id, title_ko: $title_ko, title_en: $title_en, content: $content, gallery: $gallery, article_image: $article_image, created_at: $created_at, comment_count: $comment_count, comment: $comment, most_liked_comment: $most_liked_comment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title_ko, title_ko) ||
                other.title_ko == title_ko) &&
            (identical(other.title_en, title_en) ||
                other.title_en == title_en) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.gallery, gallery) || other.gallery == gallery) &&
            const DeepCollectionEquality()
                .equals(other._article_image, _article_image) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.comment_count, comment_count) ||
                other.comment_count == comment_count) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.most_liked_comment, most_liked_comment) ||
                other.most_liked_comment == most_liked_comment));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title_ko,
      title_en,
      content,
      gallery,
      const DeepCollectionEquality().hash(_article_image),
      created_at,
      comment_count,
      comment,
      most_liked_comment);

  /// Create a copy of ArticleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArticleModelImplCopyWith<_$ArticleModelImpl> get copyWith =>
      __$$ArticleModelImplCopyWithImpl<_$ArticleModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArticleModelImplToJson(
      this,
    );
  }
}

abstract class _ArticleModel extends ArticleModel {
  const factory _ArticleModel(
      {required final int id,
      required final String title_ko,
      required final String title_en,
      required final String content,
      required final GalleryModel? gallery,
      required final List<ArticleImageModel>? article_image,
      required final DateTime created_at,
      required final int? comment_count,
      required final CommentModel? comment,
      required final CommentModel? most_liked_comment}) = _$ArticleModelImpl;
  const _ArticleModel._() : super._();

  factory _ArticleModel.fromJson(Map<String, dynamic> json) =
      _$ArticleModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title_ko;
  @override
  String get title_en;
  @override
  String get content;
  @override
  GalleryModel? get gallery;
  @override
  List<ArticleImageModel>? get article_image;
  @override
  DateTime get created_at;
  @override
  int? get comment_count;
  @override
  CommentModel? get comment;
  @override
  CommentModel? get most_liked_comment;

  /// Create a copy of ArticleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleModelImplCopyWith<_$ArticleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
