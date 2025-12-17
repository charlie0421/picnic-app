// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/pic/article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArticleModel {

 int get id;@JsonKey(name: 'title_ko') String get titleKo;@JsonKey(name: 'title_en') String get titleEn; String get content; GalleryModel? get gallery;@JsonKey(name: 'article_image') List<ArticleImageModel>? get articleImage;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'comment_count') int? get commentCount; CommentModel? get comment;@JsonKey(name: 'most_liked_comment') CommentModel? get mostLikedComment;
/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleModelCopyWith<ArticleModel> get copyWith => _$ArticleModelCopyWithImpl<ArticleModel>(this as ArticleModel, _$identity);

  /// Serializes this ArticleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.titleKo, titleKo) || other.titleKo == titleKo)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.content, content) || other.content == content)&&(identical(other.gallery, gallery) || other.gallery == gallery)&&const DeepCollectionEquality().equals(other.articleImage, articleImage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.mostLikedComment, mostLikedComment) || other.mostLikedComment == mostLikedComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleKo,titleEn,content,gallery,const DeepCollectionEquality().hash(articleImage),createdAt,commentCount,comment,mostLikedComment);

@override
String toString() {
  return 'ArticleModel(id: $id, titleKo: $titleKo, titleEn: $titleEn, content: $content, gallery: $gallery, articleImage: $articleImage, createdAt: $createdAt, commentCount: $commentCount, comment: $comment, mostLikedComment: $mostLikedComment)';
}


}

/// @nodoc
abstract mixin class $ArticleModelCopyWith<$Res>  {
  factory $ArticleModelCopyWith(ArticleModel value, $Res Function(ArticleModel) _then) = _$ArticleModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'title_ko') String titleKo,@JsonKey(name: 'title_en') String titleEn, String content, GalleryModel? gallery,@JsonKey(name: 'article_image') List<ArticleImageModel>? articleImage,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'comment_count') int? commentCount, CommentModel? comment,@JsonKey(name: 'most_liked_comment') CommentModel? mostLikedComment
});


$GalleryModelCopyWith<$Res>? get gallery;$CommentModelCopyWith<$Res>? get comment;$CommentModelCopyWith<$Res>? get mostLikedComment;

}
/// @nodoc
class _$ArticleModelCopyWithImpl<$Res>
    implements $ArticleModelCopyWith<$Res> {
  _$ArticleModelCopyWithImpl(this._self, this._then);

  final ArticleModel _self;
  final $Res Function(ArticleModel) _then;

/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titleKo = null,Object? titleEn = null,Object? content = null,Object? gallery = freezed,Object? articleImage = freezed,Object? createdAt = null,Object? commentCount = freezed,Object? comment = freezed,Object? mostLikedComment = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titleKo: null == titleKo ? _self.titleKo : titleKo // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,gallery: freezed == gallery ? _self.gallery : gallery // ignore: cast_nullable_to_non_nullable
as GalleryModel?,articleImage: freezed == articleImage ? _self.articleImage : articleImage // ignore: cast_nullable_to_non_nullable
as List<ArticleImageModel>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,commentCount: freezed == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as CommentModel?,mostLikedComment: freezed == mostLikedComment ? _self.mostLikedComment : mostLikedComment // ignore: cast_nullable_to_non_nullable
as CommentModel?,
  ));
}
/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GalleryModelCopyWith<$Res>? get gallery {
    if (_self.gallery == null) {
    return null;
  }

  return $GalleryModelCopyWith<$Res>(_self.gallery!, (value) {
    return _then(_self.copyWith(gallery: value));
  });
}/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentModelCopyWith<$Res>? get comment {
    if (_self.comment == null) {
    return null;
  }

  return $CommentModelCopyWith<$Res>(_self.comment!, (value) {
    return _then(_self.copyWith(comment: value));
  });
}/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentModelCopyWith<$Res>? get mostLikedComment {
    if (_self.mostLikedComment == null) {
    return null;
  }

  return $CommentModelCopyWith<$Res>(_self.mostLikedComment!, (value) {
    return _then(_self.copyWith(mostLikedComment: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArticleModel].
extension ArticleModelPatterns on ArticleModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'title_ko')  String titleKo, @JsonKey(name: 'title_en')  String titleEn,  String content,  GalleryModel? gallery, @JsonKey(name: 'article_image')  List<ArticleImageModel>? articleImage, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'comment_count')  int? commentCount,  CommentModel? comment, @JsonKey(name: 'most_liked_comment')  CommentModel? mostLikedComment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleModel() when $default != null:
return $default(_that.id,_that.titleKo,_that.titleEn,_that.content,_that.gallery,_that.articleImage,_that.createdAt,_that.commentCount,_that.comment,_that.mostLikedComment);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'title_ko')  String titleKo, @JsonKey(name: 'title_en')  String titleEn,  String content,  GalleryModel? gallery, @JsonKey(name: 'article_image')  List<ArticleImageModel>? articleImage, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'comment_count')  int? commentCount,  CommentModel? comment, @JsonKey(name: 'most_liked_comment')  CommentModel? mostLikedComment)  $default,) {final _that = this;
switch (_that) {
case _ArticleModel():
return $default(_that.id,_that.titleKo,_that.titleEn,_that.content,_that.gallery,_that.articleImage,_that.createdAt,_that.commentCount,_that.comment,_that.mostLikedComment);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'title_ko')  String titleKo, @JsonKey(name: 'title_en')  String titleEn,  String content,  GalleryModel? gallery, @JsonKey(name: 'article_image')  List<ArticleImageModel>? articleImage, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'comment_count')  int? commentCount,  CommentModel? comment, @JsonKey(name: 'most_liked_comment')  CommentModel? mostLikedComment)?  $default,) {final _that = this;
switch (_that) {
case _ArticleModel() when $default != null:
return $default(_that.id,_that.titleKo,_that.titleEn,_that.content,_that.gallery,_that.articleImage,_that.createdAt,_that.commentCount,_that.comment,_that.mostLikedComment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleModel extends ArticleModel {
  const _ArticleModel({required this.id, @JsonKey(name: 'title_ko') required this.titleKo, @JsonKey(name: 'title_en') required this.titleEn, required this.content, required this.gallery, @JsonKey(name: 'article_image') required final  List<ArticleImageModel>? articleImage, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'comment_count') required this.commentCount, required this.comment, @JsonKey(name: 'most_liked_comment') required this.mostLikedComment}): _articleImage = articleImage,super._();
  factory _ArticleModel.fromJson(Map<String, dynamic> json) => _$ArticleModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'title_ko') final  String titleKo;
@override@JsonKey(name: 'title_en') final  String titleEn;
@override final  String content;
@override final  GalleryModel? gallery;
 final  List<ArticleImageModel>? _articleImage;
@override@JsonKey(name: 'article_image') List<ArticleImageModel>? get articleImage {
  final value = _articleImage;
  if (value == null) return null;
  if (_articleImage is EqualUnmodifiableListView) return _articleImage;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'comment_count') final  int? commentCount;
@override final  CommentModel? comment;
@override@JsonKey(name: 'most_liked_comment') final  CommentModel? mostLikedComment;

/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleModelCopyWith<_ArticleModel> get copyWith => __$ArticleModelCopyWithImpl<_ArticleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.titleKo, titleKo) || other.titleKo == titleKo)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.content, content) || other.content == content)&&(identical(other.gallery, gallery) || other.gallery == gallery)&&const DeepCollectionEquality().equals(other._articleImage, _articleImage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.mostLikedComment, mostLikedComment) || other.mostLikedComment == mostLikedComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleKo,titleEn,content,gallery,const DeepCollectionEquality().hash(_articleImage),createdAt,commentCount,comment,mostLikedComment);

@override
String toString() {
  return 'ArticleModel(id: $id, titleKo: $titleKo, titleEn: $titleEn, content: $content, gallery: $gallery, articleImage: $articleImage, createdAt: $createdAt, commentCount: $commentCount, comment: $comment, mostLikedComment: $mostLikedComment)';
}


}

/// @nodoc
abstract mixin class _$ArticleModelCopyWith<$Res> implements $ArticleModelCopyWith<$Res> {
  factory _$ArticleModelCopyWith(_ArticleModel value, $Res Function(_ArticleModel) _then) = __$ArticleModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'title_ko') String titleKo,@JsonKey(name: 'title_en') String titleEn, String content, GalleryModel? gallery,@JsonKey(name: 'article_image') List<ArticleImageModel>? articleImage,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'comment_count') int? commentCount, CommentModel? comment,@JsonKey(name: 'most_liked_comment') CommentModel? mostLikedComment
});


@override $GalleryModelCopyWith<$Res>? get gallery;@override $CommentModelCopyWith<$Res>? get comment;@override $CommentModelCopyWith<$Res>? get mostLikedComment;

}
/// @nodoc
class __$ArticleModelCopyWithImpl<$Res>
    implements _$ArticleModelCopyWith<$Res> {
  __$ArticleModelCopyWithImpl(this._self, this._then);

  final _ArticleModel _self;
  final $Res Function(_ArticleModel) _then;

/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titleKo = null,Object? titleEn = null,Object? content = null,Object? gallery = freezed,Object? articleImage = freezed,Object? createdAt = null,Object? commentCount = freezed,Object? comment = freezed,Object? mostLikedComment = freezed,}) {
  return _then(_ArticleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titleKo: null == titleKo ? _self.titleKo : titleKo // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,gallery: freezed == gallery ? _self.gallery : gallery // ignore: cast_nullable_to_non_nullable
as GalleryModel?,articleImage: freezed == articleImage ? _self._articleImage : articleImage // ignore: cast_nullable_to_non_nullable
as List<ArticleImageModel>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,commentCount: freezed == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as CommentModel?,mostLikedComment: freezed == mostLikedComment ? _self.mostLikedComment : mostLikedComment // ignore: cast_nullable_to_non_nullable
as CommentModel?,
  ));
}

/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GalleryModelCopyWith<$Res>? get gallery {
    if (_self.gallery == null) {
    return null;
  }

  return $GalleryModelCopyWith<$Res>(_self.gallery!, (value) {
    return _then(_self.copyWith(gallery: value));
  });
}/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentModelCopyWith<$Res>? get comment {
    if (_self.comment == null) {
    return null;
  }

  return $CommentModelCopyWith<$Res>(_self.comment!, (value) {
    return _then(_self.copyWith(comment: value));
  });
}/// Create a copy of ArticleModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentModelCopyWith<$Res>? get mostLikedComment {
    if (_self.mostLikedComment == null) {
    return null;
  }

  return $CommentModelCopyWith<$Res>(_self.mostLikedComment!, (value) {
    return _then(_self.copyWith(mostLikedComment: value));
  });
}
}

// dart format on
