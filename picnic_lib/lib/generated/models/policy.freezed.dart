// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../data/models/policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PolicyModel _$PolicyModelFromJson(Map<String, dynamic> json) {
  return _PolicyModel.fromJson(json);
}

/// @nodoc
mixin _$PolicyModel {
  @JsonKey(name: 'privacy_en')
  PrivacyModel get privacyEn => throw _privateConstructorUsedError;
  @JsonKey(name: 'terms_en')
  TermsModel get termsEn => throw _privateConstructorUsedError;
  @JsonKey(name: 'privacy_ko')
  PrivacyModel get privacyKo => throw _privateConstructorUsedError;
  @JsonKey(name: 'terms_ko')
  TermsModel get termsKo => throw _privateConstructorUsedError;

  /// Serializes this PolicyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PolicyModelCopyWith<PolicyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PolicyModelCopyWith<$Res> {
  factory $PolicyModelCopyWith(
          PolicyModel value, $Res Function(PolicyModel) then) =
      _$PolicyModelCopyWithImpl<$Res, PolicyModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'privacy_en') PrivacyModel privacyEn,
      @JsonKey(name: 'terms_en') TermsModel termsEn,
      @JsonKey(name: 'privacy_ko') PrivacyModel privacyKo,
      @JsonKey(name: 'terms_ko') TermsModel termsKo});

  $PrivacyModelCopyWith<$Res> get privacyEn;
  $TermsModelCopyWith<$Res> get termsEn;
  $PrivacyModelCopyWith<$Res> get privacyKo;
  $TermsModelCopyWith<$Res> get termsKo;
}

/// @nodoc
class _$PolicyModelCopyWithImpl<$Res, $Val extends PolicyModel>
    implements $PolicyModelCopyWith<$Res> {
  _$PolicyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? privacyEn = null,
    Object? termsEn = null,
    Object? privacyKo = null,
    Object? termsKo = null,
  }) {
    return _then(_value.copyWith(
      privacyEn: null == privacyEn
          ? _value.privacyEn
          : privacyEn // ignore: cast_nullable_to_non_nullable
              as PrivacyModel,
      termsEn: null == termsEn
          ? _value.termsEn
          : termsEn // ignore: cast_nullable_to_non_nullable
              as TermsModel,
      privacyKo: null == privacyKo
          ? _value.privacyKo
          : privacyKo // ignore: cast_nullable_to_non_nullable
              as PrivacyModel,
      termsKo: null == termsKo
          ? _value.termsKo
          : termsKo // ignore: cast_nullable_to_non_nullable
              as TermsModel,
    ) as $Val);
  }

  /// Create a copy of PolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrivacyModelCopyWith<$Res> get privacyEn {
    return $PrivacyModelCopyWith<$Res>(_value.privacyEn, (value) {
      return _then(_value.copyWith(privacyEn: value) as $Val);
    });
  }

  /// Create a copy of PolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TermsModelCopyWith<$Res> get termsEn {
    return $TermsModelCopyWith<$Res>(_value.termsEn, (value) {
      return _then(_value.copyWith(termsEn: value) as $Val);
    });
  }

  /// Create a copy of PolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrivacyModelCopyWith<$Res> get privacyKo {
    return $PrivacyModelCopyWith<$Res>(_value.privacyKo, (value) {
      return _then(_value.copyWith(privacyKo: value) as $Val);
    });
  }

  /// Create a copy of PolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TermsModelCopyWith<$Res> get termsKo {
    return $TermsModelCopyWith<$Res>(_value.termsKo, (value) {
      return _then(_value.copyWith(termsKo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PolicyModelImplCopyWith<$Res>
    implements $PolicyModelCopyWith<$Res> {
  factory _$$PolicyModelImplCopyWith(
          _$PolicyModelImpl value, $Res Function(_$PolicyModelImpl) then) =
      __$$PolicyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'privacy_en') PrivacyModel privacyEn,
      @JsonKey(name: 'terms_en') TermsModel termsEn,
      @JsonKey(name: 'privacy_ko') PrivacyModel privacyKo,
      @JsonKey(name: 'terms_ko') TermsModel termsKo});

  @override
  $PrivacyModelCopyWith<$Res> get privacyEn;
  @override
  $TermsModelCopyWith<$Res> get termsEn;
  @override
  $PrivacyModelCopyWith<$Res> get privacyKo;
  @override
  $TermsModelCopyWith<$Res> get termsKo;
}

/// @nodoc
class __$$PolicyModelImplCopyWithImpl<$Res>
    extends _$PolicyModelCopyWithImpl<$Res, _$PolicyModelImpl>
    implements _$$PolicyModelImplCopyWith<$Res> {
  __$$PolicyModelImplCopyWithImpl(
      _$PolicyModelImpl _value, $Res Function(_$PolicyModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? privacyEn = null,
    Object? termsEn = null,
    Object? privacyKo = null,
    Object? termsKo = null,
  }) {
    return _then(_$PolicyModelImpl(
      privacyEn: null == privacyEn
          ? _value.privacyEn
          : privacyEn // ignore: cast_nullable_to_non_nullable
              as PrivacyModel,
      termsEn: null == termsEn
          ? _value.termsEn
          : termsEn // ignore: cast_nullable_to_non_nullable
              as TermsModel,
      privacyKo: null == privacyKo
          ? _value.privacyKo
          : privacyKo // ignore: cast_nullable_to_non_nullable
              as PrivacyModel,
      termsKo: null == termsKo
          ? _value.termsKo
          : termsKo // ignore: cast_nullable_to_non_nullable
              as TermsModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PolicyModelImpl implements _PolicyModel {
  const _$PolicyModelImpl(
      {@JsonKey(name: 'privacy_en') required this.privacyEn,
      @JsonKey(name: 'terms_en') required this.termsEn,
      @JsonKey(name: 'privacy_ko') required this.privacyKo,
      @JsonKey(name: 'terms_ko') required this.termsKo});

  factory _$PolicyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PolicyModelImplFromJson(json);

  @override
  @JsonKey(name: 'privacy_en')
  final PrivacyModel privacyEn;
  @override
  @JsonKey(name: 'terms_en')
  final TermsModel termsEn;
  @override
  @JsonKey(name: 'privacy_ko')
  final PrivacyModel privacyKo;
  @override
  @JsonKey(name: 'terms_ko')
  final TermsModel termsKo;

  @override
  String toString() {
    return 'PolicyModel(privacyEn: $privacyEn, termsEn: $termsEn, privacyKo: $privacyKo, termsKo: $termsKo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PolicyModelImpl &&
            (identical(other.privacyEn, privacyEn) ||
                other.privacyEn == privacyEn) &&
            (identical(other.termsEn, termsEn) || other.termsEn == termsEn) &&
            (identical(other.privacyKo, privacyKo) ||
                other.privacyKo == privacyKo) &&
            (identical(other.termsKo, termsKo) || other.termsKo == termsKo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, privacyEn, termsEn, privacyKo, termsKo);

  /// Create a copy of PolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PolicyModelImplCopyWith<_$PolicyModelImpl> get copyWith =>
      __$$PolicyModelImplCopyWithImpl<_$PolicyModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PolicyModelImplToJson(
      this,
    );
  }
}

abstract class _PolicyModel implements PolicyModel {
  const factory _PolicyModel(
          {@JsonKey(name: 'privacy_en') required final PrivacyModel privacyEn,
          @JsonKey(name: 'terms_en') required final TermsModel termsEn,
          @JsonKey(name: 'privacy_ko') required final PrivacyModel privacyKo,
          @JsonKey(name: 'terms_ko') required final TermsModel termsKo}) =
      _$PolicyModelImpl;

  factory _PolicyModel.fromJson(Map<String, dynamic> json) =
      _$PolicyModelImpl.fromJson;

  @override
  @JsonKey(name: 'privacy_en')
  PrivacyModel get privacyEn;
  @override
  @JsonKey(name: 'terms_en')
  TermsModel get termsEn;
  @override
  @JsonKey(name: 'privacy_ko')
  PrivacyModel get privacyKo;
  @override
  @JsonKey(name: 'terms_ko')
  TermsModel get termsKo;

  /// Create a copy of PolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PolicyModelImplCopyWith<_$PolicyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PrivacyModel _$PrivacyModelFromJson(Map<String, dynamic> json) {
  return _PrivacyModel.fromJson(json);
}

/// @nodoc
mixin _$PrivacyModel {
  @JsonKey(name: 'content')
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'version')
  String get version => throw _privateConstructorUsedError;

  /// Serializes this PrivacyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrivacyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrivacyModelCopyWith<PrivacyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrivacyModelCopyWith<$Res> {
  factory $PrivacyModelCopyWith(
          PrivacyModel value, $Res Function(PrivacyModel) then) =
      _$PrivacyModelCopyWithImpl<$Res, PrivacyModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'content') String content,
      @JsonKey(name: 'version') String version});
}

/// @nodoc
class _$PrivacyModelCopyWithImpl<$Res, $Val extends PrivacyModel>
    implements $PrivacyModelCopyWith<$Res> {
  _$PrivacyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrivacyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PrivacyModelImplCopyWith<$Res>
    implements $PrivacyModelCopyWith<$Res> {
  factory _$$PrivacyModelImplCopyWith(
          _$PrivacyModelImpl value, $Res Function(_$PrivacyModelImpl) then) =
      __$$PrivacyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'content') String content,
      @JsonKey(name: 'version') String version});
}

/// @nodoc
class __$$PrivacyModelImplCopyWithImpl<$Res>
    extends _$PrivacyModelCopyWithImpl<$Res, _$PrivacyModelImpl>
    implements _$$PrivacyModelImplCopyWith<$Res> {
  __$$PrivacyModelImplCopyWithImpl(
      _$PrivacyModelImpl _value, $Res Function(_$PrivacyModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PrivacyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? version = null,
  }) {
    return _then(_$PrivacyModelImpl(
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PrivacyModelImpl implements _PrivacyModel {
  const _$PrivacyModelImpl(
      {@JsonKey(name: 'content') required this.content,
      @JsonKey(name: 'version') required this.version});

  factory _$PrivacyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrivacyModelImplFromJson(json);

  @override
  @JsonKey(name: 'content')
  final String content;
  @override
  @JsonKey(name: 'version')
  final String version;

  @override
  String toString() {
    return 'PrivacyModel(content: $content, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrivacyModelImpl &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, content, version);

  /// Create a copy of PrivacyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrivacyModelImplCopyWith<_$PrivacyModelImpl> get copyWith =>
      __$$PrivacyModelImplCopyWithImpl<_$PrivacyModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrivacyModelImplToJson(
      this,
    );
  }
}

abstract class _PrivacyModel implements PrivacyModel {
  const factory _PrivacyModel(
          {@JsonKey(name: 'content') required final String content,
          @JsonKey(name: 'version') required final String version}) =
      _$PrivacyModelImpl;

  factory _PrivacyModel.fromJson(Map<String, dynamic> json) =
      _$PrivacyModelImpl.fromJson;

  @override
  @JsonKey(name: 'content')
  String get content;
  @override
  @JsonKey(name: 'version')
  String get version;

  /// Create a copy of PrivacyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrivacyModelImplCopyWith<_$PrivacyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TermsModel _$TermsModelFromJson(Map<String, dynamic> json) {
  return _TermsModel.fromJson(json);
}

/// @nodoc
mixin _$TermsModel {
  @JsonKey(name: 'content')
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'version')
  String get version => throw _privateConstructorUsedError;

  /// Serializes this TermsModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TermsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TermsModelCopyWith<TermsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TermsModelCopyWith<$Res> {
  factory $TermsModelCopyWith(
          TermsModel value, $Res Function(TermsModel) then) =
      _$TermsModelCopyWithImpl<$Res, TermsModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'content') String content,
      @JsonKey(name: 'version') String version});
}

/// @nodoc
class _$TermsModelCopyWithImpl<$Res, $Val extends TermsModel>
    implements $TermsModelCopyWith<$Res> {
  _$TermsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TermsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TermsModelImplCopyWith<$Res>
    implements $TermsModelCopyWith<$Res> {
  factory _$$TermsModelImplCopyWith(
          _$TermsModelImpl value, $Res Function(_$TermsModelImpl) then) =
      __$$TermsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'content') String content,
      @JsonKey(name: 'version') String version});
}

/// @nodoc
class __$$TermsModelImplCopyWithImpl<$Res>
    extends _$TermsModelCopyWithImpl<$Res, _$TermsModelImpl>
    implements _$$TermsModelImplCopyWith<$Res> {
  __$$TermsModelImplCopyWithImpl(
      _$TermsModelImpl _value, $Res Function(_$TermsModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of TermsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? content = null,
    Object? version = null,
  }) {
    return _then(_$TermsModelImpl(
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TermsModelImpl implements _TermsModel {
  const _$TermsModelImpl(
      {@JsonKey(name: 'content') required this.content,
      @JsonKey(name: 'version') required this.version});

  factory _$TermsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TermsModelImplFromJson(json);

  @override
  @JsonKey(name: 'content')
  final String content;
  @override
  @JsonKey(name: 'version')
  final String version;

  @override
  String toString() {
    return 'TermsModel(content: $content, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TermsModelImpl &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, content, version);

  /// Create a copy of TermsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TermsModelImplCopyWith<_$TermsModelImpl> get copyWith =>
      __$$TermsModelImplCopyWithImpl<_$TermsModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TermsModelImplToJson(
      this,
    );
  }
}

abstract class _TermsModel implements TermsModel {
  const factory _TermsModel(
          {@JsonKey(name: 'content') required final String content,
          @JsonKey(name: 'version') required final String version}) =
      _$TermsModelImpl;

  factory _TermsModel.fromJson(Map<String, dynamic> json) =
      _$TermsModelImpl.fromJson;

  @override
  @JsonKey(name: 'content')
  String get content;
  @override
  @JsonKey(name: 'version')
  String get version;

  /// Create a copy of TermsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TermsModelImplCopyWith<_$TermsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
