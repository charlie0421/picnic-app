// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'board.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BoardModel _$BoardModelFromJson(Map<String, dynamic> json) {
  return _BoardModel.fromJson(json);
}

/// @nodoc
mixin _$BoardModel {
  @JsonKey(name: 'board_id')
  String get boardId => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist_id')
  int get artistId => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  Map<String, dynamic> get name => throw _privateConstructorUsedError;
  @DescriptionConverter()
  dynamic get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_official')
  bool get isOfficial => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  ArtistModel? get artist => throw _privateConstructorUsedError;
  @JsonKey(name: 'request_message')
  String? get requestMessage => throw _privateConstructorUsedError;

  /// Serializes this BoardModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BoardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BoardModelCopyWith<BoardModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoardModelCopyWith<$Res> {
  factory $BoardModelCopyWith(
          BoardModel value, $Res Function(BoardModel) then) =
      _$BoardModelCopyWithImpl<$Res, BoardModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'board_id') String boardId,
      @JsonKey(name: 'artist_id') int artistId,
      @JsonKey(name: 'name') Map<String, dynamic> name,
      @DescriptionConverter() dynamic description,
      @JsonKey(name: 'is_official') bool isOfficial,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      ArtistModel? artist,
      @JsonKey(name: 'request_message') String? requestMessage});

  $ArtistModelCopyWith<$Res>? get artist;
}

/// @nodoc
class _$BoardModelCopyWithImpl<$Res, $Val extends BoardModel>
    implements $BoardModelCopyWith<$Res> {
  _$BoardModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BoardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? boardId = null,
    Object? artistId = null,
    Object? name = null,
    Object? description = freezed,
    Object? isOfficial = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? artist = freezed,
    Object? requestMessage = freezed,
  }) {
    return _then(_value.copyWith(
      boardId: null == boardId
          ? _value.boardId
          : boardId // ignore: cast_nullable_to_non_nullable
              as String,
      artistId: null == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as dynamic,
      isOfficial: null == isOfficial
          ? _value.isOfficial
          : isOfficial // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      artist: freezed == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel?,
      requestMessage: freezed == requestMessage
          ? _value.requestMessage
          : requestMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of BoardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistModelCopyWith<$Res>? get artist {
    if (_value.artist == null) {
      return null;
    }

    return $ArtistModelCopyWith<$Res>(_value.artist!, (value) {
      return _then(_value.copyWith(artist: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BoardModelImplCopyWith<$Res>
    implements $BoardModelCopyWith<$Res> {
  factory _$$BoardModelImplCopyWith(
          _$BoardModelImpl value, $Res Function(_$BoardModelImpl) then) =
      __$$BoardModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'board_id') String boardId,
      @JsonKey(name: 'artist_id') int artistId,
      @JsonKey(name: 'name') Map<String, dynamic> name,
      @DescriptionConverter() dynamic description,
      @JsonKey(name: 'is_official') bool isOfficial,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      ArtistModel? artist,
      @JsonKey(name: 'request_message') String? requestMessage});

  @override
  $ArtistModelCopyWith<$Res>? get artist;
}

/// @nodoc
class __$$BoardModelImplCopyWithImpl<$Res>
    extends _$BoardModelCopyWithImpl<$Res, _$BoardModelImpl>
    implements _$$BoardModelImplCopyWith<$Res> {
  __$$BoardModelImplCopyWithImpl(
      _$BoardModelImpl _value, $Res Function(_$BoardModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of BoardModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? boardId = null,
    Object? artistId = null,
    Object? name = null,
    Object? description = freezed,
    Object? isOfficial = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? artist = freezed,
    Object? requestMessage = freezed,
  }) {
    return _then(_$BoardModelImpl(
      boardId: null == boardId
          ? _value.boardId
          : boardId // ignore: cast_nullable_to_non_nullable
              as String,
      artistId: null == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value._name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as dynamic,
      isOfficial: null == isOfficial
          ? _value.isOfficial
          : isOfficial // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      artist: freezed == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel?,
      requestMessage: freezed == requestMessage
          ? _value.requestMessage
          : requestMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BoardModelImpl extends _BoardModel {
  const _$BoardModelImpl(
      {@JsonKey(name: 'board_id') required this.boardId,
      @JsonKey(name: 'artist_id') required this.artistId,
      @JsonKey(name: 'name') required final Map<String, dynamic> name,
      @DescriptionConverter() required this.description,
      @JsonKey(name: 'is_official') required this.isOfficial,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      required this.artist,
      @JsonKey(name: 'request_message') required this.requestMessage})
      : _name = name,
        super._();

  factory _$BoardModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BoardModelImplFromJson(json);

  @override
  @JsonKey(name: 'board_id')
  final String boardId;
  @override
  @JsonKey(name: 'artist_id')
  final int artistId;
  final Map<String, dynamic> _name;
  @override
  @JsonKey(name: 'name')
  Map<String, dynamic> get name {
    if (_name is EqualUnmodifiableMapView) return _name;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_name);
  }

  @override
  @DescriptionConverter()
  final dynamic description;
  @override
  @JsonKey(name: 'is_official')
  final bool isOfficial;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  final ArtistModel? artist;
  @override
  @JsonKey(name: 'request_message')
  final String? requestMessage;

  @override
  String toString() {
    return 'BoardModel(boardId: $boardId, artistId: $artistId, name: $name, description: $description, isOfficial: $isOfficial, createdAt: $createdAt, updatedAt: $updatedAt, artist: $artist, requestMessage: $requestMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoardModelImpl &&
            (identical(other.boardId, boardId) || other.boardId == boardId) &&
            (identical(other.artistId, artistId) ||
                other.artistId == artistId) &&
            const DeepCollectionEquality().equals(other._name, _name) &&
            const DeepCollectionEquality()
                .equals(other.description, description) &&
            (identical(other.isOfficial, isOfficial) ||
                other.isOfficial == isOfficial) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.requestMessage, requestMessage) ||
                other.requestMessage == requestMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      boardId,
      artistId,
      const DeepCollectionEquality().hash(_name),
      const DeepCollectionEquality().hash(description),
      isOfficial,
      createdAt,
      updatedAt,
      artist,
      requestMessage);

  /// Create a copy of BoardModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BoardModelImplCopyWith<_$BoardModelImpl> get copyWith =>
      __$$BoardModelImplCopyWithImpl<_$BoardModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BoardModelImplToJson(
      this,
    );
  }
}

abstract class _BoardModel extends BoardModel {
  const factory _BoardModel(
      {@JsonKey(name: 'board_id') required final String boardId,
      @JsonKey(name: 'artist_id') required final int artistId,
      @JsonKey(name: 'name') required final Map<String, dynamic> name,
      @DescriptionConverter() required final dynamic description,
      @JsonKey(name: 'is_official') required final bool isOfficial,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'updated_at') required final DateTime updatedAt,
      required final ArtistModel? artist,
      @JsonKey(name: 'request_message')
      required final String? requestMessage}) = _$BoardModelImpl;
  const _BoardModel._() : super._();

  factory _BoardModel.fromJson(Map<String, dynamic> json) =
      _$BoardModelImpl.fromJson;

  @override
  @JsonKey(name: 'board_id')
  String get boardId;
  @override
  @JsonKey(name: 'artist_id')
  int get artistId;
  @override
  @JsonKey(name: 'name')
  Map<String, dynamic> get name;
  @override
  @DescriptionConverter()
  dynamic get description;
  @override
  @JsonKey(name: 'is_official')
  bool get isOfficial;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  ArtistModel? get artist;
  @override
  @JsonKey(name: 'request_message')
  String? get requestMessage;

  /// Create a copy of BoardModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BoardModelImplCopyWith<_$BoardModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
