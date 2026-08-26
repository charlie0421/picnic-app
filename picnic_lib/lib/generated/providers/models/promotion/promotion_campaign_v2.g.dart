// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/promotion/promotion_campaign_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActivePromotionCampaignV2Model _$ActivePromotionCampaignV2ModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_ActivePromotionCampaignV2Model',
  json,
  ($checkedConvert) {
    final val = _ActivePromotionCampaignV2Model(
      campaignId: $checkedConvert('campaign_id', (v) => v as String),
      campaignVersionId: $checkedConvert(
        'campaign_version_id',
        (v) => v as String,
      ),
      code: $checkedConvert('code', (v) => v as String),
      displayName: $checkedConvert(
        'display_name',
        (v) => v as Map<String, dynamic>,
      ),
      multiplierTenths: $checkedConvert(
        'multiplier_tenths',
        (v) => const _StrictIntConverter().fromJson(v),
      ),
      eventStartsAt: $checkedConvert(
        'event_starts_at',
        (v) => const _StrictTimestampConverter().fromJson(v),
      ),
      eventEndsAt: $checkedConvert(
        'event_ends_at',
        (v) => const _StrictTimestampConverter().fromJson(v),
      ),
      repeatIsoDows: $checkedConvert(
        'repeat_iso_dows',
        (v) => const _StrictIntListConverter().fromJson(v),
      ),
      homeCreative: $checkedConvert(
        'home_creative',
        (v) => v == null
            ? null
            : PromotionCreativeModel.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'campaignId': 'campaign_id',
    'campaignVersionId': 'campaign_version_id',
    'displayName': 'display_name',
    'multiplierTenths': 'multiplier_tenths',
    'eventStartsAt': 'event_starts_at',
    'eventEndsAt': 'event_ends_at',
    'repeatIsoDows': 'repeat_iso_dows',
    'homeCreative': 'home_creative',
  },
);

Map<String, dynamic> _$ActivePromotionCampaignV2ModelToJson(
  _ActivePromotionCampaignV2Model instance,
) => <String, dynamic>{
  'campaign_id': instance.campaignId,
  'campaign_version_id': instance.campaignVersionId,
  'code': instance.code,
  'display_name': instance.displayName,
  'multiplier_tenths': const _StrictIntConverter().toJson(
    instance.multiplierTenths,
  ),
  'event_starts_at': const _StrictTimestampConverter().toJson(
    instance.eventStartsAt,
  ),
  'event_ends_at': const _StrictTimestampConverter().toJson(
    instance.eventEndsAt,
  ),
  'repeat_iso_dows': const _StrictIntListConverter().toJson(
    instance.repeatIsoDows,
  ),
  'home_creative': instance.homeCreative?.toJson(),
};

_ActivePromotionCampaignsV2Model _$ActivePromotionCampaignsV2ModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_ActivePromotionCampaignsV2Model',
  json,
  ($checkedConvert) {
    final val = _ActivePromotionCampaignsV2Model(
      items: $checkedConvert(
        'items',
        (v) => (v as List<dynamic>)
            .map(
              (e) => ActivePromotionCampaignV2Model.fromJson(
                e as Map<String, dynamic>,
              ),
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
        (v) => const _StrictTimestampConverter().fromJson(v),
      ),
      campaignOwnedHomeBannerIds: $checkedConvert(
        'campaign_owned_home_banner_ids',
        (v) => const _StrictIntListConverter().fromJson(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'totalCount': 'total_count',
    'nextCursor': 'next_cursor',
    'snapshotAt': 'snapshot_at',
    'campaignOwnedHomeBannerIds': 'campaign_owned_home_banner_ids',
  },
);

Map<String, dynamic> _$ActivePromotionCampaignsV2ModelToJson(
  _ActivePromotionCampaignsV2Model instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total_count': const WalletAmountConverter().toJson(instance.totalCount),
  'next_cursor': instance.nextCursor,
  'snapshot_at': const _StrictTimestampConverter().toJson(instance.snapshotAt),
  'campaign_owned_home_banner_ids': const _StrictIntListConverter().toJson(
    instance.campaignOwnedHomeBannerIds,
  ),
};
