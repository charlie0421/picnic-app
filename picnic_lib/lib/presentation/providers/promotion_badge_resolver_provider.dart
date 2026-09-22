import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

typedef PaymentBadgePromotionPeriod = ({DateTime startsAt, DateTime endsAt});

typedef ActiveBoostOccurrence = ({DateTime start, DateTime end});

/// Campaign day boundaries and the periods shown to users are defined in
/// KST (Asia/Seoul, UTC+9) regardless of device locale/timezone.
const _kstOffset = Duration(hours: 9);

/// Converts an absolute instant into a UTC-flagged [DateTime] whose
/// year/month/day/hour fields are the KST wall-clock reading — lets calendar
/// arithmetic (`.weekday`, day add/subtract) be done directly.
DateTime _kstWallClock(DateTime instant) => instant.toUtc().add(_kstOffset);

/// Inverse of [_kstWallClock]: turns a KST wall-clock reading back into the
/// real absolute instant it represents.
DateTime _fromKstWallClock(DateTime kstWallClock) =>
    kstWallClock.subtract(_kstOffset);

DateTime _kstDayStart(DateTime kstWallClock) =>
    DateTime.utc(kstWallClock.year, kstWallClock.month, kstWallClock.day);

/// Resolves the single contiguous run of KST calendar days — the "current
/// occurrence" — that contains [snapshotAt], clipped to the campaign
/// envelope's own bounds. Never returns the full recurring envelope.
///
/// [snapshotAt] must be a server-observed instant (e.g. the V2 envelope's
/// `snapshot_at`), never the device clock — a user can set their clock to
/// anything.
///
/// Returns `null` (no period — callers must not invent a next occurrence)
/// when:
/// - [snapshotAt] is before [eventStartsAt] (campaign hasn't started), or
/// - [snapshotAt] is at or after [eventEndsAt] (exclusive end — landing
///   exactly on the end means the campaign is no longer active), or
/// - [snapshotAt]'s KST calendar day is not one of [repeatIsoDows] (today is
///   an "off" day of the recurring pattern).
///
/// Otherwise walks outward day-by-day from [snapshotAt]'s KST calendar day
/// while the neighboring day is also in [repeatIsoDows], stopping at the
/// campaign envelope bounds. This is what keeps a run that crosses a
/// Sunday/Monday or month/year boundary contiguous — each day is compared
/// independently, with no special-casing of week/month/year edges.
///
/// A campaign repeating on all 7 ISO weekdays has no "off" day, so this walk
/// grows until it hits [eventStartsAt]/[eventEndsAt] on both sides: the
/// envelope itself is already a finite bound, so an every-day campaign
/// deliberately resolves to its whole (still finite) envelope rather than
/// needing a separate "continuous campaign" representation.
///
/// The first/last day of the resolved run are clipped to the actual
/// [eventStartsAt]/[eventEndsAt] instants, so a campaign that starts or ends
/// partway through a day never reports more than the campaign actually
/// covers.
ActiveBoostOccurrence? resolveActiveBoostOccurrence({
  required DateTime eventStartsAt,
  required DateTime eventEndsAt,
  required List<int> repeatIsoDows,
  required DateTime snapshotAt,
}) {
  final startKst = _kstWallClock(eventStartsAt);
  final endKst = _kstWallClock(eventEndsAt);
  final nowKst = _kstWallClock(snapshotAt);

  if (nowKst.isBefore(startKst) || !nowKst.isBefore(endKst)) return null;

  final todayStart = _kstDayStart(nowKst);
  if (!repeatIsoDows.contains(todayStart.weekday)) return null;

  final envelopeFirstDay = _kstDayStart(startKst);
  final endKstDayStart = _kstDayStart(endKst);
  final endIsPartialDay = endKst.isAfter(endKstDayStart);
  final envelopeExclusiveEndDay = endIsPartialDay
      ? endKstDayStart.add(const Duration(days: 1))
      : endKstDayStart;

  var streakStartDay = todayStart;
  while (true) {
    final candidate = streakStartDay.subtract(const Duration(days: 1));
    if (candidate.isBefore(envelopeFirstDay)) break;
    if (!repeatIsoDows.contains(candidate.weekday)) break;
    streakStartDay = candidate;
  }

  var streakEndDayExclusive = todayStart.add(const Duration(days: 1));
  while (true) {
    if (!streakEndDayExclusive.isBefore(envelopeExclusiveEndDay)) break;
    if (!repeatIsoDows.contains(streakEndDayExclusive.weekday)) break;
    streakEndDayExclusive = streakEndDayExclusive.add(const Duration(days: 1));
  }

  final occurrenceStartKst = streakStartDay.isAfter(startKst)
      ? streakStartDay
      : startKst;
  final occurrenceEndKst = streakEndDayExclusive.isBefore(endKst)
      ? streakEndDayExclusive
      : endKst;

  return (
    start: _fromKstWallClock(occurrenceStartKst),
    end: _fromKstWallClock(occurrenceEndKst),
  );
}

/// Returns only a settled resolver value for display.
///
/// Riverpod retains the previous value during refresh/loading and failed
/// refreshes. Promotion UI must fail closed in those states: advertising the
/// retained value could promise a campaign that the current resolution no
/// longer authorizes.
ResolvedPaymentBadgePromotion? paymentBadgePromotionForDisplay(
  AsyncValue<ResolvedPaymentBadgePromotion?> resolution,
) => resolution.unwrapPrevious().value;

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

/// Looks up the CANDY_BOOST_DAY item in [v2] and, if present, resolves its
/// currently active occurrence against [v2]'s own server `snapshot_at`
/// (never the device clock).
///
/// Returns `null` both when no matching item exists and when one exists but
/// today is not one of its active days (or the envelope hasn't started /
/// already ended) — either way, the badge must not advertise a bonus the
/// purchase path is not currently honoring.
({ActivePromotionCampaignV2Model item, ActiveBoostOccurrence occurrence})?
_activeV2CandyBoost(ActivePromotionCampaignsV2Model v2) {
  final item = v2.items.where((i) => i.code == _candyBoostDayCode).firstOrNull;
  if (item == null) return null;
  final occurrence = resolveActiveBoostOccurrence(
    eventStartsAt: item.eventStartsAt,
    eventEndsAt: item.eventEndsAt,
    repeatIsoDows: item.repeatIsoDows,
    snapshotAt: v2.snapshotAt,
  );
  if (occurrence == null) return null;
  return (item: item, occurrence: occurrence);
}

@riverpod
Future<ResolvedPaymentBadgePromotion?> paymentBadgePromotion(Ref ref) async {
  final v2 = await _readEligibleV2(
    () => ref.watch(
      activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge).future,
    ),
  );
  if (v2 != null && v2.items.isNotEmpty) {
    final active = _activeV2CandyBoost(v2);
    if (active == null) return null;
    return (
      displayName: active.item.displayName,
      code: active.item.code,
      multiplierTenths: active.item.multiplierTenths,
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

final paymentBadgePromotionPeriodProvider =
    FutureProvider.autoDispose<PaymentBadgePromotionPeriod?>((ref) async {
      final v2 = await _readEligibleV2(
        () => ref.watch(
          activePromotionCampaignV2Provider(
            PromotionSurfaceV2.paymentBadge,
          ).future,
        ),
      );
      if (v2 != null && v2.items.isNotEmpty) {
        final active = _activeV2CandyBoost(v2);
        if (active == null) return null;
        return (
          startsAt: active.occurrence.start,
          endsAt: active.occurrence.end,
        );
      }

      final v1 = await ref.watch(
        activePromotionCampaignProvider(PromotionSurface.store).future,
      );
      final item = v1.items
          .where((item) => item.code == _candyBoostDayCode && item.showInStore)
          .firstOrNull;
      if (item == null) return null;
      return (startsAt: item.windowStartsAt, endsAt: item.windowEndsAt);
    });

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
