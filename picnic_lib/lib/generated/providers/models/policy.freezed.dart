// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PolicyModel {

@JsonKey(name: 'privacy_en') PrivacyModel get privacyEn;@JsonKey(name: 'terms_en') TermsModel get termsEn;@JsonKey(name: 'privacy_ko') PrivacyModel get privacyKo;@JsonKey(name: 'terms_ko') TermsModel get termsKo;
/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PolicyModelCopyWith<PolicyModel> get copyWith => _$PolicyModelCopyWithImpl<PolicyModel>(this as PolicyModel, _$identity);

  /// Serializes this PolicyModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PolicyModel&&(identical(other.privacyEn, privacyEn) || other.privacyEn == privacyEn)&&(identical(other.termsEn, termsEn) || other.termsEn == termsEn)&&(identical(other.privacyKo, privacyKo) || other.privacyKo == privacyKo)&&(identical(other.termsKo, termsKo) || other.termsKo == termsKo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,privacyEn,termsEn,privacyKo,termsKo);

@override
String toString() {
  return 'PolicyModel(privacyEn: $privacyEn, termsEn: $termsEn, privacyKo: $privacyKo, termsKo: $termsKo)';
}


}

/// @nodoc
abstract mixin class $PolicyModelCopyWith<$Res>  {
  factory $PolicyModelCopyWith(PolicyModel value, $Res Function(PolicyModel) _then) = _$PolicyModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'privacy_en') PrivacyModel privacyEn,@JsonKey(name: 'terms_en') TermsModel termsEn,@JsonKey(name: 'privacy_ko') PrivacyModel privacyKo,@JsonKey(name: 'terms_ko') TermsModel termsKo
});


$PrivacyModelCopyWith<$Res> get privacyEn;$TermsModelCopyWith<$Res> get termsEn;$PrivacyModelCopyWith<$Res> get privacyKo;$TermsModelCopyWith<$Res> get termsKo;

}
/// @nodoc
class _$PolicyModelCopyWithImpl<$Res>
    implements $PolicyModelCopyWith<$Res> {
  _$PolicyModelCopyWithImpl(this._self, this._then);

  final PolicyModel _self;
  final $Res Function(PolicyModel) _then;

/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? privacyEn = null,Object? termsEn = null,Object? privacyKo = null,Object? termsKo = null,}) {
  return _then(_self.copyWith(
privacyEn: null == privacyEn ? _self.privacyEn : privacyEn // ignore: cast_nullable_to_non_nullable
as PrivacyModel,termsEn: null == termsEn ? _self.termsEn : termsEn // ignore: cast_nullable_to_non_nullable
as TermsModel,privacyKo: null == privacyKo ? _self.privacyKo : privacyKo // ignore: cast_nullable_to_non_nullable
as PrivacyModel,termsKo: null == termsKo ? _self.termsKo : termsKo // ignore: cast_nullable_to_non_nullable
as TermsModel,
  ));
}
/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyModelCopyWith<$Res> get privacyEn {
  
  return $PrivacyModelCopyWith<$Res>(_self.privacyEn, (value) {
    return _then(_self.copyWith(privacyEn: value));
  });
}/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TermsModelCopyWith<$Res> get termsEn {
  
  return $TermsModelCopyWith<$Res>(_self.termsEn, (value) {
    return _then(_self.copyWith(termsEn: value));
  });
}/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyModelCopyWith<$Res> get privacyKo {
  
  return $PrivacyModelCopyWith<$Res>(_self.privacyKo, (value) {
    return _then(_self.copyWith(privacyKo: value));
  });
}/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TermsModelCopyWith<$Res> get termsKo {
  
  return $TermsModelCopyWith<$Res>(_self.termsKo, (value) {
    return _then(_self.copyWith(termsKo: value));
  });
}
}


/// Adds pattern-matching-related methods to [PolicyModel].
extension PolicyModelPatterns on PolicyModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PolicyModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PolicyModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PolicyModel value)  $default,){
final _that = this;
switch (_that) {
case _PolicyModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PolicyModel value)?  $default,){
final _that = this;
switch (_that) {
case _PolicyModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'privacy_en')  PrivacyModel privacyEn, @JsonKey(name: 'terms_en')  TermsModel termsEn, @JsonKey(name: 'privacy_ko')  PrivacyModel privacyKo, @JsonKey(name: 'terms_ko')  TermsModel termsKo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PolicyModel() when $default != null:
return $default(_that.privacyEn,_that.termsEn,_that.privacyKo,_that.termsKo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'privacy_en')  PrivacyModel privacyEn, @JsonKey(name: 'terms_en')  TermsModel termsEn, @JsonKey(name: 'privacy_ko')  PrivacyModel privacyKo, @JsonKey(name: 'terms_ko')  TermsModel termsKo)  $default,) {final _that = this;
switch (_that) {
case _PolicyModel():
return $default(_that.privacyEn,_that.termsEn,_that.privacyKo,_that.termsKo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'privacy_en')  PrivacyModel privacyEn, @JsonKey(name: 'terms_en')  TermsModel termsEn, @JsonKey(name: 'privacy_ko')  PrivacyModel privacyKo, @JsonKey(name: 'terms_ko')  TermsModel termsKo)?  $default,) {final _that = this;
switch (_that) {
case _PolicyModel() when $default != null:
return $default(_that.privacyEn,_that.termsEn,_that.privacyKo,_that.termsKo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PolicyModel implements PolicyModel {
  const _PolicyModel({@JsonKey(name: 'privacy_en') required this.privacyEn, @JsonKey(name: 'terms_en') required this.termsEn, @JsonKey(name: 'privacy_ko') required this.privacyKo, @JsonKey(name: 'terms_ko') required this.termsKo});
  factory _PolicyModel.fromJson(Map<String, dynamic> json) => _$PolicyModelFromJson(json);

@override@JsonKey(name: 'privacy_en') final  PrivacyModel privacyEn;
@override@JsonKey(name: 'terms_en') final  TermsModel termsEn;
@override@JsonKey(name: 'privacy_ko') final  PrivacyModel privacyKo;
@override@JsonKey(name: 'terms_ko') final  TermsModel termsKo;

/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PolicyModelCopyWith<_PolicyModel> get copyWith => __$PolicyModelCopyWithImpl<_PolicyModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PolicyModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PolicyModel&&(identical(other.privacyEn, privacyEn) || other.privacyEn == privacyEn)&&(identical(other.termsEn, termsEn) || other.termsEn == termsEn)&&(identical(other.privacyKo, privacyKo) || other.privacyKo == privacyKo)&&(identical(other.termsKo, termsKo) || other.termsKo == termsKo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,privacyEn,termsEn,privacyKo,termsKo);

@override
String toString() {
  return 'PolicyModel(privacyEn: $privacyEn, termsEn: $termsEn, privacyKo: $privacyKo, termsKo: $termsKo)';
}


}

/// @nodoc
abstract mixin class _$PolicyModelCopyWith<$Res> implements $PolicyModelCopyWith<$Res> {
  factory _$PolicyModelCopyWith(_PolicyModel value, $Res Function(_PolicyModel) _then) = __$PolicyModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'privacy_en') PrivacyModel privacyEn,@JsonKey(name: 'terms_en') TermsModel termsEn,@JsonKey(name: 'privacy_ko') PrivacyModel privacyKo,@JsonKey(name: 'terms_ko') TermsModel termsKo
});


@override $PrivacyModelCopyWith<$Res> get privacyEn;@override $TermsModelCopyWith<$Res> get termsEn;@override $PrivacyModelCopyWith<$Res> get privacyKo;@override $TermsModelCopyWith<$Res> get termsKo;

}
/// @nodoc
class __$PolicyModelCopyWithImpl<$Res>
    implements _$PolicyModelCopyWith<$Res> {
  __$PolicyModelCopyWithImpl(this._self, this._then);

  final _PolicyModel _self;
  final $Res Function(_PolicyModel) _then;

/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? privacyEn = null,Object? termsEn = null,Object? privacyKo = null,Object? termsKo = null,}) {
  return _then(_PolicyModel(
privacyEn: null == privacyEn ? _self.privacyEn : privacyEn // ignore: cast_nullable_to_non_nullable
as PrivacyModel,termsEn: null == termsEn ? _self.termsEn : termsEn // ignore: cast_nullable_to_non_nullable
as TermsModel,privacyKo: null == privacyKo ? _self.privacyKo : privacyKo // ignore: cast_nullable_to_non_nullable
as PrivacyModel,termsKo: null == termsKo ? _self.termsKo : termsKo // ignore: cast_nullable_to_non_nullable
as TermsModel,
  ));
}

/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyModelCopyWith<$Res> get privacyEn {
  
  return $PrivacyModelCopyWith<$Res>(_self.privacyEn, (value) {
    return _then(_self.copyWith(privacyEn: value));
  });
}/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TermsModelCopyWith<$Res> get termsEn {
  
  return $TermsModelCopyWith<$Res>(_self.termsEn, (value) {
    return _then(_self.copyWith(termsEn: value));
  });
}/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrivacyModelCopyWith<$Res> get privacyKo {
  
  return $PrivacyModelCopyWith<$Res>(_self.privacyKo, (value) {
    return _then(_self.copyWith(privacyKo: value));
  });
}/// Create a copy of PolicyModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TermsModelCopyWith<$Res> get termsKo {
  
  return $TermsModelCopyWith<$Res>(_self.termsKo, (value) {
    return _then(_self.copyWith(termsKo: value));
  });
}
}


/// @nodoc
mixin _$PrivacyModel {

@JsonKey(name: 'content') String get content;@JsonKey(name: 'version') String get version;
/// Create a copy of PrivacyModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrivacyModelCopyWith<PrivacyModel> get copyWith => _$PrivacyModelCopyWithImpl<PrivacyModel>(this as PrivacyModel, _$identity);

  /// Serializes this PrivacyModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrivacyModel&&(identical(other.content, content) || other.content == content)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,version);

@override
String toString() {
  return 'PrivacyModel(content: $content, version: $version)';
}


}

/// @nodoc
abstract mixin class $PrivacyModelCopyWith<$Res>  {
  factory $PrivacyModelCopyWith(PrivacyModel value, $Res Function(PrivacyModel) _then) = _$PrivacyModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'content') String content,@JsonKey(name: 'version') String version
});




}
/// @nodoc
class _$PrivacyModelCopyWithImpl<$Res>
    implements $PrivacyModelCopyWith<$Res> {
  _$PrivacyModelCopyWithImpl(this._self, this._then);

  final PrivacyModel _self;
  final $Res Function(PrivacyModel) _then;

/// Create a copy of PrivacyModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? version = null,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PrivacyModel].
extension PrivacyModelPatterns on PrivacyModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrivacyModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrivacyModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrivacyModel value)  $default,){
final _that = this;
switch (_that) {
case _PrivacyModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrivacyModel value)?  $default,){
final _that = this;
switch (_that) {
case _PrivacyModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'content')  String content, @JsonKey(name: 'version')  String version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrivacyModel() when $default != null:
return $default(_that.content,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'content')  String content, @JsonKey(name: 'version')  String version)  $default,) {final _that = this;
switch (_that) {
case _PrivacyModel():
return $default(_that.content,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'content')  String content, @JsonKey(name: 'version')  String version)?  $default,) {final _that = this;
switch (_that) {
case _PrivacyModel() when $default != null:
return $default(_that.content,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PrivacyModel implements PrivacyModel {
  const _PrivacyModel({@JsonKey(name: 'content') required this.content, @JsonKey(name: 'version') required this.version});
  factory _PrivacyModel.fromJson(Map<String, dynamic> json) => _$PrivacyModelFromJson(json);

@override@JsonKey(name: 'content') final  String content;
@override@JsonKey(name: 'version') final  String version;

/// Create a copy of PrivacyModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrivacyModelCopyWith<_PrivacyModel> get copyWith => __$PrivacyModelCopyWithImpl<_PrivacyModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrivacyModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrivacyModel&&(identical(other.content, content) || other.content == content)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,version);

@override
String toString() {
  return 'PrivacyModel(content: $content, version: $version)';
}


}

/// @nodoc
abstract mixin class _$PrivacyModelCopyWith<$Res> implements $PrivacyModelCopyWith<$Res> {
  factory _$PrivacyModelCopyWith(_PrivacyModel value, $Res Function(_PrivacyModel) _then) = __$PrivacyModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'content') String content,@JsonKey(name: 'version') String version
});




}
/// @nodoc
class __$PrivacyModelCopyWithImpl<$Res>
    implements _$PrivacyModelCopyWith<$Res> {
  __$PrivacyModelCopyWithImpl(this._self, this._then);

  final _PrivacyModel _self;
  final $Res Function(_PrivacyModel) _then;

/// Create a copy of PrivacyModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? version = null,}) {
  return _then(_PrivacyModel(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TermsModel {

@JsonKey(name: 'content') String get content;@JsonKey(name: 'version') String get version;
/// Create a copy of TermsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TermsModelCopyWith<TermsModel> get copyWith => _$TermsModelCopyWithImpl<TermsModel>(this as TermsModel, _$identity);

  /// Serializes this TermsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TermsModel&&(identical(other.content, content) || other.content == content)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,version);

@override
String toString() {
  return 'TermsModel(content: $content, version: $version)';
}


}

/// @nodoc
abstract mixin class $TermsModelCopyWith<$Res>  {
  factory $TermsModelCopyWith(TermsModel value, $Res Function(TermsModel) _then) = _$TermsModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'content') String content,@JsonKey(name: 'version') String version
});




}
/// @nodoc
class _$TermsModelCopyWithImpl<$Res>
    implements $TermsModelCopyWith<$Res> {
  _$TermsModelCopyWithImpl(this._self, this._then);

  final TermsModel _self;
  final $Res Function(TermsModel) _then;

/// Create a copy of TermsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? version = null,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TermsModel].
extension TermsModelPatterns on TermsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TermsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TermsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TermsModel value)  $default,){
final _that = this;
switch (_that) {
case _TermsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TermsModel value)?  $default,){
final _that = this;
switch (_that) {
case _TermsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'content')  String content, @JsonKey(name: 'version')  String version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TermsModel() when $default != null:
return $default(_that.content,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'content')  String content, @JsonKey(name: 'version')  String version)  $default,) {final _that = this;
switch (_that) {
case _TermsModel():
return $default(_that.content,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'content')  String content, @JsonKey(name: 'version')  String version)?  $default,) {final _that = this;
switch (_that) {
case _TermsModel() when $default != null:
return $default(_that.content,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TermsModel implements TermsModel {
  const _TermsModel({@JsonKey(name: 'content') required this.content, @JsonKey(name: 'version') required this.version});
  factory _TermsModel.fromJson(Map<String, dynamic> json) => _$TermsModelFromJson(json);

@override@JsonKey(name: 'content') final  String content;
@override@JsonKey(name: 'version') final  String version;

/// Create a copy of TermsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TermsModelCopyWith<_TermsModel> get copyWith => __$TermsModelCopyWithImpl<_TermsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TermsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TermsModel&&(identical(other.content, content) || other.content == content)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,version);

@override
String toString() {
  return 'TermsModel(content: $content, version: $version)';
}


}

/// @nodoc
abstract mixin class _$TermsModelCopyWith<$Res> implements $TermsModelCopyWith<$Res> {
  factory _$TermsModelCopyWith(_TermsModel value, $Res Function(_TermsModel) _then) = __$TermsModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'content') String content,@JsonKey(name: 'version') String version
});




}
/// @nodoc
class __$TermsModelCopyWithImpl<$Res>
    implements _$TermsModelCopyWith<$Res> {
  __$TermsModelCopyWithImpl(this._self, this._then);

  final _TermsModel _self;
  final $Res Function(_TermsModel) _then;

/// Create a copy of TermsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? version = null,}) {
  return _then(_TermsModel(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
