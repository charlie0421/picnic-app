// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoteListModel _$VoteListModelFromJson(Map<String, dynamic> json) =>
    VoteListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => VoteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VoteListModelToJson(VoteListModel instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

VoteModel _$VoteModelFromJson(Map<String, dynamic> json) => VoteModel(
      id: json['id'] as int,
      voteTitle: json['voteTitle'] as String,
      voteCategory: json['voteCategory'] as String,
      mainImage: json['mainImage'] as String,
      waitImage: json['waitImage'] as String,
      resultImage: json['resultImage'] as String,
      voteContent: json['voteContent'] as String,
      voteItems: (json['voteItems'] as List<dynamic>)
          .map((e) => VoteItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      visibleAt: DateTime.parse(json['visibleAt'] as String),
      stopAt: DateTime.parse(json['stopAt'] as String),
      startAt: DateTime.parse(json['startAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$VoteModelToJson(VoteModel instance) => <String, dynamic>{
      'id': instance.id,
      'voteTitle': instance.voteTitle,
      'voteCategory': instance.voteCategory,
      'mainImage': instance.mainImage,
      'waitImage': instance.waitImage,
      'resultImage': instance.resultImage,
      'voteContent': instance.voteContent,
      'voteItems': instance.voteItems,
      'createdAt': instance.createdAt.toIso8601String(),
      'visibleAt': instance.visibleAt.toIso8601String(),
      'stopAt': instance.stopAt.toIso8601String(),
      'startAt': instance.startAt.toIso8601String(),
    };

VoteItem _$VoteItemFromJson(Map<String, dynamic> json) => VoteItem(
      id: json['id'] as int,
      voteTotal: json['voteTotal'] as int,
      voteId: json['voteId'] as int,
      myStarMember: MyStarMemberModel.fromJson(
          json['myStarMember'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VoteItemToJson(VoteItem instance) => <String, dynamic>{
      'id': instance.id,
      'voteTotal': instance.voteTotal,
      'voteId': instance.voteId,
      'myStarMember': instance.myStarMember,
    };

MyStarMemberModel _$MyStarMemberModelFromJson(Map<String, dynamic> json) =>
    MyStarMemberModel(
      id: json['id'] as int,
      nameKo: json['nameKo'] as String,
      nameEn: json['nameEn'] as String,
      gender: json['gender'] as String,
      image: json['image'] as String,
    );

Map<String, dynamic> _$MyStarMemberModelToJson(MyStarMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nameKo': instance.nameKo,
      'nameEn': instance.nameEn,
      'gender': instance.gender,
      'image': instance.image,
    };
