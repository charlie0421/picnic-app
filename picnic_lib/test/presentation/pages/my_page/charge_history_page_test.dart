import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/admin/payment_breakdown.dart';
import 'package:picnic_lib/presentation/pages/my_page/charge_history_page.dart';
import 'package:picnic_lib/presentation/providers/admin_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';

import '../../../helpers/mock_data.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

final _platformItems = [
  PaymentBreakdownItem(
    key: 'google_play',
    payCount: BigInt.from(12),
    revenueUsd: '32.50',
  ),
];

final _productItems = [
  PaymentBreakdownItem(
    key: 'star_candy_100',
    payCount: BigInt.from(4),
    revenueUsd: '8.00',
  ),
];

List<dynamic> _breakdownOverrides({
  Future<List<PaymentBreakdownItem>>? platform,
  Future<List<PaymentBreakdownItem>>? product,
}) => [
  platformPaymentBreakdownProvider.overrideWith(
    (_) => platform ?? Future.value(_platformItems),
  ),
  productPaymentBreakdownProvider.overrideWith(
    (_) => product ?? Future.value(_productItems),
  ),
];

void main() {
  setUpAll(initTestColors);

  testWidgets('shows platform and product breakdown tabs with their rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const ChargeHistoryPage(),
        userProfile: MockData.userProfile(isAdmin: true),
        extraOverrides: _breakdownOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChargeHistoryPage)),
    );
    expect(container.read(navigationInfoProvider).myPageTitle, '충전 내역');
    expect(find.text('플랫폼별'), findsOneWidget);
    expect(find.text('상품별'), findsOneWidget);
    expect(find.text('google_play'), findsOneWidget);
    expect(find.text('결제 12건 · \$32.50'), findsOneWidget);

    await tester.tap(find.text('상품별'));
    await tester.pumpAndSettle();

    expect(find.text('star_candy_100'), findsOneWidget);
    expect(find.text('결제 4건 · \$8.00'), findsOneWidget);
  });

  testWidgets('shows loading, error, and empty states for a breakdown tab', (
    tester,
  ) async {
    final loading = Completer<List<PaymentBreakdownItem>>();
    await tester.pumpWidget(
      buildTestApp(
        const ChargeHistoryPage(),
        userProfile: MockData.userProfile(isAdmin: true),
        extraOverrides: _breakdownOverrides(platform: loading.future),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    loading.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('충전 내역을 불러오지 못했습니다.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    await tester.pumpWidget(
      buildTestApp(
        const ChargeHistoryPage(),
        userProfile: MockData.userProfile(isAdmin: true),
        extraOverrides: _breakdownOverrides(platform: Future.value([])),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('충전 내역이 없습니다.'), findsOneWidget);
  });

  testWidgets('denies direct access for a non-administrator', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const ChargeHistoryPage(),
        userProfile: MockData.userProfile(isAdmin: false),
        extraOverrides: _breakdownOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('접근 권한이 없습니다.'), findsOneWidget);
    expect(find.text('플랫폼별'), findsNothing);
  });

  testWidgets('uses an exact 16px horizontal content inset', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        const ChargeHistoryPage(),
        userProfile: MockData.userProfile(isAdmin: true),
        extraOverrides: _breakdownOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(
      find.byKey(const Key('charge-history-list')),
    );
    final padding = list.padding! as EdgeInsets;
    expect(padding.left, 16);
    expect(padding.right, 16);
  });
}
