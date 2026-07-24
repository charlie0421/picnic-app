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

final unavailableCottonReceipt = CandyRewardReceipt(
  referenceKey: 'AD:unavailable',
  items: [
    CandyRewardReceiptItem(
      currency: WalletCurrency.cottonCandy,
      grantedAmount: BigInt.from(20),
      balanceAfter: null,
    ),
  ],
);

final crowdedReceipt = CandyRewardReceipt(
  referenceKey: 'PURCHASE:crowded',
  items: List.generate(
    6,
    (index) => CandyRewardReceiptItem(
      currency: WalletCurrency.starCandy,
      grantedAmount: BigInt.from(1000 + index),
      balanceAfter: BigInt.from(5000 + index),
    ),
  ),
);

void main() {
  test('formats arbitrary-precision amounts with Bengali grouping pattern', () {
    expect(
      formatCandyRewardAmount(
        BigInt.parse('123456789012345678901234567'),
        const Locale('bn'),
      ),
      '১২,৩৪,৫৬,৭৮,৯০,১২,৩৪,৫৬,৭৮,৯০,১২,৩৪,৫৬৭',
    );
  });

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

  testWidgets('includes localized expiry in the single row semantics label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        child: CandyRewardReceiptDialog(receipt: cottonReceipt),
      ),
    );

    expect(
      find.bySemanticsLabel(
        RegExp(
          r'^Cotton Candy, added 20, balance will refresh shortly, '
          r'Expires .+$',
        ),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('uses a non-duplicated unavailable balance semantics branch', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        child: CandyRewardReceiptDialog(receipt: unavailableCottonReceipt),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Cotton Candy, added 20, balance will refresh shortly',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'current balance Balance')),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('keeps confirmation reachable in a narrow short 2x viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        textScaler: const TextScaler.linear(2),
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showCandyRewardReceiptDialog(
              context,
              crowdedReceipt,
              supportingMessage:
                  'Your updated balance may take a moment to appear.',
            ),
            child: const Text('Open crowded receipt'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open crowded receipt'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final scrollable = find.descendant(
      of: find.byType(CandyRewardReceiptDialog),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Confirm'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Confirm').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Confirm').hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(CandyRewardReceiptDialog), findsNothing);
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
