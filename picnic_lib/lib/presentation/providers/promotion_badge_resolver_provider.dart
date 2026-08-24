import 'dart:async';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_v2_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part '../../generated/providers/promotion_badge_resolver_provider.g.dart';

typedef ResolvedPaymentBadgePromotion = ({
  Map<String, dynamic> displayName,
  String code,
  int? multiplierTenths,
  int? extraBonusBps,
});

typedef HomePromotionSlideData = ({
  int bannerId,
  int durationMs,
  PromotionCreativeModel creative,
});

typedef HomePromotionResolution = ({
  List<HomePromotionSlideData> slides,
  Set<int> ownedBannerIds,
});

/// Settlement (`get_active_promotion_campaigns_v2`/V1 store SQL) only tracks
/// this campaign code today. Selecting any other active V2 item would show a
/// badge the backend cannot actually settle a bonus for.
const _candyBoostDayCode = 'CANDY_BOOST_DAY';

/// Reads the V2 surface through the generated active provider (never the
/// repository directly, so overrides and its cache apply) and classifies the
/// outcome:
///
/// - Returns the decoded envelope on success (including a successful but
///   empty envelope — the caller decides what "zero items" means).
/// - Returns `null` for an explicitly eligible transport/unsupported-RPC
///   failure (`PostgrestException`, `SocketException`, `TimeoutException`),
///   the only errors this migration window treats as "V2 not available yet."
/// - Rethrows `FormatException`, `TypeError`, and `CheckedFromJsonException`
///   unchanged: a corrupt payload or a programming bug must fail closed, not
///   silently revive V1 data that could mask real drift.
Future<ActivePromotionCampaignsV2Model?> _readEligibleV2(
  Future<ActivePromotionCampaignsV2Model> Function() read,
) async {
  try {
    return await read();
  } on FormatException {
    rethrow;
  } on TypeError {
    rethrow;
  } on CheckedFromJsonException {
    rethrow;
  } on PostgrestException {
    return null;
  } on SocketException {
    return null;
  } on TimeoutException {
    return null;
  }
}

@riverpod
Future<ResolvedPaymentBadgePromotion?> paymentBadgePromotion(Ref ref) async {
  final v2 = await _readEligibleV2(
    () => ref.watch(
      activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge).future,
    ),
  );
  if (v2 != null && v2.items.isNotEmpty) {
    final item = v2.items
        .where((i) => i.code == _candyBoostDayCode)
        .firstOrNull;
    if (item == null) return null;
    return (
      displayName: item.displayName,
      code: item.code,
      multiplierTenths: item.multiplierTenths,
      extraBonusBps: null,
    );
  }
  final v1 = await ref.watch(
    activePromotionCampaignProvider(PromotionSurface.store).future,
  );
  final item = v1.items.where((i) => i.showInStore).firstOrNull;
  if (item == null) return null;
  return (
    displayName: item.displayName,
    code: item.code,
    multiplierTenths: null,
    extraBonusBps: item.extraBonusBps,
  );
}

@riverpod
Future<HomePromotionResolution> homePromotionCampaign(
  Ref ref,
  String locale,
) async {
  final v2 = await _readEligibleV2(
    () => ref.watch(
      activePromotionCampaignV2Provider(PromotionSurfaceV2.home).future,
    ),
  );
  if (v2 != null && v2.items.isNotEmpty) {
    // V2 has active items: it is authoritative regardless of whether the
    // creative is readable in this locale. Do not fall back to V1 (that
    // could show a stale campaign or a plain copy of a campaign-owned
    // banner) — just omit the unreadable slide while keeping every owned id.
    return (
      slides: [
        for (final item in v2.visibleHomeItems(locale))
          (
            bannerId: item.homeCreative!.bannerId,
            durationMs: item.homeCreative!.duration,
            creative: item.homeCreative!,
          ),
      ],
      ownedBannerIds: v2.campaignOwnedHomeBannerIds.toSet(),
    );
  }
  final v1 = await ref.watch(
    activePromotionCampaignProvider(PromotionSurface.home).future,
  );
  // V2 was either eligible-empty (dark launch, flag still off) or threw an
  // eligible transport error. Either way the client cannot tell "V2 truly
  // has no campaign" from "V2 isn't live yet," so V1 is read as the
  // authoritative fallback. When V2 did succeed empty it may still carry
  // immutable HOME ownership (banners already assigned to a campaign even
  // though no version is currently active) — union that into V1's ownership
  // so those banners are not shown twice as ordinary rows.
  final v2OwnedIds = v2?.campaignOwnedHomeBannerIds.toSet() ?? const <int>{};
  return (
    slides: [
      for (final item in v1.visibleHomeItems(locale))
        (
          bannerId: item.homeCreative!.bannerId,
          durationMs: item.homeCreative!.duration,
          creative: item.homeCreative!,
        ),
    ],
    ownedBannerIds: v1.campaignOwnedHomeBannerIds.toSet().union(v2OwnedIds),
  );
}
