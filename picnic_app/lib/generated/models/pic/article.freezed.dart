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
  @JsonKey(name: 'title_ko')
  String get titleKo => throw _privateConstructorUsedError;
  @JsonKey(name: 'title_en')
  String get titleEn => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  GalleryModel? get gallery => throw _privateConstructorUsedError;
  @JsonKey(name: 'article_image')
  List<ArticleImageModel>? get articleImage =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'comment_count')
  int? get commentCount => throw _privateConstructorUsedError;
  CommentModel? get comment => throw _privateConstructorUsedError;
  @JsonKey(name: 'most_liked_comment')
  CommentModel? get mostLikedComment => throw _privateConstructorUsedError;

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
      @JsonKey(name: 'title_ko') String titleKo,
      @JsonKey(name: 'title_en') String titleEn,
      String content,
      GalleryModel? gallery,
      @JsonKey(name: 'article_image') List<ArticleImageModel>? articleImage,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'comment_count') int? commentCount,
      CommentModel? comment,
      @JsonKey(name: 'most_liked_comment') CommentModel? mostLikedComment});

  $GalleryModelCopyWith<$Res>? get gallery;
  $CommentModelCopyWith<$Res>? get comment;
  $CommentModelCopyWith<$Res>? get mostLikedComment;
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
    Object? titleKo = null,
    Object? titleEn = null,
    Object? content = null,
    Object? gallery = freezed,
    Object? articleImage = freezed,
    Object? createdAt = null,
    Object? commentCount = freezed,
    Object? comment = freezed,
    Object? mostLikedComment = freezed,
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      gallery: freezed == gallery
          ? _value.gallery
          : gallery // ignore: cast_nullable_to_non_nullable
              as GalleryModel?,
      articleImage: freezed == articleImage
          ? _value.articleImage
          : articleImage // ignore: cast_nullable_to_non_nullable
              as List<ArticleImageModel>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      commentCount: freezed == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as CommentModel?,
      mostLikedComment: freezed == mostLikedComment
          ? _value.mostLikedComment
          : mostLikedComment // ignore: cast_nullable_to_non_nullable
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
  $CommentModelCopyWith<$Res>? get mostLikedComment {
    if (_value.mostLikedComment == null) {
      return null;
    }

    return $CommentModelCopyWith<$Res>(_value.mostLikedComment!, (value) {
      return _then(_value.copyWith(mostLikedComment: value) as $Val);
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
      @JsonKey(name: 'title_ko') String titleKo,
      @JsonKey(name: 'title_en') String titleEn,
      String content,
      GalleryModel? gallery,
      @JsonKey(name: 'article_image') List<ArticleImageModel>? articleImage,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'comment_count') int? commentCount,
      CommentModel? comment,
      @JsonKey(name: 'most_liked_comment') CommentModel? mostLikedComment});

  @override
  $GalleryModelCopyWith<$Res>? get gallery;
  @override
  $CommentModelCopyWith<$Res>? get comment;
  @override
  $CommentModelCopyWith<$Res>? get mostLikedComment;
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
    Object? titleKo = null,
    Object? titleEn = null,
    Object? content = null,
    Object? gallery = freezed,
    Object? articleImage = freezed,
    Object? createdAt = null,
    Object? commentCount = freezed,
    Object? comment = freezed,
    Object? mostLikedComment = freezed,
  }) {
    return _then(_$ArticleModelImpl(
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      gallery: freezed == gallery
          ? _value.gallery
          : gallery // ignore: cast_nullable_to_non_nullable
              as GalleryModel?,
      articleImage: freezed == articleImage
          ? _value._articleImage
          : articleImage // ignore: cast_nullable_to_non_nullable
              as List<ArticleImageModel>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      commentCount: freezed == commentCount
          ? _value.commentCount
          : commentCount // ignore: cast_nullable_to_non_nullable
              as int?,
      comment: freezed == comment
          ? _value.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as CommentModel?,
      mostLikedComment: freezed == mostLikedComment
          ? _value.mostLikedComment
          : mostLikedComment // ignore: cast_nullable_to_non_nullable
              as CommentModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArticleModelImpl extends _ArticleModel {
  const _$ArticleModelImpl(
      {required this.id,
      @JsonKey(name: 'title_ko') required this.titleKo,
      @JsonKey(name: 'title_en') required this.titleEn,
      required this.content,
      required this.gallery,
      @JsonKey(name: 'article_image')
      required final List<ArticleImageModel>? articleImage,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'comment_count') required this.commentCount,
      required this.comment,
      @JsonKey(name: 'most_liked_comment') required this.mostLikedComment})
      : _articleImage = articleImage,
        super._();

  factory _$ArticleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArticleModelImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'title_ko')
  final String titleKo;
  @override
  @JsonKey(name: 'title_en')
  final String titleEn;
  @override
  final String content;
  @override
  final GalleryModel? gallery;
  final List<ArticleImageModel>? _articleImage;
  @override
  @JsonKey(name: 'article_image')
  List<ArticleImageModel>? get articleImage {
    final value = _articleImage;
    if (value == null) return null;
    if (_articleImage is EqualUnmodifiableListView) return _articleImage;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'comment_count')
  final int? commentCount;
  @override
  final CommentModel? comment;
  @override
  @JsonKey(name: 'most_liked_comment')
  final CommentModel? mostLikedComment;

  @override
  String toString() {
    return 'ArticleModel(id: $id, titleKo: $titleKo, titleEn: $titleEn, content: $content, gallery: $gallery, articleImage: $articleImage, createdAt: $createdAt, commentCount: $commentCount, comment: $comment, mostLikedComment: $mostLikedComment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArticleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.titleKo, titleKo) || other.titleKo == titleKo) &&
            (identical(other.titleEn, titleEn) || other.titleEn == titleEn) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.gallery, gallery) || other.gallery == gallery) &&
            const DeepCollectionEquality()
                .equals(other._articleImage, _articleImage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.commentCount, commentCount) ||
                other.commentCount == commentCount) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.mostLikedComment, mostLikedComment) ||
                other.mostLikedComment == mostLikedComment));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      titleKo,
      titleEn,
      content,
      gallery,
      const DeepCollectionEquality().hash(_articleImage),
      createdAt,
      commentCount,
      comment,
      mostLikedComment);

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
      @JsonKey(name: 'title_ko') required final String titleKo,
      @JsonKey(name: 'title_en') required final String titleEn,
      required final String content,
      required final GalleryModel? gallery,
      @JsonKey(name: 'article_image')
      required final List<ArticleImageModel>? articleImage,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'comment_count') required final int? commentCount,
      required final CommentModel? comment,
      @JsonKey(name: 'most_liked_comment')
      required final CommentModel? mostLikedComment}) = _$ArticleModelImpl;
  const _ArticleModel._() : super._();

  factory _ArticleModel.fromJson(Map<String, dynamic> json) =
      _$ArticleModelImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'title_ko')
  String get titleKo;
  @override
  @JsonKey(name: 'title_en')
  String get titleEn;
  @override
  String get content;
  @override
  GalleryModel? get gallery;
  @override
  @JsonKey(name: 'article_image')
  List<ArticleImageModel>? get articleImage;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'comment_count')
  int? get commentCount;
  @override
  CommentModel? get comment;
  @override
  @JsonKey(name: 'most_liked_comment')
  CommentModel? get mostLikedComment;

  /// Create a copy of ArticleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArticleModelImplCopyWith<_$ArticleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
