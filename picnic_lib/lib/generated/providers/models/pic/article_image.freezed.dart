// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/pic/article_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArticleImageModel {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'title_ko') String get titleKo;@JsonKey(name: 'title_en') String get titleEn;@JsonKey(name: 'image') String? get image;@JsonKey(name: 'article_image_user') List<UserProfilesModel>? get articleImageUser;
/// Create a copy of ArticleImageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleImageModelCopyWith<ArticleImageModel> get copyWith => _$ArticleImageModelCopyWithImpl<ArticleImageModel>(this as ArticleImageModel, _$identity);

  /// Serializes this ArticleImageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleImageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.titleKo, titleKo) || other.titleKo == titleKo)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.image, image) || other.image == image)&&const DeepCollectionEquality().equals(other.articleImageUser, articleImageUser));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleKo,titleEn,image,const DeepCollectionEquality().hash(articleImageUser));

@override
String toString() {
  return 'ArticleImageModel(id: $id, titleKo: $titleKo, titleEn: $titleEn, image: $image, articleImageUser: $articleImageUser)';
}


}

/// @nodoc
abstract mixin class $ArticleImageModelCopyWith<$Res>  {
  factory $ArticleImageModelCopyWith(ArticleImageModel value, $Res Function(ArticleImageModel) _then) = _$ArticleImageModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title_ko') String titleKo,@JsonKey(name: 'title_en') String titleEn,@JsonKey(name: 'image') String? image,@JsonKey(name: 'article_image_user') List<UserProfilesModel>? articleImageUser
});




}
/// @nodoc
class _$ArticleImageModelCopyWithImpl<$Res>
    implements $ArticleImageModelCopyWith<$Res> {
  _$ArticleImageModelCopyWithImpl(this._self, this._then);

  final ArticleImageModel _self;
  final $Res Function(ArticleImageModel) _then;

/// Create a copy of ArticleImageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titleKo = null,Object? titleEn = null,Object? image = freezed,Object? articleImageUser = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titleKo: null == titleKo ? _self.titleKo : titleKo // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,articleImageUser: freezed == articleImageUser ? _self.articleImageUser : articleImageUser // ignore: cast_nullable_to_non_nullable
as List<UserProfilesModel>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleImageModel].
extension ArticleImageModelPatterns on ArticleImageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleImageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleImageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleImageModel value)  $default,){
final _that = this;
switch (_that) {
case _ArticleImageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleImageModel value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleImageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title_ko')  String titleKo, @JsonKey(name: 'title_en')  String titleEn, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'article_image_user')  List<UserProfilesModel>? articleImageUser)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleImageModel() when $default != null:
return $default(_that.id,_that.titleKo,_that.titleEn,_that.image,_that.articleImageUser);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title_ko')  String titleKo, @JsonKey(name: 'title_en')  String titleEn, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'article_image_user')  List<UserProfilesModel>? articleImageUser)  $default,) {final _that = this;
switch (_that) {
case _ArticleImageModel():
return $default(_that.id,_that.titleKo,_that.titleEn,_that.image,_that.articleImageUser);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'title_ko')  String titleKo, @JsonKey(name: 'title_en')  String titleEn, @JsonKey(name: 'image')  String? image, @JsonKey(name: 'article_image_user')  List<UserProfilesModel>? articleImageUser)?  $default,) {final _that = this;
switch (_that) {
case _ArticleImageModel() when $default != null:
return $default(_that.id,_that.titleKo,_that.titleEn,_that.image,_that.articleImageUser);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArticleImageModel extends ArticleImageModel {
  const _ArticleImageModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'title_ko') required this.titleKo, @JsonKey(name: 'title_en') required this.titleEn, @JsonKey(name: 'image') this.image, @JsonKey(name: 'article_image_user') required final  List<UserProfilesModel>? articleImageUser}): _articleImageUser = articleImageUser,super._();
  factory _ArticleImageModel.fromJson(Map<String, dynamic> json) => _$ArticleImageModelFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'title_ko') final  String titleKo;
@override@JsonKey(name: 'title_en') final  String titleEn;
@override@JsonKey(name: 'image') final  String? image;
 final  List<UserProfilesModel>? _articleImageUser;
@override@JsonKey(name: 'article_image_user') List<UserProfilesModel>? get articleImageUser {
  final value = _articleImageUser;
  if (value == null) return null;
  if (_articleImageUser is EqualUnmodifiableListView) return _articleImageUser;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ArticleImageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleImageModelCopyWith<_ArticleImageModel> get copyWith => __$ArticleImageModelCopyWithImpl<_ArticleImageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArticleImageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleImageModel&&(identical(other.id, id) || other.id == id)&&(identical(other.titleKo, titleKo) || other.titleKo == titleKo)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.image, image) || other.image == image)&&const DeepCollectionEquality().equals(other._articleImageUser, _articleImageUser));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleKo,titleEn,image,const DeepCollectionEquality().hash(_articleImageUser));

@override
String toString() {
  return 'ArticleImageModel(id: $id, titleKo: $titleKo, titleEn: $titleEn, image: $image, articleImageUser: $articleImageUser)';
}


}

/// @nodoc
abstract mixin class _$ArticleImageModelCopyWith<$Res> implements $ArticleImageModelCopyWith<$Res> {
  factory _$ArticleImageModelCopyWith(_ArticleImageModel value, $Res Function(_ArticleImageModel) _then) = __$ArticleImageModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'title_ko') String titleKo,@JsonKey(name: 'title_en') String titleEn,@JsonKey(name: 'image') String? image,@JsonKey(name: 'article_image_user') List<UserProfilesModel>? articleImageUser
});




}
/// @nodoc
class __$ArticleImageModelCopyWithImpl<$Res>
    implements _$ArticleImageModelCopyWith<$Res> {
  __$ArticleImageModelCopyWithImpl(this._self, this._then);

  final _ArticleImageModel _self;
  final $Res Function(_ArticleImageModel) _then;

/// Create a copy of ArticleImageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titleKo = null,Object? titleEn = null,Object? image = freezed,Object? articleImageUser = freezed,}) {
  return _then(_ArticleImageModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titleKo: null == titleKo ? _self.titleKo : titleKo // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,articleImageUser: freezed == articleImageUser ? _self._articleImageUser : articleImageUser // ignore: cast_nullable_to_non_nullable
as List<UserProfilesModel>?,
  ));
}


}

// dart format on
