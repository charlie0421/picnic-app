// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../../data/models/ad/ad_reward_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdRewardReference {

@AdRewardReferenceTypeConverter() AdRewardReferenceType get type; String get id;
/// Create a copy of AdRewardReference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdRewardReferenceCopyWith<AdRewardReference> get copyWith => _$AdRewardReferenceCopyWithImpl<AdRewardReference>(this as AdRewardReference, _$identity);

  /// Serializes this AdRewardReference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdRewardReference&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,id);

@override
String toString() {
  return 'AdRewardReference(type: $type, id: $id)';
}


}

/// @nodoc
abstract mixin class $AdRewardReferenceCopyWith<$Res>  {
  factory $AdRewardReferenceCopyWith(AdRewardReference value, $Res Function(AdRewardReference) _then) = _$AdRewardReferenceCopyWithImpl;
@useResult
$Res call({
@AdRewardReferenceTypeConverter() AdRewardReferenceType type, String id
});




}
/// @nodoc
class _$AdRewardReferenceCopyWithImpl<$Res>
    implements $AdRewardReferenceCopyWith<$Res> {
  _$AdRewardReferenceCopyWithImpl(this._self, this._then);

  final AdRewardReference _self;
  final $Res Function(AdRewardReference) _then;

/// Create a copy of AdRewardReference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? id = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AdRewardReferenceType,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AdRewardReference].
extension AdRewardReferencePatterns on AdRewardReference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdRewardReference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdRewardReference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdRewardReference value)  $default,){
final _that = this;
switch (_that) {
case _AdRewardReference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdRewardReference value)?  $default,){
final _that = this;
switch (_that) {
case _AdRewardReference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@AdRewardReferenceTypeConverter()  AdRewardReferenceType type,  String id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdRewardReference() when $default != null:
return $default(_that.type,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@AdRewardReferenceTypeConverter()  AdRewardReferenceType type,  String id)  $default,) {final _that = this;
switch (_that) {
case _AdRewardReference():
return $default(_that.type,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@AdRewardReferenceTypeConverter()  AdRewardReferenceType type,  String id)?  $default,) {final _that = this;
switch (_that) {
case _AdRewardReference() when $default != null:
return $default(_that.type,_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdRewardReference implements AdRewardReference {
  const _AdRewardReference({@AdRewardReferenceTypeConverter() required this.type, required this.id});
  factory _AdRewardReference.fromJson(Map<String, dynamic> json) => _$AdRewardReferenceFromJson(json);

@override@AdRewardReferenceTypeConverter() final  AdRewardReferenceType type;
@override final  String id;

/// Create a copy of AdRewardReference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdRewardReferenceCopyWith<_AdRewardReference> get copyWith => __$AdRewardReferenceCopyWithImpl<_AdRewardReference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdRewardReferenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdRewardReference&&(identical(other.type, type) || other.type == type)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,id);

@override
String toString() {
  return 'AdRewardReference(type: $type, id: $id)';
}


}

/// @nodoc
abstract mixin class _$AdRewardReferenceCopyWith<$Res> implements $AdRewardReferenceCopyWith<$Res> {
  factory _$AdRewardReferenceCopyWith(_AdRewardReference value, $Res Function(_AdRewardReference) _then) = __$AdRewardReferenceCopyWithImpl;
@override @useResult
$Res call({
@AdRewardReferenceTypeConverter() AdRewardReferenceType type, String id
});




}
/// @nodoc
class __$AdRewardReferenceCopyWithImpl<$Res>
    implements _$AdRewardReferenceCopyWith<$Res> {
  __$AdRewardReferenceCopyWithImpl(this._self, this._then);

  final _AdRewardReference _self;
  final $Res Function(_AdRewardReference) _then;

/// Create a copy of AdRewardReference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? id = null,}) {
  return _then(_AdRewardReference(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AdRewardReferenceType,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PangleClaimModel {

 AdRewardReference get reference; String get platform;@JsonKey(name: 'signed_token') String get signedToken;@JsonKey(name: 'expires_at') DateTime get expiresAt;
/// Create a copy of PangleClaimModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PangleClaimModelCopyWith<PangleClaimModel> get copyWith => _$PangleClaimModelCopyWithImpl<PangleClaimModel>(this as PangleClaimModel, _$identity);

  /// Serializes this PangleClaimModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PangleClaimModel&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.signedToken, signedToken) || other.signedToken == signedToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reference,platform,signedToken,expiresAt);

@override
String toString() {
  return 'PangleClaimModel(reference: $reference, platform: $platform, signedToken: $signedToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $PangleClaimModelCopyWith<$Res>  {
  factory $PangleClaimModelCopyWith(PangleClaimModel value, $Res Function(PangleClaimModel) _then) = _$PangleClaimModelCopyWithImpl;
@useResult
$Res call({
 AdRewardReference reference, String platform,@JsonKey(name: 'signed_token') String signedToken,@JsonKey(name: 'expires_at') DateTime expiresAt
});


$AdRewardReferenceCopyWith<$Res> get reference;

}
/// @nodoc
class _$PangleClaimModelCopyWithImpl<$Res>
    implements $PangleClaimModelCopyWith<$Res> {
  _$PangleClaimModelCopyWithImpl(this._self, this._then);

  final PangleClaimModel _self;
  final $Res Function(PangleClaimModel) _then;

/// Create a copy of PangleClaimModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? platform = null,Object? signedToken = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as AdRewardReference,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,signedToken: null == signedToken ? _self.signedToken : signedToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of PangleClaimModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardReferenceCopyWith<$Res> get reference {

  return $AdRewardReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}


/// Adds pattern-matching-related methods to [PangleClaimModel].
extension PangleClaimModelPatterns on PangleClaimModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PangleClaimModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PangleClaimModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PangleClaimModel value)  $default,){
final _that = this;
switch (_that) {
case _PangleClaimModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PangleClaimModel value)?  $default,){
final _that = this;
switch (_that) {
case _PangleClaimModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdRewardReference reference,  String platform, @JsonKey(name: 'signed_token')  String signedToken, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PangleClaimModel() when $default != null:
return $default(_that.reference,_that.platform,_that.signedToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdRewardReference reference,  String platform, @JsonKey(name: 'signed_token')  String signedToken, @JsonKey(name: 'expires_at')  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _PangleClaimModel():
return $default(_that.reference,_that.platform,_that.signedToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdRewardReference reference,  String platform, @JsonKey(name: 'signed_token')  String signedToken, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _PangleClaimModel() when $default != null:
return $default(_that.reference,_that.platform,_that.signedToken,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PangleClaimModel extends PangleClaimModel {
  const _PangleClaimModel({required this.reference, required this.platform, @JsonKey(name: 'signed_token') required this.signedToken, @JsonKey(name: 'expires_at') required this.expiresAt}): super._();
  factory _PangleClaimModel.fromJson(Map<String, dynamic> json) => _$PangleClaimModelFromJson(json);

@override final  AdRewardReference reference;
@override final  String platform;
@override@JsonKey(name: 'signed_token') final  String signedToken;
@override@JsonKey(name: 'expires_at') final  DateTime expiresAt;

/// Create a copy of PangleClaimModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PangleClaimModelCopyWith<_PangleClaimModel> get copyWith => __$PangleClaimModelCopyWithImpl<_PangleClaimModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PangleClaimModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PangleClaimModel&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.signedToken, signedToken) || other.signedToken == signedToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reference,platform,signedToken,expiresAt);

@override
String toString() {
  return 'PangleClaimModel(reference: $reference, platform: $platform, signedToken: $signedToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$PangleClaimModelCopyWith<$Res> implements $PangleClaimModelCopyWith<$Res> {
  factory _$PangleClaimModelCopyWith(_PangleClaimModel value, $Res Function(_PangleClaimModel) _then) = __$PangleClaimModelCopyWithImpl;
@override @useResult
$Res call({
 AdRewardReference reference, String platform,@JsonKey(name: 'signed_token') String signedToken,@JsonKey(name: 'expires_at') DateTime expiresAt
});


@override $AdRewardReferenceCopyWith<$Res> get reference;

}
/// @nodoc
class __$PangleClaimModelCopyWithImpl<$Res>
    implements _$PangleClaimModelCopyWith<$Res> {
  __$PangleClaimModelCopyWithImpl(this._self, this._then);

  final _PangleClaimModel _self;
  final $Res Function(_PangleClaimModel) _then;

/// Create a copy of PangleClaimModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? platform = null,Object? signedToken = null,Object? expiresAt = null,}) {
  return _then(_PangleClaimModel(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as AdRewardReference,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,signedToken: null == signedToken ? _self.signedToken : signedToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of PangleClaimModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardReferenceCopyWith<$Res> get reference {

  return $AdRewardReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}


/// @nodoc
mixin _$AdmobClaimModel {

 AdRewardReference get reference; String get platform;@JsonKey(name: 'signed_token') String get signedToken;@JsonKey(name: 'expires_at') DateTime get expiresAt;
/// Create a copy of AdmobClaimModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdmobClaimModelCopyWith<AdmobClaimModel> get copyWith => _$AdmobClaimModelCopyWithImpl<AdmobClaimModel>(this as AdmobClaimModel, _$identity);

  /// Serializes this AdmobClaimModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdmobClaimModel&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.signedToken, signedToken) || other.signedToken == signedToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reference,platform,signedToken,expiresAt);

@override
String toString() {
  return 'AdmobClaimModel(reference: $reference, platform: $platform, signedToken: $signedToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $AdmobClaimModelCopyWith<$Res>  {
  factory $AdmobClaimModelCopyWith(AdmobClaimModel value, $Res Function(AdmobClaimModel) _then) = _$AdmobClaimModelCopyWithImpl;
@useResult
$Res call({
 AdRewardReference reference, String platform,@JsonKey(name: 'signed_token') String signedToken,@JsonKey(name: 'expires_at') DateTime expiresAt
});


$AdRewardReferenceCopyWith<$Res> get reference;

}
/// @nodoc
class _$AdmobClaimModelCopyWithImpl<$Res>
    implements $AdmobClaimModelCopyWith<$Res> {
  _$AdmobClaimModelCopyWithImpl(this._self, this._then);

  final AdmobClaimModel _self;
  final $Res Function(AdmobClaimModel) _then;

/// Create a copy of AdmobClaimModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? platform = null,Object? signedToken = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as AdRewardReference,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,signedToken: null == signedToken ? _self.signedToken : signedToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of AdmobClaimModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardReferenceCopyWith<$Res> get reference {

  return $AdRewardReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdmobClaimModel].
extension AdmobClaimModelPatterns on AdmobClaimModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdmobClaimModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdmobClaimModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdmobClaimModel value)  $default,){
final _that = this;
switch (_that) {
case _AdmobClaimModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdmobClaimModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdmobClaimModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdRewardReference reference,  String platform, @JsonKey(name: 'signed_token')  String signedToken, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdmobClaimModel() when $default != null:
return $default(_that.reference,_that.platform,_that.signedToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdRewardReference reference,  String platform, @JsonKey(name: 'signed_token')  String signedToken, @JsonKey(name: 'expires_at')  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _AdmobClaimModel():
return $default(_that.reference,_that.platform,_that.signedToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdRewardReference reference,  String platform, @JsonKey(name: 'signed_token')  String signedToken, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _AdmobClaimModel() when $default != null:
return $default(_that.reference,_that.platform,_that.signedToken,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdmobClaimModel implements AdmobClaimModel {
  const _AdmobClaimModel({required this.reference, required this.platform, @JsonKey(name: 'signed_token') required this.signedToken, @JsonKey(name: 'expires_at') required this.expiresAt});
  factory _AdmobClaimModel.fromJson(Map<String, dynamic> json) => _$AdmobClaimModelFromJson(json);

@override final  AdRewardReference reference;
@override final  String platform;
@override@JsonKey(name: 'signed_token') final  String signedToken;
@override@JsonKey(name: 'expires_at') final  DateTime expiresAt;

/// Create a copy of AdmobClaimModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdmobClaimModelCopyWith<_AdmobClaimModel> get copyWith => __$AdmobClaimModelCopyWithImpl<_AdmobClaimModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdmobClaimModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdmobClaimModel&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.signedToken, signedToken) || other.signedToken == signedToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reference,platform,signedToken,expiresAt);

@override
String toString() {
  return 'AdmobClaimModel(reference: $reference, platform: $platform, signedToken: $signedToken, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$AdmobClaimModelCopyWith<$Res> implements $AdmobClaimModelCopyWith<$Res> {
  factory _$AdmobClaimModelCopyWith(_AdmobClaimModel value, $Res Function(_AdmobClaimModel) _then) = __$AdmobClaimModelCopyWithImpl;
@override @useResult
$Res call({
 AdRewardReference reference, String platform,@JsonKey(name: 'signed_token') String signedToken,@JsonKey(name: 'expires_at') DateTime expiresAt
});


@override $AdRewardReferenceCopyWith<$Res> get reference;

}
/// @nodoc
class __$AdmobClaimModelCopyWithImpl<$Res>
    implements _$AdmobClaimModelCopyWith<$Res> {
  __$AdmobClaimModelCopyWithImpl(this._self, this._then);

  final _AdmobClaimModel _self;
  final $Res Function(_AdmobClaimModel) _then;

/// Create a copy of AdmobClaimModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? platform = null,Object? signedToken = null,Object? expiresAt = null,}) {
  return _then(_AdmobClaimModel(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as AdRewardReference,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,signedToken: null == signedToken ? _self.signedToken : signedToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of AdmobClaimModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardReferenceCopyWith<$Res> get reference {

  return $AdRewardReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}
}


/// @nodoc
mixin _$AdRewardGrantModel {

 String get id;@WalletCurrencyConverter() WalletCurrency get currency;@WalletAmountConverter() BigInt get amount;@JsonKey(name: 'granted_at') DateTime get grantedAt;@JsonKey(name: 'expires_at') DateTime get expiresAt;
/// Create a copy of AdRewardGrantModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdRewardGrantModelCopyWith<AdRewardGrantModel> get copyWith => _$AdRewardGrantModelCopyWithImpl<AdRewardGrantModel>(this as AdRewardGrantModel, _$identity);

  /// Serializes this AdRewardGrantModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdRewardGrantModel&&(identical(other.id, id) || other.id == id)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.grantedAt, grantedAt) || other.grantedAt == grantedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,currency,amount,grantedAt,expiresAt);

@override
String toString() {
  return 'AdRewardGrantModel(id: $id, currency: $currency, amount: $amount, grantedAt: $grantedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $AdRewardGrantModelCopyWith<$Res>  {
  factory $AdRewardGrantModelCopyWith(AdRewardGrantModel value, $Res Function(AdRewardGrantModel) _then) = _$AdRewardGrantModelCopyWithImpl;
@useResult
$Res call({
 String id,@WalletCurrencyConverter() WalletCurrency currency,@WalletAmountConverter() BigInt amount,@JsonKey(name: 'granted_at') DateTime grantedAt,@JsonKey(name: 'expires_at') DateTime expiresAt
});




}
/// @nodoc
class _$AdRewardGrantModelCopyWithImpl<$Res>
    implements $AdRewardGrantModelCopyWith<$Res> {
  _$AdRewardGrantModelCopyWithImpl(this._self, this._then);

  final AdRewardGrantModel _self;
  final $Res Function(AdRewardGrantModel) _then;

/// Create a copy of AdRewardGrantModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? currency = null,Object? amount = null,Object? grantedAt = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as WalletCurrency,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,grantedAt: null == grantedAt ? _self.grantedAt : grantedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AdRewardGrantModel].
extension AdRewardGrantModelPatterns on AdRewardGrantModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdRewardGrantModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdRewardGrantModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdRewardGrantModel value)  $default,){
final _that = this;
switch (_that) {
case _AdRewardGrantModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdRewardGrantModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdRewardGrantModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @WalletCurrencyConverter()  WalletCurrency currency, @WalletAmountConverter()  BigInt amount, @JsonKey(name: 'granted_at')  DateTime grantedAt, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdRewardGrantModel() when $default != null:
return $default(_that.id,_that.currency,_that.amount,_that.grantedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @WalletCurrencyConverter()  WalletCurrency currency, @WalletAmountConverter()  BigInt amount, @JsonKey(name: 'granted_at')  DateTime grantedAt, @JsonKey(name: 'expires_at')  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _AdRewardGrantModel():
return $default(_that.id,_that.currency,_that.amount,_that.grantedAt,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @WalletCurrencyConverter()  WalletCurrency currency, @WalletAmountConverter()  BigInt amount, @JsonKey(name: 'granted_at')  DateTime grantedAt, @JsonKey(name: 'expires_at')  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _AdRewardGrantModel() when $default != null:
return $default(_that.id,_that.currency,_that.amount,_that.grantedAt,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdRewardGrantModel implements AdRewardGrantModel {
  const _AdRewardGrantModel({required this.id, @WalletCurrencyConverter() required this.currency, @WalletAmountConverter() required this.amount, @JsonKey(name: 'granted_at') required this.grantedAt, @JsonKey(name: 'expires_at') required this.expiresAt});
  factory _AdRewardGrantModel.fromJson(Map<String, dynamic> json) => _$AdRewardGrantModelFromJson(json);

@override final  String id;
@override@WalletCurrencyConverter() final  WalletCurrency currency;
@override@WalletAmountConverter() final  BigInt amount;
@override@JsonKey(name: 'granted_at') final  DateTime grantedAt;
@override@JsonKey(name: 'expires_at') final  DateTime expiresAt;

/// Create a copy of AdRewardGrantModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdRewardGrantModelCopyWith<_AdRewardGrantModel> get copyWith => __$AdRewardGrantModelCopyWithImpl<_AdRewardGrantModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdRewardGrantModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdRewardGrantModel&&(identical(other.id, id) || other.id == id)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.grantedAt, grantedAt) || other.grantedAt == grantedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,currency,amount,grantedAt,expiresAt);

@override
String toString() {
  return 'AdRewardGrantModel(id: $id, currency: $currency, amount: $amount, grantedAt: $grantedAt, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$AdRewardGrantModelCopyWith<$Res> implements $AdRewardGrantModelCopyWith<$Res> {
  factory _$AdRewardGrantModelCopyWith(_AdRewardGrantModel value, $Res Function(_AdRewardGrantModel) _then) = __$AdRewardGrantModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@WalletCurrencyConverter() WalletCurrency currency,@WalletAmountConverter() BigInt amount,@JsonKey(name: 'granted_at') DateTime grantedAt,@JsonKey(name: 'expires_at') DateTime expiresAt
});




}
/// @nodoc
class __$AdRewardGrantModelCopyWithImpl<$Res>
    implements _$AdRewardGrantModelCopyWith<$Res> {
  __$AdRewardGrantModelCopyWithImpl(this._self, this._then);

  final _AdRewardGrantModel _self;
  final $Res Function(_AdRewardGrantModel) _then;

/// Create a copy of AdRewardGrantModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? currency = null,Object? amount = null,Object? grantedAt = null,Object? expiresAt = null,}) {
  return _then(_AdRewardGrantModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as WalletCurrency,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as BigInt,grantedAt: null == grantedAt ? _self.grantedAt : grantedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$AdRewardStatusModel {

 AdRewardReference get reference;@AdRewardStateConverter() AdRewardState get state; AdRewardGrantModel? get grant; WalletSummaryModel get wallet;@JsonKey(name: 'snapshot_at') DateTime get snapshotAt;
/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdRewardStatusModelCopyWith<AdRewardStatusModel> get copyWith => _$AdRewardStatusModelCopyWithImpl<AdRewardStatusModel>(this as AdRewardStatusModel, _$identity);

  /// Serializes this AdRewardStatusModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdRewardStatusModel&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.state, state) || other.state == state)&&(identical(other.grant, grant) || other.grant == grant)&&(identical(other.wallet, wallet) || other.wallet == wallet)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reference,state,grant,wallet,snapshotAt);

@override
String toString() {
  return 'AdRewardStatusModel(reference: $reference, state: $state, grant: $grant, wallet: $wallet, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class $AdRewardStatusModelCopyWith<$Res>  {
  factory $AdRewardStatusModelCopyWith(AdRewardStatusModel value, $Res Function(AdRewardStatusModel) _then) = _$AdRewardStatusModelCopyWithImpl;
@useResult
$Res call({
 AdRewardReference reference,@AdRewardStateConverter() AdRewardState state, AdRewardGrantModel? grant, WalletSummaryModel wallet,@JsonKey(name: 'snapshot_at') DateTime snapshotAt
});


$AdRewardReferenceCopyWith<$Res> get reference;$AdRewardGrantModelCopyWith<$Res>? get grant;$WalletSummaryModelCopyWith<$Res> get wallet;

}
/// @nodoc
class _$AdRewardStatusModelCopyWithImpl<$Res>
    implements $AdRewardStatusModelCopyWith<$Res> {
  _$AdRewardStatusModelCopyWithImpl(this._self, this._then);

  final AdRewardStatusModel _self;
  final $Res Function(AdRewardStatusModel) _then;

/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? state = null,Object? grant = freezed,Object? wallet = null,Object? snapshotAt = null,}) {
  return _then(_self.copyWith(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as AdRewardReference,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AdRewardState,grant: freezed == grant ? _self.grant : grant // ignore: cast_nullable_to_non_nullable
as AdRewardGrantModel?,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletSummaryModel,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardReferenceCopyWith<$Res> get reference {

  return $AdRewardReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardGrantModelCopyWith<$Res>? get grant {
    if (_self.grant == null) {
    return null;
  }

  return $AdRewardGrantModelCopyWith<$Res>(_self.grant!, (value) {
    return _then(_self.copyWith(grant: value));
  });
}/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletSummaryModelCopyWith<$Res> get wallet {

  return $WalletSummaryModelCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdRewardStatusModel].
extension AdRewardStatusModelPatterns on AdRewardStatusModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdRewardStatusModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdRewardStatusModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdRewardStatusModel value)  $default,){
final _that = this;
switch (_that) {
case _AdRewardStatusModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdRewardStatusModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdRewardStatusModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AdRewardReference reference, @AdRewardStateConverter()  AdRewardState state,  AdRewardGrantModel? grant,  WalletSummaryModel wallet, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdRewardStatusModel() when $default != null:
return $default(_that.reference,_that.state,_that.grant,_that.wallet,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AdRewardReference reference, @AdRewardStateConverter()  AdRewardState state,  AdRewardGrantModel? grant,  WalletSummaryModel wallet, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)  $default,) {final _that = this;
switch (_that) {
case _AdRewardStatusModel():
return $default(_that.reference,_that.state,_that.grant,_that.wallet,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AdRewardReference reference, @AdRewardStateConverter()  AdRewardState state,  AdRewardGrantModel? grant,  WalletSummaryModel wallet, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)?  $default,) {final _that = this;
switch (_that) {
case _AdRewardStatusModel() when $default != null:
return $default(_that.reference,_that.state,_that.grant,_that.wallet,_that.snapshotAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdRewardStatusModel implements AdRewardStatusModel {
  const _AdRewardStatusModel({required this.reference, @AdRewardStateConverter() required this.state, required this.grant, required this.wallet, @JsonKey(name: 'snapshot_at') required this.snapshotAt});
  factory _AdRewardStatusModel.fromJson(Map<String, dynamic> json) => _$AdRewardStatusModelFromJson(json);

@override final  AdRewardReference reference;
@override@AdRewardStateConverter() final  AdRewardState state;
@override final  AdRewardGrantModel? grant;
@override final  WalletSummaryModel wallet;
@override@JsonKey(name: 'snapshot_at') final  DateTime snapshotAt;

/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdRewardStatusModelCopyWith<_AdRewardStatusModel> get copyWith => __$AdRewardStatusModelCopyWithImpl<_AdRewardStatusModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdRewardStatusModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdRewardStatusModel&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.state, state) || other.state == state)&&(identical(other.grant, grant) || other.grant == grant)&&(identical(other.wallet, wallet) || other.wallet == wallet)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reference,state,grant,wallet,snapshotAt);

@override
String toString() {
  return 'AdRewardStatusModel(reference: $reference, state: $state, grant: $grant, wallet: $wallet, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class _$AdRewardStatusModelCopyWith<$Res> implements $AdRewardStatusModelCopyWith<$Res> {
  factory _$AdRewardStatusModelCopyWith(_AdRewardStatusModel value, $Res Function(_AdRewardStatusModel) _then) = __$AdRewardStatusModelCopyWithImpl;
@override @useResult
$Res call({
 AdRewardReference reference,@AdRewardStateConverter() AdRewardState state, AdRewardGrantModel? grant, WalletSummaryModel wallet,@JsonKey(name: 'snapshot_at') DateTime snapshotAt
});


@override $AdRewardReferenceCopyWith<$Res> get reference;@override $AdRewardGrantModelCopyWith<$Res>? get grant;@override $WalletSummaryModelCopyWith<$Res> get wallet;

}
/// @nodoc
class __$AdRewardStatusModelCopyWithImpl<$Res>
    implements _$AdRewardStatusModelCopyWith<$Res> {
  __$AdRewardStatusModelCopyWithImpl(this._self, this._then);

  final _AdRewardStatusModel _self;
  final $Res Function(_AdRewardStatusModel) _then;

/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? state = null,Object? grant = freezed,Object? wallet = null,Object? snapshotAt = null,}) {
  return _then(_AdRewardStatusModel(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as AdRewardReference,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as AdRewardState,grant: freezed == grant ? _self.grant : grant // ignore: cast_nullable_to_non_nullable
as AdRewardGrantModel?,wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as WalletSummaryModel,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardReferenceCopyWith<$Res> get reference {

  return $AdRewardReferenceCopyWith<$Res>(_self.reference, (value) {
    return _then(_self.copyWith(reference: value));
  });
}/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardGrantModelCopyWith<$Res>? get grant {
    if (_self.grant == null) {
    return null;
  }

  return $AdRewardGrantModelCopyWith<$Res>(_self.grant!, (value) {
    return _then(_self.copyWith(grant: value));
  });
}/// Create a copy of AdRewardStatusModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletSummaryModelCopyWith<$Res> get wallet {

  return $WalletSummaryModelCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}


/// @nodoc
mixin _$AdRewardPageModel {

 List<AdRewardStatusModel> get items;@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt get totalCount;@JsonKey(name: 'next_cursor') String? get nextCursor;@JsonKey(name: 'snapshot_at') DateTime get snapshotAt;
/// Create a copy of AdRewardPageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdRewardPageModelCopyWith<AdRewardPageModel> get copyWith => _$AdRewardPageModelCopyWithImpl<AdRewardPageModel>(this as AdRewardPageModel, _$identity);

  /// Serializes this AdRewardPageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdRewardPageModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalCount,nextCursor,snapshotAt);

@override
String toString() {
  return 'AdRewardPageModel(items: $items, totalCount: $totalCount, nextCursor: $nextCursor, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class $AdRewardPageModelCopyWith<$Res>  {
  factory $AdRewardPageModelCopyWith(AdRewardPageModel value, $Res Function(AdRewardPageModel) _then) = _$AdRewardPageModelCopyWithImpl;
@useResult
$Res call({
 List<AdRewardStatusModel> items,@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt totalCount,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'snapshot_at') DateTime snapshotAt
});




}
/// @nodoc
class _$AdRewardPageModelCopyWithImpl<$Res>
    implements $AdRewardPageModelCopyWith<$Res> {
  _$AdRewardPageModelCopyWithImpl(this._self, this._then);

  final AdRewardPageModel _self;
  final $Res Function(AdRewardPageModel) _then;

/// Create a copy of AdRewardPageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalCount = null,Object? nextCursor = freezed,Object? snapshotAt = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AdRewardStatusModel>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as BigInt,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AdRewardPageModel].
extension AdRewardPageModelPatterns on AdRewardPageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdRewardPageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdRewardPageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdRewardPageModel value)  $default,){
final _that = this;
switch (_that) {
case _AdRewardPageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdRewardPageModel value)?  $default,){
final _that = this;
switch (_that) {
case _AdRewardPageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AdRewardStatusModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdRewardPageModel() when $default != null:
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AdRewardStatusModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)  $default,) {final _that = this;
switch (_that) {
case _AdRewardPageModel():
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AdRewardStatusModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter()  BigInt totalCount, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'snapshot_at')  DateTime snapshotAt)?  $default,) {final _that = this;
switch (_that) {
case _AdRewardPageModel() when $default != null:
return $default(_that.items,_that.totalCount,_that.nextCursor,_that.snapshotAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdRewardPageModel implements AdRewardPageModel {
  const _AdRewardPageModel({required final  List<AdRewardStatusModel> items, @JsonKey(name: 'total_count')@WalletAmountConverter() required this.totalCount, @JsonKey(name: 'next_cursor') required this.nextCursor, @JsonKey(name: 'snapshot_at') required this.snapshotAt}): _items = items;
  factory _AdRewardPageModel.fromJson(Map<String, dynamic> json) => _$AdRewardPageModelFromJson(json);

 final  List<AdRewardStatusModel> _items;
@override List<AdRewardStatusModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'total_count')@WalletAmountConverter() final  BigInt totalCount;
@override@JsonKey(name: 'next_cursor') final  String? nextCursor;
@override@JsonKey(name: 'snapshot_at') final  DateTime snapshotAt;

/// Create a copy of AdRewardPageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdRewardPageModelCopyWith<_AdRewardPageModel> get copyWith => __$AdRewardPageModelCopyWithImpl<_AdRewardPageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdRewardPageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdRewardPageModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.snapshotAt, snapshotAt) || other.snapshotAt == snapshotAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalCount,nextCursor,snapshotAt);

@override
String toString() {
  return 'AdRewardPageModel(items: $items, totalCount: $totalCount, nextCursor: $nextCursor, snapshotAt: $snapshotAt)';
}


}

/// @nodoc
abstract mixin class _$AdRewardPageModelCopyWith<$Res> implements $AdRewardPageModelCopyWith<$Res> {
  factory _$AdRewardPageModelCopyWith(_AdRewardPageModel value, $Res Function(_AdRewardPageModel) _then) = __$AdRewardPageModelCopyWithImpl;
@override @useResult
$Res call({
 List<AdRewardStatusModel> items,@JsonKey(name: 'total_count')@WalletAmountConverter() BigInt totalCount,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'snapshot_at') DateTime snapshotAt
});




}
/// @nodoc
class __$AdRewardPageModelCopyWithImpl<$Res>
    implements _$AdRewardPageModelCopyWith<$Res> {
  __$AdRewardPageModelCopyWithImpl(this._self, this._then);

  final _AdRewardPageModel _self;
  final $Res Function(_AdRewardPageModel) _then;

/// Create a copy of AdRewardPageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalCount = null,Object? nextCursor = freezed,Object? snapshotAt = null,}) {
  return _then(_AdRewardPageModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AdRewardStatusModel>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as BigInt,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,snapshotAt: null == snapshotAt ? _self.snapshotAt : snapshotAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$InternalShortformViewResponse {

 bool get ok;@JsonKey(name: 'reward_added') int get rewardAdded;@JsonKey(name: 'impression_id') String get impressionId;@JsonKey(name: 'new_bonus') int? get newBonus; AdRewardStatusModel? get reward;
/// Create a copy of InternalShortformViewResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalShortformViewResponseCopyWith<InternalShortformViewResponse> get copyWith => _$InternalShortformViewResponseCopyWithImpl<InternalShortformViewResponse>(this as InternalShortformViewResponse, _$identity);

  /// Serializes this InternalShortformViewResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalShortformViewResponse&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.rewardAdded, rewardAdded) || other.rewardAdded == rewardAdded)&&(identical(other.impressionId, impressionId) || other.impressionId == impressionId)&&(identical(other.newBonus, newBonus) || other.newBonus == newBonus)&&(identical(other.reward, reward) || other.reward == reward));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,rewardAdded,impressionId,newBonus,reward);

@override
String toString() {
  return 'InternalShortformViewResponse(ok: $ok, rewardAdded: $rewardAdded, impressionId: $impressionId, newBonus: $newBonus, reward: $reward)';
}


}

/// @nodoc
abstract mixin class $InternalShortformViewResponseCopyWith<$Res>  {
  factory $InternalShortformViewResponseCopyWith(InternalShortformViewResponse value, $Res Function(InternalShortformViewResponse) _then) = _$InternalShortformViewResponseCopyWithImpl;
@useResult
$Res call({
 bool ok,@JsonKey(name: 'reward_added') int rewardAdded,@JsonKey(name: 'impression_id') String impressionId,@JsonKey(name: 'new_bonus') int? newBonus, AdRewardStatusModel? reward
});


$AdRewardStatusModelCopyWith<$Res>? get reward;

}
/// @nodoc
class _$InternalShortformViewResponseCopyWithImpl<$Res>
    implements $InternalShortformViewResponseCopyWith<$Res> {
  _$InternalShortformViewResponseCopyWithImpl(this._self, this._then);

  final InternalShortformViewResponse _self;
  final $Res Function(InternalShortformViewResponse) _then;

/// Create a copy of InternalShortformViewResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,Object? rewardAdded = null,Object? impressionId = null,Object? newBonus = freezed,Object? reward = freezed,}) {
  return _then(_self.copyWith(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,rewardAdded: null == rewardAdded ? _self.rewardAdded : rewardAdded // ignore: cast_nullable_to_non_nullable
as int,impressionId: null == impressionId ? _self.impressionId : impressionId // ignore: cast_nullable_to_non_nullable
as String,newBonus: freezed == newBonus ? _self.newBonus : newBonus // ignore: cast_nullable_to_non_nullable
as int?,reward: freezed == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as AdRewardStatusModel?,
  ));
}
/// Create a copy of InternalShortformViewResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardStatusModelCopyWith<$Res>? get reward {
    if (_self.reward == null) {
    return null;
  }

  return $AdRewardStatusModelCopyWith<$Res>(_self.reward!, (value) {
    return _then(_self.copyWith(reward: value));
  });
}
}


/// Adds pattern-matching-related methods to [InternalShortformViewResponse].
extension InternalShortformViewResponsePatterns on InternalShortformViewResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalShortformViewResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalShortformViewResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalShortformViewResponse value)  $default,){
final _that = this;
switch (_that) {
case _InternalShortformViewResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalShortformViewResponse value)?  $default,){
final _that = this;
switch (_that) {
case _InternalShortformViewResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok, @JsonKey(name: 'reward_added')  int rewardAdded, @JsonKey(name: 'impression_id')  String impressionId, @JsonKey(name: 'new_bonus')  int? newBonus,  AdRewardStatusModel? reward)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalShortformViewResponse() when $default != null:
return $default(_that.ok,_that.rewardAdded,_that.impressionId,_that.newBonus,_that.reward);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok, @JsonKey(name: 'reward_added')  int rewardAdded, @JsonKey(name: 'impression_id')  String impressionId, @JsonKey(name: 'new_bonus')  int? newBonus,  AdRewardStatusModel? reward)  $default,) {final _that = this;
switch (_that) {
case _InternalShortformViewResponse():
return $default(_that.ok,_that.rewardAdded,_that.impressionId,_that.newBonus,_that.reward);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok, @JsonKey(name: 'reward_added')  int rewardAdded, @JsonKey(name: 'impression_id')  String impressionId, @JsonKey(name: 'new_bonus')  int? newBonus,  AdRewardStatusModel? reward)?  $default,) {final _that = this;
switch (_that) {
case _InternalShortformViewResponse() when $default != null:
return $default(_that.ok,_that.rewardAdded,_that.impressionId,_that.newBonus,_that.reward);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalShortformViewResponse implements InternalShortformViewResponse {
  const _InternalShortformViewResponse({required this.ok, @JsonKey(name: 'reward_added') required this.rewardAdded, @JsonKey(name: 'impression_id') required this.impressionId, @JsonKey(name: 'new_bonus') required this.newBonus, this.reward});
  factory _InternalShortformViewResponse.fromJson(Map<String, dynamic> json) => _$InternalShortformViewResponseFromJson(json);

@override final  bool ok;
@override@JsonKey(name: 'reward_added') final  int rewardAdded;
@override@JsonKey(name: 'impression_id') final  String impressionId;
@override@JsonKey(name: 'new_bonus') final  int? newBonus;
@override final  AdRewardStatusModel? reward;

/// Create a copy of InternalShortformViewResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalShortformViewResponseCopyWith<_InternalShortformViewResponse> get copyWith => __$InternalShortformViewResponseCopyWithImpl<_InternalShortformViewResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalShortformViewResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalShortformViewResponse&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.rewardAdded, rewardAdded) || other.rewardAdded == rewardAdded)&&(identical(other.impressionId, impressionId) || other.impressionId == impressionId)&&(identical(other.newBonus, newBonus) || other.newBonus == newBonus)&&(identical(other.reward, reward) || other.reward == reward));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,rewardAdded,impressionId,newBonus,reward);

@override
String toString() {
  return 'InternalShortformViewResponse(ok: $ok, rewardAdded: $rewardAdded, impressionId: $impressionId, newBonus: $newBonus, reward: $reward)';
}


}

/// @nodoc
abstract mixin class _$InternalShortformViewResponseCopyWith<$Res> implements $InternalShortformViewResponseCopyWith<$Res> {
  factory _$InternalShortformViewResponseCopyWith(_InternalShortformViewResponse value, $Res Function(_InternalShortformViewResponse) _then) = __$InternalShortformViewResponseCopyWithImpl;
@override @useResult
$Res call({
 bool ok,@JsonKey(name: 'reward_added') int rewardAdded,@JsonKey(name: 'impression_id') String impressionId,@JsonKey(name: 'new_bonus') int? newBonus, AdRewardStatusModel? reward
});


@override $AdRewardStatusModelCopyWith<$Res>? get reward;

}
/// @nodoc
class __$InternalShortformViewResponseCopyWithImpl<$Res>
    implements _$InternalShortformViewResponseCopyWith<$Res> {
  __$InternalShortformViewResponseCopyWithImpl(this._self, this._then);

  final _InternalShortformViewResponse _self;
  final $Res Function(_InternalShortformViewResponse) _then;

/// Create a copy of InternalShortformViewResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,Object? rewardAdded = null,Object? impressionId = null,Object? newBonus = freezed,Object? reward = freezed,}) {
  return _then(_InternalShortformViewResponse(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,rewardAdded: null == rewardAdded ? _self.rewardAdded : rewardAdded // ignore: cast_nullable_to_non_nullable
as int,impressionId: null == impressionId ? _self.impressionId : impressionId // ignore: cast_nullable_to_non_nullable
as String,newBonus: freezed == newBonus ? _self.newBonus : newBonus // ignore: cast_nullable_to_non_nullable
as int?,reward: freezed == reward ? _self.reward : reward // ignore: cast_nullable_to_non_nullable
as AdRewardStatusModel?,
  ));
}

/// Create a copy of InternalShortformViewResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdRewardStatusModelCopyWith<$Res>? get reward {
    if (_self.reward == null) {
    return null;
  }

  return $AdRewardStatusModelCopyWith<$Res>(_self.reward!, (value) {
    return _then(_self.copyWith(reward: value));
  });
}
}

// dart format on
