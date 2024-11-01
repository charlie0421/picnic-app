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

VoteModel _$VoteModelFromJson(Map<String, dynamic> json) {
  return _VoteModel.fromJson(json);
}

/// @nodoc
mixin _$VoteModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'title')
  Map<String, dynamic> get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_category')
  String? get voteCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'main_image')
  String? get mainImage => throw _privateConstructorUsedError;
  @JsonKey(name: 'wait_image')
  String? get waitImage => throw _privateConstructorUsedError;
  @JsonKey(name: 'result_image')
  String? get resultImage => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_content')
  String? get voteContent => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_item')
  List<VoteItemModel>? get voteItem => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'visible_at')
  DateTime? get visibleAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'stop_at')
  DateTime? get stopAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_at')
  DateTime? get startAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_ended')
  bool? get isEnded => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_upcoming')
  bool? get isUpcoming => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward')
  List<RewardModel>? get reward => throw _privateConstructorUsedError;

  /// Serializes this VoteModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoteModelCopyWith<VoteModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteModelCopyWith<$Res> {
  factory $VoteModelCopyWith(VoteModel value, $Res Function(VoteModel) then) =
      _$VoteModelCopyWithImpl<$Res, VoteModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title') Map<String, dynamic> title,
      @JsonKey(name: 'vote_category') String? voteCategory,
      @JsonKey(name: 'main_image') String? mainImage,
      @JsonKey(name: 'wait_image') String? waitImage,
      @JsonKey(name: 'result_image') String? resultImage,
      @JsonKey(name: 'vote_content') String? voteContent,
      @JsonKey(name: 'vote_item') List<VoteItemModel>? voteItem,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'visible_at') DateTime? visibleAt,
      @JsonKey(name: 'stop_at') DateTime? stopAt,
      @JsonKey(name: 'start_at') DateTime? startAt,
      @JsonKey(name: 'is_ended') bool? isEnded,
      @JsonKey(name: 'is_upcoming') bool? isUpcoming,
      @JsonKey(name: 'reward') List<RewardModel>? reward});
}

/// @nodoc
class _$VoteModelCopyWithImpl<$Res, $Val extends VoteModel>
    implements $VoteModelCopyWith<$Res> {
  _$VoteModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? voteCategory = freezed,
    Object? mainImage = freezed,
    Object? waitImage = freezed,
    Object? resultImage = freezed,
    Object? voteContent = freezed,
    Object? voteItem = freezed,
    Object? createdAt = freezed,
    Object? visibleAt = freezed,
    Object? stopAt = freezed,
    Object? startAt = freezed,
    Object? isEnded = freezed,
    Object? isUpcoming = freezed,
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
      voteCategory: freezed == voteCategory
          ? _value.voteCategory
          : voteCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      mainImage: freezed == mainImage
          ? _value.mainImage
          : mainImage // ignore: cast_nullable_to_non_nullable
              as String?,
      waitImage: freezed == waitImage
          ? _value.waitImage
          : waitImage // ignore: cast_nullable_to_non_nullable
              as String?,
      resultImage: freezed == resultImage
          ? _value.resultImage
          : resultImage // ignore: cast_nullable_to_non_nullable
              as String?,
      voteContent: freezed == voteContent
          ? _value.voteContent
          : voteContent // ignore: cast_nullable_to_non_nullable
              as String?,
      voteItem: freezed == voteItem
          ? _value.voteItem
          : voteItem // ignore: cast_nullable_to_non_nullable
              as List<VoteItemModel>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      visibleAt: freezed == visibleAt
          ? _value.visibleAt
          : visibleAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stopAt: freezed == stopAt
          ? _value.stopAt
          : stopAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startAt: freezed == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isEnded: freezed == isEnded
          ? _value.isEnded
          : isEnded // ignore: cast_nullable_to_non_nullable
              as bool?,
      isUpcoming: freezed == isUpcoming
          ? _value.isUpcoming
          : isUpcoming // ignore: cast_nullable_to_non_nullable
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'title') Map<String, dynamic> title,
      @JsonKey(name: 'vote_category') String? voteCategory,
      @JsonKey(name: 'main_image') String? mainImage,
      @JsonKey(name: 'wait_image') String? waitImage,
      @JsonKey(name: 'result_image') String? resultImage,
      @JsonKey(name: 'vote_content') String? voteContent,
      @JsonKey(name: 'vote_item') List<VoteItemModel>? voteItem,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'visible_at') DateTime? visibleAt,
      @JsonKey(name: 'stop_at') DateTime? stopAt,
      @JsonKey(name: 'start_at') DateTime? startAt,
      @JsonKey(name: 'is_ended') bool? isEnded,
      @JsonKey(name: 'is_upcoming') bool? isUpcoming,
      @JsonKey(name: 'reward') List<RewardModel>? reward});
}

/// @nodoc
class __$$VoteModelImplCopyWithImpl<$Res>
    extends _$VoteModelCopyWithImpl<$Res, _$VoteModelImpl>
    implements _$$VoteModelImplCopyWith<$Res> {
  __$$VoteModelImplCopyWithImpl(
      _$VoteModelImpl _value, $Res Function(_$VoteModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? voteCategory = freezed,
    Object? mainImage = freezed,
    Object? waitImage = freezed,
    Object? resultImage = freezed,
    Object? voteContent = freezed,
    Object? voteItem = freezed,
    Object? createdAt = freezed,
    Object? visibleAt = freezed,
    Object? stopAt = freezed,
    Object? startAt = freezed,
    Object? isEnded = freezed,
    Object? isUpcoming = freezed,
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
      voteCategory: freezed == voteCategory
          ? _value.voteCategory
          : voteCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      mainImage: freezed == mainImage
          ? _value.mainImage
          : mainImage // ignore: cast_nullable_to_non_nullable
              as String?,
      waitImage: freezed == waitImage
          ? _value.waitImage
          : waitImage // ignore: cast_nullable_to_non_nullable
              as String?,
      resultImage: freezed == resultImage
          ? _value.resultImage
          : resultImage // ignore: cast_nullable_to_non_nullable
              as String?,
      voteContent: freezed == voteContent
          ? _value.voteContent
          : voteContent // ignore: cast_nullable_to_non_nullable
              as String?,
      voteItem: freezed == voteItem
          ? _value._voteItem
          : voteItem // ignore: cast_nullable_to_non_nullable
              as List<VoteItemModel>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      visibleAt: freezed == visibleAt
          ? _value.visibleAt
          : visibleAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      stopAt: freezed == stopAt
          ? _value.stopAt
          : stopAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startAt: freezed == startAt
          ? _value.startAt
          : startAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isEnded: freezed == isEnded
          ? _value.isEnded
          : isEnded // ignore: cast_nullable_to_non_nullable
              as bool?,
      isUpcoming: freezed == isUpcoming
          ? _value.isUpcoming
          : isUpcoming // ignore: cast_nullable_to_non_nullable
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
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'title') required final Map<String, dynamic> title,
      @JsonKey(name: 'vote_category') required this.voteCategory,
      @JsonKey(name: 'main_image') required this.mainImage,
      @JsonKey(name: 'wait_image') required this.waitImage,
      @JsonKey(name: 'result_image') required this.resultImage,
      @JsonKey(name: 'vote_content') required this.voteContent,
      @JsonKey(name: 'vote_item') required final List<VoteItemModel>? voteItem,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'visible_at') required this.visibleAt,
      @JsonKey(name: 'stop_at') required this.stopAt,
      @JsonKey(name: 'start_at') required this.startAt,
      @JsonKey(name: 'is_ended') required this.isEnded,
      @JsonKey(name: 'is_upcoming') required this.isUpcoming,
      @JsonKey(name: 'reward') required final List<RewardModel>? reward})
      : _title = title,
        _voteItem = voteItem,
        _reward = reward,
        super._();

  factory _$VoteModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteModelImplFromJson(json);

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
  @JsonKey(name: 'vote_category')
  final String? voteCategory;
  @override
  @JsonKey(name: 'main_image')
  final String? mainImage;
  @override
  @JsonKey(name: 'wait_image')
  final String? waitImage;
  @override
  @JsonKey(name: 'result_image')
  final String? resultImage;
  @override
  @JsonKey(name: 'vote_content')
  final String? voteContent;
  final List<VoteItemModel>? _voteItem;
  @override
  @JsonKey(name: 'vote_item')
  List<VoteItemModel>? get voteItem {
    final value = _voteItem;
    if (value == null) return null;
    if (_voteItem is EqualUnmodifiableListView) return _voteItem;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'visible_at')
  final DateTime? visibleAt;
  @override
  @JsonKey(name: 'stop_at')
  final DateTime? stopAt;
  @override
  @JsonKey(name: 'start_at')
  final DateTime? startAt;
  @override
  @JsonKey(name: 'is_ended')
  final bool? isEnded;
  @override
  @JsonKey(name: 'is_upcoming')
  final bool? isUpcoming;
  final List<RewardModel>? _reward;
  @override
  @JsonKey(name: 'reward')
  List<RewardModel>? get reward {
    final value = _reward;
    if (value == null) return null;
    if (_reward is EqualUnmodifiableListView) return _reward;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'VoteModel(id: $id, title: $title, voteCategory: $voteCategory, mainImage: $mainImage, waitImage: $waitImage, resultImage: $resultImage, voteContent: $voteContent, voteItem: $voteItem, createdAt: $createdAt, visibleAt: $visibleAt, stopAt: $stopAt, startAt: $startAt, isEnded: $isEnded, isUpcoming: $isUpcoming, reward: $reward)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._title, _title) &&
            (identical(other.voteCategory, voteCategory) ||
                other.voteCategory == voteCategory) &&
            (identical(other.mainImage, mainImage) ||
                other.mainImage == mainImage) &&
            (identical(other.waitImage, waitImage) ||
                other.waitImage == waitImage) &&
            (identical(other.resultImage, resultImage) ||
                other.resultImage == resultImage) &&
            (identical(other.voteContent, voteContent) ||
                other.voteContent == voteContent) &&
            const DeepCollectionEquality().equals(other._voteItem, _voteItem) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.visibleAt, visibleAt) ||
                other.visibleAt == visibleAt) &&
            (identical(other.stopAt, stopAt) || other.stopAt == stopAt) &&
            (identical(other.startAt, startAt) || other.startAt == startAt) &&
            (identical(other.isEnded, isEnded) || other.isEnded == isEnded) &&
            (identical(other.isUpcoming, isUpcoming) ||
                other.isUpcoming == isUpcoming) &&
            const DeepCollectionEquality().equals(other._reward, _reward));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_title),
      voteCategory,
      mainImage,
      waitImage,
      resultImage,
      voteContent,
      const DeepCollectionEquality().hash(_voteItem),
      createdAt,
      visibleAt,
      stopAt,
      startAt,
      isEnded,
      isUpcoming,
      const DeepCollectionEquality().hash(_reward));

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') required final int id,
      @JsonKey(name: 'title') required final Map<String, dynamic> title,
      @JsonKey(name: 'vote_category') required final String? voteCategory,
      @JsonKey(name: 'main_image') required final String? mainImage,
      @JsonKey(name: 'wait_image') required final String? waitImage,
      @JsonKey(name: 'result_image') required final String? resultImage,
      @JsonKey(name: 'vote_content') required final String? voteContent,
      @JsonKey(name: 'vote_item') required final List<VoteItemModel>? voteItem,
      @JsonKey(name: 'created_at') required final DateTime? createdAt,
      @JsonKey(name: 'visible_at') required final DateTime? visibleAt,
      @JsonKey(name: 'stop_at') required final DateTime? stopAt,
      @JsonKey(name: 'start_at') required final DateTime? startAt,
      @JsonKey(name: 'is_ended') required final bool? isEnded,
      @JsonKey(name: 'is_upcoming') required final bool? isUpcoming,
      @JsonKey(name: 'reward')
      required final List<RewardModel>? reward}) = _$VoteModelImpl;
  const _VoteModel._() : super._();

  factory _VoteModel.fromJson(Map<String, dynamic> json) =
      _$VoteModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'title')
  Map<String, dynamic> get title;
  @override
  @JsonKey(name: 'vote_category')
  String? get voteCategory;
  @override
  @JsonKey(name: 'main_image')
  String? get mainImage;
  @override
  @JsonKey(name: 'wait_image')
  String? get waitImage;
  @override
  @JsonKey(name: 'result_image')
  String? get resultImage;
  @override
  @JsonKey(name: 'vote_content')
  String? get voteContent;
  @override
  @JsonKey(name: 'vote_item')
  List<VoteItemModel>? get voteItem;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'visible_at')
  DateTime? get visibleAt;
  @override
  @JsonKey(name: 'stop_at')
  DateTime? get stopAt;
  @override
  @JsonKey(name: 'start_at')
  DateTime? get startAt;
  @override
  @JsonKey(name: 'is_ended')
  bool? get isEnded;
  @override
  @JsonKey(name: 'is_upcoming')
  bool? get isUpcoming;
  @override
  @JsonKey(name: 'reward')
  List<RewardModel>? get reward;

  /// Create a copy of VoteModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoteModelImplCopyWith<_$VoteModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VoteItemModel _$VoteItemModelFromJson(Map<String, dynamic> json) {
  return _VoteItemModel.fromJson(json);
}

/// @nodoc
mixin _$VoteItemModel {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_total')
  int? get voteTotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_id')
  int get voteId => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist')
  ArtistModel get artist => throw _privateConstructorUsedError;
  @JsonKey(name: 'artist_group')
  ArtistGroupModel get artistGroup => throw _privateConstructorUsedError;

  /// Serializes this VoteItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'vote_total') int? voteTotal,
      @JsonKey(name: 'vote_id') int voteId,
      @JsonKey(name: 'artist') ArtistModel artist,
      @JsonKey(name: 'artist_group') ArtistGroupModel artistGroup});

  $ArtistModelCopyWith<$Res> get artist;
  $ArtistGroupModelCopyWith<$Res> get artistGroup;
}

/// @nodoc
class _$VoteItemModelCopyWithImpl<$Res, $Val extends VoteItemModel>
    implements $VoteItemModelCopyWith<$Res> {
  _$VoteItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteTotal = freezed,
    Object? voteId = null,
    Object? artist = null,
    Object? artistGroup = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      voteTotal: freezed == voteTotal
          ? _value.voteTotal
          : voteTotal // ignore: cast_nullable_to_non_nullable
              as int?,
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
              as int,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel,
      artistGroup: null == artistGroup
          ? _value.artistGroup
          : artistGroup // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel,
    ) as $Val);
  }

  /// Create a copy of VoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistModelCopyWith<$Res> get artist {
    return $ArtistModelCopyWith<$Res>(_value.artist, (value) {
      return _then(_value.copyWith(artist: value) as $Val);
    });
  }

  /// Create a copy of VoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtistGroupModelCopyWith<$Res> get artistGroup {
    return $ArtistGroupModelCopyWith<$Res>(_value.artistGroup, (value) {
      return _then(_value.copyWith(artistGroup: value) as $Val);
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
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'vote_total') int? voteTotal,
      @JsonKey(name: 'vote_id') int voteId,
      @JsonKey(name: 'artist') ArtistModel artist,
      @JsonKey(name: 'artist_group') ArtistGroupModel artistGroup});

  @override
  $ArtistModelCopyWith<$Res> get artist;
  @override
  $ArtistGroupModelCopyWith<$Res> get artistGroup;
}

/// @nodoc
class __$$VoteItemModelImplCopyWithImpl<$Res>
    extends _$VoteItemModelCopyWithImpl<$Res, _$VoteItemModelImpl>
    implements _$$VoteItemModelImplCopyWith<$Res> {
  __$$VoteItemModelImplCopyWithImpl(
      _$VoteItemModelImpl _value, $Res Function(_$VoteItemModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of VoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteTotal = freezed,
    Object? voteId = null,
    Object? artist = null,
    Object? artistGroup = null,
  }) {
    return _then(_$VoteItemModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      voteTotal: freezed == voteTotal
          ? _value.voteTotal
          : voteTotal // ignore: cast_nullable_to_non_nullable
              as int?,
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
              as int,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as ArtistModel,
      artistGroup: null == artistGroup
          ? _value.artistGroup
          : artistGroup // ignore: cast_nullable_to_non_nullable
              as ArtistGroupModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoteItemModelImpl extends _VoteItemModel {
  const _$VoteItemModelImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'vote_total') required this.voteTotal,
      @JsonKey(name: 'vote_id') required this.voteId,
      @JsonKey(name: 'artist') required this.artist,
      @JsonKey(name: 'artist_group') required this.artistGroup})
      : super._();

  factory _$VoteItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteItemModelImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'vote_total')
  final int? voteTotal;
  @override
  @JsonKey(name: 'vote_id')
  final int voteId;
  @override
  @JsonKey(name: 'artist')
  final ArtistModel artist;
  @override
  @JsonKey(name: 'artist_group')
  final ArtistGroupModel artistGroup;

  @override
  String toString() {
    return 'VoteItemModel(id: $id, voteTotal: $voteTotal, voteId: $voteId, artist: $artist, artistGroup: $artistGroup)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.voteTotal, voteTotal) ||
                other.voteTotal == voteTotal) &&
            (identical(other.voteId, voteId) || other.voteId == voteId) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.artistGroup, artistGroup) ||
                other.artistGroup == artistGroup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, voteTotal, voteId, artist, artistGroup);

  /// Create a copy of VoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {@JsonKey(name: 'id') required final int id,
      @JsonKey(name: 'vote_total') required final int? voteTotal,
      @JsonKey(name: 'vote_id') required final int voteId,
      @JsonKey(name: 'artist') required final ArtistModel artist,
      @JsonKey(name: 'artist_group')
      required final ArtistGroupModel artistGroup}) = _$VoteItemModelImpl;
  const _VoteItemModel._() : super._();

  factory _VoteItemModel.fromJson(Map<String, dynamic> json) =
      _$VoteItemModelImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'vote_total')
  int? get voteTotal;
  @override
  @JsonKey(name: 'vote_id')
  int get voteId;
  @override
  @JsonKey(name: 'artist')
  ArtistModel get artist;
  @override
  @JsonKey(name: 'artist_group')
  ArtistGroupModel get artistGroup;

  /// Create a copy of VoteItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoteItemModelImplCopyWith<_$VoteItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VoteAchieve _$VoteAchieveFromJson(Map<String, dynamic> json) {
  return _VoteAchieve.fromJson(json);
}

/// @nodoc
mixin _$VoteAchieve {
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote_id')
  int get voteId => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward_id')
  int get rewardId => throw _privateConstructorUsedError;
  @JsonKey(name: 'order')
  int get order => throw _privateConstructorUsedError;
  @JsonKey(name: 'amount')
  int get amount => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward')
  RewardModel get reward => throw _privateConstructorUsedError;
  @JsonKey(name: 'vote')
  VoteModel get vote => throw _privateConstructorUsedError;

  /// Serializes this VoteAchieve to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VoteAchieve
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoteAchieveCopyWith<VoteAchieve> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoteAchieveCopyWith<$Res> {
  factory $VoteAchieveCopyWith(
          VoteAchieve value, $Res Function(VoteAchieve) then) =
      _$VoteAchieveCopyWithImpl<$Res, VoteAchieve>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'vote_id') int voteId,
      @JsonKey(name: 'reward_id') int rewardId,
      @JsonKey(name: 'order') int order,
      @JsonKey(name: 'amount') int amount,
      @JsonKey(name: 'reward') RewardModel reward,
      @JsonKey(name: 'vote') VoteModel vote});

  $RewardModelCopyWith<$Res> get reward;
  $VoteModelCopyWith<$Res> get vote;
}

/// @nodoc
class _$VoteAchieveCopyWithImpl<$Res, $Val extends VoteAchieve>
    implements $VoteAchieveCopyWith<$Res> {
  _$VoteAchieveCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoteAchieve
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteId = null,
    Object? rewardId = null,
    Object? order = null,
    Object? amount = null,
    Object? reward = null,
    Object? vote = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
              as int,
      rewardId: null == rewardId
          ? _value.rewardId
          : rewardId // ignore: cast_nullable_to_non_nullable
              as int,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      reward: null == reward
          ? _value.reward
          : reward // ignore: cast_nullable_to_non_nullable
              as RewardModel,
      vote: null == vote
          ? _value.vote
          : vote // ignore: cast_nullable_to_non_nullable
              as VoteModel,
    ) as $Val);
  }

  /// Create a copy of VoteAchieve
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RewardModelCopyWith<$Res> get reward {
    return $RewardModelCopyWith<$Res>(_value.reward, (value) {
      return _then(_value.copyWith(reward: value) as $Val);
    });
  }

  /// Create a copy of VoteAchieve
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VoteModelCopyWith<$Res> get vote {
    return $VoteModelCopyWith<$Res>(_value.vote, (value) {
      return _then(_value.copyWith(vote: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VoteAchieveImplCopyWith<$Res>
    implements $VoteAchieveCopyWith<$Res> {
  factory _$$VoteAchieveImplCopyWith(
          _$VoteAchieveImpl value, $Res Function(_$VoteAchieveImpl) then) =
      __$$VoteAchieveImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int id,
      @JsonKey(name: 'vote_id') int voteId,
      @JsonKey(name: 'reward_id') int rewardId,
      @JsonKey(name: 'order') int order,
      @JsonKey(name: 'amount') int amount,
      @JsonKey(name: 'reward') RewardModel reward,
      @JsonKey(name: 'vote') VoteModel vote});

  @override
  $RewardModelCopyWith<$Res> get reward;
  @override
  $VoteModelCopyWith<$Res> get vote;
}

/// @nodoc
class __$$VoteAchieveImplCopyWithImpl<$Res>
    extends _$VoteAchieveCopyWithImpl<$Res, _$VoteAchieveImpl>
    implements _$$VoteAchieveImplCopyWith<$Res> {
  __$$VoteAchieveImplCopyWithImpl(
      _$VoteAchieveImpl _value, $Res Function(_$VoteAchieveImpl) _then)
      : super(_value, _then);

  /// Create a copy of VoteAchieve
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? voteId = null,
    Object? rewardId = null,
    Object? order = null,
    Object? amount = null,
    Object? reward = null,
    Object? vote = null,
  }) {
    return _then(_$VoteAchieveImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      voteId: null == voteId
          ? _value.voteId
          : voteId // ignore: cast_nullable_to_non_nullable
              as int,
      rewardId: null == rewardId
          ? _value.rewardId
          : rewardId // ignore: cast_nullable_to_non_nullable
              as int,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      reward: null == reward
          ? _value.reward
          : reward // ignore: cast_nullable_to_non_nullable
              as RewardModel,
      vote: null == vote
          ? _value.vote
          : vote // ignore: cast_nullable_to_non_nullable
              as VoteModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VoteAchieveImpl extends _VoteAchieve {
  const _$VoteAchieveImpl(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'vote_id') required this.voteId,
      @JsonKey(name: 'reward_id') required this.rewardId,
      @JsonKey(name: 'order') required this.order,
      @JsonKey(name: 'amount') required this.amount,
      @JsonKey(name: 'reward') required this.reward,
      @JsonKey(name: 'vote') required this.vote})
      : super._();

  factory _$VoteAchieveImpl.fromJson(Map<String, dynamic> json) =>
      _$$VoteAchieveImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int id;
  @override
  @JsonKey(name: 'vote_id')
  final int voteId;
  @override
  @JsonKey(name: 'reward_id')
  final int rewardId;
  @override
  @JsonKey(name: 'order')
  final int order;
  @override
  @JsonKey(name: 'amount')
  final int amount;
  @override
  @JsonKey(name: 'reward')
  final RewardModel reward;
  @override
  @JsonKey(name: 'vote')
  final VoteModel vote;

  @override
  String toString() {
    return 'VoteAchieve(id: $id, voteId: $voteId, rewardId: $rewardId, order: $order, amount: $amount, reward: $reward, vote: $vote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoteAchieveImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.voteId, voteId) || other.voteId == voteId) &&
            (identical(other.rewardId, rewardId) ||
                other.rewardId == rewardId) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.reward, reward) || other.reward == reward) &&
            (identical(other.vote, vote) || other.vote == vote));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, voteId, rewardId, order, amount, reward, vote);

  /// Create a copy of VoteAchieve
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoteAchieveImplCopyWith<_$VoteAchieveImpl> get copyWith =>
      __$$VoteAchieveImplCopyWithImpl<_$VoteAchieveImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VoteAchieveImplToJson(
      this,
    );
  }
}

abstract class _VoteAchieve extends VoteAchieve {
  const factory _VoteAchieve(
          {@JsonKey(name: 'id') required final int id,
          @JsonKey(name: 'vote_id') required final int voteId,
          @JsonKey(name: 'reward_id') required final int rewardId,
          @JsonKey(name: 'order') required final int order,
          @JsonKey(name: 'amount') required final int amount,
          @JsonKey(name: 'reward') required final RewardModel reward,
          @JsonKey(name: 'vote') required final VoteModel vote}) =
      _$VoteAchieveImpl;
  const _VoteAchieve._() : super._();

  factory _VoteAchieve.fromJson(Map<String, dynamic> json) =
      _$VoteAchieveImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int get id;
  @override
  @JsonKey(name: 'vote_id')
  int get voteId;
  @override
  @JsonKey(name: 'reward_id')
  int get rewardId;
  @override
  @JsonKey(name: 'order')
  int get order;
  @override
  @JsonKey(name: 'amount')
  int get amount;
  @override
  @JsonKey(name: 'reward')
  RewardModel get reward;
  @override
  @JsonKey(name: 'vote')
  VoteModel get vote;

  /// Create a copy of VoteAchieve
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoteAchieveImplCopyWith<_$VoteAchieveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
