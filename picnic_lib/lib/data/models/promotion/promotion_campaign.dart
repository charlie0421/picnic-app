import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

part '../../../generated/providers/models/promotion/promotion_campaign.freezed.dart';
part '../../../generated/providers/models/promotion/promotion_campaign.g.dart';

enum PromotionSurface { home, store }

const _creativeKeys = {
  'banner_id',
  'title',
  'image',
  'thumbnail',
  'link',
  'duration',
};
const _campaignKeys = {
  'campaign_id',
  'campaign_version_id',
  'code',
  'display_name',
  'extra_bonus_bps',
  'window_starts_at',
  'window_ends_at',
  'show_in_store',
  'show_home_banner',
  'home_creative',
};
const _campaignEnvelopeKeys = {
  'items',
  'total_count',
  'next_cursor',
  'snapshot_at',
  'campaign_owned_home_banner_ids',
};

extension PromotionSurfaceWire on PromotionSurface {
  String get wireValue => this == PromotionSurface.home ? 'HOME' : 'STORE';
}

@freezed
abstract class PromotionCreativeModel with _$PromotionCreativeModel {
  const PromotionCreativeModel._();
  const factory PromotionCreativeModel({
    @JsonKey(name: 'banner_id') required int bannerId,
    required Map<String, dynamic> title,
    required Map<String, dynamic> image,
    String? thumbnail,
    String? link,
    @Default(3000) int duration,
  }) = _PromotionCreativeModel;

  String? localizedImage(String locale) => _localized(image, locale);
  String? localizedTitle(String locale) => _localized(title, locale);

  factory PromotionCreativeModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionCreativeModelFromJson(
        requireExactContractKeys(json, _creativeKeys),
      );
}

String? _localized(Map<String, dynamic> values, String locale) {
  for (final key in [locale, 'ko', 'en']) {
    final value = values[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

@freezed
abstract class ActivePromotionCampaignModel
    with _$ActivePromotionCampaignModel {
  const ActivePromotionCampaignModel._();
  const factory ActivePromotionCampaignModel({
    @JsonKey(name: 'campaign_id') required String campaignId,
    @JsonKey(name: 'campaign_version_id') required String campaignVersionId,
    required String code,
    @JsonKey(name: 'display_name') required Map<String, dynamic> displayName,
    @JsonKey(name: 'extra_bonus_bps') required int extraBonusBps,
    @JsonKey(name: 'window_starts_at') required DateTime windowStartsAt,
    @JsonKey(name: 'window_ends_at') required DateTime windowEndsAt,
    @JsonKey(name: 'show_in_store') required bool showInStore,
    @JsonKey(name: 'show_home_banner') required bool showHomeBanner,
    @JsonKey(name: 'home_creative') PromotionCreativeModel? homeCreative,
  }) = _ActivePromotionCampaignModel;

  String localizedDisplayName(String locale) {
    for (final key in [locale, 'ko']) {
      final value = displayName[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return code;
  }

  bool hasReadableHomeCreative(String locale) =>
      showHomeBanner &&
      homeCreative?.localizedTitle(locale) != null &&
      homeCreative?.localizedImage(locale) != null;

  factory ActivePromotionCampaignModel.fromJson(Map<String, dynamic> json) {
    final exact = requireExactContractKeys(json, _campaignKeys);
    if (exact['home_creative'] is Map &&
        (exact['home_creative'] as Map).isEmpty) {
      exact['home_creative'] = null;
    }
    return _$ActivePromotionCampaignModelFromJson(exact);
  }
}

@freezed
abstract class ActivePromotionCampaignsModel
    with _$ActivePromotionCampaignsModel {
  const ActivePromotionCampaignsModel._();
  const factory ActivePromotionCampaignsModel({
    required List<ActivePromotionCampaignModel> items,
    @JsonKey(name: 'total_count')
    @WalletAmountConverter()
    required BigInt totalCount,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
    @JsonKey(name: 'campaign_owned_home_banner_ids')
    required List<int> campaignOwnedHomeBannerIds,
  }) = _ActivePromotionCampaignsModel;

  List<ActivePromotionCampaignModel> visibleHomeItems(String locale) =>
      items.where((item) => item.hasReadableHomeCreative(locale)).toList();

  factory ActivePromotionCampaignsModel.fromJson(Map<String, dynamic> json) =>
      _$ActivePromotionCampaignsModelFromJson(
        requireExactContractKeys(json, _campaignEnvelopeKeys),
      );
}
