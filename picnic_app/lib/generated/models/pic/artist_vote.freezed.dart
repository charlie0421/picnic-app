// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../../../models/pic/artist_vote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArtistVoteModel _$ArtistVoteModelFromJson(Map<String, dynamic> json) {
  return _ArtistVoteModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistVoteModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'title')
  Map<String, dynamic> get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'category')
  String get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist_vote_item')
  List<ArtistVoteItemModel>? get artistVoteItem =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'visible_at')
  DateTime? get visibleAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'stop_at')
  DateTime get stopAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_at')
  DateTime get startAt => throw _privateConstructorUsedError;

  /// Serializes this ArtistVoteModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArtistVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title') Map<String, dynamic> title,
      @JsonKey(name: 'category') String category,
      @JsonKey(name: 'artist_vote_item')
      List<ArtistVoteItemModel>? artistVoteItem,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'visible_at') DateTime? visibleAt,
      @JsonKey(name: 'stop_at') DateTime stopAt,
      @JsonKey(name: 'start_at') DateTime startAt});
}

/// @nodoc
class _$ArtistVoteModelCopyWithImpl<$Res, $Val extends ArtistVoteModel>
    implements $ArtistVoteModelCopyWith<$Res> {
  _$ArtistVoteModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArtistVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? artistVoteItem = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? visibleAt = freezed,
    Object? stopAt = null,
    Object? startAt = null,
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
      artistVoteItem: freezed == artistVoteItem
          ? _value.artistVoteItem
          : artistVoteItem // ignore: cast_nullable_to_non_nullable
              as List<ArtistVoteItemModel>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      visibleAt: freezed == visibleAt
          ? _value.visibleAt
          : visibleAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stopAt: null == stopAt
          ? _value.stopAt
          : stopAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      startAt: null == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title') Map<String, dynamic> title,
      @JsonKey(name: 'category') String category,
      @JsonKey(name: 'artist_vote_item')
      List<ArtistVoteItemModel>? artistVoteItem,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'visible_at') DateTime? visibleAt,
      @JsonKey(name: 'stop_at') DateTime stopAt,
      @JsonKey(name: 'start_at') DateTime startAt});
}

/// @nodoc
class __$$ArtistVoteModelImplCopyWithImpl<$Res>
    extends _$ArtistVoteModelCopyWithImpl<$Res, _$ArtistVoteModelImpl>
    implements _$$ArtistVoteModelImplCopyWith<$Res> {
  __$$ArtistVoteModelImplCopyWithImpl(
      _$ArtistVoteModelImpl _value, $Res Function(_$ArtistVoteModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArtistVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? artistVoteItem = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? visibleAt = freezed,
    Object? stopAt = null,
    Object? startAt = null,
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
      artistVoteItem: freezed == artistVoteItem
          ? _value._artistVoteItem
          : artistVoteItem // ignore: cast_nullable_to_non_nullable
              as List<ArtistVoteItemModel>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      visibleAt: freezed == visibleAt
          ? _value.visibleAt
          : visibleAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stopAt: null == stopAt
          ? _value.stopAt
          : stopAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      startAt: null == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistVoteModelImpl extends _ArtistVoteModel {
  const _$ArtistVoteModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'title') required final Map<String, dynamic> title,
      @JsonKey(name: 'category') required this.category,
      @JsonKey(name: 'artist_vote_item')
      required final List<ArtistVoteItemModel>? artistVoteItem,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'visible_at') required this.visibleAt,
      @JsonKey(name: 'stop_at') required this.stopAt,
      @JsonKey(name: 'start_at') required this.startAt})
      : _title = title,
        _artistVoteItem = artistVoteItem,
        super._();

  factory _$ArtistVoteModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistVoteModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  final Map<String, dynamic> _title;
  @override
  @JsonKey(name: 'title')
  Map<String, dynamic> get title {
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_title);
  }

  @override
  @JsonKey(name: 'category')
  final String category;
  final List<ArtistVoteItemModel>? _artistVoteItem;
  @override
  @JsonKey(name: 'artist_vote_item')
  List<ArtistVoteItemModel>? get artistVoteItem {
    final value = _artistVoteItem;
    if (value == null) return null;
    if (_artistVoteItem is EqualUnmodifiableListView) return _artistVoteItem;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'visible_at')
  final DateTime? visibleAt;
  @override
  @JsonKey(name: 'stop_at')
  final DateTime stopAt;
  @override
  @JsonKey(name: 'start_at')
  final DateTime startAt;

  @override
  String toString() {
    return 'ArtistVoteModel(id: $id, title: $title, category: $category, artistVoteItem: $artistVoteItem, createdAt: $createdAt, updatedAt: $updatedAt, visibleAt: $visibleAt, stopAt: $stopAt, startAt: $startAt)';
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
                .equals(other._artistVoteItem, _artistVoteItem) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.visibleAt, visibleAt) ||
                other.visibleAt == visibleAt) &&
            (identical(other.stopAt, stopAt) || other.stopAt == stopAt) &&
            (identical(other.startAt, startAt) || other.startAt == startAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_title),
      category,
      const DeepCollectionEquality().hash(_artistVoteItem),
      createdAt,
      updatedAt,
      visibleAt,
      stopAt,
      startAt);

  /// Create a copy of ArtistVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'title') required final Map<String, dynamic> title,
          @JsonKey(name: 'category') required final String category,
          @JsonKey(name: 'artist_vote_item')
          required final List<ArtistVoteItemModel>? artistVoteItem,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime? updatedAt,
          @JsonKey(name: 'visible_at') required final DateTime? visibleAt,
          @JsonKey(name: 'stop_at') required final DateTime stopAt,
          @JsonKey(name: 'start_at') required final DateTime startAt}) =
      _$ArtistVoteModelImpl;
  const _ArtistVoteModel._() : super._();

  factory _ArtistVoteModel.fromJson(Map<String, dynamic> json) =
      _$ArtistVoteModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'title')
  Map<String, dynamic> get title;
  @override
  @JsonKey(name: 'category')
  String get category;
  @override
  @JsonKey(name: 'artist_vote_item')
  List<ArtistVoteItemModel>? get artistVoteItem;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'visible_at')
  DateTime? get visibleAt;
  @override
  @JsonKey(name: 'stop_at')
  DateTime get stopAt;
  @override
  @JsonKey(name: 'start_at')
  DateTime get startAt;

  /// Create a copy of ArtistVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistVoteModelImplCopyWith<_$ArtistVoteModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistVoteItemModel _$ArtistVoteItemModelFromJson(Map<String, dynamic> json) {
  return _ArtistVoteItemModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistVoteItemModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_total')
  int get voteTotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist_vote_id')
  int get artistVoteId => throw _privateConstructorUsedError;
  @JsonKey(name: 'title')
  Map<String, dynamic> get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'description')
  Map<String, dynamic> get description => throw _privateConstructorUsedError;

  /// Serializes this ArtistVoteItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArtistVoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'vote_total') int voteTotal,
      @JsonKey(name: 'artist_vote_id') int artistVoteId,
      @JsonKey(name: 'title') Map<String, dynamic> title,
      @JsonKey(name: 'description') Map<String, dynamic> description});
}

/// @nodoc
class _$ArtistVoteItemModelCopyWithImpl<$Res, $Val extends ArtistVoteItemModel>
    implements $ArtistVoteItemModelCopyWith<$Res> {
  _$ArtistVoteItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArtistVoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteTotal = null,
    Object? artistVoteId = null,
    Object? title = null,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      voteTotal: null == voteTotal
          ? _value.voteTotal
          : voteTotal // ignore: cast_nullable_to_non_nullable
              as int,
      artistVoteId: null == artistVoteId
          ? _value.artistVoteId
          : artistVoteId // ignore: cast_nullable_to_non_nullable
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'vote_total') int voteTotal,
      @JsonKey(name: 'artist_vote_id') int artistVoteId,
      @JsonKey(name: 'title') Map<String, dynamic> title,
      @JsonKey(name: 'description') Map<String, dynamic> description});
}

/// @nodoc
class __$$ArtistVoteItemModelImplCopyWithImpl<$Res>
    extends _$ArtistVoteItemModelCopyWithImpl<$Res, _$ArtistVoteItemModelImpl>
    implements _$$ArtistVoteItemModelImplCopyWith<$Res> {
  __$$ArtistVoteItemModelImplCopyWithImpl(_$ArtistVoteItemModelImpl _value,
      $Res Function(_$ArtistVoteItemModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArtistVoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteTotal = null,
    Object? artistVoteId = null,
    Object? title = null,
    Object? description = null,
  }) {
    return _then(_$ArtistVoteItemModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      voteTotal: null == voteTotal
          ? _value.voteTotal
          : voteTotal // ignore: cast_nullable_to_non_nullable
              as int,
      artistVoteId: null == artistVoteId
          ? _value.artistVoteId
          : artistVoteId // ignore: cast_nullable_to_non_nullable
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
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'vote_total') required this.voteTotal,
      @JsonKey(name: 'artist_vote_id') required this.artistVoteId,
      @JsonKey(name: 'title') required final Map<String, dynamic> title,
      @JsonKey(name: 'description')
      required final Map<String, dynamic> description})
      : _title = title,
        _description = description,
        super._();

  factory _$ArtistVoteItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistVoteItemModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'vote_total')
  final int voteTotal;
  @override
  @JsonKey(name: 'artist_vote_id')
  final int artistVoteId;
  final Map<String, dynamic> _title;
  @override
  @JsonKey(name: 'title')
  Map<String, dynamic> get title {
    if (_title is EqualUnmodifiableMapView) return _title;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_title);
  }

  final Map<String, dynamic> _description;
  @override
  @JsonKey(name: 'description')
  Map<String, dynamic> get description {
    if (_description is EqualUnmodifiableMapView) return _description;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_description);
  }

  @override
  String toString() {
    return 'ArtistVoteItemModel(id: $id, voteTotal: $voteTotal, artistVoteId: $artistVoteId, title: $title, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistVoteItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.voteTotal, voteTotal) ||
                other.voteTotal == voteTotal) &&
            (identical(other.artistVoteId, artistVoteId) ||
                other.artistVoteId == artistVoteId) &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            const DeepCollectionEquality()
                .equals(other._description, _description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      voteTotal,
      artistVoteId,
      const DeepCollectionEquality().hash(_title),
      const DeepCollectionEquality().hash(_description));

  /// Create a copy of ArtistVoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'vote_total') required final int voteTotal,
          @JsonKey(name: 'artist_vote_id') required final int artistVoteId,
          @JsonKey(name: 'title') required final Map<String, dynamic> title,
          @JsonKey(name: 'description')
          required final Map<String, dynamic> description}) =
      _$ArtistVoteItemModelImpl;
  const _ArtistVoteItemModel._() : super._();

  factory _ArtistVoteItemModel.fromJson(Map<String, dynamic> json) =
      _$ArtistVoteItemModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'vote_total')
  int get voteTotal;
  @override
  @JsonKey(name: 'artist_vote_id')
  int get artistVoteId;
  @override
  @JsonKey(name: 'title')
  Map<String, dynamic> get title;
  @override
  @JsonKey(name: 'description')
  Map<String, dynamic> get description;

  /// Create a copy of ArtistVoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistVoteItemModelImplCopyWith<_$ArtistVoteItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MyStarMemberModel _$MyStarMemberModelFromJson(Map<String, dynamic> json) {
  return _MyStarMemberModel.fromJson(json);
}

/// @nodoc
mixin _$MyStarMemberModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_ko')
  String get nameKo => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_en')
  String get nameEn => throw _privateConstructorUsedError;
  @JsonKey(name: 'gender')
  String get gender => throw _privateConstructorUsedError;
  @JsonKey(name: 'image')
  String? get image => throw _privateConstructorUsedError;
  @JsonKey(name: 'mystar_group')
  MyStarGroupModel? get mystarGroup => throw _privateConstructorUsedError;

  /// Serializes this MyStarMemberModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MyStarMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name_ko') String nameKo,
      @JsonKey(name: 'name_en') String nameEn,
      @JsonKey(name: 'gender') String gender,
      @JsonKey(name: 'image') String? image,
      @JsonKey(name: 'mystar_group') MyStarGroupModel? mystarGroup});

  $MyStarGroupModelCopyWith<$Res>? get mystarGroup;
}

/// @nodoc
class _$MyStarMemberModelCopyWithImpl<$Res, $Val extends MyStarMemberModel>
    implements $MyStarMemberModelCopyWith<$Res> {
  _$MyStarMemberModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyStarMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameKo = null,
    Object? nameEn = null,
    Object? gender = null,
    Object? image = freezed,
    Object? mystarGroup = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nameKo: null == nameKo
          ? _value.nameKo
          : nameKo // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      mystarGroup: freezed == mystarGroup
          ? _value.mystarGroup
          : mystarGroup // ignore: cast_nullable_to_non_nullable
              as MyStarGroupModel?,
    ) as $Val);
  }

  /// Create a copy of MyStarMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MyStarGroupModelCopyWith<$Res>? get mystarGroup {
    if (_value.mystarGroup == null) {
      return null;
    }

    return $MyStarGroupModelCopyWith<$Res>(_value.mystarGroup!, (value) {
      return _then(_value.copyWith(mystarGroup: value) as $Val);
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name_ko') String nameKo,
      @JsonKey(name: 'name_en') String nameEn,
      @JsonKey(name: 'gender') String gender,
      @JsonKey(name: 'image') String? image,
      @JsonKey(name: 'mystar_group') MyStarGroupModel? mystarGroup});

  @override
  $MyStarGroupModelCopyWith<$Res>? get mystarGroup;
}

/// @nodoc
class __$$MyStarMemberModelImplCopyWithImpl<$Res>
    extends _$MyStarMemberModelCopyWithImpl<$Res, _$MyStarMemberModelImpl>
    implements _$$MyStarMemberModelImplCopyWith<$Res> {
  __$$MyStarMemberModelImplCopyWithImpl(_$MyStarMemberModelImpl _value,
      $Res Function(_$MyStarMemberModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of MyStarMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameKo = null,
    Object? nameEn = null,
    Object? gender = null,
    Object? image = freezed,
    Object? mystarGroup = freezed,
  }) {
    return _then(_$MyStarMemberModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nameKo: null == nameKo
          ? _value.nameKo
          : nameKo // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      mystarGroup: freezed == mystarGroup
          ? _value.mystarGroup
          : mystarGroup // ignore: cast_nullable_to_non_nullable
              as MyStarGroupModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MyStarMemberModelImpl extends _MyStarMemberModel {
  const _$MyStarMemberModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'name_ko') required this.nameKo,
      @JsonKey(name: 'name_en') required this.nameEn,
      @JsonKey(name: 'gender') required this.gender,
      @JsonKey(name: 'image') required this.image,
      @JsonKey(name: 'mystar_group') this.mystarGroup})
      : super._();

  factory _$MyStarMemberModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyStarMemberModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'name_ko')
  final String nameKo;
  @override
  @JsonKey(name: 'name_en')
  final String nameEn;
  @override
  @JsonKey(name: 'gender')
  final String gender;
  @override
  @JsonKey(name: 'image')
  final String? image;
  @override
  @JsonKey(name: 'mystar_group')
  final MyStarGroupModel? mystarGroup;

  @override
  String toString() {
    return 'MyStarMemberModel(id: $id, nameKo: $nameKo, nameEn: $nameEn, gender: $gender, image: $image, mystarGroup: $mystarGroup)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyStarMemberModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameKo, nameKo) || other.nameKo == nameKo) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.mystarGroup, mystarGroup) ||
                other.mystarGroup == mystarGroup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, nameKo, nameEn, gender, image, mystarGroup);

  /// Create a copy of MyStarMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'name_ko') required final String nameKo,
          @JsonKey(name: 'name_en') required final String nameEn,
          @JsonKey(name: 'gender') required final String gender,
          @JsonKey(name: 'image') required final String? image,
          @JsonKey(name: 'mystar_group') final MyStarGroupModel? mystarGroup}) =
      _$MyStarMemberModelImpl;
  const _MyStarMemberModel._() : super._();

  factory _MyStarMemberModel.fromJson(Map<String, dynamic> json) =
      _$MyStarMemberModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'name_ko')
  String get nameKo;
  @override
  @JsonKey(name: 'name_en')
  String get nameEn;
  @override
  @JsonKey(name: 'gender')
  String get gender;
  @override
  @JsonKey(name: 'image')
  String? get image;
  @override
  @JsonKey(name: 'mystar_group')
  MyStarGroupModel? get mystarGroup;

  /// Create a copy of MyStarMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyStarMemberModelImplCopyWith<_$MyStarMemberModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MyStarGroupModel _$MyStarGroupModelFromJson(Map<String, dynamic> json) {
  return _MyStarGroupModel.fromJson(json);
}

/// @nodoc
mixin _$MyStarGroupModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_ko')
  String get nameKo => throw _privateConstructorUsedError;
  @JsonKey(name: 'name_en')
  String get nameEn => throw _privateConstructorUsedError;
  String? get image => throw _privateConstructorUsedError;

  /// Serializes this MyStarGroupModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MyStarGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MyStarGroupModelCopyWith<MyStarGroupModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyStarGroupModelCopyWith<$Res> {
  factory $MyStarGroupModelCopyWith(
          MyStarGroupModel value, $Res Function(MyStarGroupModel) then) =
      _$MyStarGroupModelCopyWithImpl<$Res, MyStarGroupModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name_ko') String nameKo,
      @JsonKey(name: 'name_en') String nameEn,
      String? image});
}

/// @nodoc
class _$MyStarGroupModelCopyWithImpl<$Res, $Val extends MyStarGroupModel>
    implements $MyStarGroupModelCopyWith<$Res> {
  _$MyStarGroupModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MyStarGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameKo = null,
    Object? nameEn = null,
    Object? image = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nameKo: null == nameKo
          ? _value.nameKo
          : nameKo // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
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
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name_ko') String nameKo,
      @JsonKey(name: 'name_en') String nameEn,
      String? image});
}

/// @nodoc
class __$$MyStarGroupModelImplCopyWithImpl<$Res>
    extends _$MyStarGroupModelCopyWithImpl<$Res, _$MyStarGroupModelImpl>
    implements _$$MyStarGroupModelImplCopyWith<$Res> {
  __$$MyStarGroupModelImplCopyWithImpl(_$MyStarGroupModelImpl _value,
      $Res Function(_$MyStarGroupModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of MyStarGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameKo = null,
    Object? nameEn = null,
    Object? image = freezed,
  }) {
    return _then(_$MyStarGroupModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nameKo: null == nameKo
          ? _value.nameKo
          : nameKo // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
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
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'name_ko') required this.nameKo,
      @JsonKey(name: 'name_en') required this.nameEn,
      this.image})
      : super._();

  factory _$MyStarGroupModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MyStarGroupModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'name_ko')
  final String nameKo;
  @override
  @JsonKey(name: 'name_en')
  final String nameEn;
  @override
  final String? image;

  @override
  String toString() {
    return 'MyStarGroupModel(id: $id, nameKo: $nameKo, nameEn: $nameEn, image: $image)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyStarGroupModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameKo, nameKo) || other.nameKo == nameKo) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.image, image) || other.image == image));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, nameKo, nameEn, image);

  /// Create a copy of MyStarGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') required final int id,
      @JsonKey(name: 'name_ko') required final String nameKo,
      @JsonKey(name: 'name_en') required final String nameEn,
      final String? image}) = _$MyStarGroupModelImpl;
  const _MyStarGroupModel._() : super._();

  factory _MyStarGroupModel.fromJson(Map<String, dynamic> json) =
      _$MyStarGroupModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'name_ko')
  String get nameKo;
  @override
  @JsonKey(name: 'name_en')
  String get nameEn;
  @override
  String? get image;

  /// Create a copy of MyStarGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MyStarGroupModelImplCopyWith<_$MyStarGroupModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistMemberModel _$ArtistMemberModelFromJson(Map<String, dynamic> json) {
  return _ArtistMemberModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistMemberModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  Map<String, String> get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'gender')
  String get gender => throw _privateConstructorUsedError;
  @JsonKey(name: 'image')
  String? get image => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist_group')
  ArtistGroupModel? get artistGroup => throw _privateConstructorUsedError;

  /// Serializes this ArtistMemberModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArtistMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArtistMemberModelCopyWith<ArtistMemberModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistMemberModelCopyWith<$Res> {
  factory $ArtistMemberModelCopyWith(
          ArtistMemberModel value, $Res Function(ArtistMemberModel) then) =
      _$ArtistMemberModelCopyWithImpl<$Res, ArtistMemberModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name') Map<String, String> name,
      @JsonKey(name: 'gender') String gender,
      @JsonKey(name: 'image') String? image,
      @JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup});

  $ArtistGroupModelCopyWith<$Res>? get artistGroup;
}

/// @nodoc
class _$ArtistMemberModelCopyWithImpl<$Res, $Val extends ArtistMemberModel>
    implements $ArtistMemberModelCopyWith<$Res> {
  _$ArtistMemberModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArtistMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? gender = null,
    Object? image = freezed,
    Object? artistGroup = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      artistGroup: freezed == artistGroup
          ? _value.artistGroup
          : artistGroup // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel?,
    ) as $Val);
  }

  /// Create a copy of ArtistMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistGroupModelCopyWith<$Res>? get artistGroup {
    if (_value.artistGroup == null) {
      return null;
    }

    return $ArtistGroupModelCopyWith<$Res>(_value.artistGroup!, (value) {
      return _then(_value.copyWith(artistGroup: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ArtistMemberModelImplCopyWith<$Res>
    implements $ArtistMemberModelCopyWith<$Res> {
  factory _$$ArtistMemberModelImplCopyWith(_$ArtistMemberModelImpl value,
          $Res Function(_$ArtistMemberModelImpl) then) =
      __$$ArtistMemberModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name') Map<String, String> name,
      @JsonKey(name: 'gender') String gender,
      @JsonKey(name: 'image') String? image,
      @JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup});

  @override
  $ArtistGroupModelCopyWith<$Res>? get artistGroup;
}

/// @nodoc
class __$$ArtistMemberModelImplCopyWithImpl<$Res>
    extends _$ArtistMemberModelCopyWithImpl<$Res, _$ArtistMemberModelImpl>
    implements _$$ArtistMemberModelImplCopyWith<$Res> {
  __$$ArtistMemberModelImplCopyWithImpl(_$ArtistMemberModelImpl _value,
      $Res Function(_$ArtistMemberModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArtistMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? gender = null,
    Object? image = freezed,
    Object? artistGroup = freezed,
  }) {
    return _then(_$ArtistMemberModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value._name
          : name // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String,
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
      artistGroup: freezed == artistGroup
          ? _value.artistGroup
          : artistGroup // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistMemberModelImpl extends _ArtistMemberModel {
  const _$ArtistMemberModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'name') required final Map<String, String> name,
      @JsonKey(name: 'gender') required this.gender,
      @JsonKey(name: 'image') required this.image,
      @JsonKey(name: 'artist_group') this.artistGroup})
      : _name = name,
        super._();

  factory _$ArtistMemberModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistMemberModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  final Map<String, String> _name;
  @override
  @JsonKey(name: 'name')
  Map<String, String> get name {
    if (_name is EqualUnmodifiableMapView) return _name;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_name);
  }

  @override
  @JsonKey(name: 'gender')
  final String gender;
  @override
  @JsonKey(name: 'image')
  final String? image;
  @override
  @JsonKey(name: 'artist_group')
  final ArtistGroupModel? artistGroup;

  @override
  String toString() {
    return 'ArtistMemberModel(id: $id, name: $name, gender: $gender, image: $image, artistGroup: $artistGroup)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistMemberModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._name, _name) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.artistGroup, artistGroup) ||
                other.artistGroup == artistGroup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id,
      const DeepCollectionEquality().hash(_name), gender, image, artistGroup);

  /// Create a copy of ArtistMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistMemberModelImplCopyWith<_$ArtistMemberModelImpl> get copyWith =>
      __$$ArtistMemberModelImplCopyWithImpl<_$ArtistMemberModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistMemberModelImplToJson(
      this,
    );
  }
}

abstract class _ArtistMemberModel extends ArtistMemberModel {
  const factory _ArtistMemberModel(
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'name') required final Map<String, String> name,
          @JsonKey(name: 'gender') required final String gender,
          @JsonKey(name: 'image') required final String? image,
          @JsonKey(name: 'artist_group') final ArtistGroupModel? artistGroup}) =
      _$ArtistMemberModelImpl;
  const _ArtistMemberModel._() : super._();

  factory _ArtistMemberModel.fromJson(Map<String, dynamic> json) =
      _$ArtistMemberModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'name')
  Map<String, String> get name;
  @override
  @JsonKey(name: 'gender')
  String get gender;
  @override
  @JsonKey(name: 'image')
  String? get image;
  @override
  @JsonKey(name: 'artist_group')
  ArtistGroupModel? get artistGroup;

  /// Create a copy of ArtistMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistMemberModelImplCopyWith<_$ArtistMemberModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ArtistGroupModel _$ArtistGroupModelFromJson(Map<String, dynamic> json) {
  return _ArtistGroupModel.fromJson(json);
}

/// @nodoc
mixin _$ArtistGroupModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  Map<String, dynamic> get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'image')
  String? get image => throw _privateConstructorUsedError;

  /// Serializes this ArtistGroupModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArtistGroupModelCopyWith<ArtistGroupModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistGroupModelCopyWith<$Res> {
  factory $ArtistGroupModelCopyWith(
          ArtistGroupModel value, $Res Function(ArtistGroupModel) then) =
      _$ArtistGroupModelCopyWithImpl<$Res, ArtistGroupModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name') Map<String, dynamic> name,
      @JsonKey(name: 'image') String? image});
}

/// @nodoc
class _$ArtistGroupModelCopyWithImpl<$Res, $Val extends ArtistGroupModel>
    implements $ArtistGroupModelCopyWith<$Res> {
  _$ArtistGroupModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? image = freezed,
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
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
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
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'name') Map<String, dynamic> name,
      @JsonKey(name: 'image') String? image});
}

/// @nodoc
class __$$ArtistGroupModelImplCopyWithImpl<$Res>
    extends _$ArtistGroupModelCopyWithImpl<$Res, _$ArtistGroupModelImpl>
    implements _$$ArtistGroupModelImplCopyWith<$Res> {
  __$$ArtistGroupModelImplCopyWithImpl(_$ArtistGroupModelImpl _value,
      $Res Function(_$ArtistGroupModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? image = freezed,
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
      image: freezed == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistGroupModelImpl extends _ArtistGroupModel {
  const _$ArtistGroupModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'name') required final Map<String, dynamic> name,
      @JsonKey(name: 'image') this.image})
      : _name = name,
        super._();

  factory _$ArtistGroupModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistGroupModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  final Map<String, dynamic> _name;
  @override
  @JsonKey(name: 'name')
  Map<String, dynamic> get name {
    if (_name is EqualUnmodifiableMapView) return _name;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_name);
  }

  @override
  @JsonKey(name: 'image')
  final String? image;

  @override
  String toString() {
    return 'ArtistGroupModel(id: $id, name: $name, image: $image)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistGroupModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._name, _name) &&
            (identical(other.image, image) || other.image == image));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, const DeepCollectionEquality().hash(_name), image);

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') required final int id,
      @JsonKey(name: 'name') required final Map<String, dynamic> name,
      @JsonKey(name: 'image') final String? image}) = _$ArtistGroupModelImpl;
  const _ArtistGroupModel._() : super._();

  factory _ArtistGroupModel.fromJson(Map<String, dynamic> json) =
      _$ArtistGroupModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'name')
  Map<String, dynamic> get name;
  @override
  @JsonKey(name: 'image')
  String? get image;

  /// Create a copy of ArtistGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistGroupModelImplCopyWith<_$ArtistGroupModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
