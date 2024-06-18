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

VotePickListModel _$VotePickListModelFromJson(Map<String, dynamic> json) {
  return _VotePickListModel.fromJson(json);
}

/// @nodoc
mixin _$VotePickListModel {
  List<VotePickModel> get items => throw _privateConstructorUsedError;
  MetaModel get meta => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VotePickListModelCopyWith<VotePickListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VotePickListModelCopyWith<$Res> {
  factory $VotePickListModelCopyWith(
          VotePickListModel value, $Res Function(VotePickListModel) then) =
      _$VotePickListModelCopyWithImpl<$Res, VotePickListModel>;
  @useResult
  $Res call({List<VotePickModel> items, MetaModel meta});

  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class _$VotePickListModelCopyWithImpl<$Res, $Val extends VotePickListModel>
    implements $VotePickListModelCopyWith<$Res> {
  _$VotePickListModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<VotePickModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MetaModelCopyWith<$Res> get meta {
    return $MetaModelCopyWith<$Res>(_value.meta, (value) {
      return _then(_value.copyWith(meta: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VotePickListModelImplCopyWith<$Res>
    implements $VotePickListModelCopyWith<$Res> {
  factory _$$VotePickListModelImplCopyWith(_$VotePickListModelImpl value,
          $Res Function(_$VotePickListModelImpl) then) =
      __$$VotePickListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<VotePickModel> items, MetaModel meta});

  @override
  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class __$$VotePickListModelImplCopyWithImpl<$Res>
    extends _$VotePickListModelCopyWithImpl<$Res, _$VotePickListModelImpl>
    implements _$$VotePickListModelImplCopyWith<$Res> {
  __$$VotePickListModelImplCopyWithImpl(_$VotePickListModelImpl _value,
      $Res Function(_$VotePickListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_$VotePickListModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<VotePickModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VotePickListModelImpl extends _VotePickListModel {
  const _$VotePickListModelImpl(
      {required final List<VotePickModel> items, required this.meta})
      : _items = items,
        super._();

  factory _$VotePickListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VotePickListModelImplFromJson(json);

  final List<VotePickModel> _items;
  @override
  List<VotePickModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final MetaModel meta;

  @override
  String toString() {
    return 'VotePickListModel(items: $items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VotePickListModelImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.meta, meta) || other.meta == meta));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_items), meta);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VotePickListModelImplCopyWith<_$VotePickListModelImpl> get copyWith =>
      __$$VotePickListModelImplCopyWithImpl<_$VotePickListModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VotePickListModelImplToJson(
      this,
    );
  }
}

abstract class _VotePickListModel extends VotePickListModel {
  const factory _VotePickListModel(
      {required final List<VotePickModel> items,
      required final MetaModel meta}) = _$VotePickListModelImpl;
  const _VotePickListModel._() : super._();

  factory _VotePickListModel.fromJson(Map<String, dynamic> json) =
      _$VotePickListModelImpl.fromJson;

  @override
  List<VotePickModel> get items;
  @override
  MetaModel get meta;
  @override
  @JsonKey(ignore: true)
  _$$VotePickListModelImplCopyWith<_$VotePickListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VotePickModel _$VotePickModelFromJson(Map<String, dynamic> json) {
  return _VotePickModel.fromJson(json);
}

/// @nodoc
mixin _$VotePickModel {
  int get id => throw _privateConstructorUsedError;
  VoteModel get vote => throw _privateConstructorUsedError;
  VoteItemModel get vote_item => throw _privateConstructorUsedError;
  int get amount => throw _privateConstructorUsedError;
  DateTime get created_at => throw _privateConstructorUsedError;
  DateTime get updated_at => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      {int id,
      VoteModel vote,
      VoteItemModel vote_item,
      int amount,
      DateTime created_at,
      DateTime updated_at});

  $VoteModelCopyWith<$Res> get vote;
  $VoteItemModelCopyWith<$Res> get vote_item;
}

/// @nodoc
class _$VotePickModelCopyWithImpl<$Res, $Val extends VotePickModel>
    implements $VotePickModelCopyWith<$Res> {
  _$VotePickModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vote = null,
    Object? vote_item = null,
    Object? amount = null,
    Object? created_at = null,
    Object? updated_at = null,
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
      vote_item: null == vote_item
          ? _value.vote_item
          : vote_item // ignore: cast_nullable_to_non_nullable
              as VoteItemModel,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated_at: null == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $VoteModelCopyWith<$Res> get vote {
    return $VoteModelCopyWith<$Res>(_value.vote, (value) {
      return _then(_value.copyWith(vote: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $VoteItemModelCopyWith<$Res> get vote_item {
    return $VoteItemModelCopyWith<$Res>(_value.vote_item, (value) {
      return _then(_value.copyWith(vote_item: value) as $Val);
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
      {int id,
      VoteModel vote,
      VoteItemModel vote_item,
      int amount,
      DateTime created_at,
      DateTime updated_at});

  @override
  $VoteModelCopyWith<$Res> get vote;
  @override
  $VoteItemModelCopyWith<$Res> get vote_item;
}

/// @nodoc
class __$$VotePickModelImplCopyWithImpl<$Res>
    extends _$VotePickModelCopyWithImpl<$Res, _$VotePickModelImpl>
    implements _$$VotePickModelImplCopyWith<$Res> {
  __$$VotePickModelImplCopyWithImpl(
      _$VotePickModelImpl _value, $Res Function(_$VotePickModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vote = null,
    Object? vote_item = null,
    Object? amount = null,
    Object? created_at = null,
    Object? updated_at = null,
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
      vote_item: null == vote_item
          ? _value.vote_item
          : vote_item // ignore: cast_nullable_to_non_nullable
              as VoteItemModel,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated_at: null == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VotePickModelImpl extends _VotePickModel {
  const _$VotePickModelImpl(
      {required this.id,
      required this.vote,
      required this.vote_item,
      required this.amount,
      required this.created_at,
      required this.updated_at})
      : super._();

  factory _$VotePickModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VotePickModelImplFromJson(json);

  @override
  final int id;
  @override
  final VoteModel vote;
  @override
  final VoteItemModel vote_item;
  @override
  final int amount;
  @override
  final DateTime created_at;
  @override
  final DateTime updated_at;

  @override
  String toString() {
    return 'VotePickModel(id: $id, vote: $vote, vote_item: $vote_item, amount: $amount, created_at: $created_at, updated_at: $updated_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VotePickModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vote, vote) || other.vote == vote) &&
            (identical(other.vote_item, vote_item) ||
                other.vote_item == vote_item) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.updated_at, updated_at) ||
                other.updated_at == updated_at));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, vote, vote_item, amount, created_at, updated_at);

  @JsonKey(ignore: true)
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
      {required final int id,
      required final VoteModel vote,
      required final VoteItemModel vote_item,
      required final int amount,
      required final DateTime created_at,
      required final DateTime updated_at}) = _$VotePickModelImpl;
  const _VotePickModel._() : super._();

  factory _VotePickModel.fromJson(Map<String, dynamic> json) =
      _$VotePickModelImpl.fromJson;

  @override
  int get id;
  @override
  VoteModel get vote;
  @override
  VoteItemModel get vote_item;
  @override
  int get amount;
  @override
  DateTime get created_at;
  @override
  DateTime get updated_at;
  @override
  @JsonKey(ignore: true)
  _$$VotePickModelImplCopyWith<_$VotePickModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
