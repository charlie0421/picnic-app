// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../models/ad_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AdInfo {
  RewardedAd? get ad => throw _privateConstructorUsedError;
  bool get isShowing => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of AdInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdInfoCopyWith<AdInfo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdInfoCopyWith<$Res> {
  factory $AdInfoCopyWith(AdInfo value, $Res Function(AdInfo) then) =
      _$AdInfoCopyWithImpl<$Res, AdInfo>;
  @useResult
  $Res call({RewardedAd? ad, bool isShowing, bool isLoading});
}

/// @nodoc
class _$AdInfoCopyWithImpl<$Res, $Val extends AdInfo>
    implements $AdInfoCopyWith<$Res> {
  _$AdInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ad = freezed,
    Object? isShowing = null,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      ad: freezed == ad
          ? _value.ad
          : ad // ignore: cast_nullable_to_non_nullable
              as RewardedAd?,
      isShowing: null == isShowing
          ? _value.isShowing
          : isShowing // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdInfoImplCopyWith<$Res> implements $AdInfoCopyWith<$Res> {
  factory _$$AdInfoImplCopyWith(
          _$AdInfoImpl value, $Res Function(_$AdInfoImpl) then) =
      __$$AdInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({RewardedAd? ad, bool isShowing, bool isLoading});
}

/// @nodoc
class __$$AdInfoImplCopyWithImpl<$Res>
    extends _$AdInfoCopyWithImpl<$Res, _$AdInfoImpl>
    implements _$$AdInfoImplCopyWith<$Res> {
  __$$AdInfoImplCopyWithImpl(
      _$AdInfoImpl _value, $Res Function(_$AdInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ad = freezed,
    Object? isShowing = null,
    Object? isLoading = null,
  }) {
    return _then(_$AdInfoImpl(
      ad: freezed == ad
          ? _value.ad
          : ad // ignore: cast_nullable_to_non_nullable
              as RewardedAd?,
      isShowing: null == isShowing
          ? _value.isShowing
          : isShowing // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$AdInfoImpl implements _AdInfo {
  const _$AdInfoImpl({this.ad, this.isShowing = false, this.isLoading = false});

  @override
  final RewardedAd? ad;
  @override
  @JsonKey()
  final bool isShowing;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'AdInfo(ad: $ad, isShowing: $isShowing, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdInfoImpl &&
            (identical(other.ad, ad) || other.ad == ad) &&
            (identical(other.isShowing, isShowing) ||
                other.isShowing == isShowing) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType, ad, isShowing, isLoading);

  /// Create a copy of AdInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdInfoImplCopyWith<_$AdInfoImpl> get copyWith =>
      __$$AdInfoImplCopyWithImpl<_$AdInfoImpl>(this, _$identity);
}

abstract class _AdInfo implements AdInfo {
  const factory _AdInfo(
      {final RewardedAd? ad,
      final bool isShowing,
      final bool isLoading}) = _$AdInfoImpl;

  @override
  RewardedAd? get ad;
  @override
  bool get isShowing;
  @override
  bool get isLoading;

  /// Create a copy of AdInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdInfoImplCopyWith<_$AdInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AdState {
  List<AdInfo> get ads => throw _privateConstructorUsedError;

  /// Create a copy of AdState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdStateCopyWith<AdState> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdStateCopyWith<$Res> {
  factory $AdStateCopyWith(AdState value, $Res Function(AdState) then) =
      _$AdStateCopyWithImpl<$Res, AdState>;
  @useResult
  $Res call({List<AdInfo> ads});
}

/// @nodoc
class _$AdStateCopyWithImpl<$Res, $Val extends AdState>
    implements $AdStateCopyWith<$Res> {
  _$AdStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ads = null,
  }) {
    return _then(_value.copyWith(
      ads: null == ads
          ? _value.ads
          : ads // ignore: cast_nullable_to_non_nullable
              as List<AdInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AdStateImplCopyWith<$Res> implements $AdStateCopyWith<$Res> {
  factory _$$AdStateImplCopyWith(
          _$AdStateImpl value, $Res Function(_$AdStateImpl) then) =
      __$$AdStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<AdInfo> ads});
}

/// @nodoc
class __$$AdStateImplCopyWithImpl<$Res>
    extends _$AdStateCopyWithImpl<$Res, _$AdStateImpl>
    implements _$$AdStateImplCopyWith<$Res> {
  __$$AdStateImplCopyWithImpl(
      _$AdStateImpl _value, $Res Function(_$AdStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ads = null,
  }) {
    return _then(_$AdStateImpl(
      ads: null == ads
          ? _value._ads
          : ads // ignore: cast_nullable_to_non_nullable
              as List<AdInfo>,
    ));
  }
}

/// @nodoc

class _$AdStateImpl implements _AdState {
  const _$AdStateImpl({required final List<AdInfo> ads}) : _ads = ads;

  final List<AdInfo> _ads;
  @override
  List<AdInfo> get ads {
    if (_ads is EqualUnmodifiableListView) return _ads;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ads);
  }

  @override
  String toString() {
    return 'AdState(ads: $ads)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdStateImpl &&
            const DeepCollectionEquality().equals(other._ads, _ads));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_ads));

  /// Create a copy of AdState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdStateImplCopyWith<_$AdStateImpl> get copyWith =>
      __$$AdStateImplCopyWithImpl<_$AdStateImpl>(this, _$identity);
}

abstract class _AdState implements AdState {
  const factory _AdState({required final List<AdInfo> ads}) = _$AdStateImpl;

  @override
  List<AdInfo> get ads;

  /// Create a copy of AdState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdStateImplCopyWith<_$AdStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
