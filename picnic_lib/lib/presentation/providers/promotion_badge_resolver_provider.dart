import 'dart:async';
import 'dart:io';

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

/// PostgREST's documented "Could not find the function in the schema cache"
/// error code — the wire response for calling an RPC that is not deployed
/// (or not yet reloaded into the schema cache). This is the only PostgREST
/// code this migration window treats as "the V2 RPC does not exist here."
///
/// Deliberately excluded: `42883` (Postgres undefined_function). It can only
/// surface when PostgREST's schema cache and the database disagree, and its
/// deployed wire shape has not been verified against this backend — so it
/// fails closed like every other code until someone proves it.
const _postgrestMissingFunctionCode = 'PGRST202';

/// Whether [error] is one of the explicitly documented "V2 is not available
/// here yet" failures that may revive the V1 read:
///
/// - [PostgrestException] with code [_postgrestMissingFunctionCode]: the RPC
///   is missing/unsupported on this backend (pre-migration production).
/// - [SocketException] / [TimeoutException]: the request never got a
///   PostgREST answer at all (raw network transport failure).
///
/// Everything else — auth, permission (`42501`), backend-raised domain
/// errors (`P0001`), validation, rate-limit (`429`), server errors (5xx),
/// status-code-only fallbacks, code-less PostgREST errors, decoder failures,
/// and programming errors — is an answer from a live backend (or a client
/// bug) and must propagate so the UI fails closed instead of advertising a
/// V1 promotion the settlement path may no longer honor.
bool isEligibleV2FallbackError(Object error) {
  if (error is PostgrestException) {
    return error.code == _postgrestMissingFunctionCode;
  }
  return error is SocketException || error is TimeoutException;
}

/// Reads the V2 surface through the generated active provider (never the
/// repository directly, so overrides and its cache apply) and classifies the
/// outcome:
///
/// - Returns the decoded envelope on success (including a successful but
///   empty envelope — the caller decides what "zero items" means).
/// - Returns `null` only for [isEligibleV2FallbackError] failures — a
///   missing/unsupported V2 RPC (`PGRST202`) or a raw network transport
///   failure — the only errors this migration window treats as "V2 not
///   available yet."
/// - Rethrows everything else unchanged: auth/permission/domain/rate-limit/
///   server/unknown PostgREST answers, corrupt payloads
///   (`FormatException`/`CheckedFromJsonException`) and programming bugs
///   (`TypeError`, …) must fail closed, not silently revive V1 data that
///   could mask real drift.
Future<ActivePromotionCampaignsV2Model?> _readEligibleV2(
  Future<ActivePromotionCampaignsV2Model> Function() read,
) async {
  try {
    return await read();
  } catch (error) {
    if (isEligibleV2FallbackError(error)) return null;
    rethrow;
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
  // The V1 read RPC may aggregate every active STORE item; settlement still
  // only evaluates CANDY_BOOST_DAY, so any other campaign's badge would
  // advertise a bonus the purchase path cannot honor. Exact code or nothing.
  final item = v1.items
      .where((i) => i.code == _candyBoostDayCode && i.showInStore)
      .firstOrNull;
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
