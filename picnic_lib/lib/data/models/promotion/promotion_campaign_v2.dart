import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

part '../../../generated/providers/models/promotion/promotion_campaign_v2.freezed.dart';
part '../../../generated/providers/models/promotion/promotion_campaign_v2.g.dart';

enum PromotionSurfaceV2 { home, paymentBadge }

extension PromotionSurfaceV2Wire on PromotionSurfaceV2 {
  String get wireValue =>
      this == PromotionSurfaceV2.home ? 'HOME' : 'PAYMENT_BADGE';
}

const _campaignV2Keys = {
  'campaign_id',
  'campaign_version_id',
  'code',
  'display_name',
  'multiplier_tenths',
  'event_starts_at',
  'event_ends_at',
  'repeat_iso_dows',
  'home_creative',
};
const _campaignV2EnvelopeKeys = {
  'items',
  'total_count',
  'next_cursor',
  'snapshot_at',
  'campaign_owned_home_banner_ids',
};

@freezed
abstract class ActivePromotionCampaignV2Model
    with _$ActivePromotionCampaignV2Model {
  const ActivePromotionCampaignV2Model._();
  const factory ActivePromotionCampaignV2Model({
    @JsonKey(name: 'campaign_id') required String campaignId,
    @JsonKey(name: 'campaign_version_id') required String campaignVersionId,
    required String code,
    @JsonKey(name: 'display_name') required Map<String, dynamic> displayName,
    @JsonKey(name: 'multiplier_tenths') required int multiplierTenths,
    @JsonKey(name: 'event_starts_at') required DateTime eventStartsAt,
    @JsonKey(name: 'event_ends_at') required DateTime eventEndsAt,
    @JsonKey(name: 'repeat_iso_dows') required List<int> repeatIsoDows,
    @JsonKey(name: 'home_creative') PromotionCreativeModel? homeCreative,
  }) = _ActivePromotionCampaignV2Model;

  String localizedDisplayName(String locale) {
    for (final key in [locale, 'ko']) {
      final value = displayName[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return code;
  }

  bool hasReadableHomeCreative(String locale) =>
      homeCreative?.localizedTitle(locale) != null &&
      homeCreative?.localizedImage(locale) != null;

  factory ActivePromotionCampaignV2Model.fromJson(Map<String, dynamic> json) =>
      _$ActivePromotionCampaignV2ModelFromJson(_normalizeCampaignV2Json(json));
}

Map<String, dynamic> _normalizeCampaignV2Json(Map<String, dynamic> json) {
  final exact = requireExactContractKeys(json, _campaignV2Keys);
  if (exact['home_creative'] is Map &&
      (exact['home_creative'] as Map).isEmpty) {
    exact['home_creative'] = null;
  }
  return exact;
}

@freezed
abstract class ActivePromotionCampaignsV2Model
    with _$ActivePromotionCampaignsV2Model {
  const ActivePromotionCampaignsV2Model._();
  const factory ActivePromotionCampaignsV2Model({
    required List<ActivePromotionCampaignV2Model> items,
    @JsonKey(name: 'total_count')
    @WalletAmountConverter()
    required BigInt totalCount,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
    @JsonKey(name: 'campaign_owned_home_banner_ids')
    required List<int> campaignOwnedHomeBannerIds,
  }) = _ActivePromotionCampaignsV2Model;

  List<ActivePromotionCampaignV2Model> visibleHomeItems(String locale) =>
      items.where((item) => item.hasReadableHomeCreative(locale)).toList();

  factory ActivePromotionCampaignsV2Model.fromJson(
    Map<String, dynamic> json,
  ) => _$ActivePromotionCampaignsV2ModelFromJson(
    requireExactContractKeys(json, _campaignV2EnvelopeKeys),
  );
}
