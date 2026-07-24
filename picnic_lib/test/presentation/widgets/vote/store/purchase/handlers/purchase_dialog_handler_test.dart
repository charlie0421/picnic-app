import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/purchase/purchase_settlement_result.dart';
import 'package:picnic_lib/data/models/wallet/candy_reward_receipt.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler.dart';

import '../../../../../../helpers/test_environment.dart';

class _MockPurchaseService extends Mock implements PurchaseService {}

void main() {
  setUpAll(() {
    initTestColors();
  });

  ActivePromotionCampaignModel campaign() => ActivePromotionCampaignModel(
    campaignId: 'campaign',
    campaignVersionId: 'version',
    code: 'BOOST',
    displayName: const {'en': 'Boost'},
    extraBonusBps: 999999,
    windowStartsAt: DateTime.utc(2026),
    windowEndsAt: DateTime.utc(2027),
    showInStore: true,
    showHomeBanner: false,
  );
  PurchaseSettlementResultModel result({
    PurchasePromotionState? state,
    String? version = 'version',
    BigInt? amount,
    BigInt? baseStarAmount,
    BigInt? baseBonusAmount,
  }) => PurchaseSettlementResultModel(
    contractVersion: 'wallet.v1',
    operationId: 'operation',
    replayed: false,
    baseStarAmount: baseStarAmount ?? BigInt.from(100),
    baseBonusAmount: baseBonusAmount ?? BigInt.from(20),
    promotion: state == null
        ? null
        : PurchasePromotionResultModel(
            resolutionId: 'resolution',
            state: state,
            campaignVersionId: version,
            promoBonusAmount: amount ?? BigInt.zero,
            domainCode: state == PurchasePromotionState.pendingTime
                ? 'PROMO_REVIEW_REQUIRED'
                : null,
          ),
    wallet: WalletSummaryModel(
      contractVersion: 'wallet.v1',
      star: BigInt.zero,
      bonus: BigInt.zero,
      cotton: BigInt.zero,
      cottonExpiringAmount: BigInt.zero,
      cottonNextExpiresAt: null,
      snapshotAt: DateTime.utc(2026),
    ),
  );

  group('receipt presentation wiring', () {
    testWidgets('success selects checking message and awaits presenter', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      final presentation = Completer<void>();
      CandyRewardReceipt? presentedReceipt;
      String? presentedMessage;
      final handler = PurchaseDialogHandler(
        context: context,
        purchaseService: _MockPurchaseService(),
        receiptContext: () => context,
        receiptPresenter: (context, receipt, {supportingMessage}) {
          presentedReceipt = receipt;
          presentedMessage = supportingMessage;
          return presentation.future;
        },
      );

      var completed = false;
      final future = handler
          .showSuccessDialog(
            result: result(state: PurchasePromotionState.pendingTime),
            displayedCampaign: campaign(),
          )
          .then((_) => completed = true);
      await tester.pump();

      expect(presentedReceipt!.items, isNotEmpty);
      expect(
        presentedMessage,
        AppLocalizations.of(context).candy_boost_promotion_checking,
      );
      expect(completed, isFalse);

      presentation.complete();
      await future;
      expect(completed, isTrue);
    });

    testWidgets('late success selects late explanation', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      final presentation = Completer<void>();
      String? presentedMessage;
      final handler = PurchaseDialogHandler(
        context: context,
        purchaseService: _MockPurchaseService(),
        receiptContext: () => context,
        receiptPresenter: (context, receipt, {supportingMessage}) {
          presentedMessage = supportingMessage;
          return presentation.future;
        },
      );

      var completed = false;
      final future = handler
          .showLatePurchaseSuccessDialog(
            result: result(),
            displayedCampaign: null,
          )
          .then((_) => completed = true);
      await tester.pump();

      expect(
        presentedMessage,
        AppLocalizations.of(context).candy_boost_late_purchase_explanation,
      );
      expect(completed, isFalse);

      presentation.complete();
      await future;
      expect(completed, isTrue);
    });
  });

  test('normal purchase receipt contains only positive star reward', () {
    final receipt = receiptFromPurchase(
      result(baseStarAmount: BigInt.from(100), baseBonusAmount: BigInt.zero),
    );

    expect(receipt!.items.map((item) => item.currency), [
      WalletCurrency.starCandy,
    ]);
  });

  test('promotion receipt combines base and promo bonus from server', () {
    final receipt = receiptFromPurchase(
      result(
        state: PurchasePromotionState.granted,
        amount: BigInt.from(30),
        baseStarAmount: BigInt.from(100),
        baseBonusAmount: BigInt.from(20),
      ),
    );

    expect(
      receipt!.items
          .singleWhere((item) => item.currency == WalletCurrency.bonusStarCandy)
          .grantedAmount,
      BigInt.from(50),
    );
  });

  test('success decision uses server amount only for matching GRANTED', () {
    final decision = decidePurchaseSuccess(
      result(state: PurchasePromotionState.granted, amount: BigInt.from(37)),
      campaign(),
    );
    expect(decision.kind, PurchaseSuccessKind.granted);
    expect(decision.promoBonusAmount, BigInt.from(37));
  });

  test('pending and eligible use checking presentation', () {
    for (final state in [
      PurchasePromotionState.pendingTime,
      PurchasePromotionState.eligible,
    ]) {
      expect(
        decidePurchaseSuccess(result(state: state), campaign()).kind,
        PurchaseSuccessKind.checking,
      );
    }
  });

  test('all non-claim cases use generic presentation', () {
    expect(
      decidePurchaseSuccess(result(), campaign()).kind,
      PurchaseSuccessKind.generic,
    );
    for (final state in [
      PurchasePromotionState.ineligible,
      PurchasePromotionState.rejected,
      PurchasePromotionState.cancelledByRefund,
    ]) {
      expect(
        decidePurchaseSuccess(result(state: state), campaign()).kind,
        PurchaseSuccessKind.generic,
      );
    }
    expect(
      decidePurchaseSuccess(
        result(state: PurchasePromotionState.granted),
        null,
      ).kind,
      PurchaseSuccessKind.generic,
    );
    expect(
      decidePurchaseSuccess(
        result(state: PurchasePromotionState.granted, version: 'other'),
        campaign(),
      ).kind,
      PurchaseSuccessKind.generic,
    );
  });

  group('parseProductDescription', () {
    test('splits description with + separator', () {
      final result = parseProductDescription('스타캔디 100개 + 보너스 10개');
      expect(result.mainDescription, '스타캔디 100개');
      expect(result.bonusDescription, '+보너스 10개');
    });

    test('handles description without + separator', () {
      final result = parseProductDescription('스타캔디 100개');
      expect(result.mainDescription, '스타캔디 100개');
      expect(result.bonusDescription, isNull);
    });

    test('handles description with multiple + separators', () {
      final result = parseProductDescription('스타캔디 100개 + 보너스 10개 + 추가 5개');
      expect(result.mainDescription, '스타캔디 100개');
      expect(result.bonusDescription, '+보너스 10개 + 추가 5개');
    });

    test('handles empty description', () {
      final result = parseProductDescription('');
      expect(result.mainDescription, '');
      expect(result.bonusDescription, isNull);
    });

    test('handles description with only +', () {
      final result = parseProductDescription('+');
      expect(result.mainDescription, '');
      expect(result.bonusDescription, '+');
    });

    test('handles description with + at start', () {
      final result = parseProductDescription('+보너스만');
      expect(result.mainDescription, '');
      expect(result.bonusDescription, '+보너스만');
    });

    test('handles description with + at end', () {
      final result = parseProductDescription('스타캔디 100개 +');
      expect(result.mainDescription, '스타캔디 100개');
      expect(result.bonusDescription, '+');
    });

    test('handles English description', () {
      final result = parseProductDescription('100 Star Candy + 10 Bonus');
      expect(result.mainDescription, '100 Star Candy');
      expect(result.bonusDescription, '+10 Bonus');
    });

    test('preserves whitespace trimming', () {
      final result = parseProductDescription('  스타캔디 100개  +  보너스 10개  ');
      expect(result.mainDescription, '스타캔디 100개');
      expect(result.bonusDescription, '+보너스 10개');
    });
  });

  group('extractStarSuffix', () {
    test('extracts number from STAR100', () {
      expect(extractStarSuffix('STAR100'), '100');
    });

    test('extracts number from STAR500', () {
      expect(extractStarSuffix('STAR500'), '500');
    });

    test('extracts number from STAR1000', () {
      expect(extractStarSuffix('STAR1000'), '1000');
    });

    test('extracts number from STAR50', () {
      expect(extractStarSuffix('STAR50'), '50');
    });

    test('returns empty string for just STAR', () {
      expect(extractStarSuffix('STAR'), '');
    });

    test('returns original string if no STAR prefix', () {
      expect(extractStarSuffix('100'), '100');
    });

    test('handles empty string', () {
      expect(extractStarSuffix(''), '');
    });

    test('removes all STAR occurrences', () {
      expect(extractStarSuffix('STARSTAR'), '');
    });

    test('handles lowercase star (no removal)', () {
      expect(extractStarSuffix('star100'), 'star100');
    });
  });

  group('shouldShowDebugInfo', () {
    test('returns true in debug mode regardless of env', () {
      // kDebugMode is a compile-time constant, but we test the function behavior
      final envInfo = {
        'environment': 'production',
        'isDebugMode': false,
        'installerStore': 'com.apple',
      };
      // In test mode, kDebugMode is true
      final result = shouldShowDebugInfo(envInfo);
      expect(result, kDebugMode || false);
    });

    test('detects TestFlight environment', () {
      final envInfo = {
        'environment': 'sandbox',
        'isDebugMode': false,
        'installerStore': 'com.apple.testflight',
      };
      // isTestFlight will be true
      final isTestFlight =
          envInfo['environment'] == 'sandbox' &&
          !(envInfo['isDebugMode'] as bool) &&
          (envInfo['installerStore'] == 'com.apple.testflight' ||
              envInfo['installerStore'] == null);
      // In test mode, shouldShowDebugInfo = kDebugMode || isTestFlight
      expect(shouldShowDebugInfo(envInfo), kDebugMode || isTestFlight);
    });

    test('sandbox with debug mode is not TestFlight', () {
      final envInfo = {
        'environment': 'sandbox',
        'isDebugMode': true,
        'installerStore': null,
      };
      final isTestFlight =
          envInfo['environment'] == 'sandbox' &&
          !(envInfo['isDebugMode'] as bool) &&
          (envInfo['installerStore'] == 'com.apple.testflight' ||
              envInfo['installerStore'] == null);
      expect(isTestFlight, isFalse);
      // But shouldShowDebugInfo may still be true due to kDebugMode
      expect(shouldShowDebugInfo(envInfo), kDebugMode || isTestFlight);
    });

    test('production environment is not TestFlight', () {
      final envInfo = {
        'environment': 'production',
        'isDebugMode': false,
        'installerStore': 'com.apple',
      };
      final isTestFlight =
          envInfo['environment'] == 'sandbox' &&
          !(envInfo['isDebugMode'] as bool) &&
          (envInfo['installerStore'] == 'com.apple.testflight' ||
              envInfo['installerStore'] == null);
      expect(isTestFlight, isFalse);
    });

    test('sandbox with null installer store counts as TestFlight', () {
      final envInfo = {
        'environment': 'sandbox',
        'isDebugMode': false,
        'installerStore': null,
      };
      final isTestFlight =
          envInfo['environment'] == 'sandbox' &&
          !(envInfo['isDebugMode'] as bool) &&
          (envInfo['installerStore'] == 'com.apple.testflight' ||
              envInfo['installerStore'] == null);
      expect(isTestFlight, isTrue);
    });
  });

  group('Price formatting pattern', () {
    test('formats price with dollar sign', () {
      final price = 0.99;
      final formatted = '$price \$';
      expect(formatted, '0.99 \$');
    });

    test('formats integer price', () {
      final price = 9.99;
      final formatted = '$price \$';
      expect(formatted, '9.99 \$');
    });

    test('formats large price', () {
      final price = 99.99;
      final formatted = '$price \$';
      expect(formatted, '99.99 \$');
    });
  });

  group('Server product data structure', () {
    test('parses standard server product', () {
      final serverProduct = {
        'id': 'STAR100',
        'price': 0.99,
        'description': {
          'ko': '스타캔디 100개 + 보너스 10개',
          'en': '100 Star Candy + 10 Bonus',
        },
      };

      expect(serverProduct['id'], 'STAR100');
      expect(serverProduct['price'], 0.99);
      expect(extractStarSuffix(serverProduct['id'] as String), '100');
    });

    test('description parsing integrates with parseProductDescription', () {
      const koDesc = '스타캔디 500개 + 보너스 50개';
      final result = parseProductDescription(koDesc);
      expect(result.mainDescription, '스타캔디 500개');
      expect(result.bonusDescription, '+보너스 50개');
    });
  });

  group('Debug info formatting', () {
    test('debug info includes all fields', () {
      final envInfo = {
        'environment': 'sandbox',
        'platform': 'iOS',
        'installerStore': 'com.apple.testflight',
        'appName': 'Picnic',
        'version': '1.0.0',
        'buildNumber': '42',
        'isDebugMode': false,
      };

      final debugInfo =
          '''
환경: ${envInfo['environment']}
플랫폼: ${envInfo['platform']}
설치 스토어: ${envInfo['installerStore'] ?? 'null'}
앱 이름: ${envInfo['appName']}
버전: ${envInfo['version']} (${envInfo['buildNumber']})
디버그 모드: ${envInfo['isDebugMode']}

오류: Test error
''';

      expect(debugInfo, contains('sandbox'));
      expect(debugInfo, contains('iOS'));
      expect(debugInfo, contains('com.apple.testflight'));
      expect(debugInfo, contains('Picnic'));
      expect(debugInfo, contains('1.0.0'));
      expect(debugInfo, contains('42'));
      expect(debugInfo, contains('Test error'));
    });

    test('debug info handles null installer store', () {
      final envInfo = <String, dynamic>{'installerStore': null};

      final store = envInfo['installerStore'] ?? 'null';
      expect(store, 'null');
    });
  });
}
