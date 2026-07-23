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

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _HistoryRepository extends WalletRepository {
  _HistoryRepository() : super(_UnusedSupabaseClient());

  final calls = <WalletCurrency>[];

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) async {
    calls.add(currency);
    final delta = switch (currency) {
      WalletCurrency.cottonCandy => BigInt.from(30),
      _ => BigInt.from(-10),
    };
    return CurrencyHistoryPageModel(
      items: [
        CurrencyHistoryItemModel(
          id: currency.wireValue,
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
      nextCursor: null,
      snapshotAt: DateTime.utc(2026, 7, 23),
    );
  }
}

void main() {
  setUpAll(initTestColors);

  testWidgets('shows three currencies in wallet order and switches history', (
    tester,
  ) async {
    final repository = _HistoryRepository();
    await tester.pumpWidget(
      buildTestApp(
        const CurrencyHistoryPage(),
        extraOverrides: [
          walletRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('스타캔디'), findsOneWidget);
    expect(find.text('보너스 스타캔디'), findsOneWidget);
    expect(find.text('코튼캔디'), findsOneWidget);
    expect(find.text('-10'), findsOneWidget);

    await tester.tap(find.text('코튼캔디'));
    await tester.pumpAndSettle();

    expect(find.text('+30'), findsOneWidget);
    final list = find.byType(Scrollable).last;
    ScrollEndNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 0,
        pixels: 0,
        viewportDimension: 600,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: tester.element(list),
    ).dispatch(tester.element(list));
    await tester.pump();
    expect(
      repository.calls.where(
        (currency) => currency == WalletCurrency.cottonCandy,
      ),
      hasLength(1),
    );
  });
}
