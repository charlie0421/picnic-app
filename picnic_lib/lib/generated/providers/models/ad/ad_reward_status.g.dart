// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/ad/ad_reward_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdRewardReference _$AdRewardReferenceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AdRewardReference', json, ($checkedConvert) {
      final val = _AdRewardReference(
        type: $checkedConvert(
          'type',
          (v) => const AdRewardReferenceTypeConverter().fromJson(v as String),
        ),
        id: $checkedConvert('id', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AdRewardReferenceToJson(_AdRewardReference instance) =>
    <String, dynamic>{
      'type': const AdRewardReferenceTypeConverter().toJson(instance.type),
      'id': instance.id,
    };

_PangleClaimModel _$PangleClaimModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_PangleClaimModel',
      json,
      ($checkedConvert) {
        final val = _PangleClaimModel(
          reference: $checkedConvert(
            'reference',
            (v) => AdRewardReference.fromJson(v as Map<String, dynamic>),
          ),
          platform: $checkedConvert('platform', (v) => v as String),
          signedToken: $checkedConvert('signed_token', (v) => v as String),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'signedToken': 'signed_token',
        'expiresAt': 'expires_at',
      },
    );

Map<String, dynamic> _$PangleClaimModelToJson(_PangleClaimModel instance) =>
    <String, dynamic>{
      'reference': instance.reference.toJson(),
      'platform': instance.platform,
      'signed_token': instance.signedToken,
      'expires_at': instance.expiresAt.toIso8601String(),
    };

_AdmobClaimModel _$AdmobClaimModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_AdmobClaimModel',
      json,
      ($checkedConvert) {
        final val = _AdmobClaimModel(
          reference: $checkedConvert(
            'reference',
            (v) => AdRewardReference.fromJson(v as Map<String, dynamic>),
          ),
          platform: $checkedConvert('platform', (v) => v as String),
          signedToken: $checkedConvert('signed_token', (v) => v as String),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'signedToken': 'signed_token',
        'expiresAt': 'expires_at',
      },
    );

Map<String, dynamic> _$AdmobClaimModelToJson(_AdmobClaimModel instance) =>
    <String, dynamic>{
      'reference': instance.reference.toJson(),
      'platform': instance.platform,
      'signed_token': instance.signedToken,
      'expires_at': instance.expiresAt.toIso8601String(),
    };

_AdRewardGrantModel _$AdRewardGrantModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_AdRewardGrantModel',
      json,
      ($checkedConvert) {
        final val = _AdRewardGrantModel(
          id: $checkedConvert('id', (v) => v as String),
          currency: $checkedConvert(
            'currency',
            (v) => const WalletCurrencyConverter().fromJson(v as String),
          ),
          amount: $checkedConvert(
            'amount',
            (v) => const WalletAmountConverter().fromJson(v),
          ),
          grantedAt: $checkedConvert(
            'granted_at',
            (v) => DateTime.parse(v as String),
          ),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {'grantedAt': 'granted_at', 'expiresAt': 'expires_at'},
    );

Map<String, dynamic> _$AdRewardGrantModelToJson(_AdRewardGrantModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'currency': const WalletCurrencyConverter().toJson(instance.currency),
      'amount': const WalletAmountConverter().toJson(instance.amount),
      'granted_at': instance.grantedAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
    };

_AdRewardStatusModel _$AdRewardStatusModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AdRewardStatusModel', json, ($checkedConvert) {
      final val = _AdRewardStatusModel(
        reference: $checkedConvert(
          'reference',
          (v) => AdRewardReference.fromJson(v as Map<String, dynamic>),
        ),
        state: $checkedConvert(
          'state',
          (v) => const AdRewardStateConverter().fromJson(v as String),
        ),
        grant: $checkedConvert(
          'grant',
          (v) => v == null
              ? null
              : AdRewardGrantModel.fromJson(v as Map<String, dynamic>),
        ),
        wallet: $checkedConvert(
          'wallet',
          (v) => WalletSummaryModel.fromJson(v as Map<String, dynamic>),
        ),
        snapshotAt: $checkedConvert(
          'snapshot_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'snapshotAt': 'snapshot_at'});

Map<String, dynamic> _$AdRewardStatusModelToJson(
  _AdRewardStatusModel instance,
) => <String, dynamic>{
  'reference': instance.reference.toJson(),
  'state': const AdRewardStateConverter().toJson(instance.state),
  'grant': instance.grant?.toJson(),
  'wallet': instance.wallet.toJson(),
  'snapshot_at': instance.snapshotAt.toIso8601String(),
};

_AdRewardPageModel _$AdRewardPageModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_AdRewardPageModel',
      json,
      ($checkedConvert) {
        final val = _AdRewardPageModel(
          items: $checkedConvert(
            'items',
            (v) => (v as List<dynamic>)
                .map(
                  (e) =>
                      AdRewardStatusModel.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          totalCount: $checkedConvert(
            'total_count',
            (v) => const WalletAmountConverter().fromJson(v),
          ),
          nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
          snapshotAt: $checkedConvert(
            'snapshot_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'totalCount': 'total_count',
        'nextCursor': 'next_cursor',
        'snapshotAt': 'snapshot_at',
      },
    );

Map<String, dynamic> _$AdRewardPageModelToJson(_AdRewardPageModel instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total_count': const WalletAmountConverter().toJson(instance.totalCount),
      'next_cursor': instance.nextCursor,
      'snapshot_at': instance.snapshotAt.toIso8601String(),
    };

_InternalShortformViewResponse _$InternalShortformViewResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_InternalShortformViewResponse',
  json,
  ($checkedConvert) {
    final val = _InternalShortformViewResponse(
      ok: $checkedConvert('ok', (v) => v as bool),
      rewardAdded: $checkedConvert('reward_added', (v) => (v as num).toInt()),
      impressionId: $checkedConvert('impression_id', (v) => v as String),
      newBonus: $checkedConvert('new_bonus', (v) => (v as num?)?.toInt()),
      reward: $checkedConvert(
        'reward',
        (v) => v == null
            ? null
            : AdRewardStatusModel.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'rewardAdded': 'reward_added',
    'impressionId': 'impression_id',
    'newBonus': 'new_bonus',
  },
);

Map<String, dynamic> _$InternalShortformViewResponseToJson(
  _InternalShortformViewResponse instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'reward_added': instance.rewardAdded,
  'impression_id': instance.impressionId,
  'new_bonus': instance.newBonus,
  'reward': instance.reward?.toJson(),
};
