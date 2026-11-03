import 'dart:async';
import 'dart:io';

// This file constructs Riverpod's retained-previous composite states to prove
// promotion display fails closed during real refresh/error transitions.
// ignore_for_file: invalid_use_of_internal_member

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_v2_repository.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_v2_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _v2HomeItem({
  String code = 'CANDY_BOOST_V2',
  Map<String, dynamic> title = const {'ko': '부스트 배너', 'en': 'Boost banner'},
  Map<String, dynamic> image = const {
    'ko': 'https://cdn.picnic.fan/boost.png',
  },
  int bannerId = 501,
}) => {
  'campaign_id': '33333333-3333-4333-8333-333333333333',
  'campaign_version_id': '44444444-4444-4444-8444-444444444444',
  'code': code,
  'display_name': {'ko': '추석 캔디 부스트', 'en': 'Chuseok Candy Boost'},
  'multiplier_tenths': 15,
  'event_starts_at': '2026-09-07T00:00:00+09:00',
  'event_ends_at': '2026-09-14T00:00:00+09:00',
  'repeat_iso_dows': [1, 3, 5],
  'home_creative': {
    'banner_id': bannerId,
    'title': title,
    'image': image,
    'thumbnail': null,
    'link': null,
    'duration': 4000,
  },
};

Map<String, dynamic> _v2HomeEnvelope({
  List<Map<String, dynamic>> items = const [],
  List<int> ownedIds = const [],
}) => {
  'items': items,
  'total_count': '${items.length}',
  'next_cursor': null,
  'snapshot_at': '2026-09-07T00:10:00Z',
  'campaign_owned_home_banner_ids': ownedIds,
};

ActivePromotionCampaignsV2Model _v2Home({
  List<Map<String, dynamic>> items = const [],
  List<int> ownedIds = const [],
}) => ActivePromotionCampaignsV2Model.fromJson(
  _v2HomeEnvelope(items: items, ownedIds: ownedIds),
);

Map<String, dynamic> _v2BadgeItem({
  String code = 'CANDY_BOOST_DAY',
  int multiplierTenths = 15,
  // Every day active by default so these fixtures exercise code
  // selection/fallback behavior without also depending on the envelope's
  // `snapshot_at` (2026-09-07T00:10:00Z, a Monday) landing on an active
  // weekday. Bounded-occurrence gating itself is covered by dedicated
  // tests in the 'active occurrence gating' group below.
  List<int> repeatIsoDows = const [1, 2, 3, 4, 5, 6, 7],
}) => {
  'campaign_id': '55555555-5555-4555-8555-555555555555',
  'campaign_version_id': '66666666-6666-4666-8666-666666666666',
  'code': code,
  'display_name': {'ko': '결제 배지 부스트', 'en': 'Payment Badge Boost'},
  'multiplier_tenths': multiplierTenths,
  'event_starts_at': '2026-09-07T00:00:00+09:00',
  'event_ends_at': '2026-09-14T00:00:00+09:00',
  'repeat_iso_dows': repeatIsoDows,
  'home_creative': null,
};

ActivePromotionCampaignsV2Model _v2Badge({
  List<Map<String, dynamic>> items = const [],
}) => ActivePromotionCampaignsV2Model.fromJson({
  'items': items,
  'total_count': '${items.length}',
  'next_cursor': null,
  'snapshot_at': '2026-09-07T00:10:00Z',
  'campaign_owned_home_banner_ids': <int>[],
});

Map<String, dynamic> _v1Item({
  String code = 'CANDY_BOOST_DAY',
  bool showInStore = true,
  int extraBonusBps = 10000,
}) => {
  'campaign_id': 'campaign-$code',
  'campaign_version_id': 'version-$code',
  'code': code,
  'display_name': {'en': 'Campaign $code', 'ko': '캠페인 $code'},
  'extra_bonus_bps': extraBonusBps,
  'window_starts_at': '2026-07-21T00:00:00Z',
  'window_ends_at': '2026-07-22T00:00:00Z',
  'show_in_store': showInStore,
  'show_home_banner': true,
  'home_creative': {
    'banner_id': 101,
    'title': {'en': 'V1 creative', 'ko': 'V1 크리에이티브'},
    'image': {'en': 'https://example.com/v1.jpg'},
    'thumbnail': null,
    'link': null,
    'duration': 3500,
  },
};

ActivePromotionCampaignsModel _v1Store(List<Map<String, dynamic>> items) =>
    ActivePromotionCampaignsModel.fromJson({
      'items': items,
      'total_count': '${items.length}',
      'next_cursor': null,
      'snapshot_at': '2026-07-21T00:00:00Z',
      'campaign_owned_home_banner_ids': <int>[],
    });

ActivePromotionCampaignsModel _v1Home({bool active = true}) =>
    ActivePromotionCampaignsModel.fromJson({
      'items': active
          ? [
              {
                'campaign_id': 'campaign',
                'campaign_version_id': 'version',
                'code': 'CANDY_BOOST_DAY',
                'display_name': {'en': 'Candy Boost Day', 'ko': '캔디 부스트 데이'},
                'extra_bonus_bps': 10000,
                'window_starts_at': '2026-07-21T00:00:00Z',
                'window_ends_at': '2026-07-22T00:00:00Z',
                'show_in_store': true,
                'show_home_banner': true,
                'home_creative': {
                  'banner_id': 101,
                  'title': {'en': 'V1 creative', 'ko': 'V1 크리에이티브'},
                  'image': {'en': 'https://example.com/v1.jpg'},
                  'thumbnail': null,
                  'link': null,
                  'duration': 3500,
                },
              },
            ]
          : <Map<String, dynamic>>[],
      'total_count': active ? '1' : '0',
      'next_cursor': null,
      'snapshot_at': '2026-07-21T00:00:00Z',
      'campaign_owned_home_banner_ids': active ? [101] : <int>[],
    });

/// An error-capable fake for the repository behind the real generated
/// `activePromotionCampaignV2Provider` family — the stable dependency seam
/// for error-path composition tests. Overriding the keepAlive repository
/// provider (the same pattern as `promotion_campaign_v2_provider_test.dart`)
/// keeps the production chain intact: the resolver still consumes the active
/// provider family, whose real build runs and surfaces this throw.
class _ThrowingV2Repository extends PromotionCampaignV2Repository {
  _ThrowingV2Repository(this.error)
    : super(SupabaseClient('http://localhost', 'key'));
  final Object error;
  final List<PromotionSurfaceV2> requests = [];

  @override
  Future<ActivePromotionCampaignsV2Model> getActive(
    PromotionSurfaceV2 surface,
  ) async {
    requests.add(surface);
    throw error;
  }
}

// riverpod 3's public barrel does not export `Override` by name, so this
// helper takes a dynamic list rather than naming a type it cannot spell.
//
// Retry is disabled: riverpod 3's `ProviderContainer.defaultRetry` retries
// any thrown `Exception` (not `Error`) up to 10 times with real exponential
// backoff timers. Under test that leaves an erroring autoDispose provider
// parked in a retrying loading state holding a pending `Timer`, and
// disposing it then completes its internal future with an orphaned
// "disposed during loading state, yet no value could be emitted"
// `StateError` that fails the test after its own expectations passed.
// Disabling retry makes every thrown error reach its terminal `AsyncError`
// state immediately and deterministically.
ProviderContainer _container(List<dynamic> overrides) {
  final container = ProviderContainer(
    overrides: overrides.cast(),
    retry: (retryCount, error) => null,
  );
  addTearDown(container.dispose);
  return container;
}

Future<Object?> _errorFrom(Future<void> future) async {
  try {
    await future;
    return null;
  } catch (e) {
    return e;
  }
}

void main() {
  group('isEligibleV2FallbackError', () {
    final cases = <({String label, Object error, bool eligible})>[
      // Positive: the one documented PostgREST "function is missing" code —
      // PGRST202, "Could not find the function in the schema cache" — plus
      // the two accepted raw network transport failures.
      (
        label: 'PGRST202 missing/unsupported RPC',
        error: PostgrestException(
          message:
              'Could not find the function '
              'public.get_active_promotion_campaigns_v2(p_surface) '
              'in the schema cache',
          code: 'PGRST202',
        ),
        eligible: true,
      ),
      (
        label: 'SocketException network transport failure',
        error: const SocketException('connection refused'),
        eligible: true,
      ),
      (
        label: 'TimeoutException network transport failure',
        error: TimeoutException('rpc timed out'),
        eligible: true,
      ),
      // Negative: every other PostgREST outcome is an answer from a live
      // backend (auth, permission, domain, validation, rate-limit, server
      // error, unknown) and must fail closed instead of reviving V1.
      (
        label: '42501 permission denied',
        error: PostgrestException(
          message: 'permission denied for function',
          code: '42501',
        ),
        eligible: false,
      ),
      (
        label: 'P0001 backend-raised domain error',
        error: PostgrestException(
          message: 'WALLET_UNAUTHENTICATED',
          code: 'P0001',
        ),
        eligible: false,
      ),
      (
        label: '42883 undefined_function (wire shape unverified, fail closed)',
        error: PostgrestException(
          message: 'function does not exist',
          code: '42883',
        ),
        eligible: false,
      ),
      (
        label: '404 status-code fallback (non-JSON error body)',
        error: PostgrestException(message: 'Not Found', code: '404'),
        eligible: false,
      ),
      (
        label: '429 rate limit',
        error: PostgrestException(message: 'Too Many Requests', code: '429'),
        eligible: false,
      ),
      (
        label: '500 server error',
        error: PostgrestException(
          message: 'Internal Server Error',
          code: '500',
        ),
        eligible: false,
      ),
      (
        label: 'PostgrestException without a code',
        error: PostgrestException(message: 'undefined function'),
        eligible: false,
      ),
      (
        label: 'FormatException decoder failure',
        error: const FormatException('contract key drift'),
        eligible: false,
      ),
      (
        label: 'CheckedFromJsonException decoder failure',
        error: CheckedFromJsonException(
          const {},
          'event_starts_at',
          '_ActivePromotionCampaignV2Model',
          'bad shape',
        ),
        eligible: false,
      ),
      (label: 'TypeError programming error', error: TypeError(), eligible: false),
      (
        label: 'generic programming exception',
        error: Exception('boom'),
        eligible: false,
      ),
      (
        label: 'StateError programming error',
        error: StateError('bug'),
        eligible: false,
      ),
    ];

    for (final c in cases) {
      test('${c.eligible ? 'eligible' : 'not eligible'}: ${c.label}', () {
        expect(isEligibleV2FallbackError(c.error), c.eligible);
      });
    }
  });

  group('homePromotionCampaign', () {
    test('V2 active item with readable creative is authoritative', () async {
      final container = _container([
        activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
            .overrideWith(
              (ref) async => _v2Home(items: [_v2HomeItem()], ownedIds: [501]),
            ),
        activePromotionCampaignProvider(PromotionSurface.home).overrideWith(
          (ref) async =>
              throw StateError('V1 must not be read when V2 has active items'),
        ),
      ]);
      final result = await container.read(
        homePromotionCampaignProvider('en').future,
      );
      expect(result.slides, hasLength(1));
      expect(result.slides.single.bannerId, 501);
      expect(result.ownedBannerIds, {501});
    });

    test(
      'V2 active item with unreadable creative renders no slide but keeps V2 ownership',
      () async {
        final container = _container([
          activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
              .overrideWith(
                (ref) async => _v2Home(
                  items: [
                    _v2HomeItem(
                      title: const {},
                      image: const {},
                      bannerId: 501,
                    ),
                  ],
                  ownedIds: [501, 502],
                ),
              ),
          activePromotionCampaignProvider(PromotionSurface.home).overrideWith(
            (ref) async => throw StateError(
              'V1 must not be read when V2 has active items, readable or not',
            ),
          ),
        ]);
        final result = await container.read(
          homePromotionCampaignProvider('en').future,
        );
        expect(result.slides, isEmpty);
        expect(result.ownedBannerIds, {501, 502});
      },
    );

    test(
      'V2 succeeding with zero items falls back to V1 and unions ownership',
      () async {
        final container = _container([
          activePromotionCampaignV2Provider(
            PromotionSurfaceV2.home,
          ).overrideWith((ref) async => _v2Home(ownedIds: [501])),
          activePromotionCampaignProvider(
            PromotionSurface.home,
          ).overrideWith((ref) async => _v1Home()),
        ]);
        final result = await container.read(
          homePromotionCampaignProvider('en').future,
        );
        expect(result.slides, hasLength(1));
        expect(result.slides.single.bannerId, 101);
        // Union: V1's owned id (101) plus V2's still-immutable owned id (501)
        // from the dark-launch envelope, so a real HOME banner is not shown
        // as an ordinary (unfiltered) row on either side.
        expect(result.ownedBannerIds, {101, 501});
      },
    );

    test(
      'V2 missing-RPC error (PGRST202) falls back to V1 with V1-only ownership',
      () async {
        final repository = _ThrowingV2Repository(
          PostgrestException(
            message:
                'Could not find the function '
                'public.get_active_promotion_campaigns_v2(p_surface) '
                'in the schema cache',
            code: 'PGRST202',
          ),
        );
        final container = _container([
          promotionCampaignV2RepositoryProvider.overrideWithValue(repository),
          activePromotionCampaignProvider(
            PromotionSurface.home,
          ).overrideWith((ref) async => _v1Home()),
        ]);
        final states = <AsyncValue<HomePromotionResolution>>[];
        final subscription = container.listen(
          homePromotionCampaignProvider('en'),
          (_, next) => states.add(next),
        );
        addTearDown(subscription.close);
        final result = await container.read(
          homePromotionCampaignProvider('en').future,
        );
        expect(result.slides, hasLength(1));
        expect(result.ownedBannerIds, {101});
        // The real generated V2 provider build ran against the throwing
        // repository — the fallback came from classifying its error, not
        // from bypassing the source chain.
        expect(repository.requests, [PromotionSurfaceV2.home]);
        expect(states.last.hasValue, isTrue);
      },
    );

    test(
      'V2 throwing FormatException fails closed and never reads V1',
      () async {
        var v1Read = false;
        final container = _container([
          activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
              .overrideWith(
                (ref) async =>
                    throw const FormatException('contract key drift'),
              ),
          activePromotionCampaignProvider(PromotionSurface.home).overrideWith((
            ref,
          ) async {
            v1Read = true;
            throw StateError('V1 must not be read on decoder failure');
          }),
        ]);
        final error = await _errorFrom(
          container.read(homePromotionCampaignProvider('en').future),
        );
        expect(error, isA<FormatException>());
        expect(v1Read, isFalse);
      },
    );

    test('V2 throwing TypeError fails closed and never reads V1', () async {
      var v1Read = false;
      final container = _container([
        activePromotionCampaignV2Provider(
          PromotionSurfaceV2.home,
        ).overrideWith((ref) async => throw TypeError()),
        activePromotionCampaignProvider(PromotionSurface.home).overrideWith((
          ref,
        ) async {
          v1Read = true;
          throw StateError('V1 must not be read on a programming error');
        }),
      ]);
      final error = await _errorFrom(
        container.read(homePromotionCampaignProvider('en').future),
      );
      expect(error, isA<TypeError>());
      expect(v1Read, isFalse);
    });

    test(
      'V2 throwing CheckedFromJsonException fails closed and never reads V1',
      () async {
        var v1Read = false;
        final container = _container([
          activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
              .overrideWith(
                (ref) async => throw CheckedFromJsonException(
                  const {},
                  'event_starts_at',
                  '_ActivePromotionCampaignV2Model',
                  'bad shape',
                ),
              ),
          activePromotionCampaignProvider(PromotionSurface.home).overrideWith((
            ref,
          ) async {
            v1Read = true;
            throw StateError('V1 must not be read on decoder failure');
          }),
        ]);
        final error = await _errorFrom(
          container.read(homePromotionCampaignProvider('en').future),
        );
        expect(error, isA<CheckedFromJsonException>());
        expect(v1Read, isFalse);
      },
    );

    test('HOME and PAYMENT_BADGE source reads are independent', () async {
      final container = _container([
        activePromotionCampaignV2Provider(PromotionSurfaceV2.home)
            .overrideWith(
              (ref) async => _v2Home(items: [_v2HomeItem()], ownedIds: [501]),
            ),
        activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
            .overrideWith(
              (ref) async =>
                  throw StateError('HOME resolution must not touch badge'),
            ),
        activePromotionCampaignProvider(PromotionSurface.home).overrideWith(
          (ref) async => throw StateError('V1 must not be read'),
        ),
      ]);
      final result = await container.read(
        homePromotionCampaignProvider('en').future,
      );
      expect(result.slides, hasLength(1));
    });
  });

  group('paymentBadgePromotion', () {
    test('selects the item whose code is exactly CANDY_BOOST_DAY', () async {
      final container = _container([
        activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
            .overrideWith(
              (ref) async => _v2Badge(
                items: [
                  _v2BadgeItem(code: 'SOME_OTHER_CAMPAIGN'),
                  _v2BadgeItem(code: 'CANDY_BOOST_DAY', multiplierTenths: 20),
                ],
              ),
            ),
        activePromotionCampaignProvider(PromotionSurface.store).overrideWith(
          (ref) async =>
              throw StateError('V1 must not be read when V2 has items'),
        ),
      ]);
      final resolved = await container.read(
        paymentBadgePromotionProvider.future,
      );
      expect(resolved, isNotNull);
      expect(resolved!.code, 'CANDY_BOOST_DAY');
      expect(resolved.multiplierTenths, 20);
      expect(resolved.extraBonusBps, isNull);
    });

    test(
      'V2 active but with no CANDY_BOOST_DAY item resolves to no badge without falling back',
      () async {
        final container = _container([
          activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
              .overrideWith(
                (ref) async => _v2Badge(
                  items: [_v2BadgeItem(code: 'CANDY_BOOST_V2_BADGE')],
                ),
              ),
          activePromotionCampaignProvider(PromotionSurface.store).overrideWith(
            (ref) async => throw StateError(
              'V1 must not be read when V2 is active but non-matching',
            ),
          ),
        ]);
        final resolved = await container.read(
          paymentBadgePromotionProvider.future,
        );
        expect(resolved, isNull);
      },
    );

    test('V2 succeeding with zero items falls back to V1', () async {
      final container = _container([
        activePromotionCampaignV2Provider(
          PromotionSurfaceV2.paymentBadge,
        ).overrideWith((ref) async => _v2Badge()),
        activePromotionCampaignProvider(
          PromotionSurface.store,
        ).overrideWith((ref) async => _v1Home()),
      ]);
      final resolved = await container.read(
        paymentBadgePromotionProvider.future,
      );
      expect(resolved, isNotNull);
      expect(resolved!.code, 'CANDY_BOOST_DAY');
      expect(resolved.multiplierTenths, isNull);
      expect(resolved.extraBonusBps, 10000);
    });

    test(
      'V2 missing-RPC error (PGRST202) falls back to V1',
      () async {
        final repository = _ThrowingV2Repository(
          PostgrestException(
            message:
                'Could not find the function '
                'public.get_active_promotion_campaigns_v2(p_surface) '
                'in the schema cache',
            code: 'PGRST202',
          ),
        );
        final container = _container([
          promotionCampaignV2RepositoryProvider.overrideWithValue(repository),
          activePromotionCampaignProvider(
            PromotionSurface.store,
          ).overrideWith((ref) async => _v1Home()),
        ]);
        final states = <AsyncValue<ResolvedPaymentBadgePromotion?>>[];
        final subscription = container.listen(
          paymentBadgePromotionProvider,
          (_, next) => states.add(next),
        );
        addTearDown(subscription.close);
        final resolved = await container.read(
          paymentBadgePromotionProvider.future,
        );
        expect(resolved, isNotNull);
        expect(resolved!.code, 'CANDY_BOOST_DAY');
        expect(resolved.extraBonusBps, 10000);
        expect(repository.requests, [PromotionSurfaceV2.paymentBadge]);
        expect(states.last.hasValue, isTrue);
      },
    );

    test(
      'V2 permission-denied PostgREST error (42501) propagates and never '
      'reads V1',
      () async {
        var v1Read = false;
        final repository = _ThrowingV2Repository(
          PostgrestException(
            message: 'permission denied for function',
            code: '42501',
          ),
        );
        final container = _container([
          promotionCampaignV2RepositoryProvider.overrideWithValue(repository),
          activePromotionCampaignProvider(PromotionSurface.store).overrideWith((
            ref,
          ) async {
            v1Read = true;
            throw StateError('V1 must not be read on a permission failure');
          }),
        ]);
        final error = await _errorFrom(
          container.read(paymentBadgePromotionProvider.future),
        );
        expect(error, isA<PostgrestException>());
        expect((error as PostgrestException?)?.code, '42501');
        expect(v1Read, isFalse);
      },
    );

    test(
      'V2 backend-raised domain error (P0001) propagates and never reads V1',
      () async {
        var v1Read = false;
        final repository = _ThrowingV2Repository(
          PostgrestException(message: 'WALLET_UNAUTHENTICATED', code: 'P0001'),
        );
        final container = _container([
          promotionCampaignV2RepositoryProvider.overrideWithValue(repository),
          activePromotionCampaignProvider(PromotionSurface.store).overrideWith((
            ref,
          ) async {
            v1Read = true;
            throw StateError('V1 must not be read on a domain error');
          }),
        ]);
        final error = await _errorFrom(
          container.read(paymentBadgePromotionProvider.future),
        );
        expect(error, isA<PostgrestException>());
        expect((error as PostgrestException?)?.code, 'P0001');
        expect(v1Read, isFalse);
      },
    );

    test(
      'V2 code-less PostgREST error propagates and never reads V1',
      () async {
        var v1Read = false;
        final repository = _ThrowingV2Repository(
          PostgrestException(message: 'undefined function'),
        );
        final container = _container([
          promotionCampaignV2RepositoryProvider.overrideWithValue(repository),
          activePromotionCampaignProvider(PromotionSurface.store).overrideWith((
            ref,
          ) async {
            v1Read = true;
            throw StateError('V1 must not be read on an unclassified error');
          }),
        ]);
        final error = await _errorFrom(
          container.read(paymentBadgePromotionProvider.future),
        );
        expect(error, isA<PostgrestException>());
        expect(v1Read, isFalse);
      },
    );

    test(
      'V2 server error (500) propagates on HOME and never reads V1',
      () async {
        var v1Read = false;
        final repository = _ThrowingV2Repository(
          PostgrestException(message: 'Internal Server Error', code: '500'),
        );
        final container = _container([
          promotionCampaignV2RepositoryProvider.overrideWithValue(repository),
          activePromotionCampaignProvider(PromotionSurface.home).overrideWith((
            ref,
          ) async {
            v1Read = true;
            throw StateError('V1 must not be read on a server error');
          }),
        ]);
        final error = await _errorFrom(
          container.read(homePromotionCampaignProvider('en').future),
        );
        expect(error, isA<PostgrestException>());
        expect((error as PostgrestException?)?.code, '500');
        expect(v1Read, isFalse);
      },
    );

    test('V2 throwing FormatException fails closed and never reads V1', () async {
      var v1Read = false;
      final container = _container([
        activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
            .overrideWith(
              (ref) async =>
                  throw const FormatException('contract key drift'),
            ),
        activePromotionCampaignProvider(PromotionSurface.store).overrideWith((
          ref,
        ) async {
          v1Read = true;
          throw StateError('V1 must not be read on decoder failure');
        }),
      ]);
      final error = await _errorFrom(
        container.read(paymentBadgePromotionProvider.future),
      );
      expect(error, isA<FormatException>());
      expect(v1Read, isFalse);
    });

    test(
      'V1 fallback selects the exact CANDY_BOOST_DAY code even when another '
      'STORE campaign is ordered first',
      () async {
        final container = _container([
          activePromotionCampaignV2Provider(
            PromotionSurfaceV2.paymentBadge,
          ).overrideWith((ref) async => _v2Badge()),
          activePromotionCampaignProvider(PromotionSurface.store).overrideWith(
            (ref) async => _v1Store([
              // The V1 read RPC may aggregate every active STORE item ordered
              // by code; settlement only honors CANDY_BOOST_DAY, so the
              // resolver must never advertise the first arbitrary item.
              _v1Item(code: 'AAA_OTHER_CAMPAIGN', extraBonusBps: 2500),
              _v1Item(code: 'CANDY_BOOST_DAY', extraBonusBps: 10000),
            ]),
          ),
        ]);
        final resolved = await container.read(
          paymentBadgePromotionProvider.future,
        );
        expect(resolved, isNotNull);
        expect(resolved!.code, 'CANDY_BOOST_DAY');
        expect(resolved.extraBonusBps, 10000);
      },
    );

    test(
      'V1 fallback with only non-target STORE campaigns resolves to no badge',
      () async {
        final container = _container([
          activePromotionCampaignV2Provider(
            PromotionSurfaceV2.paymentBadge,
          ).overrideWith((ref) async => _v2Badge()),
          activePromotionCampaignProvider(PromotionSurface.store).overrideWith(
            (ref) async => _v1Store([
              _v1Item(code: 'AAA_OTHER_CAMPAIGN', extraBonusBps: 2500),
              _v1Item(code: 'CANDY_BOOST_DAY', showInStore: false),
            ]),
          ),
        ]);
        final resolved = await container.read(
          paymentBadgePromotionProvider.future,
        );
        expect(resolved, isNull);
      },
    );

    test('V1 fallback surfaces exact-double copy via extraBonusBps', () async {
      final container = _container([
        activePromotionCampaignV2Provider(
          PromotionSurfaceV2.paymentBadge,
        ).overrideWith((ref) async => _v2Badge()),
        activePromotionCampaignProvider(
          PromotionSurface.store,
        ).overrideWith((ref) async => _v1Home()),
      ]);
      final resolved = await container.read(
        paymentBadgePromotionProvider.future,
      );
      expect(resolved!.extraBonusBps, 10000);
      expect(resolved.multiplierTenths, isNull);
    });

    test('V1 error propagates when V2 is eligible-empty and V1 also fails', () async {
      final container = _container([
        activePromotionCampaignV2Provider(
          PromotionSurfaceV2.paymentBadge,
        ).overrideWith((ref) async => _v2Badge()),
        activePromotionCampaignProvider(PromotionSurface.store).overrideWith(
          (ref) async => throw PostgrestException(message: 'v1 unavailable'),
        ),
      ]);
      final error = await _errorFrom(
        container.read(paymentBadgePromotionProvider.future),
      );
      // V2 was eligible-empty (no active item), so V1 is read as normal and
      // its own failure is expected to surface rather than resolve to a
      // value — it must not be silently swallowed into `null`.
      expect(error, isNotNull);
    });
  });

  group('paymentBadgePromotion / period active occurrence gating', () {
    // The envelope's snapshot_at fixed above is 2026-09-07T00:10:00Z, which
    // is 2026-09-07 09:10 KST — a Monday (ISO weekday 1).
    test(
      'badge and period both resolve to null when today is not a repeat '
      'weekday, without falling back to V1',
      () async {
        final container = _container([
          activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
              .overrideWith(
                (ref) async => _v2Badge(
                  items: [
                    _v2BadgeItem(repeatIsoDows: const [2, 4, 6]), // Tue/Thu/Sat
                  ],
                ),
              ),
          activePromotionCampaignProvider(PromotionSurface.store).overrideWith(
            (ref) async => throw StateError(
              'V1 must not be read when V2 has an active-envelope item',
            ),
          ),
        ]);
        final resolved = await container.read(
          paymentBadgePromotionProvider.future,
        );
        expect(resolved, isNull);
        final period = await container.read(
          paymentBadgePromotionPeriodProvider.future,
        );
        expect(period, isNull);
      },
    );

    test(
      'badge and period both resolve when today is a repeat weekday, '
      'reporting only the bounded occurrence rather than the full envelope',
      () async {
        final container = _container([
          activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
              .overrideWith(
                (ref) async => _v2Badge(
                  items: [
                    _v2BadgeItem(repeatIsoDows: const [1, 3, 5]), // Mon/Wed/Fri
                  ],
                ),
              ),
        ]);
        final resolved = await container.read(
          paymentBadgePromotionProvider.future,
        );
        expect(resolved, isNotNull);
        expect(resolved!.code, 'CANDY_BOOST_DAY');
        final period = await container.read(
          paymentBadgePromotionPeriodProvider.future,
        );
        expect(period, isNotNull);
        // Envelope is 2026-09-07T00:00:00+09:00..2026-09-14T00:00:00+09:00;
        // Monday Sep7 is the only leading active day before Tuesday Sep8
        // breaks the run, so the bounded occurrence is just that one day —
        // not the full week-long envelope.
        expect(period!.startsAt, DateTime.parse('2026-09-06T15:00:00Z'));
        expect(period.endsAt, DateTime.parse('2026-09-07T15:00:00Z'));
      },
    );
  });

  group('localizedPromotionDisplayName', () {
    test('prefers the requested locale', () {
      expect(
        localizedPromotionDisplayName(
          {'ko': '한국어', 'en': 'English'},
          'en',
          fallbackCode: 'CODE',
        ),
        'English',
      );
    });

    test('falls back to Korean when the requested locale is absent', () {
      expect(
        localizedPromotionDisplayName(
          {'ko': '한국어'},
          'vi',
          fallbackCode: 'CODE',
        ),
        '한국어',
      );
    });

    test(
      'falls back to the campaign code when locale and Korean are both absent',
      () {
        // Only [locale, 'ko'] are checked — matching V1's original behavior
        // exactly, an 'en' entry is not an implicit third fallback.
        expect(
          localizedPromotionDisplayName(
            {'en': 'English only'},
            'vi',
            fallbackCode: 'CODE',
          ),
          'CODE',
        );
        expect(
          localizedPromotionDisplayName({}, 'vi', fallbackCode: 'CODE'),
          'CODE',
        );
      },
    );
  });

  group('payment badge display state', () {
    const selected = (
      displayName: {'ko': 'V2 캔디 부스트'},
      code: 'CANDY_BOOST_DAY',
      multiplierTenths: 15,
      extraBonusBps: null,
    );

    test('exposes only a settled data value', () {
      expect(
        paymentBadgePromotionForDisplay(const AsyncData(selected)),
        selected,
      );
      expect(
        paymentBadgePromotionForDisplay(
          const AsyncData<ResolvedPaymentBadgePromotion?>(null),
        ),
        isNull,
      );
    });

    test('fails closed for loading and error even when they retain old data', () {
      const previous = AsyncData<ResolvedPaymentBadgePromotion?>(selected);
      final refreshing = const AsyncLoading<ResolvedPaymentBadgePromotion?>()
          .copyWithPrevious(previous);
      final failedRefresh = AsyncError<ResolvedPaymentBadgePromotion?>(
        StateError('resolver failed'),
        StackTrace.empty,
      ).copyWithPrevious(previous);

      // Prove these fixtures really contain stale Riverpod data; a raw
      // `.value` consumer would advertise it during both transitional states.
      expect(refreshing.value, selected);
      expect(failedRefresh.value, selected);

      for (final state in <AsyncValue<ResolvedPaymentBadgePromotion?>>[
        const AsyncLoading(),
        AsyncError(StateError('resolver failed'), StackTrace.empty),
        refreshing,
        failedRefresh,
      ]) {
        expect(paymentBadgePromotionForDisplay(state), isNull);
      }
    });
  });

  group('candyBoostExpiryWatcherProvider', () {
    // A fixed, arbitrary "server now" reused across these fixtures so a
    // fake-time delay elapsed from container creation lines up with the
    // server-relative delay the watcher computes from snapshot_at.
    final baseSnapshot = DateTime.utc(2026, 9, 7, 0, 10);

    ActivePromotionCampaignsV2Model v2EndingIn(
      Duration delay, {
      DateTime? snapshotAt,
    }) {
      final snapshot = snapshotAt ?? baseSnapshot;
      return ActivePromotionCampaignsV2Model.fromJson({
        'items': [
          {
            'campaign_id': '55555555-5555-4555-8555-555555555555',
            'campaign_version_id': '66666666-6666-4666-8666-666666666666',
            'code': 'CANDY_BOOST_DAY',
            'display_name': {'ko': '결제 배지 부스트', 'en': 'Payment Badge Boost'},
            'multiplier_tenths': 15,
            'event_starts_at': '2026-09-01T00:00:00Z',
            'event_ends_at': snapshot.add(delay).toIso8601String(),
            'repeat_iso_dows': [1, 2, 3, 4, 5, 6, 7],
            'home_creative': null,
          },
        ],
        'total_count': '1',
        'next_cursor': null,
        'snapshot_at': snapshot.toIso8601String(),
        'campaign_owned_home_banner_ids': <int>[],
      });
    }

    ActivePromotionCampaignsModel v1EndingIn(
      Duration delay, {
      DateTime? snapshotAt,
    }) {
      final snapshot = snapshotAt ?? baseSnapshot;
      return ActivePromotionCampaignsModel.fromJson({
        'items': [
          {
            'campaign_id': 'campaign-v1',
            'campaign_version_id': 'version-v1',
            'code': 'CANDY_BOOST_DAY',
            'display_name': {'en': 'Candy Boost Day', 'ko': '캔디 부스트 데이'},
            'extra_bonus_bps': 10000,
            'window_starts_at': '2026-07-20T00:00:00Z',
            'window_ends_at': snapshot.add(delay).toIso8601String(),
            'show_in_store': true,
            'show_home_banner': true,
            'home_creative': null,
          },
        ],
        'total_count': '1',
        'next_cursor': null,
        'snapshot_at': snapshot.toIso8601String(),
        'campaign_owned_home_banner_ids': <int>[],
      });
    }

    ActivePromotionCampaignsModel v1Empty({DateTime? snapshotAt}) =>
        ActivePromotionCampaignsModel.fromJson({
          'items': <Map<String, dynamic>>[],
          'total_count': '0',
          'next_cursor': null,
          'snapshot_at': (snapshotAt ?? baseSnapshot).toIso8601String(),
          'campaign_owned_home_banner_ids': <int>[],
        });

    test(
      'a foreground expiry timer fires when the active V2 occurrence ends, '
      'invalidating both sources so the badge fails closed without resume '
      'or pull-to-refresh',
      () {
        fakeAsync((async) {
          var v2Calls = 0;
          var v1Calls = 0;
          final container = _container([
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
                .overrideWith((ref) async {
                  v2Calls++;
                  return v2Calls == 1
                      ? v2EndingIn(const Duration(seconds: 30))
                      : _v2Badge();
                }),
            activePromotionCampaignProvider(PromotionSurface.store)
                .overrideWith((ref) async {
                  v1Calls++;
                  return v1Empty();
                }),
          ]);
          addTearDown(() {});
          final watcherSub = container.listen(
            candyBoostExpiryWatcherProvider,
            (_, _) {},
          );
          addTearDown(watcherSub.close);
          final badgeSub = container.listen(
            paymentBadgePromotionProvider,
            (_, _) {},
          );
          addTearDown(badgeSub.close);

          async.flushMicrotasks();
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNotNull,
            reason: 'the occurrence is active before expiry',
          );
          expect(v2Calls, 1);
          expect(
            v1Calls,
            0,
            reason: 'V2 has an item, so V1 must never be read while it is '
                'authoritative',
          );

          // Elapse past the 30s server-relative boundary.
          async.elapse(const Duration(seconds: 31));

          expect(
            v2Calls,
            2,
            reason: 'the timer must invalidate and re-fetch the V2 source',
          );
          expect(
            v1Calls,
            greaterThanOrEqualTo(1),
            reason: 'the timer must invalidate and re-fetch the V1 source '
                'too, even though it was not the displayed source',
          );
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNull,
            reason: 'the badge must fail closed once the occurrence is over',
          );
        });
      },
    );

    test(
      'V1 fallback also expires on its own foreground timer, preventing a '
      'stale cached V1 window from continuing to display',
      () {
        fakeAsync((async) {
          var v2Calls = 0;
          var v1Calls = 0;
          final container = _container([
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
                .overrideWith((ref) async {
                  v2Calls++;
                  return _v2Badge(); // V2 never has the item: V1 is authoritative.
                }),
            activePromotionCampaignProvider(PromotionSurface.store)
                .overrideWith((ref) async {
                  v1Calls++;
                  return v1Calls == 1
                      ? v1EndingIn(const Duration(seconds: 20))
                      : v1Empty();
                }),
          ]);
          final watcherSub = container.listen(
            candyBoostExpiryWatcherProvider,
            (_, _) {},
          );
          addTearDown(watcherSub.close);
          final badgeSub = container.listen(
            paymentBadgePromotionProvider,
            (_, _) {},
          );
          addTearDown(badgeSub.close);

          async.flushMicrotasks();
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNotNull,
            reason: 'the V1 window is active before expiry',
          );
          expect(v1Calls, 1);

          async.elapse(const Duration(seconds: 21));

          expect(
            v1Calls,
            2,
            reason: 'the timer must invalidate and re-fetch V1',
          );
          expect(
            v2Calls,
            greaterThanOrEqualTo(2),
            reason: 'the timer must invalidate V2 as well',
          );
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNull,
            reason:
                'a stale, already-ended V1 window must not keep displaying',
          );
        });
      },
    );

    test(
      'a slower, unrelated V1 read completing after V2 is already active '
      'does not reschedule (and thus does not drift) the V2-anchored timer',
      () {
        fakeAsync((async) {
          var v2Calls = 0;
          var v1Calls = 0;
          final container = _container([
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
                .overrideWith((ref) async {
                  v2Calls++;
                  return v2Calls == 1
                      ? v2EndingIn(const Duration(seconds: 30))
                      : _v2Badge();
                }),
            // V1 must not be read while V2 is still authoritative (before
            // the 30s boundary) — if the watcher watched it anyway, a slow
            // read finishing here would rebuild the watcher and restart the
            // same 30s delay from this later moment, pushing the real
            // deadline out. Once V2's occurrence actually ends (after the
            // boundary), consulting V1 as the fallback is legitimate.
            activePromotionCampaignProvider(
              PromotionSurface.store,
            ).overrideWith((ref) async {
              v1Calls++;
              return v1Empty();
            }),
          ]);
          final watcherSub = container.listen(
            candyBoostExpiryWatcherProvider,
            (_, _) {},
          );
          addTearDown(watcherSub.close);
          final badgeSub = container.listen(
            paymentBadgePromotionProvider,
            (_, _) {},
          );
          addTearDown(badgeSub.close);

          async.flushMicrotasks();
          expect(v2Calls, 1);
          expect(v1Calls, 0);

          // Simulate time passing without V2 changing — the timer must still
          // fire at the original 30s boundary, not later.
          async.elapse(const Duration(seconds: 29));
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNotNull,
            reason: 'not yet at the 30s boundary',
          );
          expect(
            v1Calls,
            0,
            reason: 'still before the 30s boundary - V2 remains '
                'authoritative and V1 must stay unread',
          );

          async.elapse(const Duration(seconds: 2));
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNull,
            reason: 'the original 30s-from-snapshot deadline must still be '
                'honored, undrifted',
          );
        });
      },
    );

    test(
      'V1 is not watched while V2 is still loading, even if V1 itself '
      'would resolve quickly, and only gets consulted once V2 settles empty',
      () {
        fakeAsync((async) {
          var v2Calls = 0;
          var v1Calls = 0;
          final container = _container([
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
                .overrideWith((ref) async {
                  v2Calls++;
                  // A slow V2 read (10s): still loading at the 5s check
                  // below, settled eligible-empty well before the 15s V1
                  // window would end.
                  await Future<void>.delayed(const Duration(seconds: 10));
                  return _v2Badge();
                }),
            activePromotionCampaignProvider(PromotionSurface.store)
                .overrideWith((ref) async {
                  v1Calls++;
                  return v1EndingIn(const Duration(seconds: 15));
                }),
          ]);
          final watcherSub = container.listen(
            candyBoostExpiryWatcherProvider,
            (_, _) {},
          );
          addTearDown(watcherSub.close);

          // V1 would resolve on the very next microtask if it were ever
          // watched, but V2 is still (deliberately) stuck loading.
          async.elapse(const Duration(seconds: 5));
          expect(v2Calls, 1);
          expect(
            v1Calls,
            0,
            reason:
                'V1 must not be read while V2 has not settled - watching it '
                'here would let it resolve first and schedule a timer '
                'against a source V2 may not even need once it settles',
          );

          // V2 finally settles as eligible-empty; only now is V1 consulted,
          // anchored to a snapshot taken at this moment, not to whenever V1
          // would otherwise have resolved.
          async.elapse(const Duration(seconds: 6));
          expect(v1Calls, 1);

          async.elapse(const Duration(seconds: 16));
          expect(
            v1Calls,
            2,
            reason: 'the V1-anchored timer must still fire on its own 15s '
                'boundary from the moment V1 was actually read',
          );
        });
      },
    );

    test(
      'a source that already reports a zero/past-end delay is left '
      'unscheduled instead of spinning a Timer.zero invalidate loop',
      () {
        fakeAsync((async) {
          var v2Calls = 0;
          var v1Calls = 0;
          final container = _container([
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
                .overrideWith((ref) async {
                  v2Calls++;
                  return _v2Badge();
                }),
            activePromotionCampaignProvider(PromotionSurface.store)
                .overrideWith((ref) async {
                  v1Calls++;
                  // The window's own snapshot already reports it as over.
                  return v1EndingIn(const Duration(seconds: -5));
                }),
          ]);
          final watcherSub = container.listen(
            candyBoostExpiryWatcherProvider,
            (_, _) {},
          );
          addTearDown(watcherSub.close);

          // A small elapse (not just a microtask flush) lets the full
          // initial chain settle: V2 resolves empty, which is itself what
          // first causes V1 to be read.
          async.elapse(const Duration(seconds: 1));
          final v2CallsAfterInitialBuild = v2Calls;
          final callsAfterInitialBuild = v1Calls;
          expect(
            callsAfterInitialBuild,
            1,
            reason: 'sanity check: V1 has been read exactly once by now',
          );

          // If a Timer.zero loop were scheduled, elapsing any amount of time
          // would keep re-invoking the override indefinitely.
          async.elapse(const Duration(minutes: 5));

          expect(
            v2Calls,
            v2CallsAfterInitialBuild,
            reason:
                'an unscheduled timer must not invalidate V2 either - '
                'nothing should re-fetch at all',
          );
          expect(
            v1Calls,
            callsAfterInitialBuild,
            reason:
                'an already-past delay must not schedule an immediate-fire '
                'timer that spins invalidate/refetch forever',
          );
        });
      },
    );

    test(
      'closing the last listener (screen dispose) cancels the pending '
      'timer so it never fires',
      () {
        fakeAsync((async) {
          var v2Calls = 0;
          final container = _container([
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
                .overrideWith((ref) async {
                  v2Calls++;
                  return v2EndingIn(const Duration(seconds: 30));
                }),
            activePromotionCampaignProvider(
              PromotionSurface.store,
            ).overrideWith((ref) async => v1Empty()),
          ]);
          final watcherSub = container.listen(
            candyBoostExpiryWatcherProvider,
            (_, _) {},
          );

          async.flushMicrotasks();
          expect(v2Calls, 1);

          watcherSub.close();
          async.flushMicrotasks();

          async.elapse(const Duration(seconds: 31));
          expect(
            v2Calls,
            1,
            reason:
                'disposing the watcher (no more listeners) must cancel the '
                'pending timer, not merely stop new scheduling',
          );
        });
      },
    );

    test(
      'a fresh, shorter occurrence reschedules the timer to the new '
      'boundary instead of keeping the old one',
      () {
        fakeAsync((async) {
          var v2Calls = 0;
          final container = _container([
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
                .overrideWith((ref) async {
                  v2Calls++;
                  // The first read reports 60s remaining; before that fires,
                  // the surface is force-invalidated (e.g. by resume) and
                  // the second read reports only 10s remaining from a later
                  // snapshot. The rescheduled timer's own expiry then
                  // triggers a third read, by which point the occurrence is
                  // over.
                  switch (v2Calls) {
                    case 1:
                      return v2EndingIn(const Duration(seconds: 60));
                    case 2:
                      return v2EndingIn(
                        const Duration(seconds: 10),
                        snapshotAt: baseSnapshot.add(const Duration(seconds: 5)),
                      );
                    default:
                      return _v2Badge();
                  }
                }),
            activePromotionCampaignProvider(
              PromotionSurface.store,
            ).overrideWith((ref) async => v1Empty()),
          ]);
          final watcherSub = container.listen(
            candyBoostExpiryWatcherProvider,
            (_, _) {},
          );
          addTearDown(watcherSub.close);
          final badgeSub = container.listen(
            paymentBadgePromotionProvider,
            (_, _) {},
          );
          addTearDown(badgeSub.close);

          async.flushMicrotasks();
          expect(v2Calls, 1);

          // 5 real seconds pass, then something else forces a re-fetch that
          // reveals a much sooner boundary (15s from the original snapshot,
          // i.e. 10s from the new one).
          async.elapse(const Duration(seconds: 5));
          container.invalidate(
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge),
          );
          // Force the now-dirty provider to rebuild eagerly, the way a
          // widget's next `ref.watch` in `build()` would.
          container.read(
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge),
          );
          // Force the watcher itself (and the derived
          // paymentBadgePromotionProvider) to rebuild against the freshly
          // re-fetched source too.
          container.read(candyBoostExpiryWatcherProvider);
          container.read(paymentBadgePromotionProvider);
          async.elapse(const Duration(seconds: 1));
          expect(v2Calls, 2);
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNotNull,
            reason: 'still active per the fresh, shorter occurrence',
          );

          // The fresh occurrence ends 15s after the original snapshot (10s
          // after the new one); 9 more seconds lands just past that. The old
          // 60s-from-first-snapshot deadline would still be far off here, so
          // this only passes if the timer actually rescheduled to the new,
          // sooner boundary.
          async.elapse(const Duration(seconds: 9));
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNull,
            reason:
                'the timer must have rescheduled to the new, sooner boundary',
          );
          expect(
            v2Calls,
            3,
            reason:
                'the rescheduled (not the original) timer must be the one '
                'that fired and triggered this third, expiry-revealing read',
          );
        });
      },
    );

    test(
      'resume/pull-to-refresh style invalidation still recovers the boost '
      'when a new occurrence becomes active, independent of the timer',
      () {
        fakeAsync((async) {
          var v2Calls = 0;
          final container = _container([
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge)
                .overrideWith((ref) async {
                  v2Calls++;
                  // Not active on the first read (e.g. an off day); resume
                  // invalidation later reveals it has become active.
                  return v2Calls == 1
                      ? _v2Badge(
                          items: [
                            _v2BadgeItem(repeatIsoDows: const [2, 4, 6]),
                          ],
                        )
                      : v2EndingIn(const Duration(seconds: 30));
                }),
            activePromotionCampaignProvider(
              PromotionSurface.store,
            ).overrideWith((ref) async => v1Empty()),
          ]);
          final watcherSub = container.listen(
            candyBoostExpiryWatcherProvider,
            (_, _) {},
          );
          addTearDown(watcherSub.close);
          final badgeSub = container.listen(
            paymentBadgePromotionProvider,
            (_, _) {},
          );
          addTearDown(badgeSub.close);

          async.flushMicrotasks();
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNull,
            reason: 'not a repeat weekday on the first read',
          );

          // What `_refreshCandyBoostBoundary` (resume / pull-to-refresh)
          // does: invalidate the V2 and V1 sources directly.
          container.invalidate(
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge),
          );
          container.invalidate(
            activePromotionCampaignProvider(PromotionSurface.store),
          );
          // Force the now-dirty providers to rebuild eagerly, the way a
          // widget's next `ref.watch` in `build()` would.
          container.read(
            activePromotionCampaignV2Provider(PromotionSurfaceV2.paymentBadge),
          );
          container.read(activePromotionCampaignProvider(PromotionSurface.store));
          // Let the derived paymentBadgePromotionProvider settle against the
          // freshly re-fetched sources too.
          async.elapse(const Duration(milliseconds: 1));

          expect(v2Calls, 2);
          expect(
            paymentBadgePromotionForDisplay(
              container.read(paymentBadgePromotionProvider),
            ),
            isNotNull,
            reason:
                'resume-style invalidation must reveal the now-active '
                'occurrence without waiting for any timer',
          );
        });
      },
    );
  });
}
