import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/wallet/wallet_summary_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

class _WalletRepository extends WalletRepository {
  _WalletRepository(this.summary) : super(_UnusedClient());
  final WalletSummaryModel summary;

  @override
  Future<WalletSummaryModel> getSummary() async => summary;

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

void main() {
  setUp(initTestColors);

  testWidgets(
    'shows all localized currencies, precise amounts and server expiry',
    (tester) async {
      final summary = WalletSummaryModel(
        contractVersion: 'wallet.v1',
        star: BigInt.parse('9007199254740993'),
        bonus: BigInt.from(20),
        cotton: BigInt.from(30),
        cottonExpiringAmount: BigInt.from(10),
        cottonNextExpiresAt: DateTime.utc(2026, 7, 24, 3, 30),
        snapshotAt: DateTime.utc(2026, 7, 23),
      );
      await tester.pumpWidget(
        buildTestApp(
          const WalletSummaryPanel(),
          extraOverrides: [
            walletRepositoryProvider.overrideWithValue(
              _WalletRepository(summary),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('스타캔디'), findsOneWidget);
      expect(find.text('보너스 스타캔디'), findsOneWidget);
      expect(find.text('코튼캔디'), findsOneWidget);
      expect(find.text('9,007,199,254,740,993'), findsOneWidget);
      expect(find.textContaining('오늘 만료 10'), findsOneWidget);
      expect(find.textContaining('다음 만료'), findsOneWidget);
      for (final label in ['스타캔디', '보너스 스타캔디', '코튼캔디']) {
        expect(tester.widget<Text>(find.text(label)).textAlign, TextAlign.left);
      }
    },
  );
}
