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
  String get title_ko => throw _privateConstructorUsedError;
  String get title_en => throw _privateConstructorUsedError;
  String get title_ja => throw _privateConstructorUsedError;
  String get title_zh => throw _privateConstructorUsedError;
  String get vote_category => throw _privateConstructorUsedError;
  String get main_image => throw _privateConstructorUsedError;
  String get wait_image => throw _privateConstructorUsedError;
  String get result_image => throw _privateConstructorUsedError;
  String get vote_content => throw _privateConstructorUsedError;
  List<VoteItemModel> get vote_item => throw _privateConstructorUsedError;
  DateTime get created_at => throw _privateConstructorUsedError;
  DateTime get visible_at => throw _privateConstructorUsedError;
  DateTime get stop_at => throw _privateConstructorUsedError;
  DateTime get start_at => throw _privateConstructorUsedError;
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
      String title_ko,
      String title_en,
      String title_ja,
      String title_zh,
      String vote_category,
      String main_image,
      String wait_image,
      String result_image,
      String vote_content,
      List<VoteItemModel> vote_item,
      DateTime created_at,
      DateTime visible_at,
      DateTime stop_at,
      DateTime start_at,
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
    Object? title_ko = null,
    Object? title_en = null,
    Object? title_ja = null,
    Object? title_zh = null,
    Object? vote_category = null,
    Object? main_image = null,
    Object? wait_image = null,
    Object? result_image = null,
    Object? vote_content = null,
    Object? vote_item = null,
    Object? created_at = null,
    Object? visible_at = null,
    Object? stop_at = null,
    Object? start_at = null,
    Object? reward = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title_ko: null == title_ko
          ? _value.title_ko
          : title_ko // ignore: cast_nullable_to_non_nullable
              as String,
      title_en: null == title_en
          ? _value.title_en
          : title_en // ignore: cast_nullable_to_non_nullable
              as String,
      title_ja: null == title_ja
          ? _value.title_ja
          : title_ja // ignore: cast_nullable_to_non_nullable
              as String,
      title_zh: null == title_zh
          ? _value.title_zh
          : title_zh // ignore: cast_nullable_to_non_nullable
              as String,
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
      vote_item: null == vote_item
          ? _value.vote_item
          : vote_item // ignore: cast_nullable_to_non_nullable
              as List<VoteItemModel>,
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
      String title_ko,
      String title_en,
      String title_ja,
      String title_zh,
      String vote_category,
      String main_image,
      String wait_image,
      String result_image,
      String vote_content,
      List<VoteItemModel> vote_item,
      DateTime created_at,
      DateTime visible_at,
      DateTime stop_at,
      DateTime start_at,
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
    Object? title_ko = null,
    Object? title_en = null,
    Object? title_ja = null,
    Object? title_zh = null,
    Object? vote_category = null,
    Object? main_image = null,
    Object? wait_image = null,
    Object? result_image = null,
    Object? vote_content = null,
    Object? vote_item = null,
    Object? created_at = null,
    Object? visible_at = null,
    Object? stop_at = null,
    Object? start_at = null,
    Object? reward = freezed,
  }) {
    return _then(_$VoteModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title_ko: null == title_ko
          ? _value.title_ko
          : title_ko // ignore: cast_nullable_to_non_nullable
              as String,
      title_en: null == title_en
          ? _value.title_en
          : title_en // ignore: cast_nullable_to_non_nullable
              as String,
      title_ja: null == title_ja
          ? _value.title_ja
          : title_ja // ignore: cast_nullable_to_non_nullable
              as String,
      title_zh: null == title_zh
          ? _value.title_zh
          : title_zh // ignore: cast_nullable_to_non_nullable
              as String,
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
      vote_item: null == vote_item
          ? _value._vote_item
          : vote_item // ignore: cast_nullable_to_non_nullable
              as List<VoteItemModel>,
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
      required this.title_ko,
      required this.title_en,
      required this.title_ja,
      required this.title_zh,
      required this.vote_category,
      required this.main_image,
      required this.wait_image,
      required this.result_image,
      required this.vote_content,
      required final List<VoteItemModel> vote_item,
      required this.created_at,
      required this.visible_at,
      required this.stop_at,
      required this.start_at,
      required final List<RewardModel>? reward})
      : _vote_item = vote_item,
        _reward = reward,
        super._();

  factory _$VoteModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteModelImplFromJson(json);

  @override
  final int id;
  @override
  final String title_ko;
  @override
  final String title_en;
  @override
  final String title_ja;
  @override
  final String title_zh;
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
  final List<VoteItemModel> _vote_item;
  @override
  List<VoteItemModel> get vote_item {
    if (_vote_item is EqualUnmodifiableListView) return _vote_item;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_vote_item);
  }

  @override
  final DateTime created_at;
  @override
  final DateTime visible_at;
  @override
  final DateTime stop_at;
  @override
  final DateTime start_at;
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
    return 'VoteModel(id: $id, title_ko: $title_ko, title_en: $title_en, title_ja: $title_ja, title_zh: $title_zh, vote_category: $vote_category, main_image: $main_image, wait_image: $wait_image, result_image: $result_image, vote_content: $vote_content, vote_item: $vote_item, created_at: $created_at, visible_at: $visible_at, stop_at: $stop_at, start_at: $start_at, reward: $reward)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title_ko, title_ko) ||
                other.title_ko == title_ko) &&
            (identical(other.title_en, title_en) ||
                other.title_en == title_en) &&
            (identical(other.title_ja, title_ja) ||
                other.title_ja == title_ja) &&
            (identical(other.title_zh, title_zh) ||
                other.title_zh == title_zh) &&
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
            const DeepCollectionEquality().equals(other._reward, _reward));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title_ko,
      title_en,
      title_ja,
      title_zh,
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
      required final String title_ko,
      required final String title_en,
      required final String title_ja,
      required final String title_zh,
      required final String vote_category,
      required final String main_image,
      required final String wait_image,
      required final String result_image,
      required final String vote_content,
      required final List<VoteItemModel> vote_item,
      required final DateTime created_at,
      required final DateTime visible_at,
      required final DateTime stop_at,
      required final DateTime start_at,
      required final List<RewardModel>? reward}) = _$VoteModelImpl;
  const _VoteModel._() : super._();

  factory _VoteModel.fromJson(Map<String, dynamic> json) =
      _$VoteModelImpl.fromJson;

  @override
  int get id;
  @override
  String get title_ko;
  @override
  String get title_en;
  @override
  String get title_ja;
  @override
  String get title_zh;
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
  List<VoteItemModel> get vote_item;
  @override
  DateTime get created_at;
  @override
  DateTime get visible_at;
  @override
  DateTime get stop_at;
  @override
  DateTime get start_at;
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
  MyStarMemberModel get mystar_member => throw _privateConstructorUsedError;

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
  $Res call(
      {int id, int vote_total, int vote_id, MyStarMemberModel mystar_member});

  $MyStarMemberModelCopyWith<$Res> get mystar_member;
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
    Object? mystar_member = null,
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
      mystar_member: null == mystar_member
          ? _value.mystar_member
          : mystar_member // ignore: cast_nullable_to_non_nullable
              as MyStarMemberModel,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MyStarMemberModelCopyWith<$Res> get mystar_member {
    return $MyStarMemberModelCopyWith<$Res>(_value.mystar_member, (value) {
      return _then(_value.copyWith(mystar_member: value) as $Val);
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
  $Res call(
      {int id, int vote_total, int vote_id, MyStarMemberModel mystar_member});

  @override
  $MyStarMemberModelCopyWith<$Res> get mystar_member;
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
    Object? mystar_member = null,
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
      mystar_member: null == mystar_member
          ? _value.mystar_member
          : mystar_member // ignore: cast_nullable_to_non_nullable
              as MyStarMemberModel,
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
      required this.mystar_member})
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
  final MyStarMemberModel mystar_member;

  @override
  String toString() {
    return 'VoteItemModel(id: $id, vote_total: $vote_total, vote_id: $vote_id, mystar_member: $mystar_member)';
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
            (identical(other.mystar_member, mystar_member) ||
                other.mystar_member == mystar_member));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, vote_total, vote_id, mystar_member);

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
      required final MyStarMemberModel mystar_member}) = _$VoteItemModelImpl;
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
  MyStarMemberModel get mystar_member;
  @override
  @JsonKey(ignore: true)
  _$$VoteItemModelImplCopyWith<_$VoteItemModelImpl> get copyWith =>
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
