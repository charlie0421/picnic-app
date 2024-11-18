// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vote_pick.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VotePickModel _$VotePickModelFromJson(Map<String, dynamic> json) {
  return _VotePickModel.fromJson(json);
}

/// @nodoc
mixin _$VotePickModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote')
  VoteModel get vote => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_item')
  VoteItemModel get voteItem => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount')
  int? get amount => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this VotePickModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VotePickModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VotePickModelCopyWith<VotePickModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VotePickModelCopyWith<$Res> {
  factory $VotePickModelCopyWith(
          VotePickModel value, $Res Function(VotePickModel) then) =
      _$VotePickModelCopyWithImpl<$Res, VotePickModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'vote') VoteModel vote,
      @JsonKey(name: 'vote_item') VoteItemModel voteItem,
      @JsonKey(name: 'amount') int? amount,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});

  $VoteModelCopyWith<$Res> get vote;
  $VoteItemModelCopyWith<$Res> get voteItem;
}

/// @nodoc
class _$VotePickModelCopyWithImpl<$Res, $Val extends VotePickModel>
    implements $VotePickModelCopyWith<$Res> {
  _$VotePickModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VotePickModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vote = null,
    Object? voteItem = null,
    Object? amount = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      vote: null == vote
          ? _value.vote
          : vote // ignore: cast_nullable_to_non_nullable
              as VoteModel,
      voteItem: null == voteItem
          ? _value.voteItem
          : voteItem // ignore: cast_nullable_to_non_nullable
              as VoteItemModel,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of VotePickModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VoteModelCopyWith<$Res> get vote {
    return $VoteModelCopyWith<$Res>(_value.vote, (value) {
      return _then(_value.copyWith(vote: value) as $Val);
    });
  }

  /// Create a copy of VotePickModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VoteItemModelCopyWith<$Res> get voteItem {
    return $VoteItemModelCopyWith<$Res>(_value.voteItem, (value) {
      return _then(_value.copyWith(voteItem: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VotePickModelImplCopyWith<$Res>
    implements $VotePickModelCopyWith<$Res> {
  factory _$$VotePickModelImplCopyWith(
          _$VotePickModelImpl value, $Res Function(_$VotePickModelImpl) then) =
      __$$VotePickModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'vote') VoteModel vote,
      @JsonKey(name: 'vote_item') VoteItemModel voteItem,
      @JsonKey(name: 'amount') int? amount,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});

  @override
  $VoteModelCopyWith<$Res> get vote;
  @override
  $VoteItemModelCopyWith<$Res> get voteItem;
}

/// @nodoc
class __$$VotePickModelImplCopyWithImpl<$Res>
    extends _$VotePickModelCopyWithImpl<$Res, _$VotePickModelImpl>
    implements _$$VotePickModelImplCopyWith<$Res> {
  __$$VotePickModelImplCopyWithImpl(
      _$VotePickModelImpl _value, $Res Function(_$VotePickModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of VotePickModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vote = null,
    Object? voteItem = null,
    Object? amount = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$VotePickModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      vote: null == vote
          ? _value.vote
          : vote // ignore: cast_nullable_to_non_nullable
              as VoteModel,
      voteItem: null == voteItem
          ? _value.voteItem
          : voteItem // ignore: cast_nullable_to_non_nullable
              as VoteItemModel,
      amount: freezed == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VotePickModelImpl extends _VotePickModel {
  const _$VotePickModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'vote') required this.vote,
      @JsonKey(name: 'vote_item') required this.voteItem,
      @JsonKey(name: 'amount') required this.amount,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt})
      : super._();

  factory _$VotePickModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VotePickModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'vote')
  final VoteModel vote;
  @override
  @JsonKey(name: 'vote_item')
  final VoteItemModel voteItem;
  @override
  @JsonKey(name: 'amount')
  final int? amount;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'VotePickModel(id: $id, vote: $vote, voteItem: $voteItem, amount: $amount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VotePickModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vote, vote) || other.vote == vote) &&
            (identical(other.voteItem, voteItem) ||
                other.voteItem == voteItem) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, vote, voteItem, amount, createdAt, updatedAt);

  /// Create a copy of VotePickModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VotePickModelImplCopyWith<_$VotePickModelImpl> get copyWith =>
      __$$VotePickModelImplCopyWithImpl<_$VotePickModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VotePickModelImplToJson(
      this,
    );
  }
}

abstract class _VotePickModel extends VotePickModel {
  const factory _VotePickModel(
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'vote') required final VoteModel vote,
          @JsonKey(name: 'vote_item') required final VoteItemModel voteItem,
          @JsonKey(name: 'amount') required final int? amount,
          @JsonKey(name: 'created_at') required final DateTime? createdAt,
          @JsonKey(name: 'updated_at') required final DateTime? updatedAt}) =
      _$VotePickModelImpl;
  const _VotePickModel._() : super._();

  factory _VotePickModel.fromJson(Map<String, dynamic> json) =
      _$VotePickModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'vote')
  VoteModel get vote;
  @override
  @JsonKey(name: 'vote_item')
  VoteItemModel get voteItem;
  @override
  @JsonKey(name: 'amount')
  int? get amount;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of VotePickModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VotePickModelImplCopyWith<_$VotePickModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
