import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign_v2.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_repository.dart';
import 'package:picnic_lib/data/repositories/promotion_campaign_v2_repository.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_campaign_v2_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class _FakeUser extends Fake implements User {
  _FakeUser(this.id);

  @override
  final String id;
}

final class _FakeSession extends Fake implements Session {
  _FakeSession(String userId) : user = _FakeUser(userId);

  @override
  final User user;
}

final class _MutableAuthGateway implements WalletAuthGateway {
  _MutableAuthGateway(String? userId)
    : _session = userId == null ? null : _FakeSession(userId);

  final _changes = StreamController<AuthState>.broadcast(sync: true);
  Session? _session;
  int subscriptions = 0;

  String? get userId => _session?.user.id;

  @override
  bool get isEnabled => true;

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> get authStateChanges async* {
    subscriptions++;
    final replayed = _session;
    if (replayed != null) {
      yield AuthState(AuthChangeEvent.signedIn, replayed);
    }
    yield* _changes.stream;
  }

  void emit(AuthChangeEvent event, String? userId) {
    _session = userId == null ? null : _FakeSession(userId);
    _changes.add(AuthState(event, _session));
  }

  Future<void> close() => _changes.close();
}

final class _ErroringAuthGateway implements WalletAuthGateway {
  _ErroringAuthGateway(String userId) : _session = _FakeSession(userId);

  final _changes = StreamController<AuthState>.broadcast(sync: true);
  Session? _session;

  @override
  bool get isEnabled => true;

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> get authStateChanges => _changes.stream;

  bool get hasListener => _changes.hasListener;

  void emitError(Object error) => _changes.addError(error, StackTrace.current);

  void emit(AuthChangeEvent event, String? userId) {
    _session = userId == null ? null : _FakeSession(userId);
    _changes.add(AuthState(event, _session));
  }

  Future<void> close() => _changes.close();
}

final class _DisabledAuthGateway implements WalletAuthGateway {
  @override
  bool get isEnabled => false;

  @override
  Session? get currentSession => throw StateError('must not read session');

  @override
  Stream<AuthState> get authStateChanges =>
      throw StateError('must not subscribe');
}

typedef _V1Request = ({
  String? userId,
  PromotionSurface surface,
  Completer<ActivePromotionCampaignsModel> completer,
});

final class _DelayedV1Repository extends PromotionCampaignRepository {
  _DelayedV1Repository(this.gateway)
    : super(SupabaseClient('http://localhost', 'key'));

  final _MutableAuthGateway gateway;
  final List<_V1Request> requests = [];

  @override
  Future<ActivePromotionCampaignsModel> getActive(PromotionSurface surface) {
    final completer = Completer<ActivePromotionCampaignsModel>();
    requests.add((
      userId: gateway.userId,
      surface: surface,
      completer: completer,
    ));
    return completer.future;
  }
}

typedef _V2Request = ({
  String? userId,
  PromotionSurfaceV2 surface,
  Completer<ActivePromotionCampaignsV2Model> completer,
});

final class _DelayedV2Repository extends PromotionCampaignV2Repository {
  _DelayedV2Repository(this.gateway)
    : super(SupabaseClient('http://localhost', 'key'));

  final _MutableAuthGateway gateway;
  final List<_V2Request> requests = [];

  @override
  Future<ActivePromotionCampaignsV2Model> getActive(
    PromotionSurfaceV2 surface,
  ) {
    final completer = Completer<ActivePromotionCampaignsV2Model>();
    requests.add((
      userId: gateway.userId,
      surface: surface,
      completer: completer,
    ));
    return completer.future;
  }
}

final class _SessionAwareV1Repository extends PromotionCampaignRepository {
  _SessionAwareV1Repository(this.userId)
    : super(SupabaseClient('http://localhost', 'key'));

  final String? Function() userId;
  final List<PromotionSurface> requests = [];

  @override
  Future<ActivePromotionCampaignsModel> getActive(PromotionSurface surface) {
    requests.add(surface);
    if (userId() == null) {
      return Future.error(
        const PostgrestException(
          message: 'WALLET_UNAUTHENTICATED',
          code: 'P0001',
        ),
      );
    }
    return Future.value(_v1Envelope('authenticated-${surface.name}'));
  }
}

final class _SessionAwareV2Repository extends PromotionCampaignV2Repository {
  _SessionAwareV2Repository(this.userId)
    : super(SupabaseClient('http://localhost', 'key'));

  final String? Function() userId;
  final List<PromotionSurfaceV2> requests = [];

  @override
  Future<ActivePromotionCampaignsV2Model> getActive(
    PromotionSurfaceV2 surface,
  ) {
    requests.add(surface);
    if (userId() == null) {
      return Future.error(
        const PostgrestException(
          message: 'WALLET_UNAUTHENTICATED',
          code: 'P0001',
        ),
      );
    }
    return Future.value(_v2Envelope('authenticated-${surface.name}'));
  }
}

ActivePromotionCampaignsModel _v1Envelope(String marker) =>
    ActivePromotionCampaignsModel.fromJson({
      'items': const [],
      'total_count': '0',
      'next_cursor': marker,
      'snapshot_at': '2026-09-08T00:00:00Z',
      'campaign_owned_home_banner_ids': const [],
    });

ActivePromotionCampaignsV2Model _v2Envelope(String marker) =>
    ActivePromotionCampaignsV2Model.fromJson({
      'items': const [],
      'total_count': '0',
      'next_cursor': marker,
      'snapshot_at': '2026-09-08T00:00:00Z',
      'campaign_owned_home_banner_ids': const [],
    });

Future<void> _flush() => pumpEventQueue(times: 20);

void main() {
  test(
    'logout short-circuits every V1 and V2 surface before unauthenticated RPC retries',
    () async {
      final gateway = _MutableAuthGateway('admin');
      addTearDown(gateway.close);
      final v1Repository = _SessionAwareV1Repository(() => gateway.userId);
      final v2Repository = _SessionAwareV2Repository(() => gateway.userId);
      final container = ProviderContainer(
        overrides: [
          walletAuthGatewayProvider.overrideWithValue(gateway),
          promotionCampaignRepositoryProvider.overrideWithValue(v1Repository),
          promotionCampaignV2RepositoryProvider.overrideWithValue(v2Repository),
        ],
      );
      addTearDown(container.dispose);
      final v1Home = activePromotionCampaignProvider(PromotionSurface.home);
      final v1Store = activePromotionCampaignProvider(PromotionSurface.store);
      final v2Home = activePromotionCampaignV2Provider(PromotionSurfaceV2.home);
      final v2Badge = activePromotionCampaignV2Provider(
        PromotionSurfaceV2.paymentBadge,
      );
      final subscriptions = [
        container.listen(v1Home, (_, _) {}),
        container.listen(v1Store, (_, _) {}),
        container.listen(v2Home, (_, _) {}),
        container.listen(v2Badge, (_, _) {}),
      ];
      for (final subscription in subscriptions) {
        addTearDown(subscription.close);
      }
      await _flush();

      expect(v1Repository.requests, hasLength(2));
      expect(v2Repository.requests, hasLength(2));

      gateway.emit(AuthChangeEvent.signedOut, null);
      await Future<void>.delayed(const Duration(milliseconds: 750));

      expect(
        v1Repository.requests,
        hasLength(2),
        reason: 'a known signed-out session must not call or retry the V1 RPC',
      );
      expect(
        v2Repository.requests,
        hasLength(2),
        reason: 'a known signed-out session must not call or retry the V2 RPC',
      );
      for (final state in [container.read(v1Home), container.read(v1Store)]) {
        expect(state.hasError, isFalse);
        expect(state.value?.items, isEmpty);
        expect(state.value?.campaignOwnedHomeBannerIds, isEmpty);
      }
      for (final state in [container.read(v2Home), container.read(v2Badge)]) {
        expect(state.hasError, isFalse);
        expect(state.value?.items, isEmpty);
        expect(state.value?.campaignOwnedHomeBannerIds, isEmpty);
      }
    },
  );

  test(
    'disabled auth gateway preserves repository-backed provider tests',
    () async {
      final v1Repository = _SessionAwareV1Repository(() => 'synthetic-user');
      final v2Repository = _SessionAwareV2Repository(() => 'synthetic-user');
      final container = ProviderContainer(
        overrides: [
          walletAuthGatewayProvider.overrideWithValue(_DisabledAuthGateway()),
          promotionCampaignRepositoryProvider.overrideWithValue(v1Repository),
          promotionCampaignV2RepositoryProvider.overrideWithValue(v2Repository),
        ],
      );
      addTearDown(container.dispose);

      final v1 = await container.read(
        activePromotionCampaignProvider(PromotionSurface.home).future,
      );
      final v2 = await container.read(
        activePromotionCampaignV2Provider(PromotionSurfaceV2.home).future,
      );

      expect(v1.nextCursor, 'authenticated-home');
      expect(v2.nextCursor, 'authenticated-home');
      expect(v1Repository.requests, [PromotionSurface.home]);
      expect(v2Repository.requests, [PromotionSurfaceV2.home]);
    },
  );

  test(
    'auth identity preserves state across stream errors then handles signout and login',
    () async {
      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        final gateway = _ErroringAuthGateway('admin');
        final container = ProviderContainer(
          overrides: [walletAuthGatewayProvider.overrideWithValue(gateway)],
        );

        expect(container.read(authSessionIdentityProvider), 'admin');
        expect(gateway.hasListener, isTrue);

        gateway.emitError(StateError('secret-access-token'));
        await _flush();
        expect(container.read(authSessionIdentityProvider), 'admin');

        gateway.emit(AuthChangeEvent.signedOut, null);
        await _flush();
        expect(container.read(authSessionIdentityProvider), isNull);

        gateway.emit(AuthChangeEvent.signedIn, 'normal');
        await _flush();
        expect(container.read(authSessionIdentityProvider), 'normal');

        container.dispose();
        expect(gateway.hasListener, isFalse);
        await gateway.close();
      }, (error, _) => uncaught.add(error));

      expect(
        uncaught,
        isEmpty,
        reason:
            'auth stream errors must be handled by the provider subscription',
      );
    },
  );

  test('V1 surfaces start fresh reads after signedOut to signedIn', () async {
    final gateway = _MutableAuthGateway(null);
    addTearDown(gateway.close);
    final repository = _DelayedV1Repository(gateway);
    final container = ProviderContainer(
      overrides: [
        walletAuthGatewayProvider.overrideWithValue(gateway),
        promotionCampaignRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final home = activePromotionCampaignProvider(PromotionSurface.home);
    final store = activePromotionCampaignProvider(PromotionSurface.store);
    final homeSubscription = container.listen(home, (_, _) {});
    final storeSubscription = container.listen(store, (_, _) {});
    addTearDown(homeSubscription.close);
    addTearDown(storeSubscription.close);
    await _flush();

    expect(
      repository.requests,
      isEmpty,
      reason: 'known signed-out state is terminal without an anonymous RPC',
    );
    expect(container.read(home).value?.items, isEmpty);
    expect(container.read(store).value?.items, isEmpty);

    gateway.emit(AuthChangeEvent.signedIn, 'admin');
    await _flush();

    expect(
      repository.requests,
      hasLength(2),
      reason: 'sign-in must start new session-scoped V1 surface reads',
    );
    expect(
      repository.requests.map((request) => request.surface),
      unorderedEquals([PromotionSurface.home, PromotionSurface.store]),
    );
    expect(repository.requests.map((request) => request.userId).toSet(), {
      'admin',
    });
    final adminRequests = List<_V1Request>.from(repository.requests);

    gateway.emit(AuthChangeEvent.signedIn, 'normal');
    await _flush();
    expect(repository.requests, hasLength(4));
    expect(
      repository.requests.skip(2).map((request) => request.surface),
      unorderedEquals([PromotionSurface.home, PromotionSurface.store]),
    );
    expect(
      repository.requests.skip(2).map((request) => request.userId).toSet(),
      {'normal'},
    );

    for (final request in adminRequests) {
      request.completer.complete(_v1Envelope('admin-${request.surface.name}'));
    }
    await _flush();
    expect(
      container.read(home).value?.nextCursor,
      isNot('admin-home'),
      reason: 'late prior-account HOME must not cross the identity boundary',
    );
    expect(
      container.read(store).value?.nextCursor,
      isNot('admin-store'),
      reason: 'late prior-account STORE must not cross the identity boundary',
    );

    for (final request in repository.requests.skip(2)) {
      request.completer.complete(_v1Envelope('normal-${request.surface.name}'));
    }
    await _flush();
    expect(container.read(home).value!.nextCursor, 'normal-home');
    expect(container.read(store).value!.nextCursor, 'normal-store');
  });

  test(
    'V2 keeps surfaces independent, isolates admin to normal switch, and ignores same-user replay',
    () async {
      final gateway = _MutableAuthGateway('admin');
      addTearDown(gateway.close);
      final repository = _DelayedV2Repository(gateway);
      final container = ProviderContainer(
        overrides: [
          walletAuthGatewayProvider.overrideWithValue(gateway),
          promotionCampaignV2RepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final home = activePromotionCampaignV2Provider(PromotionSurfaceV2.home);
      final badge = activePromotionCampaignV2Provider(
        PromotionSurfaceV2.paymentBadge,
      );
      final homeSubscription = container.listen(home, (_, _) {});
      final badgeSubscription = container.listen(badge, (_, _) {});
      addTearDown(homeSubscription.close);
      addTearDown(badgeSubscription.close);
      await _flush();

      expect(
        repository.requests.map((request) => request.surface),
        unorderedEquals([
          PromotionSurfaceV2.home,
          PromotionSurfaceV2.paymentBadge,
        ]),
      );
      final adminRequests = List<_V2Request>.from(repository.requests);

      gateway.emit(AuthChangeEvent.tokenRefreshed, 'admin');
      gateway.emit(AuthChangeEvent.signedIn, 'admin');
      await _flush();
      expect(
        repository.requests,
        hasLength(2),
        reason:
            'token updates and replayed signedIn for one user must not loop',
      );
      expect(gateway.subscriptions, 1);

      gateway.emit(AuthChangeEvent.signedIn, 'normal');
      await _flush();
      expect(repository.requests, hasLength(4));
      expect(
        repository.requests.skip(2).map((request) => request.surface),
        unorderedEquals([
          PromotionSurfaceV2.home,
          PromotionSurfaceV2.paymentBadge,
        ]),
        reason: 'both independently cached V2 surfaces must re-read',
      );
      expect(
        repository.requests.skip(2).map((request) => request.userId).toSet(),
        {'normal'},
      );

      for (final request in adminRequests) {
        request.completer.complete(
          _v2Envelope('admin-${request.surface.name}'),
        );
      }
      await _flush();
      expect(
        container.read(home).value?.nextCursor,
        isNot('admin-home'),
        reason: 'late admin HOME must not revive after the identity changed',
      );
      expect(
        container.read(badge).value?.nextCursor,
        isNot('admin-paymentBadge'),
        reason:
            'late admin PAYMENT_BADGE must not revive after the identity changed',
      );

      for (final request in repository.requests.skip(2)) {
        request.completer.complete(
          _v2Envelope('normal-${request.surface.name}'),
        );
      }
      await _flush();
      expect(container.read(home).value!.nextCursor, 'normal-home');
      expect(container.read(badge).value!.nextCursor, 'normal-paymentBadge');
    },
  );

  test(
    'ordinary banner reads ignore an old-account response without invalidating an unrelated location on same-user replay',
    () async {
      final gateway = _MutableAuthGateway('admin');
      addTearDown(gateway.close);
      final requests =
          <
            ({
              String? userId,
              http.BaseRequest request,
              Completer<http.Response> response,
            })
          >[];
      final client = MockClient((request) {
        final response = Completer<http.Response>();
        requests.add((
          userId: gateway.userId,
          request: request,
          response: response,
        ));
        return response.future;
      });
      testSupabaseClient = SupabaseClient(
        'http://localhost',
        'key',
        httpClient: client,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(() {
        testSupabaseClient = null;
        client.close();
      });
      final container = ProviderContainer(
        overrides: [walletAuthGatewayProvider.overrideWithValue(gateway)],
      );
      addTearDown(container.dispose);
      final vote = asyncBannerListProvider(location: 'vote_home');
      final pic = asyncBannerListProvider(location: 'pic_home');
      final voteSubscription = container.listen(vote, (_, _) {});
      final picSubscription = container.listen(pic, (_, _) {});
      addTearDown(voteSubscription.close);
      addTearDown(picSubscription.close);
      await _flush();

      expect(requests, hasLength(2));
      gateway.emit(AuthChangeEvent.signedIn, 'normal');
      await _flush();
      expect(
        requests,
        hasLength(4),
        reason:
            'all ordinary banner locations must cross the new identity boundary',
      );

      for (final request in requests.take(2)) {
        request.response.complete(
          http.Response(
            jsonEncode([
              {
                'id': 900,
                'title': {'en': 'admin-only'},
                'thumbnail': 'admin.jpg',
                'image': {'en': 'admin.jpg'},
                'duration': 3000,
                'link': null,
              },
            ]),
            200,
            request: request.request,
            headers: {
              'content-type': 'application/json',
              'content-range': '0-0/1',
            },
          ),
        );
      }
      await _flush();
      expect(
        container.read(vote).value?.map((banner) => banner.id),
        isNot(contains(900)),
      );
      expect(
        container.read(pic).value?.map((banner) => banner.id),
        isNot(contains(900)),
      );

      for (final request in requests.skip(2)) {
        final location = request.request.url.queryParameters['location']!;
        request.response.complete(
          http.Response(
            jsonEncode([
              {
                'id': location.contains('vote_home') ? 101 : 202,
                'title': {'en': 'normal'},
                'thumbnail': 'normal.jpg',
                'image': {'en': 'normal.jpg'},
                'duration': 3000,
                'link': null,
              },
            ]),
            200,
            request: request.request,
            headers: {
              'content-type': 'application/json',
              'content-range': '0-0/1',
            },
          ),
        );
      }
      final fresh = await Future.wait([
        container.read(vote.future),
        container.read(pic.future),
      ]);
      expect(fresh[0].single.id, 101);
      expect(fresh[1].single.id, 202);

      gateway.emit(AuthChangeEvent.tokenRefreshed, 'normal');
      await _flush();
      expect(requests, hasLength(4));
      expect(container.read(vote).value!.single.id, 101);
      expect(container.read(pic).value!.single.id, 202);
    },
  );
}
