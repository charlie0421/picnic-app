// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VoteListModel _$VoteListModelFromJson(Map<String, dynamic> json) {
  return _VoteListModel.fromJson(json);
}

/// @nodoc
mixin _$VoteListModel {
  List<VoteModel> get items => throw _privateConstructorUsedError;
  MetaModel get meta => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VoteListModelCopyWith<VoteListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteListModelCopyWith<$Res> {
  factory $VoteListModelCopyWith(
          VoteListModel value, $Res Function(VoteListModel) then) =
      _$VoteListModelCopyWithImpl<$Res, VoteListModel>;
  @useResult
  $Res call({List<VoteModel> items, MetaModel meta});

  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class _$VoteListModelCopyWithImpl<$Res, $Val extends VoteListModel>
    implements $VoteListModelCopyWith<$Res> {
  _$VoteListModelCopyWithImpl(this._value, this._then);

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
              as List<VoteModel>,
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
abstract class _$$VoteListModelImplCopyWith<$Res>
    implements $VoteListModelCopyWith<$Res> {
  factory _$$VoteListModelImplCopyWith(
          _$VoteListModelImpl value, $Res Function(_$VoteListModelImpl) then) =
      __$$VoteListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<VoteModel> items, MetaModel meta});

  @override
  $MetaModelCopyWith<$Res> get meta;
}

/// @nodoc
class __$$VoteListModelImplCopyWithImpl<$Res>
    extends _$VoteListModelCopyWithImpl<$Res, _$VoteListModelImpl>
    implements _$$VoteListModelImplCopyWith<$Res> {
  __$$VoteListModelImplCopyWithImpl(
      _$VoteListModelImpl _value, $Res Function(_$VoteListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? meta = null,
  }) {
    return _then(_$VoteListModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<VoteModel>,
      meta: null == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as MetaModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoteListModelImpl extends _VoteListModel {
  const _$VoteListModelImpl(
      {required final List<VoteModel> items, required this.meta})
      : _items = items,
        super._();

  factory _$VoteListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteListModelImplFromJson(json);

  final List<VoteModel> _items;
  @override
  List<VoteModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final MetaModel meta;

  @override
  String toString() {
    return 'VoteListModel(items: $items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteListModelImpl &&
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
  _$$VoteListModelImplCopyWith<_$VoteListModelImpl> get copyWith =>
      __$$VoteListModelImplCopyWithImpl<_$VoteListModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoteListModelImplToJson(
      this,
    );
  }
}

abstract class _VoteListModel extends VoteListModel {
  const factory _VoteListModel(
      {required final List<VoteModel> items,
      required final MetaModel meta}) = _$VoteListModelImpl;
  const _VoteListModel._() : super._();

  factory _VoteListModel.fromJson(Map<String, dynamic> json) =
      _$VoteListModelImpl.fromJson;

  @override
  List<VoteModel> get items;
  @override
  MetaModel get meta;
  @override
  @JsonKey(ignore: true)
  _$$VoteListModelImplCopyWith<_$VoteListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VoteModel _$VoteModelFromJson(Map<String, dynamic> json) {
  return _VoteModel.fromJson(json);
}

/// @nodoc
mixin _$VoteModel {
  int get id => throw _privateConstructorUsedError;
  Map<String, dynamic> get title => throw _privateConstructorUsedError;
  String get vote_category => throw _privateConstructorUsedError;
  String get main_image => throw _privateConstructorUsedError;
  String get wait_image => throw _privateConstructorUsedError;
  String get result_image => throw _privateConstructorUsedError;
  String get vote_content => throw _privateConstructorUsedError;
  List<VoteItemModel>? get vote_item => throw _privateConstructorUsedError;
  DateTime get created_at => throw _privateConstructorUsedError;
  DateTime get visible_at => throw _privateConstructorUsedError;
  DateTime get stop_at => throw _privateConstructorUsedError;
  DateTime get start_at => throw _privateConstructorUsedError;
  bool? get is_ended => throw _privateConstructorUsedError;
  bool? get is_upcoming => throw _privateConstructorUsedError;
  List<RewardModel>? get reward => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VoteModelCopyWith<VoteModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteModelCopyWith<$Res> {
  factory $VoteModelCopyWith(VoteModel value, $Res Function(VoteModel) then) =
      _$VoteModelCopyWithImpl<$Res, VoteModel>;
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic> title,
      String vote_category,
      String main_image,
      String wait_image,
      String result_image,
      String vote_content,
      List<VoteItemModel>? vote_item,
      DateTime created_at,
      DateTime visible_at,
      DateTime stop_at,
      DateTime start_at,
      bool? is_ended,
      bool? is_upcoming,
      List<RewardModel>? reward});
}

/// @nodoc
class _$VoteModelCopyWithImpl<$Res, $Val extends VoteModel>
    implements $VoteModelCopyWith<$Res> {
  _$VoteModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? vote_category = null,
    Object? main_image = null,
    Object? wait_image = null,
    Object? result_image = null,
    Object? vote_content = null,
    Object? vote_item = freezed,
    Object? created_at = null,
    Object? visible_at = null,
    Object? stop_at = null,
    Object? start_at = null,
    Object? is_ended = freezed,
    Object? is_upcoming = freezed,
    Object? reward = freezed,
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
      vote_category: null == vote_category
          ? _value.vote_category
          : vote_category // ignore: cast_nullable_to_non_nullable
              as String,
      main_image: null == main_image
          ? _value.main_image
          : main_image // ignore: cast_nullable_to_non_nullable
              as String,
      wait_image: null == wait_image
          ? _value.wait_image
          : wait_image // ignore: cast_nullable_to_non_nullable
              as String,
      result_image: null == result_image
          ? _value.result_image
          : result_image // ignore: cast_nullable_to_non_nullable
              as String,
      vote_content: null == vote_content
          ? _value.vote_content
          : vote_content // ignore: cast_nullable_to_non_nullable
              as String,
      vote_item: freezed == vote_item
          ? _value.vote_item
          : vote_item // ignore: cast_nullable_to_non_nullable
              as List<VoteItemModel>?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      visible_at: null == visible_at
          ? _value.visible_at
          : visible_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      stop_at: null == stop_at
          ? _value.stop_at
          : stop_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      start_at: null == start_at
          ? _value.start_at
          : start_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      is_ended: freezed == is_ended
          ? _value.is_ended
          : is_ended // ignore: cast_nullable_to_non_nullable
              as bool?,
      is_upcoming: freezed == is_upcoming
          ? _value.is_upcoming
          : is_upcoming // ignore: cast_nullable_to_non_nullable
              as bool?,
      reward: freezed == reward
          ? _value.reward
          : reward // ignore: cast_nullable_to_non_nullable
              as List<RewardModel>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VoteModelImplCopyWith<$Res>
    implements $VoteModelCopyWith<$Res> {
  factory _$$VoteModelImplCopyWith(
          _$VoteModelImpl value, $Res Function(_$VoteModelImpl) then) =
      __$$VoteModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic> title,
      String vote_category,
      String main_image,
      String wait_image,
      String result_image,
      String vote_content,
      List<VoteItemModel>? vote_item,
      DateTime created_at,
      DateTime visible_at,
      DateTime stop_at,
      DateTime start_at,
      bool? is_ended,
      bool? is_upcoming,
      List<RewardModel>? reward});
}

/// @nodoc
class __$$VoteModelImplCopyWithImpl<$Res>
    extends _$VoteModelCopyWithImpl<$Res, _$VoteModelImpl>
    implements _$$VoteModelImplCopyWith<$Res> {
  __$$VoteModelImplCopyWithImpl(
      _$VoteModelImpl _value, $Res Function(_$VoteModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? vote_category = null,
    Object? main_image = null,
    Object? wait_image = null,
    Object? result_image = null,
    Object? vote_content = null,
    Object? vote_item = freezed,
    Object? created_at = null,
    Object? visible_at = null,
    Object? stop_at = null,
    Object? start_at = null,
    Object? is_ended = freezed,
    Object? is_upcoming = freezed,
    Object? reward = freezed,
  }) {
    return _then(_$VoteModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value._title
          : title // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      vote_category: null == vote_category
          ? _value.vote_category
          : vote_category // ignore: cast_nullable_to_non_nullable
              as String,
      main_image: null == main_image
          ? _value.main_image
          : main_image // ignore: cast_nullable_to_non_nullable
              as String,
      wait_image: null == wait_image
          ? _value.wait_image
          : wait_image // ignore: cast_nullable_to_non_nullable
              as String,
      result_image: null == result_image
          ? _value.result_image
          : result_image // ignore: cast_nullable_to_non_nullable
              as String,
      vote_content: null == vote_content
          ? _value.vote_content
          : vote_content // ignore: cast_nullable_to_non_nullable
              as String,
      vote_item: freezed == vote_item
          ? _value._vote_item
          : vote_item // ignore: cast_nullable_to_non_nullable
              as List<VoteItemModel>?,
      created_at: null == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      visible_at: null == visible_at
          ? _value.visible_at
          : visible_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      stop_at: null == stop_at
          ? _value.stop_at
          : stop_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      start_at: null == start_at
          ? _value.start_at
          : start_at // ignore: cast_nullable_to_non_nullable
              as DateTime,
      is_ended: freezed == is_ended
          ? _value.is_ended
          : is_ended // ignore: cast_nullable_to_non_nullable
              as bool?,
      is_upcoming: freezed == is_upcoming
          ? _value.is_upcoming
          : is_upcoming // ignore: cast_nullable_to_non_nullable
              as bool?,
      reward: freezed == reward
          ? _value._reward
          : reward // ignore: cast_nullable_to_non_nullable
              as List<RewardModel>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoteModelImpl extends _VoteModel {
  const _$VoteModelImpl(
      {required this.id,
      required final Map<String, dynamic> title,
      required this.vote_category,
      required this.main_image,
      required this.wait_image,
      required this.result_image,
      required this.vote_content,
      required final List<VoteItemModel>? vote_item,
      required this.created_at,
      required this.visible_at,
      required this.stop_at,
      required this.start_at,
      required this.is_ended,
      required this.is_upcoming,
      required final List<RewardModel>? reward})
      : _title = title,
        _vote_item = vote_item,
        _reward = reward,
        super._();

  factory _$VoteModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteModelImplFromJson(json);

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
  final String vote_category;
  @override
  final String main_image;
  @override
  final String wait_image;
  @override
  final String result_image;
  @override
  final String vote_content;
  final List<VoteItemModel>? _vote_item;
  @override
  List<VoteItemModel>? get vote_item {
    final value = _vote_item;
    if (value == null) return null;
    if (_vote_item is EqualUnmodifiableListView) return _vote_item;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime created_at;
  @override
  final DateTime visible_at;
  @override
  final DateTime stop_at;
  @override
  final DateTime start_at;
  @override
  final bool? is_ended;
  @override
  final bool? is_upcoming;
  final List<RewardModel>? _reward;
  @override
  List<RewardModel>? get reward {
    final value = _reward;
    if (value == null) return null;
    if (_reward is EqualUnmodifiableListView) return _reward;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'VoteModel(id: $id, title: $title, vote_category: $vote_category, main_image: $main_image, wait_image: $wait_image, result_image: $result_image, vote_content: $vote_content, vote_item: $vote_item, created_at: $created_at, visible_at: $visible_at, stop_at: $stop_at, start_at: $start_at, is_ended: $is_ended, is_upcoming: $is_upcoming, reward: $reward)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            (identical(other.vote_category, vote_category) ||
                other.vote_category == vote_category) &&
            (identical(other.main_image, main_image) ||
                other.main_image == main_image) &&
            (identical(other.wait_image, wait_image) ||
                other.wait_image == wait_image) &&
            (identical(other.result_image, result_image) ||
                other.result_image == result_image) &&
            (identical(other.vote_content, vote_content) ||
                other.vote_content == vote_content) &&
            const DeepCollectionEquality()
                .equals(other._vote_item, _vote_item) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.visible_at, visible_at) ||
                other.visible_at == visible_at) &&
            (identical(other.stop_at, stop_at) || other.stop_at == stop_at) &&
            (identical(other.start_at, start_at) ||
                other.start_at == start_at) &&
            (identical(other.is_ended, is_ended) ||
                other.is_ended == is_ended) &&
            (identical(other.is_upcoming, is_upcoming) ||
                other.is_upcoming == is_upcoming) &&
            const DeepCollectionEquality().equals(other._reward, _reward));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_title),
      vote_category,
      main_image,
      wait_image,
      result_image,
      vote_content,
      const DeepCollectionEquality().hash(_vote_item),
      created_at,
      visible_at,
      stop_at,
      start_at,
      is_ended,
      is_upcoming,
      const DeepCollectionEquality().hash(_reward));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VoteModelImplCopyWith<_$VoteModelImpl> get copyWith =>
      __$$VoteModelImplCopyWithImpl<_$VoteModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoteModelImplToJson(
      this,
    );
  }
}

abstract class _VoteModel extends VoteModel {
  const factory _VoteModel(
      {required final int id,
      required final Map<String, dynamic> title,
      required final String vote_category,
      required final String main_image,
      required final String wait_image,
      required final String result_image,
      required final String vote_content,
      required final List<VoteItemModel>? vote_item,
      required final DateTime created_at,
      required final DateTime visible_at,
      required final DateTime stop_at,
      required final DateTime start_at,
      required final bool? is_ended,
      required final bool? is_upcoming,
      required final List<RewardModel>? reward}) = _$VoteModelImpl;
  const _VoteModel._() : super._();

  factory _VoteModel.fromJson(Map<String, dynamic> json) =
      _$VoteModelImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, dynamic> get title;
  @override
  String get vote_category;
  @override
  String get main_image;
  @override
  String get wait_image;
  @override
  String get result_image;
  @override
  String get vote_content;
  @override
  List<VoteItemModel>? get vote_item;
  @override
  DateTime get created_at;
  @override
  DateTime get visible_at;
  @override
  DateTime get stop_at;
  @override
  DateTime get start_at;
  @override
  bool? get is_ended;
  @override
  bool? get is_upcoming;
  @override
  List<RewardModel>? get reward;
  @override
  @JsonKey(ignore: true)
  _$$VoteModelImplCopyWith<_$VoteModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VoteItemModel _$VoteItemModelFromJson(Map<String, dynamic> json) {
  return _VoteItemModel.fromJson(json);
}

/// @nodoc
mixin _$VoteItemModel {
  int get id => throw _privateConstructorUsedError;
  int get vote_total => throw _privateConstructorUsedError;
  int get vote_id => throw _privateConstructorUsedError;
  ArtistModel get artist => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VoteItemModelCopyWith<VoteItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteItemModelCopyWith<$Res> {
  factory $VoteItemModelCopyWith(
          VoteItemModel value, $Res Function(VoteItemModel) then) =
      _$VoteItemModelCopyWithImpl<$Res, VoteItemModel>;
  @useResult
  $Res call({int id, int vote_total, int vote_id, ArtistModel artist});

  $ArtistModelCopyWith<$Res> get artist;
}

/// @nodoc
class _$VoteItemModelCopyWithImpl<$Res, $Val extends VoteItemModel>
    implements $VoteItemModelCopyWith<$Res> {
  _$VoteItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vote_total = null,
    Object? vote_id = null,
    Object? artist = null,
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
      vote_id: null == vote_id
          ? _value.vote_id
          : vote_id // ignore: cast_nullable_to_non_nullable
              as int,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ArtistModelCopyWith<$Res> get artist {
    return $ArtistModelCopyWith<$Res>(_value.artist, (value) {
      return _then(_value.copyWith(artist: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VoteItemModelImplCopyWith<$Res>
    implements $VoteItemModelCopyWith<$Res> {
  factory _$$VoteItemModelImplCopyWith(
          _$VoteItemModelImpl value, $Res Function(_$VoteItemModelImpl) then) =
      __$$VoteItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, int vote_total, int vote_id, ArtistModel artist});

  @override
  $ArtistModelCopyWith<$Res> get artist;
}

/// @nodoc
class __$$VoteItemModelImplCopyWithImpl<$Res>
    extends _$VoteItemModelCopyWithImpl<$Res, _$VoteItemModelImpl>
    implements _$$VoteItemModelImplCopyWith<$Res> {
  __$$VoteItemModelImplCopyWithImpl(
      _$VoteItemModelImpl _value, $Res Function(_$VoteItemModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? vote_total = null,
    Object? vote_id = null,
    Object? artist = null,
  }) {
    return _then(_$VoteItemModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      vote_total: null == vote_total
          ? _value.vote_total
          : vote_total // ignore: cast_nullable_to_non_nullable
              as int,
      vote_id: null == vote_id
          ? _value.vote_id
          : vote_id // ignore: cast_nullable_to_non_nullable
              as int,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoteItemModelImpl extends _VoteItemModel {
  const _$VoteItemModelImpl(
      {required this.id,
      required this.vote_total,
      required this.vote_id,
      required this.artist})
      : super._();

  factory _$VoteItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteItemModelImplFromJson(json);

  @override
  final int id;
  @override
  final int vote_total;
  @override
  final int vote_id;
  @override
  final ArtistModel artist;

  @override
  String toString() {
    return 'VoteItemModel(id: $id, vote_total: $vote_total, vote_id: $vote_id, artist: $artist)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.vote_total, vote_total) ||
                other.vote_total == vote_total) &&
            (identical(other.vote_id, vote_id) || other.vote_id == vote_id) &&
            (identical(other.artist, artist) || other.artist == artist));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, vote_total, vote_id, artist);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VoteItemModelImplCopyWith<_$VoteItemModelImpl> get copyWith =>
      __$$VoteItemModelImplCopyWithImpl<_$VoteItemModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoteItemModelImplToJson(
      this,
    );
  }
}

abstract class _VoteItemModel extends VoteItemModel {
  const factory _VoteItemModel(
      {required final int id,
      required final int vote_total,
      required final int vote_id,
      required final ArtistModel artist}) = _$VoteItemModelImpl;
  const _VoteItemModel._() : super._();

  factory _VoteItemModel.fromJson(Map<String, dynamic> json) =
      _$VoteItemModelImpl.fromJson;

  @override
  int get id;
  @override
  int get vote_total;
  @override
  int get vote_id;
  @override
  ArtistModel get artist;
  @override
  @JsonKey(ignore: true)
  _$$VoteItemModelImplCopyWith<_$VoteItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistModel _$ArtistModelFromJson(Map<String, dynamic> json) {
  return _ArtistModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistModel {
  int get id => throw _privateConstructorUsedError;
  Map<String, dynamic> get name => throw _privateConstructorUsedError;
  int? get yy => throw _privateConstructorUsedError;
  int? get mm => throw _privateConstructorUsedError;
  int? get dd => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  String get image => throw _privateConstructorUsedError;
  ArtistGroupModel get artist_group => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistModelCopyWith<ArtistModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistModelCopyWith<$Res> {
  factory $ArtistModelCopyWith(
          ArtistModel value, $Res Function(ArtistModel) then) =
      _$ArtistModelCopyWithImpl<$Res, ArtistModel>;
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic> name,
      int? yy,
      int? mm,
      int? dd,
      String gender,
      String image,
      ArtistGroupModel artist_group});

  $ArtistGroupModelCopyWith<$Res> get artist_group;
}

/// @nodoc
class _$ArtistModelCopyWithImpl<$Res, $Val extends ArtistModel>
    implements $ArtistModelCopyWith<$Res> {
  _$ArtistModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? yy = freezed,
    Object? mm = freezed,
    Object? dd = freezed,
    Object? gender = null,
    Object? image = null,
    Object? artist_group = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      yy: freezed == yy
          ? _value.yy
          : yy // ignore: cast_nullable_to_non_nullable
              as int?,
      mm: freezed == mm
          ? _value.mm
          : mm // ignore: cast_nullable_to_non_nullable
              as int?,
      dd: freezed == dd
          ? _value.dd
          : dd // ignore: cast_nullable_to_non_nullable
              as int?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      artist_group: null == artist_group
          ? _value.artist_group
          : artist_group // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ArtistGroupModelCopyWith<$Res> get artist_group {
    return $ArtistGroupModelCopyWith<$Res>(_value.artist_group, (value) {
      return _then(_value.copyWith(artist_group: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArtistModelImplCopyWith<$Res>
    implements $ArtistModelCopyWith<$Res> {
  factory _$$ArtistModelImplCopyWith(
          _$ArtistModelImpl value, $Res Function(_$ArtistModelImpl) then) =
      __$$ArtistModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      Map<String, dynamic> name,
      int? yy,
      int? mm,
      int? dd,
      String gender,
      String image,
      ArtistGroupModel artist_group});

  @override
  $ArtistGroupModelCopyWith<$Res> get artist_group;
}

/// @nodoc
class __$$ArtistModelImplCopyWithImpl<$Res>
    extends _$ArtistModelCopyWithImpl<$Res, _$ArtistModelImpl>
    implements _$$ArtistModelImplCopyWith<$Res> {
  __$$ArtistModelImplCopyWithImpl(
      _$ArtistModelImpl _value, $Res Function(_$ArtistModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? yy = freezed,
    Object? mm = freezed,
    Object? dd = freezed,
    Object? gender = null,
    Object? image = null,
    Object? artist_group = null,
  }) {
    return _then(_$ArtistModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value._name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      yy: freezed == yy
          ? _value.yy
          : yy // ignore: cast_nullable_to_non_nullable
              as int?,
      mm: freezed == mm
          ? _value.mm
          : mm // ignore: cast_nullable_to_non_nullable
              as int?,
      dd: freezed == dd
          ? _value.dd
          : dd // ignore: cast_nullable_to_non_nullable
              as int?,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      artist_group: null == artist_group
          ? _value.artist_group
          : artist_group // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistModelImpl extends _ArtistModel {
  const _$ArtistModelImpl(
      {required this.id,
      required final Map<String, dynamic> name,
      required this.yy,
      required this.mm,
      required this.dd,
      required this.gender,
      required this.image,
      required this.artist_group})
      : _name = name,
        super._();

  factory _$ArtistModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistModelImplFromJson(json);

  @override
  final int id;
  final Map<String, dynamic> _name;
  @override
  Map<String, dynamic> get name {
    if (_name is EqualUnmodifiableMapView) return _name;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_name);
  }

  @override
  final int? yy;
  @override
  final int? mm;
  @override
  final int? dd;
  @override
  final String gender;
  @override
  final String image;
  @override
  final ArtistGroupModel artist_group;

  @override
  String toString() {
    return 'ArtistModel(id: $id, name: $name, yy: $yy, mm: $mm, dd: $dd, gender: $gender, image: $image, artist_group: $artist_group)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._name, _name) &&
            (identical(other.yy, yy) || other.yy == yy) &&
            (identical(other.mm, mm) || other.mm == mm) &&
            (identical(other.dd, dd) || other.dd == dd) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.artist_group, artist_group) ||
                other.artist_group == artist_group));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_name),
      yy,
      mm,
      dd,
      gender,
      image,
      artist_group);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistModelImplCopyWith<_$ArtistModelImpl> get copyWith =>
      __$$ArtistModelImplCopyWithImpl<_$ArtistModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistModelImplToJson(
      this,
    );
  }
}

abstract class _ArtistModel extends ArtistModel {
  const factory _ArtistModel(
      {required final int id,
      required final Map<String, dynamic> name,
      required final int? yy,
      required final int? mm,
      required final int? dd,
      required final String gender,
      required final String image,
      required final ArtistGroupModel artist_group}) = _$ArtistModelImpl;
  const _ArtistModel._() : super._();

  factory _ArtistModel.fromJson(Map<String, dynamic> json) =
      _$ArtistModelImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, dynamic> get name;
  @override
  int? get yy;
  @override
  int? get mm;
  @override
  int? get dd;
  @override
  String get gender;
  @override
  String get image;
  @override
  ArtistGroupModel get artist_group;
  @override
  @JsonKey(ignore: true)
  _$$ArtistModelImplCopyWith<_$ArtistModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistGroupModel _$ArtistGroupModelFromJson(Map<String, dynamic> json) {
  return _ArtistGroupModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistGroupModel {
  int get id => throw _privateConstructorUsedError;
  Map<String, dynamic> get name => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ArtistGroupModelCopyWith<ArtistGroupModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistGroupModelCopyWith<$Res> {
  factory $ArtistGroupModelCopyWith(
          ArtistGroupModel value, $Res Function(ArtistGroupModel) then) =
      _$ArtistGroupModelCopyWithImpl<$Res, ArtistGroupModel>;
  @useResult
  $Res call({int id, Map<String, dynamic> name});
}

/// @nodoc
class _$ArtistGroupModelCopyWithImpl<$Res, $Val extends ArtistGroupModel>
    implements $ArtistGroupModelCopyWith<$Res> {
  _$ArtistGroupModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistGroupModelImplCopyWith<$Res>
    implements $ArtistGroupModelCopyWith<$Res> {
  factory _$$ArtistGroupModelImplCopyWith(_$ArtistGroupModelImpl value,
          $Res Function(_$ArtistGroupModelImpl) then) =
      __$$ArtistGroupModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, Map<String, dynamic> name});
}

/// @nodoc
class __$$ArtistGroupModelImplCopyWithImpl<$Res>
    extends _$ArtistGroupModelCopyWithImpl<$Res, _$ArtistGroupModelImpl>
    implements _$$ArtistGroupModelImplCopyWith<$Res> {
  __$$ArtistGroupModelImplCopyWithImpl(_$ArtistGroupModelImpl _value,
      $Res Function(_$ArtistGroupModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$ArtistGroupModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value._name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistGroupModelImpl extends _ArtistGroupModel {
  const _$ArtistGroupModelImpl(
      {required this.id, required final Map<String, dynamic> name})
      : _name = name,
        super._();

  factory _$ArtistGroupModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistGroupModelImplFromJson(json);

  @override
  final int id;
  final Map<String, dynamic> _name;
  @override
  Map<String, dynamic> get name {
    if (_name is EqualUnmodifiableMapView) return _name;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_name);
  }

  @override
  String toString() {
    return 'ArtistGroupModel(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistGroupModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._name, _name));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, const DeepCollectionEquality().hash(_name));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistGroupModelImplCopyWith<_$ArtistGroupModelImpl> get copyWith =>
      __$$ArtistGroupModelImplCopyWithImpl<_$ArtistGroupModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistGroupModelImplToJson(
      this,
    );
  }
}

abstract class _ArtistGroupModel extends ArtistGroupModel {
  const factory _ArtistGroupModel(
      {required final int id,
      required final Map<String, dynamic> name}) = _$ArtistGroupModelImpl;
  const _ArtistGroupModel._() : super._();

  factory _ArtistGroupModel.fromJson(Map<String, dynamic> json) =
      _$ArtistGroupModelImpl.fromJson;

  @override
  int get id;
  @override
  Map<String, dynamic> get name;
  @override
  @JsonKey(ignore: true)
  _$$ArtistGroupModelImplCopyWith<_$ArtistGroupModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
