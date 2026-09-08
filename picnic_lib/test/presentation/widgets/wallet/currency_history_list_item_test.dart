import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
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

  testWidgets('shows public transaction details without internal metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        CurrencyHistoryListItem(item: _item(delta: BigInt.from(30))),
      ),
    );

    expect(find.text('+30'), findsOneWidget);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CurrencyHistoryListItem)),
    );
    expect(find.text(l10n.wallet_cotton_candy), findsOneWidget);
    expect(find.textContaining('2026.07.23'), findsOneWidget);
    expect(
      find.textContaining(l10n.bonus_candy_expiration_policy_expiration_date),
      findsOneWidget,
    );
    expect(find.textContaining('operation-123'), findsNothing);
    expect(find.textContaining('VOTE'), findsNothing);
    expect(find.text('general_vote'), findsNothing);
    expect(find.textContaining('Support:'), findsNothing);
  });

  testWidgets('keeps the minus sign for debits', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        CurrencyHistoryListItem(item: _item(delta: BigInt.from(-10))),
      ),
    );

    expect(find.text('-10'), findsOneWidget);
  });

  // The panel above this list renders 1,300 while a row rendered 1300, so the
  // same balance was shown two ways in one flow. Group digits here as well.
  testWidgets('groups digits like every other wallet surface', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        CurrencyHistoryListItem(item: _item(delta: BigInt.from(1300))),
      ),
    );

    expect(find.text('+1,300'), findsOneWidget);
  });

  testWidgets('groups digits for debits too', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        CurrencyHistoryListItem(item: _item(delta: BigInt.from(-1234567))),
      ),
    );

    expect(find.text('-1,234,567'), findsOneWidget);
  });
}
