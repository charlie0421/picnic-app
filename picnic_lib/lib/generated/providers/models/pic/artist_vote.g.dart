// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/pic/artist_vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArtistVoteModel _$ArtistVoteModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_ArtistVoteModel',
  json,
  ($checkedConvert) {
    final val = _ArtistVoteModel(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      title: $checkedConvert('title', (v) => v as Map<String, dynamic>),
      category: $checkedConvert('category', (v) => v as String),
      artistVoteItem: $checkedConvert(
        'artist_vote_item',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => ArtistVoteItemModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      visibleAt: $checkedConvert(
        'visible_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      stopAt: $checkedConvert('stop_at', (v) => DateTime.parse(v as String)),
      startAt: $checkedConvert('start_at', (v) => DateTime.parse(v as String)),
    );
    return val;
  },
  fieldKeyMap: const {
    'artistVoteItem': 'artist_vote_item',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
    'visibleAt': 'visible_at',
    'stopAt': 'stop_at',
    'startAt': 'start_at',
  },
);

Map<String, dynamic> _$ArtistVoteModelToJson(
  _ArtistVoteModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'category': instance.category,
  'artist_vote_item': instance.artistVoteItem?.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'visible_at': instance.visibleAt?.toIso8601String(),
  'stop_at': instance.stopAt.toIso8601String(),
  'start_at': instance.startAt.toIso8601String(),
};

_ArtistVoteItemModel _$ArtistVoteItemModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ArtistVoteItemModel',
      json,
      ($checkedConvert) {
        final val = _ArtistVoteItemModel(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          voteTotal: $checkedConvert('vote_total', (v) => (v as num).toInt()),
          artistVoteId: $checkedConvert(
            'artist_vote_id',
            (v) => (v as num).toInt(),
          ),
          title: $checkedConvert('title', (v) => v as Map<String, dynamic>),
          description: $checkedConvert(
            'description',
            (v) => v as Map<String, dynamic>,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'voteTotal': 'vote_total',
        'artistVoteId': 'artist_vote_id',
      },
    );

Map<String, dynamic> _$ArtistVoteItemModelToJson(
  _ArtistVoteItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'vote_total': instance.voteTotal,
  'artist_vote_id': instance.artistVoteId,
  'title': instance.title,
  'description': instance.description,
};

_MyStarMemberModel _$MyStarMemberModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_MyStarMemberModel',
      json,
      ($checkedConvert) {
        final val = _MyStarMemberModel(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          nameKo: $checkedConvert('name_ko', (v) => v as String),
          nameEn: $checkedConvert('name_en', (v) => v as String),
          gender: $checkedConvert('gender', (v) => v as String),
          image: $checkedConvert('image', (v) => v as String?),
          mystarGroup: $checkedConvert(
            'mystar_group',
            (v) => v == null
                ? null
                : MyStarGroupModel.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'nameKo': 'name_ko',
        'nameEn': 'name_en',
        'mystarGroup': 'mystar_group',
      },
    );

Map<String, dynamic> _$MyStarMemberModelToJson(_MyStarMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.nameKo,
      'name_en': instance.nameEn,
      'gender': instance.gender,
      'image': instance.image,
      'mystar_group': instance.mystarGroup?.toJson(),
    };

_MyStarGroupModel _$MyStarGroupModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_MyStarGroupModel',
      json,
      ($checkedConvert) {
        final val = _MyStarGroupModel(
          id: $checkedConvert('id', (v) => (v as num).toInt()),
          nameKo: $checkedConvert('name_ko', (v) => v as String),
          nameEn: $checkedConvert('name_en', (v) => v as String),
          image: $checkedConvert('image', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'nameKo': 'name_ko', 'nameEn': 'name_en'},
    );

Map<String, dynamic> _$MyStarGroupModelToJson(_MyStarGroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_ko': instance.nameKo,
      'name_en': instance.nameEn,
      'image': instance.image,
    };

_ArtistMemberModel _$ArtistMemberModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ArtistMemberModel', json, ($checkedConvert) {
      final val = _ArtistMemberModel(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        name: $checkedConvert(
          'name',
          (v) => Map<String, String>.from(v as Map),
        ),
        gender: $checkedConvert('gender', (v) => v as String),
        image: $checkedConvert('image', (v) => v as String?),
        artistGroup: $checkedConvert(
          'artist_group',
          (v) => v == null
              ? null
              : ArtistGroupModel.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'artistGroup': 'artist_group'});

Map<String, dynamic> _$ArtistMemberModelToJson(_ArtistMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'gender': instance.gender,
      'image': instance.image,
      'artist_group': instance.artistGroup?.toJson(),
    };

_ArtistGroupModel _$ArtistGroupModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ArtistGroupModel', json, ($checkedConvert) {
      final val = _ArtistGroupModel(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as Map<String, dynamic>),
        image: $checkedConvert('image', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ArtistGroupModelToJson(_ArtistGroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
    };
