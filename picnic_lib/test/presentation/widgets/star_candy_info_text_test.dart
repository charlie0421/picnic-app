import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

class _WalletRepository extends WalletRepository {
  _WalletRepository() : super(_UnusedClient());

  @override
  Future<WalletSummaryModel> getSummary() async => WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.one,
    bonus: BigInt.from(2),
    cotton: BigInt.from(3),
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026, 7, 23),
  );

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

Widget _buildSubject(StarCandyInfoText child) => buildTestApp(
  child,
  extraOverrides: [
    walletRepositoryProvider.overrideWithValue(_WalletRepository()),
  ],
);

void main() {
  setUp(() {
    initTestColors();
  });

  group('StarCandyInfoText', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(_buildSubject(const StarCandyInfoText()));
      await tester.pumpAndSettle();

      expect(find.byType(StarCandyInfoText), findsOneWidget);
      expect(find.text('스타캔디'), findsOneWidget);
      expect(find.text('보너스 스타캔디'), findsOneWidget);
      expect(find.text('코튼캔디'), findsOneWidget);
    });

    testWidgets('renders with center alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildSubject(
          const StarCandyInfoText(alignment: MainAxisAlignment.center),
        ),
      );
      await tester.pump();

      expect(find.byType(StarCandyInfoText), findsOneWidget);
    });

    testWidgets('renders with start alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildSubject(
          const StarCandyInfoText(alignment: MainAxisAlignment.start),
        ),
      );
      await tester.pump();

      expect(find.byType(StarCandyInfoText), findsOneWidget);
    });
  });
}
