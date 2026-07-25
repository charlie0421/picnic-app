// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../../data/models/promotion/promotion_campaign.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PromotionCreativeModel _$PromotionCreativeModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_PromotionCreativeModel', json, ($checkedConvert) {
  final val = _PromotionCreativeModel(
    bannerId: $checkedConvert('banner_id', (v) => (v as num).toInt()),
    title: $checkedConvert('title', (v) => v as Map<String, dynamic>),
    image: $checkedConvert('image', (v) => v as Map<String, dynamic>),
    thumbnail: $checkedConvert('thumbnail', (v) => v as String?),
    link: $checkedConvert('link', (v) => v as String?),
    duration: $checkedConvert('duration', (v) => (v as num?)?.toInt() ?? 3000),
  );
  return val;
}, fieldKeyMap: const {'bannerId': 'banner_id'});

Map<String, dynamic> _$PromotionCreativeModelToJson(
  _PromotionCreativeModel instance,
) => <String, dynamic>{
  'banner_id': instance.bannerId,
  'title': instance.title,
  'image': instance.image,
  'thumbnail': instance.thumbnail,
  'link': instance.link,
  'duration': instance.duration,
};

_ActivePromotionCampaignModel _$ActivePromotionCampaignModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_ActivePromotionCampaignModel',
  json,
  ($checkedConvert) {
    final val = _ActivePromotionCampaignModel(
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
      extraBonusBps: $checkedConvert(
        'extra_bonus_bps',
        (v) => (v as num).toInt(),
      ),
      windowStartsAt: $checkedConvert(
        'window_starts_at',
        (v) => DateTime.parse(v as String),
      ),
      windowEndsAt: $checkedConvert(
        'window_ends_at',
        (v) => DateTime.parse(v as String),
      ),
      showInStore: $checkedConvert('show_in_store', (v) => v as bool),
      showHomeBanner: $checkedConvert('show_home_banner', (v) => v as bool),
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
    'extraBonusBps': 'extra_bonus_bps',
    'windowStartsAt': 'window_starts_at',
    'windowEndsAt': 'window_ends_at',
    'showInStore': 'show_in_store',
    'showHomeBanner': 'show_home_banner',
    'homeCreative': 'home_creative',
  },
);

Map<String, dynamic> _$ActivePromotionCampaignModelToJson(
  _ActivePromotionCampaignModel instance,
) => <String, dynamic>{
  'campaign_id': instance.campaignId,
  'campaign_version_id': instance.campaignVersionId,
  'code': instance.code,
  'display_name': instance.displayName,
  'extra_bonus_bps': instance.extraBonusBps,
  'window_starts_at': instance.windowStartsAt.toIso8601String(),
  'window_ends_at': instance.windowEndsAt.toIso8601String(),
  'show_in_store': instance.showInStore,
  'show_home_banner': instance.showHomeBanner,
  'home_creative': instance.homeCreative?.toJson(),
};

_ActivePromotionCampaignsModel _$ActivePromotionCampaignsModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_ActivePromotionCampaignsModel',
  json,
  ($checkedConvert) {
    final val = _ActivePromotionCampaignsModel(
      items: $checkedConvert(
        'items',
        (v) => (v as List<dynamic>)
            .map(
              (e) => ActivePromotionCampaignModel.fromJson(
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
        (v) => DateTime.parse(v as String),
      ),
      campaignOwnedHomeBannerIds: $checkedConvert(
        'campaign_owned_home_banner_ids',
        (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
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

Map<String, dynamic> _$ActivePromotionCampaignsModelToJson(
  _ActivePromotionCampaignsModel instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total_count': const WalletAmountConverter().toJson(instance.totalCount),
  'next_cursor': instance.nextCursor,
  'snapshot_at': instance.snapshotAt.toIso8601String(),
  'campaign_owned_home_banner_ids': instance.campaignOwnedHomeBannerIds,
};
