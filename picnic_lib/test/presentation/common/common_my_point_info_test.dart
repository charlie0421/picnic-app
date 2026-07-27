import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/common/common_my_point_info.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/gradient_border_painter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommonMyPoint', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider.overrideWith(
              () => _MockScreenInfosNotifier({}),
            ),
          ],
        ),
      );
      await tester.pump();
      // Clear Image.asset errors (asset not available in test)
      tester.takeException();

      expect(find.byType(CommonMyPoint), findsOneWidget);
    });

    testWidgets('contains CustomPaint with GradientBorderPainter', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider.overrideWith(
              () => _MockScreenInfosNotifier({}),
            ),
          ],
        ),
      );
      await tester.pump();
      tester.takeException();

      final customPaint = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is GradientBorderPainter,
      );
      expect(customPaint, findsOneWidget);
    });

    testWidgets('contains Row widget', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider.overrideWith(
              () => _MockScreenInfosNotifier({}),
            ),
          ],
        ),
      );
      await tester.pump();
      tester.takeException();

      final rowFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Row &&
            widget.mainAxisAlignment == MainAxisAlignment.spaceBetween,
      );
      expect(rowFinder, findsOneWidget);
    });

    testWidgets('displays the precise total of all three wallet currencies', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider.overrideWith(
              () => _MockScreenInfosNotifier({}),
            ),
            walletRepositoryProvider.overrideWithValue(_WalletRepository()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      tester.takeException();

      expect(find.text('9,007,199,254,741,023'), findsOneWidget);
    });

    testWidgets('GestureDetector is present for tap', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const CommonMyPoint(),
          extraOverrides: [
            screenInfosProvider.overrideWith(
              () => _MockScreenInfosNotifier({}),
            ),
          ],
        ),
      );
      await tester.pump();
      tester.takeException();

      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}

class _UnusedClient extends Fake implements SupabaseClient {}

class _WalletRepository extends WalletRepository {
  _WalletRepository() : super(_UnusedClient());

  @override
  Future<WalletSummaryModel> getSummary() async => WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.parse('9007199254740993'),
    bonus: BigInt.from(20),
    cotton: BigInt.from(10),
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

class _MockScreenInfosNotifier extends ScreenInfosNotifier {
  final Map<String, ScreenInfo> _initial;

  _MockScreenInfosNotifier(this._initial);

  @override
  Map<String, ScreenInfo> build() => _initial;
}
