import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/currency_history_page.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';
import '../../../helpers/mock_data.dart';

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _HistoryUser extends Fake implements User {
  _HistoryUser([this.id = 'test-user-id']);
  @override
  final String id;
}

class _HistorySession extends Fake implements Session {
  _HistorySession([String owner = 'test-user-id']) : user = _HistoryUser(owner);
  @override
  final User user;
}

class _HistoryAuth extends Fake implements WalletAuthGateway {
  @override
  bool get isEnabled => true;
  @override
  Session get currentSession => _HistorySession();
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
}

class _MutableHistoryAuth extends Fake implements WalletAuthGateway {
  final events = StreamController<AuthState>.broadcast(sync: true);
  Session? session = _HistorySession();

  @override
  bool get isEnabled => true;
  @override
  Session? get currentSession => session;
  @override
  Stream<AuthState> get authStateChanges => events.stream;

  void signIn(bool signedIn, {String owner = 'test-user-id'}) {
    session = signedIn ? _HistorySession(owner) : null;
    events.add(
      AuthState(
        signedIn ? AuthChangeEvent.signedIn : AuthChangeEvent.signedOut,
        session,
      ),
    );
  }
}

class _HistoryRepository extends WalletRepository {
  _HistoryRepository() : super(_UnusedSupabaseClient());

  final calls = <WalletCurrency>[];
  bool failFirst = false;
  bool hasNext = false;
  bool failNext = false;
  bool stallFirst = false;
  bool stallNext = false;
  final cursors = <String?>[];

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) async {
    calls.add(currency);
    cursors.add(cursor);
    if (failFirst) {
      failFirst = false;
      throw const PostgrestException(message: 'offline');
    }
    if (cursor != null && failNext) {
      failNext = false;
      throw const PostgrestException(message: 'next page offline');
    }
    if ((cursor == null && stallFirst) || (cursor != null && stallNext)) {
      return Completer<CurrencyHistoryPageModel>().future;
    }
    final delta = switch (currency) {
      WalletCurrency.cottonCandy => BigInt.from(30),
      _ => BigInt.from(-10),
    };
    return CurrencyHistoryPageModel(
      items: [
        CurrencyHistoryItemModel(
          id: '${currency.wireValue}:${cursor ?? 'first'}',
          currency: currency,
          eventType: 'TEST',
          origin: 'widget_test',
          delta: delta,
          balanceEffect: delta,
          operationId: 'operation-${currency.wireValue}',
          createdAt: DateTime.utc(2026, 7, 23),
        ),
      ],
      totalCount: BigInt.one,
      nextCursor: hasNext && cursor == null ? 'next' : null,
      snapshotAt: DateTime.utc(2026, 7, 23),
    );
  }
}

void main() {
  setUpAll(initTestColors);

  testWidgets('an owner mismatch hides rows while the profile catches up', (
    tester,
  ) async {
    final repository = _HistoryRepository();
    final auth = _MutableHistoryAuth();
    addTearDown(auth.events.close);
    await tester.pumpWidget(
      buildTestApp(
        const CurrencyHistoryPage(),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(auth),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+30'), findsOneWidget);

    auth.signIn(true, owner: 'another-user');
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('+30'), findsNothing);
    // The still-subscribed provider can begin one read for the new auth
    // owner before Flutter unmounts it. Neither owner's rows may be shown
    // while the profile and auth session disagree, and no reads repeat.
    final callsAfterSwitch = repository.calls.length;
    expect(callsAfterSwitch, lessThanOrEqualTo(2));
    await tester.pump(const Duration(seconds: 30));
    expect(repository.calls.length, callsAfterSwitch);
    expect(find.text('+30'), findsNothing);
  });

  testWidgets(
    'a stalled first page reaches manual retry without automatic requests',
    (tester) async {
      final repository = _HistoryRepository()..stallFirst = true;
      await tester.pumpWidget(
        buildTestApp(
          const CurrencyHistoryPage(),
          extraOverrides: [
            walletRepositoryProvider.overrideWithValue(repository),
            walletAuthGatewayProvider.overrideWithValue(_HistoryAuth()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 7));
      await tester.pump();
      final retry = find.byKey(const Key('currency-history-retry'));
      expect(retry, findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(repository.calls, [WalletCurrency.cottonCandy]);
      repository.stallFirst = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('+30'), findsOneWidget);
      expect(repository.calls.length, 2);
    },
  );

  testWidgets('a stalled next page keeps rows and unlocks manual retry', (
    tester,
  ) async {
    final repository = _HistoryRepository()
      ..hasNext = true
      ..stallNext = true;
    await tester.pumpWidget(
      buildTestApp(
        const CurrencyHistoryPage(),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(_HistoryAuth()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final next = find.byKey(const Key('currency-history-next'));
    await tester.tap(next);
    await tester.pump(const Duration(seconds: 7));
    await tester.pump();
    expect(find.text('+30'), findsOneWidget);
    expect(
      find.byKey(const Key('currency-history-next-error')),
      findsOneWidget,
    );
    repository.stallNext = false;
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(repository.cursors, [null, 'next', 'next']);
    expect(find.text('+30'), findsNWidgets(2));
  });

  testWidgets('selected tab matches data after the session is restored', (
    tester,
  ) async {
    final repository = _HistoryRepository();
    final auth = _MutableHistoryAuth();
    addTearDown(auth.events.close);
    await tester.pumpWidget(
      buildTestApp(
        const CurrencyHistoryPage(),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(auth),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('보너스 스타캔디'));
    await tester.pumpAndSettle();

    auth.signIn(false);
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
    auth.signIn(true);
    await tester.pumpAndSettle();

    final controller = DefaultTabController.of(
      tester.element(find.byType(TabBar)),
    );
    expect(controller.index, 2);
    expect(repository.calls.last, WalletCurrency.bonusStarCandy);
    expect(find.text('-10'), findsOneWidget);
  });

  testWidgets(
    'regular user opens cotton history and loads only the selected currency',
    (tester) async {
      final repository = _HistoryRepository();
      await tester.pumpWidget(
        buildTestApp(
          const CurrencyHistoryPage(),
          userProfile: MockData.userProfile(isAdmin: false),
          extraOverrides: [
            walletRepositoryProvider.overrideWithValue(repository),
            walletAuthGatewayProvider.overrideWithValue(_HistoryAuth()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('스타캔디'), findsOneWidget);
      expect(find.text('보너스 스타캔디'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(TabBar), matching: find.text('코튼캔디')),
        findsOneWidget,
      );
      expect(find.text('+30'), findsOneWidget);
      expect(repository.calls, [WalletCurrency.cottonCandy]);

      await tester.tap(find.text('보너스 스타캔디'));
      await tester.pumpAndSettle();

      expect(repository.calls, [
        WalletCurrency.cottonCandy,
        WalletCurrency.bonusStarCandy,
      ]);
      expect(find.text('-10'), findsOneWidget);

      final content = tester.widget<Padding>(
        find.byKey(const Key('currency-history-content')),
      );
      expect(content.padding, const EdgeInsets.symmetric(horizontal: 16));
    },
  );

  testWidgets('does not request history for a logged-out user', (tester) async {
    final repository = _HistoryRepository();
    await tester.pumpWidget(
      buildTestApp(
        const CurrencyHistoryPage(),
        loggedIn: false,
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('스타캔디'), findsNothing);
    expect(repository.calls, isEmpty);
  });

  testWidgets('first-page failure offers a working retry', (tester) async {
    final repository = _HistoryRepository()..failFirst = true;
    await tester.pumpWidget(
      buildTestApp(
        const CurrencyHistoryPage(),
        userProfile: MockData.userProfile(isAdmin: false),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(_HistoryAuth()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.byKey(const Key('currency-history-retry'));
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(repository.calls, [
      WalletCurrency.cottonCandy,
      WalletCurrency.cottonCandy,
    ]);
    expect(find.text('+30'), findsOneWidget);
  });

  testWidgets('next-page failure keeps items and offers retry', (tester) async {
    final repository = _HistoryRepository()
      ..hasNext = true
      ..failNext = true;
    await tester.pumpWidget(
      buildTestApp(
        const CurrencyHistoryPage(),
        userProfile: MockData.userProfile(isAdmin: false),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(repository),
          walletAuthGatewayProvider.overrideWithValue(_HistoryAuth()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-history-next')));
    await tester.pumpAndSettle();
    expect(find.text('+30'), findsOneWidget);
    expect(
      find.byKey(const Key('currency-history-next-error')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('currency-history-next')));
    await tester.pumpAndSettle();
    expect(repository.cursors, [null, 'next', 'next']);
    expect(find.text('+30'), findsNWidgets(2));
    expect(find.byKey(const Key('currency-history-next')), findsNothing);
  });

  testWidgets(
    'pull-to-refresh failure stays in the error UI without an uncaught future',
    (tester) async {
      final repository = _HistoryRepository();
      await tester.pumpWidget(
        buildTestApp(
          const CurrencyHistoryPage(),
          userProfile: MockData.userProfile(isAdmin: false),
          extraOverrides: [
            walletRepositoryProvider.overrideWithValue(repository),
            walletAuthGatewayProvider.overrideWithValue(_HistoryAuth()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      repository.failFirst = true;
      final indicator = tester.state<RefreshIndicatorState>(
        find.byType(RefreshIndicator),
      );
      final refresh = indicator.show();
      await tester.pumpAndSettle();
      await refresh;
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('currency-history-retry')), findsOneWidget);
    },
  );
}
