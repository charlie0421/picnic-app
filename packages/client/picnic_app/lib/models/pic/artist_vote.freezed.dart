// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_vote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArtistVoteListModel _$ArtistVoteListModelFromJson(Map<String, dynamic> json) {
  return _ArtistVoteListModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistVoteListModel {
  List<ArtistVoteModel> get items => throw _privateConstructorUsedError;
  MetaModel get meta => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistVoteListModelCopyWith<ArtistVoteListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistVoteListModelCopyWith<$Res> {
  factory $ArtistVoteListModelCopyWith(
          ArtistVoteListModel value, $Res Function(ArtistVoteListModel) then) =
      _$ArtistVoteListModelCopyWithImpl<$Res, ArtistVoteListModel>;
  @useResult
  $Res call({List<ArtistVoteModel> items, MetaModel meta});

  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class _$ArtistVoteListModelCopyWithImpl<$Res, $Val extends ArtistVoteListModel>
    implements $ArtistVoteListModelCopyWith<$Res> {
  _$ArtistVoteListModelCopyWithImpl(this._value, this._then);

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
              as List<ArtistVoteModel>,
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
abstract class _$$ArtistVoteListModelImplCopyWith<$Res>
    implements $ArtistVoteListModelCopyWith<$Res> {
  factory _$$ArtistVoteListModelImplCopyWith(_$ArtistVoteListModelImpl value,
          $Res Function(_$ArtistVoteListModelImpl) then) =
      __$$ArtistVoteListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ArtistVoteModel> items, MetaModel meta});

  @override
  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class __$$ArtistVoteListModelImplCopyWithImpl<$Res>
    extends _$ArtistVoteListModelCopyWithImpl<$Res, _$ArtistVoteListModelImpl>
    implements _$$ArtistVoteListModelImplCopyWith<$Res> {
  __$$ArtistVoteListModelImplCopyWithImpl(_$ArtistVoteListModelImpl _value,
      $Res Function(_$ArtistVoteListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_$ArtistVoteListModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ArtistVoteModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistVoteListModelImpl extends _ArtistVoteListModel {
  const _$ArtistVoteListModelImpl(
      {required final List<ArtistVoteModel> items, required this.meta})
      : _items = items,
        super._();

  factory _$ArtistVoteListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistVoteListModelImplFromJson(json);

  final List<ArtistVoteModel> _items;
  @override
  List<ArtistVoteModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final MetaModel meta;

  @override
  String toString() {
    return 'ArtistVoteListModel(items: $items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistVoteListModelImpl &&
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
  _$$ArtistVoteListModelImplCopyWith<_$ArtistVoteListModelImpl> get copyWith =>
      __$$ArtistVoteListModelImplCopyWithImpl<_$ArtistVoteListModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistVoteListModelImplToJson(
      this,
    );
  }
}

abstract class _ArtistVoteListModel extends ArtistVoteListModel {
  const factory _ArtistVoteListModel(
      {required final List<ArtistVoteModel> items,
      required final MetaModel meta}) = _$ArtistVoteListModelImpl;
  const _ArtistVoteListModel._() : super._();

  factory _ArtistVoteListModel.fromJson(Map<String, dynamic> json) =
      _$ArtistVoteListModelImpl.fromJson;

  @override
  List<ArtistVoteModel> get items;
  @override
  MetaModel get meta;
  @override
  @JsonKey(ignore: true)
  _$$ArtistVoteListModelImplCopyWith<_$ArtistVoteListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistVoteModel _$ArtistVoteModelFromJson(Map<String, dynamic> json) {
  return _ArtistVoteModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistVoteModel {
  int get id => throw _privateConstructorUsedError;
  Map<String, dynamic> get title => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  List<ArtistVoteItemModel>? get artist_vote_item =>
      throw _privateConstructorUsedError;
  DateTime get created_at => throw _privateConstructorUsedError;
  DateTime? get updated_at => throw _privateConstructorUsedError;
  DateTime? get visible_at => throw _privateConstructorUsedError;
  DateTime get stop_at => throw _privateConstructorUsedError;
  DateTime get start_at => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistVoteModelCopyWith<ArtistVoteModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistVoteModelCopyWith<$Res> {
  factory $ArtistVoteModelCopyWith(
          ArtistVoteModel value, $Res Function(ArtistVoteModel) then) =
      _$ArtistVoteModelCopyWithImpl<$Res, ArtistVoteModel>;
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic> title,
      String category,
      List<ArtistVoteItemModel>? artist_vote_item,
      DateTime created_at,
      DateTime? updated_at,
      DateTime? visible_at,
      DateTime stop_at,
      DateTime start_at});
}

/// @nodoc
class _$ArtistVoteModelCopyWithImpl<$Res, $Val extends ArtistVoteModel>
    implements $ArtistVoteModelCopyWith<$Res> {
  _$ArtistVoteModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? artist_vote_item = freezed,
    Object? created_at = null,
    Object? updated_at = freezed,
    Object? visible_at = freezed,
    Object? stop_at = null,
    Object? start_at = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      artist_vote_item: freezed == artist_vote_item
          ? _value.artist_vote_item
          : artist_vote_item // ignore: cast_nullable_to_non_nullable
              as List<ArtistVoteItemModel>?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated_at: freezed == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      visible_at: freezed == visible_at
          ? _value.visible_at
          : visible_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stop_at: null == stop_at
          ? _value.stop_at
          : stop_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      start_at: null == start_at
          ? _value.start_at
          : start_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistVoteModelImplCopyWith<$Res>
    implements $ArtistVoteModelCopyWith<$Res> {
  factory _$$ArtistVoteModelImplCopyWith(_$ArtistVoteModelImpl value,
          $Res Function(_$ArtistVoteModelImpl) then) =
      __$$ArtistVoteModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic> title,
      String category,
      List<ArtistVoteItemModel>? artist_vote_item,
      DateTime created_at,
      DateTime? updated_at,
      DateTime? visible_at,
      DateTime stop_at,
      DateTime start_at});
}

/// @nodoc
class __$$ArtistVoteModelImplCopyWithImpl<$Res>
    extends _$ArtistVoteModelCopyWithImpl<$Res, _$ArtistVoteModelImpl>
    implements _$$ArtistVoteModelImplCopyWith<$Res> {
  __$$ArtistVoteModelImplCopyWithImpl(
      _$ArtistVoteModelImpl _value, $Res Function(_$ArtistVoteModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? artist_vote_item = freezed,
    Object? created_at = null,
    Object? updated_at = freezed,
    Object? visible_at = freezed,
    Object? stop_at = null,
    Object? start_at = null,
  }) {
    return _then(_$ArtistVoteModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value._title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      artist_vote_item: freezed == artist_vote_item
          ? _value._artist_vote_item
          : artist_vote_item // ignore: cast_nullable_to_non_nullable
              as List<ArtistVoteItemModel>?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated_at: freezed == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      visible_at: freezed == visible_at
          ? _value.visible_at
          : visible_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stop_at: null == stop_at
          ? _value.stop_at
          : stop_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      start_at: null == start_at
          ? _value.start_at
          : start_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistVoteModelImpl extends _ArtistVoteModel {
  const _$ArtistVoteModelImpl(
      {required this.id,
      required final Map<String, dynamic> title,
      required this.category,
      required final List<ArtistVoteItemModel>? artist_vote_item,
      required this.created_at,
      required this.updated_at,
      required this.visible_at,
      required this.stop_at,
      required this.start_at})
      : _title = title,
        _artist_vote_item = artist_vote_item,
        super._();

  factory _$ArtistVoteModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistVoteModelImplFromJson(json);

  @override
  final int id;
  final Map<String, dynamic> _title;
  @override
  Map<String, dynamic> get title {
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_title);
  }

  @override
  final String category;
  final List<ArtistVoteItemModel>? _artist_vote_item;
  @override
  List<ArtistVoteItemModel>? get artist_vote_item {
    final value = _artist_vote_item;
    if (value == null) return null;
    if (_artist_vote_item is EqualUnmodifiableListView)
      return _artist_vote_item;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime created_at;
  @override
  final DateTime? updated_at;
  @override
  final DateTime? visible_at;
  @override
  final DateTime stop_at;
  @override
  final DateTime start_at;

  @override
  String toString() {
    return 'ArtistVoteModel(id: $id, title: $title, category: $category, artist_vote_item: $artist_vote_item, created_at: $created_at, updated_at: $updated_at, visible_at: $visible_at, stop_at: $stop_at, start_at: $start_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistVoteModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality()
                .equals(other._artist_vote_item, _artist_vote_item) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.updated_at, updated_at) ||
                other.updated_at == updated_at) &&
            (identical(other.visible_at, visible_at) ||
                other.visible_at == visible_at) &&
            (identical(other.stop_at, stop_at) || other.stop_at == stop_at) &&
            (identical(other.start_at, start_at) ||
                other.start_at == start_at));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_title),
      category,
      const DeepCollectionEquality().hash(_artist_vote_item),
      created_at,
      updated_at,
      visible_at,
      stop_at,
      start_at);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistVoteModelImplCopyWith<_$ArtistVoteModelImpl> get copyWith =>
      __$$ArtistVoteModelImplCopyWithImpl<_$ArtistVoteModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistVoteModelImplToJson(
      this,
    );
  }
}

abstract class _ArtistVoteModel extends ArtistVoteModel {
  const factory _ArtistVoteModel(
      {required final int id,
      required final Map<String, dynamic> title,
      required final String category,
      required final List<ArtistVoteItemModel>? artist_vote_item,
      required final DateTime created_at,
      required final DateTime? updated_at,
      required final DateTime? visible_at,
      required final DateTime stop_at,
      required final DateTime start_at}) = _$ArtistVoteModelImpl;
  const _ArtistVoteModel._() : super._();

  factory _ArtistVoteModel.fromJson(Map<String, dynamic> json) =
      _$ArtistVoteModelImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, dynamic> get title;
  @override
  String get category;
  @override
  List<ArtistVoteItemModel>? get artist_vote_item;
  @override
  DateTime get created_at;
  @override
  DateTime? get updated_at;
  @override
  DateTime? get visible_at;
  @override
  DateTime get stop_at;
  @override
  DateTime get start_at;
  @override
  @JsonKey(ignore: true)
  _$$ArtistVoteModelImplCopyWith<_$ArtistVoteModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistVoteItemModel _$ArtistVoteItemModelFromJson(Map<String, dynamic> json) {
  return _ArtistVoteItemModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistVoteItemModel {
  int get id => throw _privateConstructorUsedError;
  int get vote_total => throw _privateConstructorUsedError;
  int get artist_vote_id => throw _privateConstructorUsedError;
  Map<String, dynamic> get title => throw _privateConstructorUsedError;
  Map<String, dynamic> get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistVoteItemModelCopyWith<ArtistVoteItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistVoteItemModelCopyWith<$Res> {
  factory $ArtistVoteItemModelCopyWith(
          ArtistVoteItemModel value, $Res Function(ArtistVoteItemModel) then) =
      _$ArtistVoteItemModelCopyWithImpl<$Res, ArtistVoteItemModel>;
  @useResult
  $Res call(
      {int id,
      int vote_total,
      int artist_vote_id,
      Map<String, dynamic> title,
      Map<String, dynamic> description});
}

/// @nodoc
class _$ArtistVoteItemModelCopyWithImpl<$Res, $Val extends ArtistVoteItemModel>
    implements $ArtistVoteItemModelCopyWith<$Res> {
  _$ArtistVoteItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vote_total = null,
    Object? artist_vote_id = null,
    Object? title = null,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      vote_total: null == vote_total
          ? _value.vote_total
          : vote_total // ignore: cast_nullable_to_non_nullable
              as int,
      artist_vote_id: null == artist_vote_id
          ? _value.artist_vote_id
          : artist_vote_id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistVoteItemModelImplCopyWith<$Res>
    implements $ArtistVoteItemModelCopyWith<$Res> {
  factory _$$ArtistVoteItemModelImplCopyWith(_$ArtistVoteItemModelImpl value,
          $Res Function(_$ArtistVoteItemModelImpl) then) =
      __$$ArtistVoteItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int vote_total,
      int artist_vote_id,
      Map<String, dynamic> title,
      Map<String, dynamic> description});
}

/// @nodoc
class __$$ArtistVoteItemModelImplCopyWithImpl<$Res>
    extends _$ArtistVoteItemModelCopyWithImpl<$Res, _$ArtistVoteItemModelImpl>
    implements _$$ArtistVoteItemModelImplCopyWith<$Res> {
  __$$ArtistVoteItemModelImplCopyWithImpl(_$ArtistVoteItemModelImpl _value,
      $Res Function(_$ArtistVoteItemModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vote_total = null,
    Object? artist_vote_id = null,
    Object? title = null,
    Object? description = null,
  }) {
    return _then(_$ArtistVoteItemModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      vote_total: null == vote_total
          ? _value.vote_total
          : vote_total // ignore: cast_nullable_to_non_nullable
              as int,
      artist_vote_id: null == artist_vote_id
          ? _value.artist_vote_id
          : artist_vote_id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value._title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      description: null == description
          ? _value._description
          : description // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistVoteItemModelImpl extends _ArtistVoteItemModel {
  const _$ArtistVoteItemModelImpl(
      {required this.id,
      required this.vote_total,
      required this.artist_vote_id,
      required final Map<String, dynamic> title,
      required final Map<String, dynamic> description})
      : _title = title,
        _description = description,
        super._();

  factory _$ArtistVoteItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistVoteItemModelImplFromJson(json);

  @override
  final int id;
  @override
  final int vote_total;
  @override
  final int artist_vote_id;
  final Map<String, dynamic> _title;
  @override
  Map<String, dynamic> get title {
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_title);
  }

  final Map<String, dynamic> _description;
  @override
  Map<String, dynamic> get description {
    if (_description is EqualUnmodifiableMapView) return _description;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_description);
  }

  @override
  String toString() {
    return 'ArtistVoteItemModel(id: $id, vote_total: $vote_total, artist_vote_id: $artist_vote_id, title: $title, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistVoteItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vote_total, vote_total) ||
                other.vote_total == vote_total) &&
            (identical(other.artist_vote_id, artist_vote_id) ||
                other.artist_vote_id == artist_vote_id) &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            const DeepCollectionEquality()
                .equals(other._description, _description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      vote_total,
      artist_vote_id,
      const DeepCollectionEquality().hash(_title),
      const DeepCollectionEquality().hash(_description));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistVoteItemModelImplCopyWith<_$ArtistVoteItemModelImpl> get copyWith =>
      __$$ArtistVoteItemModelImplCopyWithImpl<_$ArtistVoteItemModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistVoteItemModelImplToJson(
      this,
    );
  }
}

abstract class _ArtistVoteItemModel extends ArtistVoteItemModel {
  const factory _ArtistVoteItemModel(
          {required final int id,
          required final int vote_total,
          required final int artist_vote_id,
          required final Map<String, dynamic> title,
          required final Map<String, dynamic> description}) =
      _$ArtistVoteItemModelImpl;
  const _ArtistVoteItemModel._() : super._();

  factory _ArtistVoteItemModel.fromJson(Map<String, dynamic> json) =
      _$ArtistVoteItemModelImpl.fromJson;

  @override
  int get id;
  @override
  int get vote_total;
  @override
  int get artist_vote_id;
  @override
  Map<String, dynamic> get title;
  @override
  Map<String, dynamic> get description;
  @override
  @JsonKey(ignore: true)
  _$$ArtistVoteItemModelImplCopyWith<_$ArtistVoteItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MyStarMemberModel _$MyStarMemberModelFromJson(Map<String, dynamic> json) {
  return _MyStarMemberModel.fromJson(json);
}

/// @nodoc
mixin _$MyStarMemberModel {
  int get id => throw _privateConstructorUsedError;
  String get name_ko => throw _privateConstructorUsedError;
  String get name_en => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;
  MyStarGroupModel? get mystar_group => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MyStarMemberModelCopyWith<MyStarMemberModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyStarMemberModelCopyWith<$Res> {
  factory $MyStarMemberModelCopyWith(
          MyStarMemberModel value, $Res Function(MyStarMemberModel) then) =
      _$MyStarMemberModelCopyWithImpl<$Res, MyStarMemberModel>;
  @useResult
  $Res call(
      {int id,
      String name_ko,
      String name_en,
      String gender,
      String? image,
      MyStarGroupModel? mystar_group});

  $MyStarGroupModelCopyWith<$Res>? get mystar_group;
}

/// @nodoc
class _$MyStarMemberModelCopyWithImpl<$Res, $Val extends MyStarMemberModel>
    implements $MyStarMemberModelCopyWith<$Res> {
  _$MyStarMemberModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name_ko = null,
    Object? name_en = null,
    Object? gender = null,
    Object? image = freezed,
    Object? mystar_group = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name_ko: null == name_ko
          ? _value.name_ko
          : name_ko // ignore: cast_nullable_to_non_nullable
              as String,
      name_en: null == name_en
          ? _value.name_en
          : name_en // ignore: cast_nullable_to_non_nullable
              as String,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      mystar_group: freezed == mystar_group
          ? _value.mystar_group
          : mystar_group // ignore: cast_nullable_to_non_nullable
              as MyStarGroupModel?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MyStarGroupModelCopyWith<$Res>? get mystar_group {
    if (_value.mystar_group == null) {
      return null;
    }

    return $MyStarGroupModelCopyWith<$Res>(_value.mystar_group!, (value) {
      return _then(_value.copyWith(mystar_group: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MyStarMemberModelImplCopyWith<$Res>
    implements $MyStarMemberModelCopyWith<$Res> {
  factory _$$MyStarMemberModelImplCopyWith(_$MyStarMemberModelImpl value,
          $Res Function(_$MyStarMemberModelImpl) then) =
      __$$MyStarMemberModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name_ko,
      String name_en,
      String gender,
      String? image,
      MyStarGroupModel? mystar_group});

  @override
  $MyStarGroupModelCopyWith<$Res>? get mystar_group;
}

/// @nodoc
class __$$MyStarMemberModelImplCopyWithImpl<$Res>
    extends _$MyStarMemberModelCopyWithImpl<$Res, _$MyStarMemberModelImpl>
    implements _$$MyStarMemberModelImplCopyWith<$Res> {
  __$$MyStarMemberModelImplCopyWithImpl(_$MyStarMemberModelImpl _value,
      $Res Function(_$MyStarMemberModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name_ko = null,
    Object? name_en = null,
    Object? gender = null,
    Object? image = freezed,
    Object? mystar_group = freezed,
  }) {
    return _then(_$MyStarMemberModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name_ko: null == name_ko
          ? _value.name_ko
          : name_ko // ignore: cast_nullable_to_non_nullable
              as String,
      name_en: null == name_en
          ? _value.name_en
          : name_en // ignore: cast_nullable_to_non_nullable
              as String,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      mystar_group: freezed == mystar_group
          ? _value.mystar_group
          : mystar_group // ignore: cast_nullable_to_non_nullable
              as MyStarGroupModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MyStarMemberModelImpl extends _MyStarMemberModel {
  const _$MyStarMemberModelImpl(
      {required this.id,
      required this.name_ko,
      required this.name_en,
      required this.gender,
      required this.image,
      this.mystar_group})
      : super._();

  factory _$MyStarMemberModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyStarMemberModelImplFromJson(json);

  @override
  final int id;
  @override
  final String name_ko;
  @override
  final String name_en;
  @override
  final String gender;
  @override
  final String? image;
  @override
  final MyStarGroupModel? mystar_group;

  @override
  String toString() {
    return 'MyStarMemberModel(id: $id, name_ko: $name_ko, name_en: $name_en, gender: $gender, image: $image, mystar_group: $mystar_group)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyStarMemberModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name_ko, name_ko) || other.name_ko == name_ko) &&
            (identical(other.name_en, name_en) || other.name_en == name_en) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.mystar_group, mystar_group) ||
                other.mystar_group == mystar_group));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name_ko, name_en, gender, image, mystar_group);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MyStarMemberModelImplCopyWith<_$MyStarMemberModelImpl> get copyWith =>
      __$$MyStarMemberModelImplCopyWithImpl<_$MyStarMemberModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MyStarMemberModelImplToJson(
      this,
    );
  }
}

abstract class _MyStarMemberModel extends MyStarMemberModel {
  const factory _MyStarMemberModel(
      {required final int id,
      required final String name_ko,
      required final String name_en,
      required final String gender,
      required final String? image,
      final MyStarGroupModel? mystar_group}) = _$MyStarMemberModelImpl;
  const _MyStarMemberModel._() : super._();

  factory _MyStarMemberModel.fromJson(Map<String, dynamic> json) =
      _$MyStarMemberModelImpl.fromJson;

  @override
  int get id;
  @override
  String get name_ko;
  @override
  String get name_en;
  @override
  String get gender;
  @override
  String? get image;
  @override
  MyStarGroupModel? get mystar_group;
  @override
  @JsonKey(ignore: true)
  _$$MyStarMemberModelImplCopyWith<_$MyStarMemberModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MyStarGroupModel _$MyStarGroupModelFromJson(Map<String, dynamic> json) {
  return _MyStarGroupModel.fromJson(json);
}

/// @nodoc
mixin _$MyStarGroupModel {
  int get id => throw _privateConstructorUsedError;
  String get name_ko => throw _privateConstructorUsedError;
  String get name_en => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MyStarGroupModelCopyWith<MyStarGroupModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyStarGroupModelCopyWith<$Res> {
  factory $MyStarGroupModelCopyWith(
          MyStarGroupModel value, $Res Function(MyStarGroupModel) then) =
      _$MyStarGroupModelCopyWithImpl<$Res, MyStarGroupModel>;
  @useResult
  $Res call({int id, String name_ko, String name_en, String? image});
}

/// @nodoc
class _$MyStarGroupModelCopyWithImpl<$Res, $Val extends MyStarGroupModel>
    implements $MyStarGroupModelCopyWith<$Res> {
  _$MyStarGroupModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name_ko = null,
    Object? name_en = null,
    Object? image = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name_ko: null == name_ko
          ? _value.name_ko
          : name_ko // ignore: cast_nullable_to_non_nullable
              as String,
      name_en: null == name_en
          ? _value.name_en
          : name_en // ignore: cast_nullable_to_non_nullable
              as String,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MyStarGroupModelImplCopyWith<$Res>
    implements $MyStarGroupModelCopyWith<$Res> {
  factory _$$MyStarGroupModelImplCopyWith(_$MyStarGroupModelImpl value,
          $Res Function(_$MyStarGroupModelImpl) then) =
      __$$MyStarGroupModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String name_ko, String name_en, String? image});
}

/// @nodoc
class __$$MyStarGroupModelImplCopyWithImpl<$Res>
    extends _$MyStarGroupModelCopyWithImpl<$Res, _$MyStarGroupModelImpl>
    implements _$$MyStarGroupModelImplCopyWith<$Res> {
  __$$MyStarGroupModelImplCopyWithImpl(_$MyStarGroupModelImpl _value,
      $Res Function(_$MyStarGroupModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name_ko = null,
    Object? name_en = null,
    Object? image = freezed,
  }) {
    return _then(_$MyStarGroupModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name_ko: null == name_ko
          ? _value.name_ko
          : name_ko // ignore: cast_nullable_to_non_nullable
              as String,
      name_en: null == name_en
          ? _value.name_en
          : name_en // ignore: cast_nullable_to_non_nullable
              as String,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MyStarGroupModelImpl extends _MyStarGroupModel {
  const _$MyStarGroupModelImpl(
      {required this.id,
      required this.name_ko,
      required this.name_en,
      this.image})
      : super._();

  factory _$MyStarGroupModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyStarGroupModelImplFromJson(json);

  @override
  final int id;
  @override
  final String name_ko;
  @override
  final String name_en;
  @override
  final String? image;

  @override
  String toString() {
    return 'MyStarGroupModel(id: $id, name_ko: $name_ko, name_en: $name_en, image: $image)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyStarGroupModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name_ko, name_ko) || other.name_ko == name_ko) &&
            (identical(other.name_en, name_en) || other.name_en == name_en) &&
            (identical(other.image, image) || other.image == image));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name_ko, name_en, image);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MyStarGroupModelImplCopyWith<_$MyStarGroupModelImpl> get copyWith =>
      __$$MyStarGroupModelImplCopyWithImpl<_$MyStarGroupModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MyStarGroupModelImplToJson(
      this,
    );
  }
}

abstract class _MyStarGroupModel extends MyStarGroupModel {
  const factory _MyStarGroupModel(
      {required final int id,
      required final String name_ko,
      required final String name_en,
      final String? image}) = _$MyStarGroupModelImpl;
  const _MyStarGroupModel._() : super._();

  factory _MyStarGroupModel.fromJson(Map<String, dynamic> json) =
      _$MyStarGroupModelImpl.fromJson;

  @override
  int get id;
  @override
  String get name_ko;
  @override
  String get name_en;
  @override
  String? get image;
  @override
  @JsonKey(ignore: true)
  _$$MyStarGroupModelImplCopyWith<_$MyStarGroupModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
