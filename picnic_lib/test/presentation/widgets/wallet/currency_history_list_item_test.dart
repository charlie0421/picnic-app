import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/presentation/widgets/wallet/currency_history_list_item.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

CurrencyHistoryItemModel _item({required BigInt delta}) =>
    CurrencyHistoryItemModel(
      id: 'history-1',
      currency: WalletCurrency.cottonCandy,
      eventType: 'VOTE',
      origin: 'general_vote',
      delta: delta,
      balanceEffect: delta,
      expiresAt: DateTime.utc(2026, 8, 1),
      operationId: 'operation-123',
      createdAt: DateTime.utc(2026, 7, 23, 9, 30),
    );

void main() {
  setUpAll(initTestColors);

  testWidgets('renders signed delta and support reference', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        CurrencyHistoryListItem(item: _item(delta: BigInt.from(30))),
      ),
    );

    expect(find.text('+30'), findsOneWidget);
    expect(find.textContaining('operation-123'), findsOneWidget);
    expect(find.textContaining('VOTE'), findsOneWidget);
    expect(find.text('general_vote'), findsOneWidget);
  });

  testWidgets('keeps the minus sign for debits', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        CurrencyHistoryListItem(item: _item(delta: BigInt.from(-10))),
      ),
    );

    expect(find.text('-10'), findsOneWidget);
  });
}
