import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/candy_reward_receipt_dialog.dart';

Widget localizedApp({
  required Locale locale,
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
    child: child!,
  ),
  home: Scaffold(body: child),
);

final purchaseReceipt = CandyRewardReceipt(
  referenceKey: 'PURCHASE:test',
  items: [
    CandyRewardReceiptItem(
      currency: WalletCurrency.starCandy,
      grantedAmount: BigInt.from(1000),
      balanceAfter: BigInt.from(5000),
    ),
    CandyRewardReceiptItem(
      currency: WalletCurrency.bonusStarCandy,
      grantedAmount: BigInt.from(250),
      balanceAfter: BigInt.from(750),
    ),
  ],
);

final cottonReceipt = CandyRewardReceipt(
  referenceKey: 'AD:test',
  items: [
    CandyRewardReceiptItem(
      currency: WalletCurrency.cottonCandy,
      grantedAmount: BigInt.from(20),
      balanceAfter: null,
      expiresAt: DateTime.utc(2026, 8, 31, 15, 30),
    ),
  ],
);

void main() {
  testWidgets('renders Korean multi-currency receipt with approved assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('ko'),
        child: CandyRewardReceiptDialog(receipt: purchaseReceipt),
      ),
    );

    expect(find.text('캔디가 적립됐어요!'), findsOneWidget);
    expect(find.text('스타캔디'), findsOneWidget);
    expect(find.text('보너스 스타캔디'), findsOneWidget);
    expect(find.text('+1,000'), findsOneWidget);
    expect(find.byKey(const Key('reward-icon-STAR_CANDY')), findsOneWidget);
    expect(
      find.byKey(const Key('reward-icon-BONUS_STAR_CANDY')),
      findsOneWidget,
    );
  });

  testWidgets('uses English localization and survives 2x text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        textScaler: const TextScaler.linear(2),
        child: CandyRewardReceiptDialog(receipt: cottonReceipt),
      ),
    );

    expect(find.text('Candy added!'), findsOneWidget);
    expect(find.text('Cotton Candy'), findsOneWidget);
    expect(find.text('Balance will refresh shortly'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismisses through the localized confirmation action', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showCandyRewardReceiptDialog(
              context,
              purchaseReceipt,
              supportingMessage: 'Payment complete',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Payment complete'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.byType(CandyRewardReceiptDialog), findsNothing);
  });
}
