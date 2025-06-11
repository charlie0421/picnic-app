// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../data/models/vote/vote_item_request_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VoteItemRequestUser _$VoteItemRequestUserFromJson(Map<String, dynamic> json) {
  return _VoteItemRequestUser.fromJson(json);
}

/// @nodoc
mixin _$VoteItemRequestUser {
  @JsonKey(name: 'id')
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_id')
  int get voteId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist_id')
  int get artistId => throw _privateConstructorUsedError;
  @JsonKey(name: 'status')
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // 조인된 아티스트 정보 (선택적)
  @JsonKey(name: 'artist')
  ArtistModel? get artist => throw _privateConstructorUsedError;

  /// Serializes this VoteItemRequestUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VoteItemRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoteItemRequestUserCopyWith<VoteItemRequestUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteItemRequestUserCopyWith<$Res> {
  factory $VoteItemRequestUserCopyWith(
          VoteItemRequestUser value, $Res Function(VoteItemRequestUser) then) =
      _$VoteItemRequestUserCopyWithImpl<$Res, VoteItemRequestUser>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'vote_id') int voteId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'artist_id') int artistId,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'artist') ArtistModel? artist});

  $ArtistModelCopyWith<$Res>? get artist;
}

/// @nodoc
class _$VoteItemRequestUserCopyWithImpl<$Res, $Val extends VoteItemRequestUser>
    implements $VoteItemRequestUserCopyWith<$Res> {
  _$VoteItemRequestUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoteItemRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteId = null,
    Object? userId = null,
    Object? artistId = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? artist = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      artistId: null == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
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
    ) as $Val);
  }

  /// Create a copy of VoteItemRequestUser
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
abstract class _$$VoteItemRequestUserImplCopyWith<$Res>
    implements $VoteItemRequestUserCopyWith<$Res> {
  factory _$$VoteItemRequestUserImplCopyWith(_$VoteItemRequestUserImpl value,
          $Res Function(_$VoteItemRequestUserImpl) then) =
      __$$VoteItemRequestUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String id,
      @JsonKey(name: 'vote_id') int voteId,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'artist_id') int artistId,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'artist') ArtistModel? artist});

  @override
  $ArtistModelCopyWith<$Res>? get artist;
}

/// @nodoc
class __$$VoteItemRequestUserImplCopyWithImpl<$Res>
    extends _$VoteItemRequestUserCopyWithImpl<$Res, _$VoteItemRequestUserImpl>
    implements _$$VoteItemRequestUserImplCopyWith<$Res> {
  __$$VoteItemRequestUserImplCopyWithImpl(_$VoteItemRequestUserImpl _value,
      $Res Function(_$VoteItemRequestUserImpl) _then)
      : super(_value, _then);

  /// Create a copy of VoteItemRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteId = null,
    Object? userId = null,
    Object? artistId = null,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? artist = freezed,
  }) {
    return _then(_$VoteItemRequestUserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      artistId: null == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoteItemRequestUserImpl implements _VoteItemRequestUser {
  const _$VoteItemRequestUserImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'vote_id') required this.voteId,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'artist_id') required this.artistId,
      @JsonKey(name: 'status') required this.status,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'artist') this.artist});

  factory _$VoteItemRequestUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteItemRequestUserImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String id;
  @override
  @JsonKey(name: 'vote_id')
  final int voteId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'artist_id')
  final int artistId;
  @override
  @JsonKey(name: 'status')
  final String status;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
// 조인된 아티스트 정보 (선택적)
  @override
  @JsonKey(name: 'artist')
  final ArtistModel? artist;

  @override
  String toString() {
    return 'VoteItemRequestUser(id: $id, voteId: $voteId, userId: $userId, artistId: $artistId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, artist: $artist)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteItemRequestUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.voteId, voteId) || other.voteId == voteId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.artistId, artistId) ||
                other.artistId == artistId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.artist, artist) || other.artist == artist));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, voteId, userId, artistId,
      status, createdAt, updatedAt, artist);

  /// Create a copy of VoteItemRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoteItemRequestUserImplCopyWith<_$VoteItemRequestUserImpl> get copyWith =>
      __$$VoteItemRequestUserImplCopyWithImpl<_$VoteItemRequestUserImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoteItemRequestUserImplToJson(
      this,
    );
  }
}

abstract class _VoteItemRequestUser implements VoteItemRequestUser {
  const factory _VoteItemRequestUser(
          {@JsonKey(name: 'id') required final String id,
          @JsonKey(name: 'vote_id') required final int voteId,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'artist_id') required final int artistId,
          @JsonKey(name: 'status') required final String status,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt,
          @JsonKey(name: 'artist') final ArtistModel? artist}) =
      _$VoteItemRequestUserImpl;

  factory _VoteItemRequestUser.fromJson(Map<String, dynamic> json) =
      _$VoteItemRequestUserImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String get id;
  @override
  @JsonKey(name: 'vote_id')
  int get voteId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'artist_id')
  int get artistId;
  @override
  @JsonKey(name: 'status')
  String get status;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt; // 조인된 아티스트 정보 (선택적)
  @override
  @JsonKey(name: 'artist')
  ArtistModel? get artist;

  /// Create a copy of VoteItemRequestUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoteItemRequestUserImplCopyWith<_$VoteItemRequestUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
