import 'dart:async';
import 'dart:io';

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
}) => {
  'campaign_id': '55555555-5555-4555-8555-555555555555',
  'campaign_version_id': '66666666-6666-4666-8666-666666666666',
  'code': code,
  'display_name': {'ko': '결제 배지 부스트', 'en': 'Payment Badge Boost'},
  'multiplier_tenths': multiplierTenths,
  'event_starts_at': '2026-09-07T00:00:00+09:00',
  'event_ends_at': '2026-09-14T00:00:00+09:00',
  'repeat_iso_dows': [2, 4, 6],
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
}
