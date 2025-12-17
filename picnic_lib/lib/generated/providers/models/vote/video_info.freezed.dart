// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/vote/video_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoInfo {

@JsonKey(name: 'id') int get id;@JsonKey(name: 'video_id') String get videoId;@JsonKey(name: 'video_url') String get videoUrl;@JsonKey(name: 'title') Map<String, String> get title;@JsonKey(name: 'thumbnail_url') String get thumbnailUrl;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'channel_title') String get channelTitle;@JsonKey(name: 'channel_id') String get channelId;@JsonKey(name: 'channel_thumbnail') String get channelThumbnail;
/// Create a copy of VideoInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoInfoCopyWith<VideoInfo> get copyWith => _$VideoInfoCopyWithImpl<VideoInfo>(this as VideoInfo, _$identity);

  /// Serializes this VideoInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&const DeepCollectionEquality().equals(other.title, title)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.channelTitle, channelTitle) || other.channelTitle == channelTitle)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelThumbnail, channelThumbnail) || other.channelThumbnail == channelThumbnail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,videoId,videoUrl,const DeepCollectionEquality().hash(title),thumbnailUrl,createdAt,channelTitle,channelId,channelThumbnail);

@override
String toString() {
  return 'VideoInfo(id: $id, videoId: $videoId, videoUrl: $videoUrl, title: $title, thumbnailUrl: $thumbnailUrl, createdAt: $createdAt, channelTitle: $channelTitle, channelId: $channelId, channelThumbnail: $channelThumbnail)';
}


}

/// @nodoc
abstract mixin class $VideoInfoCopyWith<$Res>  {
  factory $VideoInfoCopyWith(VideoInfo value, $Res Function(VideoInfo) _then) = _$VideoInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'video_id') String videoId,@JsonKey(name: 'video_url') String videoUrl,@JsonKey(name: 'title') Map<String, String> title,@JsonKey(name: 'thumbnail_url') String thumbnailUrl,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'channel_title') String channelTitle,@JsonKey(name: 'channel_id') String channelId,@JsonKey(name: 'channel_thumbnail') String channelThumbnail
});




}
/// @nodoc
class _$VideoInfoCopyWithImpl<$Res>
    implements $VideoInfoCopyWith<$Res> {
  _$VideoInfoCopyWithImpl(this._self, this._then);

  final VideoInfo _self;
  final $Res Function(VideoInfo) _then;

/// Create a copy of VideoInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? videoId = null,Object? videoUrl = null,Object? title = null,Object? thumbnailUrl = null,Object? createdAt = freezed,Object? channelTitle = null,Object? channelId = null,Object? channelThumbnail = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,videoId: null == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String,videoUrl: null == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Map<String, String>,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,channelTitle: null == channelTitle ? _self.channelTitle : channelTitle // ignore: cast_nullable_to_non_nullable
as String,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,channelThumbnail: null == channelThumbnail ? _self.channelThumbnail : channelThumbnail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoInfo].
extension VideoInfoPatterns on VideoInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoInfo value)  $default,){
final _that = this;
switch (_that) {
case _VideoInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoInfo value)?  $default,){
final _that = this;
switch (_that) {
case _VideoInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'video_id')  String videoId, @JsonKey(name: 'video_url')  String videoUrl, @JsonKey(name: 'title')  Map<String, String> title, @JsonKey(name: 'thumbnail_url')  String thumbnailUrl, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'channel_title')  String channelTitle, @JsonKey(name: 'channel_id')  String channelId, @JsonKey(name: 'channel_thumbnail')  String channelThumbnail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoInfo() when $default != null:
return $default(_that.id,_that.videoId,_that.videoUrl,_that.title,_that.thumbnailUrl,_that.createdAt,_that.channelTitle,_that.channelId,_that.channelThumbnail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'video_id')  String videoId, @JsonKey(name: 'video_url')  String videoUrl, @JsonKey(name: 'title')  Map<String, String> title, @JsonKey(name: 'thumbnail_url')  String thumbnailUrl, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'channel_title')  String channelTitle, @JsonKey(name: 'channel_id')  String channelId, @JsonKey(name: 'channel_thumbnail')  String channelThumbnail)  $default,) {final _that = this;
switch (_that) {
case _VideoInfo():
return $default(_that.id,_that.videoId,_that.videoUrl,_that.title,_that.thumbnailUrl,_that.createdAt,_that.channelTitle,_that.channelId,_that.channelThumbnail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  int id, @JsonKey(name: 'video_id')  String videoId, @JsonKey(name: 'video_url')  String videoUrl, @JsonKey(name: 'title')  Map<String, String> title, @JsonKey(name: 'thumbnail_url')  String thumbnailUrl, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'channel_title')  String channelTitle, @JsonKey(name: 'channel_id')  String channelId, @JsonKey(name: 'channel_thumbnail')  String channelThumbnail)?  $default,) {final _that = this;
switch (_that) {
case _VideoInfo() when $default != null:
return $default(_that.id,_that.videoId,_that.videoUrl,_that.title,_that.thumbnailUrl,_that.createdAt,_that.channelTitle,_that.channelId,_that.channelThumbnail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoInfo implements VideoInfo {
  const _VideoInfo({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'video_id') required this.videoId, @JsonKey(name: 'video_url') required this.videoUrl, @JsonKey(name: 'title') required final  Map<String, String> title, @JsonKey(name: 'thumbnail_url') required this.thumbnailUrl, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'channel_title') required this.channelTitle, @JsonKey(name: 'channel_id') required this.channelId, @JsonKey(name: 'channel_thumbnail') required this.channelThumbnail}): _title = title;
  factory _VideoInfo.fromJson(Map<String, dynamic> json) => _$VideoInfoFromJson(json);

@override@JsonKey(name: 'id') final  int id;
@override@JsonKey(name: 'video_id') final  String videoId;
@override@JsonKey(name: 'video_url') final  String videoUrl;
 final  Map<String, String> _title;
@override@JsonKey(name: 'title') Map<String, String> get title {
  if (_title is EqualUnmodifiableMapView) return _title;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_title);
}

@override@JsonKey(name: 'thumbnail_url') final  String thumbnailUrl;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'channel_title') final  String channelTitle;
@override@JsonKey(name: 'channel_id') final  String channelId;
@override@JsonKey(name: 'channel_thumbnail') final  String channelThumbnail;

/// Create a copy of VideoInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoInfoCopyWith<_VideoInfo> get copyWith => __$VideoInfoCopyWithImpl<_VideoInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&const DeepCollectionEquality().equals(other._title, _title)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.channelTitle, channelTitle) || other.channelTitle == channelTitle)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelThumbnail, channelThumbnail) || other.channelThumbnail == channelThumbnail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,videoId,videoUrl,const DeepCollectionEquality().hash(_title),thumbnailUrl,createdAt,channelTitle,channelId,channelThumbnail);

@override
String toString() {
  return 'VideoInfo(id: $id, videoId: $videoId, videoUrl: $videoUrl, title: $title, thumbnailUrl: $thumbnailUrl, createdAt: $createdAt, channelTitle: $channelTitle, channelId: $channelId, channelThumbnail: $channelThumbnail)';
}


}

/// @nodoc
abstract mixin class _$VideoInfoCopyWith<$Res> implements $VideoInfoCopyWith<$Res> {
  factory _$VideoInfoCopyWith(_VideoInfo value, $Res Function(_VideoInfo) _then) = __$VideoInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') int id,@JsonKey(name: 'video_id') String videoId,@JsonKey(name: 'video_url') String videoUrl,@JsonKey(name: 'title') Map<String, String> title,@JsonKey(name: 'thumbnail_url') String thumbnailUrl,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'channel_title') String channelTitle,@JsonKey(name: 'channel_id') String channelId,@JsonKey(name: 'channel_thumbnail') String channelThumbnail
});




}
/// @nodoc
class __$VideoInfoCopyWithImpl<$Res>
    implements _$VideoInfoCopyWith<$Res> {
  __$VideoInfoCopyWithImpl(this._self, this._then);

  final _VideoInfo _self;
  final $Res Function(_VideoInfo) _then;

/// Create a copy of VideoInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? videoId = null,Object? videoUrl = null,Object? title = null,Object? thumbnailUrl = null,Object? createdAt = freezed,Object? channelTitle = null,Object? channelId = null,Object? channelThumbnail = null,}) {
  return _then(_VideoInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,videoId: null == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String,videoUrl: null == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self._title : title // ignore: cast_nullable_to_non_nullable
as Map<String, String>,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,channelTitle: null == channelTitle ? _self.channelTitle : channelTitle // ignore: cast_nullable_to_non_nullable
as String,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,channelThumbnail: null == channelThumbnail ? _self.channelThumbnail : channelThumbnail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
