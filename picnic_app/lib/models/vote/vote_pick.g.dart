// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote_pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VotePickListModelImpl _$$VotePickListModelImplFromJson(
        Map<String, dynamic> json) =>
    _$VotePickListModelImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => VotePickModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VotePickListModelImplToJson(
        _$VotePickListModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'meta': instance.meta,
    };

_$VotePickModelImpl _$$VotePickModelImplFromJson(Map<String, dynamic> json) =>
    _$VotePickModelImpl(
      id: (json['id'] as num).toInt(),
      vote: VoteModel.fromJson(json['vote'] as Map<String, dynamic>),
      voteItem:
          VoteItemModel.fromJson(json['vote_item'] as Map<String, dynamic>),
      amount: (json['amount'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$VotePickModelImplToJson(_$VotePickModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vote': instance.vote,
      'vote_item': instance.voteItem,
      'amount': instance.amount,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
